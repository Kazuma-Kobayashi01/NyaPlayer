//! Playback engine thread (TECH_SPEC §4.3).
//!
//! One thread owns the output device (`MixerDeviceSink`) and a rodio
//! `Player`, which plays appended sources back to back in the same output
//! stream. The engine keeps at most two sources in it: the current track and
//! the prefetched next one, so track changes are gapless. Commands arrive on
//! a channel; state changes go out through the `emit` callback.

use std::collections::{HashSet, VecDeque};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::mpsc::{Receiver, RecvTimeoutError};
use std::sync::Arc;
use std::time::Duration;

use rodio::cpal::traits::{DeviceTrait, HostTrait};
use rodio::cpal::{BufferSize, SupportedBufferSize};
use rodio::source::UniformSourceIterator;
use rodio::{
    ChannelCount, Decoder, DeviceSinkBuilder, MixerDeviceSink, Player, SampleRate, Source,
};

use crate::dsp::eq::{EqSettings, EqShared, EqSource};
use crate::player::queue::{LoopMode, PlayQueue, RemoveEffect};
use crate::player::tracked::Tracked;

/// How often the engine polls the audio thread's atomics.
const POLL: Duration = Duration::from_millis(20);

/// Consecutive files that fail to open before playback stops (FMT-07).
const MAX_CONSECUTIVE_FAILURES: u32 = 5;

#[derive(Debug)]
pub enum Command {
    OpenQueue {
        paths: Vec<String>,
        start: usize,
        autoplay: bool,
    },
    Play,
    Pause,
    Seek(Duration),
    JumpTo(usize),
    Add(String),
    Insert(usize, String),
    Remove(usize),
    Move(usize, usize),
    Reorder(Vec<usize>),
    SetLoopMode(LoopMode),
    SetEqualizer(EqSettings),
    SetVolume(f32),
    Shutdown,
}

#[derive(Clone, Debug, PartialEq)]
pub enum Event {
    Playing(bool),
    Index(Option<usize>),
    Completed,
    Error(String),
}

/// State shared with the API layer for cheap synchronous reads.
#[derive(Default)]
pub struct Shared {
    pub position_ms: AtomicU64,
}

/// A source sitting in rodio's queue.
struct Queued {
    item_id: u64,
    token: u64,
    cancel: Arc<AtomicBool>,
}

pub struct Engine {
    emit: Box<dyn Fn(Event) + Send>,
    shared: Arc<Shared>,
    queue: PlayQueue,
    sink: Option<MixerDeviceSink>,
    player: Option<Player>,
    queued: VecDeque<Queued>,
    started: Arc<AtomicU64>,
    last_started: u64,
    next_token: u64,
    device_lost: Arc<AtomicBool>,
    eq: Arc<EqShared>,
    playing: bool,
    volume: f32,
    failures: u32,
    /// Items whose file could not be opened; skipped by prefetch and
    /// reported only once.
    bad_items: HashSet<u64>,
}

impl Engine {
    pub fn new(emit: Box<dyn Fn(Event) + Send>, shared: Arc<Shared>) -> Self {
        Self {
            emit,
            shared,
            queue: PlayQueue::new(),
            sink: None,
            player: None,
            queued: VecDeque::new(),
            started: Arc::new(AtomicU64::new(0)),
            last_started: 0,
            next_token: 1,
            device_lost: Arc::new(AtomicBool::new(false)),
            eq: EqShared::new(),
            playing: false,
            volume: 1.0,
            failures: 0,
            bad_items: HashSet::new(),
        }
    }

    /// Runs until `Shutdown` or until every sender is dropped.
    pub fn run(mut self, rx: Receiver<Command>) {
        loop {
            match rx.recv_timeout(POLL) {
                Ok(Command::Shutdown) | Err(RecvTimeoutError::Disconnected) => break,
                Ok(cmd) => self.handle(cmd),
                Err(RecvTimeoutError::Timeout) => {}
            }
            self.poll();
        }
        self.player = None;
        self.sink = None;
    }

