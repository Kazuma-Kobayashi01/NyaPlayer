//! 10-band peaking equalizer (TECH_SPEC §5.1).
//!
//! * RBJ cookbook peaking biquads, 1 octave bandwidth (Q ≈ 1.414), f32,
//!   Direct Form 2 Transposed, independent state per channel.
//! * Linear preamp applied before the filters.
//! * Bit-identical bypass when disabled / flat / no active band.
//! * Lock-free on the audio path: the iterator only does an atomic load per
//!   control block and a `try_lock` when the version changed.
//! * Settings changes are ramped over ~20 ms (coefficients recomputed per
//!   32-frame block, preamp interpolated per frame) to avoid clicks.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use biquad::{Biquad, Coefficients, DirectForm2Transposed, Type};
use rodio::source::SeekError;
use rodio::{ChannelCount, Sample, SampleRate, Source};

/// Center frequencies of the 10 bands, in Hz.
pub const BAND_FREQUENCIES: [f32; 10] = [
    31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0,
];

const NUM_BANDS: usize = BAND_FREQUENCIES.len();
/// One octave bandwidth.
const BAND_Q: f32 = std::f32::consts::SQRT_2;
/// Bands at or above this fraction of the sample rate are skipped.
const MAX_FREQ_RATIO: f32 = 0.45;
/// Frames between control updates (settings polling, ramp steps).
const BLOCK_FRAMES: u32 = 32;
/// Ramp duration for settings changes.
const RAMP_SECONDS: f32 = 0.020;
/// Channels beyond this count get the preamp but no filtering
/// (fixed-size storage so the audio path never allocates).
const MAX_CHANNELS: usize = 8;
/// Gains with a smaller magnitude than this (dB) are treated as 0.
const GAIN_EPSILON_DB: f32 = 1e-4;

/// User-facing equalizer settings.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct EqSettings {
    pub enabled: bool,
    pub gains_db: [f32; 10],
    pub preamp_db: f32,
}

impl Default for EqSettings {
    fn default() -> Self {
        Self {
            enabled: true,
            gains_db: [0.0; 10],
            preamp_db: 0.0,
        }
    }
}

/// Settings shared between the control thread (writer) and the audio
/// thread(s) (readers). Readers never block: they poll `version` and use
/// `try_lock` to copy the settings.
#[derive(Debug, Default)]
pub struct EqShared {
    settings: Mutex<EqSettings>,
    version: AtomicU64,
}

impl EqShared {
    pub fn new() -> Arc<Self> {
        Arc::new(Self::default())
    }

    /// Updates the settings. Called from a normal (non-audio) thread.
    pub fn set(&self, settings: EqSettings) {
        {
            let mut guard = self.settings.lock().unwrap_or_else(|e| e.into_inner());
            *guard = settings;
        }
        self.version.fetch_add(1, Ordering::Release);
    }

    /// Returns a copy of the current settings (may block briefly; not for
    /// the audio path).
    pub fn get(&self) -> EqSettings {
        *self.settings.lock().unwrap_or_else(|e| e.into_inner())
    }

    fn version(&self) -> u64 {
        self.version.load(Ordering::Acquire)
    }

    /// Non-blocking read for the audio path. Returns `None` if contended.
    fn try_read(&self) -> Option<(u64, EqSettings)> {
        // Read version first: if a writer bumps it after we copy, we'll
        // simply see a newer version next block and re-read.
        let version = self.version();
        match self.settings.try_lock() {
            Ok(guard) => Some((version, *guard)),
            Err(std::sync::TryLockError::Poisoned(e)) => Some((version, *e.into_inner())),
            Err(std::sync::TryLockError::WouldBlock) => None,
        }
    }
}

#[inline]
fn db_to_lin(db: f32) -> f32 {
    10f32.powf(db / 20.0)
}

/// Effective (target) gains for a settings value: disabled ⇒ flat.
fn targets(settings: &EqSettings) -> ([f32; NUM_BANDS], f32) {
    if settings.enabled {
        let mut g = settings.gains_db;
        for v in &mut g {
            if !v.is_finite() {
                *v = 0.0;
            }
        }
        let p = if settings.preamp_db.is_finite() {
            settings.preamp_db
        } else {
            0.0
        };
        (g, p)
    } else {
        ([0.0; NUM_BANDS], 0.0)
    }
}

