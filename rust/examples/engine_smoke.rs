//! Drives the engine without Flutter: `cargo run --example engine_smoke -- <file>...`
//! Plays the files as a queue (volume from NYA_VOLUME, default 0 = silent),
//! prints every event and the position, then exits after completion.
use std::sync::atomic::Ordering;
use std::sync::mpsc;
use std::sync::Arc;
use std::time::{Duration, Instant};

use nya_core::player::engine::{Command, Engine, Event, Shared};

fn main() {
    let paths: Vec<String> = std::env::args().skip(1).collect();
    assert!(!paths.is_empty(), "usage: engine_smoke <file>...");
    let volume: f32 = std::env::var("NYA_VOLUME")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(0.0);
    let seek_secs: Option<u64> = std::env::var("NYA_SEEK").ok().and_then(|v| v.parse().ok());

    let (tx, rx) = mpsc::channel();
    let (etx, erx) = mpsc::channel::<Event>();
    let shared = Arc::new(Shared::default());
    let engine_shared = shared.clone();
    let start = Instant::now();
    let handle = std::thread::spawn(move || {
        Engine::new(
            Box::new(move |e| {
                let _ = etx.send(e);
            }),
            engine_shared,
        )
        .run(rx);
    });

    tx.send(Command::SetVolume(volume)).unwrap();
    tx.send(Command::OpenQueue {
        paths,
        start: 0,
        autoplay: true,
    })
    .unwrap();
    if let Some(s) = seek_secs {
        tx.send(Command::Seek(Duration::from_secs(s))).unwrap();
    }
    let deadline = Instant::now()
        + Duration::from_secs(
            std::env::var("NYA_TIMEOUT")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(30),
        );
    let mut last_print = Instant::now();
    loop {
        if let Ok(e) = erx.recv_timeout(Duration::from_millis(100)) {
            println!(
                "[{:>6} ms] {:?}  pos={} ms",
                start.elapsed().as_millis(),
                e,
                shared.position_ms.load(Ordering::Relaxed)
            );
            if e == Event::Completed {
                break;
            }
        }
        if last_print.elapsed() > Duration::from_secs(1) {
            println!(
                "[{:>6} ms] pos={} ms",
                start.elapsed().as_millis(),
                shared.position_ms.load(Ordering::Relaxed)
            );
            last_print = Instant::now();
        }
        if Instant::now() > deadline {
            println!("timeout");
            break;
        }
    }
    tx.send(Command::Shutdown).unwrap();
    handle.join().unwrap();
}