    fn handle(&mut self, cmd: Command) {
        match cmd {
            Command::OpenQueue {
                paths,
                start,
                autoplay,
            } => {
                self.bad_items.clear();
                self.queue.set(paths, start);
                match self.queue.current() {
                    Some(index) => self.start_at(index, autoplay, None),
                    None => self.stop(),
                }
            }
            Command::Play => self.play(),
            Command::Pause => {
                if let Some(player) = &self.player {
                    player.pause();
                }
                self.set_playing(false);
            }
            Command::Seek(pos) => {
                if let Some(player) = &self.player {
                    if let Err(e) = player.try_seek(pos) {
                        self.emit(Event::Error(format!("seek failed: {e}")));
                    }
                    self.shared
                        .position_ms
                        .store(pos.as_millis() as u64, Ordering::Relaxed);
                }
            }
            Command::JumpTo(index) => {
                if index < self.queue.len() {
                    self.start_at(index, self.playing, None);
                }
            }
            Command::Add(path) => {
                if self.queue.add(path) {
                    self.emit(Event::Index(self.queue.current()));
                }
                self.refresh_next();
            }
            Command::Insert(index, path) => {
                if self.queue.insert(index, path) {
                    self.emit(Event::Index(self.queue.current()));
                }
                self.refresh_next();
            }
            Command::Remove(index) => match self.queue.remove(index) {
                RemoveEffect::CurrentRemoved => match self.queue.current() {
                    Some(next) => self.start_at(next, self.playing, None),
                    None => self.stop(),
                },
                RemoveEffect::CurrentKept => {
                    self.emit(Event::Index(self.queue.current()));
                    self.refresh_next();
                }
            },
            Command::Move(from, to) => {
                if self.queue.move_item(from, to) {
                    self.emit(Event::Index(self.queue.current()));
                }
                self.refresh_next();
            }
            Command::SetLoopMode(mode) => {
                self.queue.loop_mode = mode;
                self.refresh_next();
            }
            Command::Reorder(order) => match self.queue.reorder(order) {
                Ok(changed) => {
                    if changed {
                        self.emit(Event::Index(self.queue.current()));
                    }
                    self.refresh_next();
                }
                Err(message) => self.emit(Event::Error(message.into())),
            },
            Command::SetEqualizer(settings) => self.eq.set(settings),
            Command::SetVolume(volume) => {
                self.volume = volume.clamp(0.0, 1.0);
                if let Some(player) = &self.player {
                    player.set_volume(self.volume);
                }
            }
            Command::Shutdown => {}
        }
    }

    fn emit(&self, event: Event) {
        (self.emit)(event);
    }

    fn set_playing(&mut self, playing: bool) {
        if self.playing != playing {
            self.playing = playing;
            self.emit(Event::Playing(playing));
        }
    }

    fn play(&mut self) {
        let Some(current) = self.queue.current() else {
            return;
        };
        match &self.player {
            // Nothing loaded (first play, or after the queue completed):
            // start the current item from the beginning.
            Some(player) if !player.empty() => {
                player.play();
                self.set_playing(true);
            }
            _ => self.start_at(current, true, None),
        }
    }

    /// Drops everything and goes silent.
    fn stop(&mut self) {
        self.cancel_all();
        self.player = None;
        self.shared.position_ms.store(0, Ordering::Relaxed);
        self.emit(Event::Index(self.queue.current()));
        self.set_playing(false);
    }

    fn cancel_all(&mut self) {
        for q in self.queued.drain(..) {
            q.cancel.store(true, Ordering::Release);
        }
    }

    fn ensure_sink(&mut self) -> bool {
        if self.sink.is_some() {
            return true;
        }
        let lost = self.device_lost.clone();
        let opened = DeviceSinkBuilder::from_default_device().and_then(|builder| {
            builder
                .with_buffer_size(output_buffer_size())
                .with_error_callback(move |err| {
                    log::warn!("output stream error: {err}");
                    lost.store(true, Ordering::Release);
                })
                .open_stream()
        });
        match opened {
            Ok(mut sink) => {
                sink.log_on_drop(false);
                self.sink = Some(sink);
                true
            }
            Err(e) => {
                self.emit(Event::Error(format!("cannot open audio output: {e}")));
                false
            }
        }
    }

    /// Starts `index` from the beginning (or `seek`), replacing whatever is
    /// loaded, then prefetches the next item. Files that fail to open are
    /// reported and skipped.
    fn start_at(&mut self, mut index: usize, autoplay: bool, seek: Option<Duration>) {
        if !self.ensure_sink() {
            self.set_playing(false);
            return;
        }
        self.cancel_all();
        let player = Player::connect_new(self.sink.as_ref().expect("sink").mixer());
        player.set_volume(self.volume);
        if !autoplay {
            player.pause();
        }
        self.player = Some(player);
        self.shared.position_ms.store(0, Ordering::Relaxed);

        let mut tried = 0usize;
        loop {
            if self.append(index) {
                self.failures = 0;
                break;
            }
            self.failures += 1;
            tried += 1;
            let next = match self.queue.loop_mode {
                // Repeating a broken file would spin; move on instead.
                LoopMode::One if index + 1 < self.queue.len() => Some(index + 1),
                LoopMode::One => None,
                _ => self.queue.next_after(index),
            };
            match next {
                Some(n) if self.failures < MAX_CONSECUTIVE_FAILURES && tried < self.queue.len() => {
                    index = n
                }
                _ => {
                    self.queue.set_current(Some(index));
                    self.player = None;
                    self.emit(Event::Index(self.queue.current()));
                    self.set_playing(false);
                    return;
                }
            }
        }

        self.queue.set_current(Some(index));
        self.last_started = self.started.load(Ordering::Acquire);
        self.emit(Event::Index(Some(index)));
        if let (Some(pos), Some(player)) = (seek, &self.player) {
            let _ = player.try_seek(pos);
        }
        self.refresh_next();
        self.set_playing(autoplay);
    }