const IDENTITY: Coefficients<f32> = Coefficients {
    a1: 0.0,
    a2: 0.0,
    b0: 1.0,
    b1: 0.0,
    b2: 0.0,
};

/// Wraps a rodio source and applies the 10-band EQ.
pub struct EqSource<S> {
    inner: S,
    shared: Arc<EqShared>,
    seen_version: u64,

    // Stream format.
    channels: u16,
    sample_rate: u32,
    channel_idx: usize,
    frames_in_block: u32,

    // Filters: [channel][band].
    filters: [[DirectForm2Transposed<f32>; NUM_BANDS]; MAX_CHANNELS],
    band_active: [bool; NUM_BANDS],
    any_band_active: bool,

    // Effective values (what is currently applied) and ramp state.
    cur_gains: [f32; NUM_BANDS],
    cur_preamp_db: f32,
    ramp_from_gains: [f32; NUM_BANDS],
    ramp_from_preamp: f32,
    target_gains: [f32; NUM_BANDS],
    target_preamp: f32,
    ramp_block: u32,
    ramp_blocks: u32,

    // Preamp, interpolated per frame inside a block.
    preamp_lin: f32,
    preamp_step: f32,
    preamp_block_end: f32,

    bypass: bool,
}

impl<S: Source> EqSource<S> {
    pub fn new(inner: S, shared: Arc<EqShared>) -> Self {
        let (version, settings) = (shared.version(), shared.get());
        let (gains, preamp) = targets(&settings);
        let channels = inner.channels().get();
        let sample_rate = inner.sample_rate().get();
        let preamp_lin = db_to_lin(preamp);
        let mut s = Self {
            inner,
            shared,
            seen_version: version,
            channels,
            sample_rate,
            channel_idx: 0,
            frames_in_block: 0,
            filters: [[DirectForm2Transposed::<f32>::new(IDENTITY); NUM_BANDS]; MAX_CHANNELS],
            band_active: [false; NUM_BANDS],
            any_band_active: false,
            cur_gains: gains,
            cur_preamp_db: preamp,
            ramp_from_gains: gains,
            ramp_from_preamp: preamp,
            target_gains: gains,
            target_preamp: preamp,
            ramp_block: 0,
            ramp_blocks: 0,
            preamp_lin,
            preamp_step: 0.0,
            preamp_block_end: preamp_lin,
            bypass: true,
        };
        s.update_coefficients(true);
        s.update_bypass();
        s
    }

    fn is_ramping(&self) -> bool {
        self.ramp_block < self.ramp_blocks
    }

    fn update_bypass(&mut self) {
        self.bypass = !self.is_ramping()
            && !self.any_band_active
            && self.cur_preamp_db.abs() < GAIN_EPSILON_DB
            && self.preamp_step == 0.0;
    }

    /// Recomputes coefficients for `cur_gains`. Bands becoming active get
    /// their state reset (a 0 dB peaking filter is an identity with zero
    /// state, so this is continuous).
    fn update_coefficients(&mut self, reset_all: bool) {
        let fs = self.sample_rate as f32;
        let mut any = false;
        for band in 0..NUM_BANDS {
            let f0 = BAND_FREQUENCIES[band];
            let gain = self.cur_gains[band];
            let coeffs = if f0 < MAX_FREQ_RATIO * fs && gain.abs() >= GAIN_EPSILON_DB {
                Coefficients::<f32>::from_normalized_params(
                    Type::PeakingEQ(gain),
                    2.0 * f0 / fs,
                    BAND_Q,
                )
                .ok()
            } else {
                None
            };
            let was_active = self.band_active[band];
            match coeffs {
                Some(c) => {
                    for ch in &mut self.filters {
                        if reset_all || !was_active {
                            ch[band].reset_state();
                        }
                        ch[band].update_coefficients(c);
                    }
                    self.band_active[band] = true;
                    any = true;
                }
                None => self.band_active[band] = false,
            }
        }
        self.any_band_active = any;
    }

    fn reset_filter_state(&mut self) {
        for ch in &mut self.filters {
            for f in ch {
                f.reset_state();
            }
        }
    }

