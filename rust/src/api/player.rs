//! Player API exposed to Dart (wrapped by `RustPlayerEngine`).
//!
//! Commands are synchronous FFI calls that only enqueue work for the engine
//! thread, so they return immediately. Events arrive through the stream
//! returned by `player_events`.

use std::sync::mpsc::{self, Sender};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::Duration;

use crate::dsp::eq::EqSettings;
use crate::frb_generated::StreamSink;
use crate::player::engine::{Command, Engine, Event, Shared};
use crate::player::queue::LoopMode;

pub enum PlayerEventKind {
    Playing,
    CurrentIndex,
    Completed,
    Error,
}

/// Flat event record (no enum payloads, so the Dart side needs no codegen
/// beyond flutter_rust_bridge itself).
pub struct PlayerEvent {
    pub kind: PlayerEventKind,
    pub playing: bool,
    pub index: Option<u32>,
    pub message: Option<String>,
}

pub enum RepeatMode {
    None,
    All,
    One,
}

struct Handle {
    tx: Sender<Command>,
    shared: Arc<Shared>,
}

static HANDLE: OnceLock<Handle> = OnceLock::new();
static EVENTS: Mutex<Option<StreamSink<PlayerEvent>>> = Mutex::new(None);

fn to_dart(event: Event) -> PlayerEvent {
    let mut out = PlayerEvent {
        kind: PlayerEventKind::Completed,
        playing: false,
        index: None,
        message: None,
    };
    match event {
        Event::Playing(playing) => {
            out.kind = PlayerEventKind::Playing;
            out.playing = playing;
        }
        Event::Index(index) => {
            out.kind = PlayerEventKind::CurrentIndex;
            out.index = index.map(|i| i as u32);
        }
        Event::Completed => out.kind = PlayerEventKind::Completed,
        Event::Error(message) => {
            out.kind = PlayerEventKind::Error;
            out.message = Some(message);
        }
    }
    out
}

fn handle() -> &'static Handle {
    HANDLE.get_or_init(|| {
        let (tx, rx) = mpsc::channel();
        let shared = Arc::new(Shared::default());
        let engine_shared = shared.clone();
        std::thread::Builder::new()
            .name("nya-engine".into())
            .spawn(move || {
                let emit = Box::new(|event: Event| {
                    if let Ok(guard) = EVENTS.lock() {
                        if let Some(sink) = guard.as_ref() {
                            let _ = sink.add(to_dart(event));
                        }
                    }
                });
                Engine::new(emit, engine_shared).run(rx);
            })
            .expect("spawn engine thread");
        Handle { tx, shared }
    })
}

fn send(cmd: Command) {
    let _ = handle().tx.send(cmd);
}

/// Subscribes to engine events. A new subscription replaces the old one.
pub fn player_events(sink: StreamSink<PlayerEvent>) {
    if let Ok(mut guard) = EVENTS.lock() {
        *guard = Some(sink);
    }
    handle();
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_open_queue(paths: Vec<String>, start_index: u32, autoplay: bool) {
    send(Command::OpenQueue {
        paths,
        start: start_index as usize,
        autoplay,
    });
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_play() {
    send(Command::Play);
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_pause() {
    send(Command::Pause);
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_seek(position_ms: u64) {
    send(Command::Seek(Duration::from_millis(position_ms)));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_jump_to(index: u32) {
    send(Command::JumpTo(index as usize));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_add(path: String) {
    send(Command::Add(path));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_insert(index: u32, path: String) {
    send(Command::Insert(index as usize, path));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_remove(index: u32) {
    send(Command::Remove(index as usize));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_move(from: u32, to: u32) {
    send(Command::Move(from as usize, to as usize));
}

/// A complete permutation of old queue indexes. Keeps the playing source.
#[flutter_rust_bridge::frb(sync)]
pub fn player_reorder(order: Vec<u32>) {
    send(Command::Reorder(
        order.into_iter().map(|i| i as usize).collect(),
    ));
}

#[flutter_rust_bridge::frb(sync)]
pub fn player_set_repeat_mode(mode: RepeatMode) {
    send(Command::SetLoopMode(match mode {
        RepeatMode::None => LoopMode::None,
        RepeatMode::All => LoopMode::All,
        RepeatMode::One => LoopMode::One,
    }));
}

/// `gains_db` must have 15 entries (25 Hz … 16 kHz); missing ones are 0.
#[flutter_rust_bridge::frb(sync)]
pub fn player_set_equalizer(enabled: bool, gains_db: Vec<f32>, preamp_db: f32) {
    let mut gains = [0.0f32; 15];
    for (slot, gain) in gains.iter_mut().zip(gains_db) {
        *slot = gain;
    }
    send(Command::SetEqualizer(EqSettings {
        enabled,
        gains_db: gains,
        preamp_db,
    }));
}

/// Linear volume 0..1 (used for ducking).
#[flutter_rust_bridge::frb(sync)]
pub fn player_set_volume(volume: f32) {
    send(Command::SetVolume(volume));
}

/// Position in the current track, updated by the engine every 20 ms.
#[flutter_rust_bridge::frb(sync)]
pub fn player_position_ms() -> u64 {
    handle()
        .shared
        .position_ms
        .load(std::sync::atomic::Ordering::Relaxed)
}