    /// Opens the item at `index` and appends it to the player. Returns false
    /// (after reporting) when the file cannot be decoded.
    fn append(&mut self, index: usize) -> bool {
        let Some(item) = self.queue.item(index).cloned() else {
            return false;
        };
        let (Some(player), Some(sink)) = (&self.player, &self.sink) else {
            return false;
        };
        match open_decoder(&item.path) {
            Ok(decoder) => {
                let token = self.next_token;
                self.next_token += 1;
                let cancel = Arc::new(AtomicBool::new(false));
                let source = Tracked::new(
                    output_source(
                        decoder,
                        sink.config().channel_count(),
                        sink.config().sample_rate(),
                        self.eq.clone(),
                    ),
                    token,
                    self.started.clone(),
                    cancel.clone(),
                );
                player.append(source);
                self.queued.push_back(Queued {
                    item_id: item.id,
                    token,
                    cancel,
                });
                true
            }
            Err(e) => {
                if self.bad_items.insert(item.id) {
                    self.emit(Event::Error(format!("{}: {e}", item.path)));
                }
                false
            }
        }
    }

    /// Makes sure the prefetched source is the item that should play next,
    /// replacing it after queue edits or loop-mode changes.
    fn refresh_next(&mut self) {
        if self.player.is_none() || self.queued.is_empty() {
            return;
        }
        let wanted = self
            .next_playable()
            .and_then(|i| self.queue.item(i))
            .map(|item| item.id);
        // Everything after the playing source is a prefetch.
        while self.queued.len() > 1 {
            let last = self.queued.back().expect("len > 1");
            if Some(last.item_id) == wanted && self.queued.len() == 2 {
                return;
            }
            let stale = self.queued.pop_back().expect("len > 1");
            stale.cancel.store(true, Ordering::Release);
        }
        // Prefetch the next readable item; unreadable ones are skipped (they
        // are marked bad by `append`, so `next_playable` moves past them).
        while let Some(next) = self.next_playable() {
            if self.append(next) {
                break;
            }
        }
    }

    /// The item that should play after the current one, skipping items that
    /// are known to be unreadable.
    fn next_playable(&self) -> Option<usize> {
        let mut candidate = self.queue.next_index();
        for _ in 0..self.queue.len() {
            let index = candidate?;
            let item = self.queue.item(index)?;
            if !self.bad_items.contains(&item.id) {
                return Some(index);
            }
            candidate = self.queue.next_after(index);
        }
        None
    }

    fn poll(&mut self) {
        if self.device_lost.swap(false, Ordering::AcqRel) {
            self.recover_device();
        }

        let started = self.started.load(Ordering::Acquire);
        if started != self.last_started {
            self.last_started = started;
            self.on_track_started(started);
        }

        let Some(player) = &self.player else {
            return;
        };
        self.shared
            .position_ms
            .store(player.get_pos().as_millis() as u64, Ordering::Relaxed);

        if self.playing && player.empty() {
            // Ran off the end of the queue (loop none).
            self.queued.clear();
            self.player = None;
            self.shared.position_ms.store(0, Ordering::Relaxed);
            self.set_playing(false);
            self.emit(Event::Completed);
        }
    }

    /// A prefetched source produced its first sample: it is now current.
    fn on_track_started(&mut self, token: u64) {
        let Some(pos) = self.queued.iter().position(|q| q.token == token) else {
            return;
        };
        // Sources before it have finished playing.
        self.queued.drain(..pos);
        let item_id = self.queued.front().expect("found").item_id;
        if let Some(index) = self.queue.index_of(item_id) {
            if self.queue.current() != Some(index) {
                self.queue.set_current(Some(index));
                self.emit(Event::Index(Some(index)));
            }
        }
        self.failures = 0;
        self.refresh_next();
    }