    /// Runs at the start of every control block (frame-aligned).
    fn control_block(&mut self) {
        // Finish previous block's preamp interpolation exactly.
        self.preamp_lin = self.preamp_block_end;
        self.preamp_step = 0.0;

        // Poll for new settings (lock-free; skipped if contended).
        if self.shared.version() != self.seen_version {
            if let Some((version, settings)) = self.shared.try_read() {
                self.seen_version = version;
                let (gains, preamp) = targets(&settings);
                if gains != self.target_gains || preamp != self.target_preamp {
                    self.ramp_from_gains = self.cur_gains;
                    self.ramp_from_preamp = self.cur_preamp_db;
                    self.target_gains = gains;
                    self.target_preamp = preamp;
                    let ramp_frames = (RAMP_SECONDS * self.sample_rate as f32).max(1.0);
                    self.ramp_blocks = ((ramp_frames / BLOCK_FRAMES as f32).ceil() as u32).max(1);
                    self.ramp_block = 0;
                }
            }
        }

        if self.is_ramping() {
            self.ramp_block += 1;
            let t = self.ramp_block as f32 / self.ramp_blocks as f32;
            if self.ramp_block >= self.ramp_blocks {
                self.cur_gains = self.target_gains;
                self.cur_preamp_db = self.target_preamp;
            } else {
                for b in 0..NUM_BANDS {
                    self.cur_gains[b] = self.ramp_from_gains[b]
                        + (self.target_gains[b] - self.ramp_from_gains[b]) * t;
                }
                self.cur_preamp_db =
                    self.ramp_from_preamp + (self.target_preamp - self.ramp_from_preamp) * t;
            }
            self.update_coefficients(false);
            self.preamp_block_end = db_to_lin(self.cur_preamp_db);
            self.preamp_step = (self.preamp_block_end - self.preamp_lin) / BLOCK_FRAMES as f32;
        }

        self.update_bypass();
    }

    /// Called at each frame start: detects format changes (span boundaries).
    #[inline]
    fn check_format(&mut self) {
        let channels = self.inner.channels().get();
        let sample_rate = self.inner.sample_rate().get();
        if channels != self.channels || sample_rate != self.sample_rate {
            self.channels = channels;
            self.sample_rate = sample_rate;
            if self.is_ramping() {
                // Keep the ramp duration ~constant in time at the new rate.
                let ramp_frames = (RAMP_SECONDS * sample_rate as f32).max(1.0);
                let blocks = ((ramp_frames / BLOCK_FRAMES as f32).ceil() as u32).max(1);
                let t = self.ramp_block as f32 / self.ramp_blocks as f32;
                self.ramp_blocks = blocks;
                self.ramp_block = ((t * blocks as f32) as u32).min(blocks.saturating_sub(1));
            }
            self.update_coefficients(true);
            self.frames_in_block = 0;
        }
    }
}

impl<S: Source> Iterator for EqSource<S> {
    type Item = Sample;

    #[inline]
    fn next(&mut self) -> Option<Sample> {
        if self.channel_idx == 0 {
            self.check_format();
            if self.frames_in_block == 0 {
                self.control_block();
            }
        }

        let sample = self.inner.next()?;
        let ch = self.channel_idx;

        let out = if self.bypass {
            sample
        } else {
            let mut x = sample * self.preamp_lin;
            if ch < MAX_CHANNELS && self.any_band_active {
                let filters = &mut self.filters[ch];
                for (band, f) in filters.iter_mut().enumerate() {
                    if self.band_active[band] {
                        x = f.run(x);
                    }
                }
                if !x.is_finite() {
                    for f in filters.iter_mut() {
                        f.reset_state();
                    }
                    x = 0.0;
                }
            }
            x.clamp(-1.0, 1.0)
        };

        self.channel_idx += 1;
        if self.channel_idx >= self.channels as usize {
            self.channel_idx = 0;
            self.preamp_lin += self.preamp_step;
            self.frames_in_block += 1;
            if self.frames_in_block >= BLOCK_FRAMES {
                self.frames_in_block = 0;
            }
        }
        Some(out)
    }

    #[inline]
    fn size_hint(&self) -> (usize, Option<usize>) {
        self.inner.size_hint()
    }
}

impl<S: Source> Source for EqSource<S> {
    #[inline]
    fn current_span_len(&self) -> Option<usize> {
        self.inner.current_span_len()
    }

    #[inline]
    fn channels(&self) -> ChannelCount {
        self.inner.channels()
    }

    #[inline]
    fn sample_rate(&self) -> SampleRate {
        self.inner.sample_rate()
    }

    #[inline]
    fn total_duration(&self) -> Option<Duration> {
        self.inner.total_duration()
    }