    /// The output device went away (unplugged, Bluetooth dropped). Reopen the
    /// default device and continue the current item from where it was.
    fn recover_device(&mut self) {
        let pos = self.player.as_ref().map(|p| p.get_pos());
        self.cancel_all();
        self.player = None;
        self.sink = None;
        if let Some(current) = self.queue.current() {
            self.start_at(current, self.playing, pos);
        }
    }
}

/// Convert each track to the opened device format before building EQ
/// coefficients (TECH_SPEC §4.3/§5.1). The mixer's final conversion is then
/// a passthrough, including when adjacent tracks have different formats.
fn output_source<S: Source>(
    source: S,
    channels: ChannelCount,
    sample_rate: SampleRate,
    eq: Arc<EqShared>,
) -> EqSource<UniformSourceIterator<S>> {
    EqSource::new(
        UniformSourceIterator::new(source, channels, sample_rate),
        eq,
    )
}

/// Preferred output buffer in frames (~40 ms at 48 kHz): large enough to be
/// power-friendly, small enough for responsive pause/seek/EQ.
const PREFERRED_BUFFER_FRAMES: u32 = 2048;

/// rodio asks for a fixed 2048-frame buffer by default, which some devices
/// reject (e.g. Bluetooth earbuds on macOS allow at most 1024). Clamp the
/// preferred size into the range the default device reports.
fn output_buffer_size() -> BufferSize {
    let range = rodio::cpal::default_host()
        .default_output_device()
        .and_then(|d| d.default_output_config().ok())
        .map(|c| *c.buffer_size());
    match range {
        Some(SupportedBufferSize::Range { min, max }) => {
            BufferSize::Fixed(PREFERRED_BUFFER_FRAMES.clamp(min, max))
        }
        _ => BufferSize::Default,
    }
}

fn open_decoder(path: &str) -> anyhow::Result<Decoder<BufReader<File>>> {
    let file = File::open(path)?;
    let len = file.metadata()?.len();
    let mut builder = Decoder::builder()
        .with_data(BufReader::new(file))
        .with_byte_len(len)
        .with_seekable(true)
        .with_gapless(true);
    if let Some(ext) = Path::new(path).extension().and_then(|e| e.to_str()) {
        builder = builder.with_hint(&ext.to_ascii_lowercase());
    }
    Ok(builder.build()?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use rodio::buffer::SamplesBuffer;
    use std::num::NonZero;

    #[test]
    fn reorder_keeps_playing_samples_position_and_prefetch_alive() {
        // Render entirely in memory: no audio device and no audible test process.
        let (mixer, mut output) =
            rodio::mixer::mixer(NonZero::new(1).unwrap(), NonZero::new(48_000).unwrap());
        let player = Player::connect_new(&mixer);
        player.append(SamplesBuffer::new(
            NonZero::new(1).unwrap(),
            NonZero::new(48_000).unwrap(),
            (0..4096).map(|i| i as f32 / 4096.0).collect::<Vec<_>>(),
        ));
        for i in 0..16 {
            assert_eq!(output.next(), Some(i as f32 / 4096.0));
        }
        let (tx, rx) = std::sync::mpsc::channel();
        let shared = Arc::new(Shared::default());
        shared.position_ms.store(42_000, Ordering::Relaxed);
        let mut engine = Engine::new(
            Box::new(move |e| {
                tx.send(e).unwrap();
            }),
            shared.clone(),
        );
        engine
            .queue
            .set(vec!["a".into(), "b".into(), "c".into()], 1);
        engine.player = Some(player);
        engine.playing = true;
        let current = Arc::new(AtomicBool::new(false));
        let next = Arc::new(AtomicBool::new(false));
        for (index, cancel) in [(1, current.clone()), (2, next.clone())] {
            engine.queued.push_back(Queued {
                item_id: engine.queue.item(index).unwrap().id,
                token: index as u64,
                cancel,
            });
        }
        engine.handle(Command::Reorder(vec![1, 2, 0]));
        assert!(engine.playing);
        assert_eq!(shared.position_ms.load(Ordering::Relaxed), 42_000);
        assert!(!current.load(Ordering::Relaxed));
        assert!(!next.load(Ordering::Relaxed));
        assert_eq!(
            rx.try_iter().collect::<Vec<_>>(),
            vec![Event::Index(Some(0))]
        );
        for i in 16..32 {
            assert_eq!(output.next(), Some(i as f32 / 4096.0));
        }
    }

    fn sine(sample_rate: u32, frequency: f32) -> SamplesBuffer {
        let data: Vec<f32> = (0..sample_rate)
            .map(|i| {
                0.1 * (std::f32::consts::TAU * frequency * i as f32 / sample_rate as f32).sin()
            })
            .collect();
        SamplesBuffer::new(
            NonZero::new(1).unwrap(),
            NonZero::new(sample_rate).unwrap(),
            data,
        )
    }

    #[test]
    fn hires_resampling_keeps_duration_and_eq_center_frequency() {
        let input = sine(192_000, 1000.0);
        let eq = EqShared::new();
        let mut settings = EqSettings::default();
        settings.gains_db[5] = 6.0;
        eq.set(settings);
        let source = output_source(
            input,
            NonZero::new(2).unwrap(),
            NonZero::new(48_000).unwrap(),
            eq,
        );
        assert_eq!(source.sample_rate().get(), 48_000);
        assert_eq!(source.channels().get(), 2);
        assert_eq!(source.total_duration(), Some(Duration::from_secs(1)));
        let output: Vec<f32> = source.collect();
        assert!(
            output.len().abs_diff(96_000) <= 2,
            "{} samples",
            output.len()
        );
        assert!(output
            .as_chunks::<2>()
            .0
            .iter()
            .all(|frame| frame[0] == frame[1]));
        let steady: Vec<f32> = output.iter().skip(19_200).step_by(2).copied().collect();
        let rms = (steady.iter().map(|v| f64::from(*v).powi(2)).sum::<f64>() / steady.len() as f64)
            .sqrt();
        let gain_db = 20.0 * (rms / (0.1 / 2.0f64.sqrt())).log10();
        assert!((gain_db - 6.0).abs() < 0.2, "1 kHz gain: {gain_db} dB");
    }

    #[test]
    fn eq_skips_bands_above_output_nyquist_even_for_hires_input() {
        let input = sine(192_000, 8000.0);
        let channels = NonZero::new(1).unwrap();
        let sample_rate = NonZero::new(22_050).unwrap();
        let baseline: Vec<f32> =
            output_source(input.clone(), channels, sample_rate, EqShared::new()).collect();
        let eq = EqShared::new();
        let mut settings = EqSettings::default();
        settings.gains_db[9] = 12.0; // 16 kHz is valid at 192k, not at 22.05k.
        eq.set(settings);
        let output: Vec<f32> = output_source(input, channels, sample_rate, eq).collect();
        assert_eq!(output, baseline);
    }

    #[test]
    fn upsampling_keeps_high_band_active_at_the_output_rate() {
        let input = sine(44_100, 8000.0);
        let channels = NonZero::new(2).unwrap();
        let sample_rate = NonZero::new(48_000).unwrap();
        let baseline: Vec<f32> =
            output_source(input.clone(), channels, sample_rate, EqShared::new()).collect();
        let eq = EqShared::new();
        let mut settings = EqSettings::default();
        settings.gains_db[9] = 12.0;
        eq.set(settings);
        let output: Vec<f32> = output_source(input, channels, sample_rate, eq).collect();
        assert_eq!(output.len(), baseline.len());
        assert!(output.iter().all(|v| v.is_finite()));
        assert!(output
            .iter()
            .zip(&baseline)
            .any(|(a, b)| (a - b).abs() > 0.001));
    }

    #[test]
    fn decoded_flac_tracks_join_without_padding_or_lost_samples() {
        // The existing fixture is 250 ms of 440 Hz (110 complete cycles),
        // so two copies form a continuous sine across the track boundary.
        let path = concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/sine_44k_16bit_mono.flac.bin"
        );
        for rate in [44_100, 48_000] {
            let channels = NonZero::new(2).unwrap();
            let sample_rate = NonZero::new(rate).unwrap();
            let eq = EqShared::new();
            let first: Vec<f32> = output_source(
                open_decoder(path).unwrap(),
                channels,
                sample_rate,
                eq.clone(),
            )
            .collect();
            assert!(first.len().abs_diff((rate / 4 * 2) as usize) <= 2);
            let (input, output) = rodio::queue::queue(false);
            let started = Arc::new(AtomicU64::new(0));
            for token in [1, 2] {
                input.append(Tracked::new(
                    output_source(
                        open_decoder(path).unwrap(),
                        channels,
                        sample_rate,
                        eq.clone(),
                    ),
                    token,
                    started.clone(),
                    Arc::new(AtomicBool::new(false)),
                ));
            }
            let joined: Vec<f32> = output.collect();
            let expected: Vec<f32> = first.iter().chain(&first).copied().collect();
            assert_eq!(joined, expected, "track boundary at {rate} Hz");
            let boundary_step = (joined[first.len()] - joined[first.len() - 2]).abs();
            assert!(boundary_step < 0.02, "sine discontinuity: {boundary_step}");
            assert_eq!(started.load(Ordering::Acquire), 2);
        }
    }
}