    fn try_seek(&mut self, pos: Duration) -> Result<(), SeekError> {
        let result = self.inner.try_seek(pos);
        self.reset_filter_state();
        self.channel_idx = 0;
        self.frames_in_block = 0;
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rodio::buffer::SamplesBuffer;
    use std::num::NonZero;

    fn sine(freq: f32, sr: u32, secs: f32, amp: f32) -> Vec<f32> {
        let n = (sr as f32 * secs) as usize;
        (0..n)
            .map(|i| amp * (2.0 * std::f32::consts::PI * freq * i as f32 / sr as f32).sin())
            .collect()
    }

    fn buf(channels: u16, sr: u32, data: Vec<f32>) -> SamplesBuffer {
        SamplesBuffer::new(
            NonZero::new(channels).unwrap(),
            NonZero::new(sr).unwrap(),
            data,
        )
    }

    fn shared_with(settings: EqSettings) -> Arc<EqShared> {
        let s = EqShared::new();
        s.set(settings);
        s
    }

    fn rms(x: &[f32]) -> f32 {
        (x.iter().map(|v| (*v as f64).powi(2)).sum::<f64>() / x.len() as f64).sqrt() as f32
    }

    fn db(ratio: f32) -> f32 {
        20.0 * ratio.log10()
    }

    /// Gain in dB of a mono sine through the given settings (steady state).
    fn sine_gain_db(freq: f32, sr: u32, settings: EqSettings) -> f32 {
        let input = sine(freq, sr, 1.0, 0.25);
        let out: Vec<f32> =
            EqSource::new(buf(1, sr, input.clone()), shared_with(settings)).collect();
        let skip = sr as usize / 5;
        db(rms(&out[skip..]) / rms(&input[skip..]))
    }

    fn band(idx: usize, gain: f32) -> EqSettings {
        let mut s = EqSettings::default();
        s.gains_db[idx] = gain;
        s
    }

    #[test]
    fn bypass_is_bit_identical() {
        // Includes out-of-range samples, which must not be clamped in bypass.
        let mut input = sine(440.0, 48_000, 0.1, 0.8);
        input.extend_from_slice(&[1.5, -2.0, 0.0, -0.0]);

        let flat = EqSettings::default();
        let out: Vec<f32> =
            EqSource::new(buf(2, 48_000, input.clone()), shared_with(flat)).collect();
        assert_eq!(
            out.iter().map(|v| v.to_bits()).collect::<Vec<_>>(),
            input.iter().map(|v| v.to_bits()).collect::<Vec<_>>()
        );

        let disabled = EqSettings {
            enabled: false,
            gains_db: [6.0; 10],
            preamp_db: -3.0,
        };
        let out: Vec<f32> =
            EqSource::new(buf(2, 48_000, input.clone()), shared_with(disabled)).collect();
        assert_eq!(
            out.iter().map(|v| v.to_bits()).collect::<Vec<_>>(),
            input.iter().map(|v| v.to_bits()).collect::<Vec<_>>()
        );

        // Only band above 0.45 × fs is "active" → skipped → bypass.
        let high = band(9, 12.0);
        let out: Vec<f32> =
            EqSource::new(buf(1, 22_050, input.clone()), shared_with(high)).collect();
        assert_eq!(
            out.iter().map(|v| v.to_bits()).collect::<Vec<_>>(),
            input.iter().map(|v| v.to_bits()).collect::<Vec<_>>()
        );
    }

    #[test]
    fn band_gain_at_center_and_far_away() {
        let g = sine_gain_db(1000.0, 48_000, band(5, 6.0));
        assert!((g - 6.0).abs() <= 0.3, "1 kHz band gain {g} dB");

        let g = sine_gain_db(1000.0, 48_000, band(0, 6.0));
        assert!(g.abs() < 0.5, "31 Hz band affected 1 kHz by {g} dB");
    }

    #[test]
    fn preamp_minus_6db() {
        let s = EqSettings {
            preamp_db: -6.0,
            ..EqSettings::default()
        };
        let g = sine_gain_db(1000.0, 48_000, s);
        assert!((g + 6.0).abs() <= 0.1, "preamp gain {g} dB");
    }

    #[test]
    fn mid_stream_change_is_ramped_and_fast() {
        let sr = 48_000;
        // DC input makes any preamp jump obvious.
        let input = vec![0.5f32; sr as usize];
        let shared = EqShared::new();
        let mut src = EqSource::new(buf(1, sr, input), shared.clone());
        let change_at = 10_000;
        let mut out = Vec::new();
        for i in 0..sr as usize {
            if i == change_at {
                shared.set(EqSettings {
                    preamp_db: -6.0,
                    ..EqSettings::default()
                });
            }
            out.push(src.next().unwrap());
        }
        let max_jump = out
            .windows(2)
            .map(|w| (w[1] - w[0]).abs())
            .fold(0.0f32, f32::max);
        assert!(max_jump < 0.005, "preamp jump {max_jump}");
        let settled = change_at + (0.025 * sr as f32) as usize;
        let expected = 0.5 * db_to_lin(-6.0);
        for v in &out[settled..] {
            assert!((v - expected).abs() < 1e-5, "{v} vs {expected}");
        }
        assert!((out[change_at - 1] - 0.5).abs() < 1e-7);

        // Band gain change on a sine: no sample-to-sample jump beyond what
        // the final (boosted) sine itself has.
        let amp = 0.1;
        let input = sine(1000.0, sr, 1.0, amp);
        let in_max_diff = input
            .windows(2)
            .map(|w| (w[1] - w[0]).abs())
            .fold(0.0f32, f32::max);
        let shared = EqShared::new();
        let mut src = EqSource::new(buf(1, sr, input.clone()), shared.clone());
        let mut out = Vec::new();
        for i in 0..input.len() {
            if i == change_at {
                shared.set(band(5, 12.0));
            }
            out.push(src.next().unwrap());
        }
        let max_jump = out
            .windows(2)
            .map(|w| (w[1] - w[0]).abs())
            .fold(0.0f32, f32::max);
        let bound = in_max_diff * db_to_lin(12.0) * 1.1;
        assert!(max_jump <= bound, "jump {max_jump} > {bound}");
        // Takes effect within ~25 ms (+ a few ms for filter settling).
        let from = change_at + (0.025 * sr as f32) as usize;
        let window = 480 * 4;
        let g = db(rms(&out[from + 480..from + 480 + window])
            / rms(&input[from + 480..from + 480 + window]));
        assert!((g - 12.0).abs() < 0.3, "gain after change {g}");
    }

    #[test]
    fn stereo_independent_state_and_44k1() {
        let sr = 44_100;
        let left = sine(1000.0, sr, 1.0, 0.25);
        let interleaved: Vec<f32> = left.iter().flat_map(|l| [*l, 0.0]).collect();
        let settings = band(5, 6.0);
        let out: Vec<f32> = EqSource::new(buf(2, sr, interleaved), shared_with(settings)).collect();
        let out_l: Vec<f32> = out.iter().step_by(2).copied().collect();
        let out_r: Vec<f32> = out.iter().skip(1).step_by(2).copied().collect();
        assert!(out_r.iter().all(|v| *v == 0.0), "right channel leaked");

        let mono: Vec<f32> =
            EqSource::new(buf(1, sr, left.clone()), shared_with(settings)).collect();
        assert_eq!(out_l, mono);

        let skip = sr as usize / 5;
        let g = db(rms(&out_l[skip..]) / rms(&left[skip..]));
        assert!((g - 6.0).abs() <= 0.3, "44.1k gain {g}");
    }

    #[test]
    fn output_is_clamped() {
        let input = sine(1000.0, 48_000, 0.5, 0.95);
        let s = EqSettings {
            enabled: true,
            gains_db: [12.0; 10],
            preamp_db: 6.0,
        };
        let out: Vec<f32> = EqSource::new(buf(2, 48_000, input), shared_with(s)).collect();
        assert!(out.iter().all(|v| (-1.0..=1.0).contains(v)));
        assert!(out.iter().any(|v| v.abs() == 1.0));
    }

    #[test]
    fn seek_and_metadata_forwarded() {
        let input = sine(1000.0, 48_000, 0.5, 0.5);
        let mut src = EqSource::new(buf(2, 48_000, input), shared_with(band(5, 3.0)));
        assert_eq!(src.channels().get(), 2);
        assert_eq!(src.sample_rate().get(), 48_000);
        assert!(src.total_duration().is_some());
        let _ = src.next();
        assert!(src.try_seek(Duration::from_millis(100)).is_ok());
        assert!(src.all(|v| v.is_finite()));
    }
}
