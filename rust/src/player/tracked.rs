//! Source wrapper that reports when a queued track starts and can be
//! cancelled before it starts.
//!
//! The engine appends the current and the next track to rodio's sequential
//! queue; the next one starts sample-accurately when the current one ends
//! (gapless). Its first sample marks the track change, which this wrapper
//! publishes through an atomic the engine polls — no allocation or locking on
//! the audio thread.

use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;

use rodio::source::SeekError;
use rodio::{ChannelCount, Sample, SampleRate, Source};

pub struct Tracked<S> {
    inner: S,
    token: u64,
    started: Arc<AtomicU64>,
    cancel: Arc<AtomicBool>,
    announced: bool,
}

impl<S> Tracked<S> {
    pub fn new(inner: S, token: u64, started: Arc<AtomicU64>, cancel: Arc<AtomicBool>) -> Self {
        Self {
            inner,
            token,
            started,
            cancel,
            announced: false,
        }
    }
}

impl<S: Source> Iterator for Tracked<S> {
    type Item = Sample;

    #[inline]
    fn next(&mut self) -> Option<Sample> {
        if !self.announced {
            // A prefetched track that was replaced before it started is
            // skipped entirely; rodio then moves on to the following source.
            if self.cancel.load(Ordering::Acquire) {
                return None;
            }
            self.announced = true;
            self.started.store(self.token, Ordering::Release);
        }
        self.inner.next()
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.inner.size_hint()
    }
}

impl<S: Source> Source for Tracked<S> {
    fn current_span_len(&self) -> Option<usize> {
        if !self.announced && self.cancel.load(Ordering::Acquire) {
            return Some(0);
        }
        self.inner.current_span_len()
    }

    fn channels(&self) -> ChannelCount {
        self.inner.channels()
    }

    fn sample_rate(&self) -> SampleRate {
        self.inner.sample_rate()
    }

    fn total_duration(&self) -> Option<Duration> {
        self.inner.total_duration()
    }

    fn try_seek(&mut self, pos: Duration) -> Result<(), SeekError> {
        self.inner.try_seek(pos)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rodio::buffer::SamplesBuffer;
    use std::num::NonZero;

    fn buffer() -> SamplesBuffer {
        SamplesBuffer::new(
            NonZero::new(1).unwrap(),
            NonZero::new(48_000).unwrap(),
            vec![0.1, 0.2, 0.3],
        )
    }

    #[test]
    fn announces_on_first_sample() {
        let started = Arc::new(AtomicU64::new(0));
        let mut src = Tracked::new(
            buffer(),
            7,
            started.clone(),
            Arc::new(AtomicBool::new(false)),
        );
        assert_eq!(started.load(Ordering::Acquire), 0);
        assert_eq!(src.next(), Some(0.1));
        assert_eq!(started.load(Ordering::Acquire), 7);
        assert_eq!(src.by_ref().count(), 2);
    }

    #[test]
    fn cancelled_before_start_yields_nothing() {
        let started = Arc::new(AtomicU64::new(0));
        let cancel = Arc::new(AtomicBool::new(true));
        let mut src = Tracked::new(buffer(), 9, started.clone(), cancel);
        assert_eq!(src.next(), None);
        assert_eq!(started.load(Ordering::Acquire), 0);
    }

    #[test]
    fn cancel_after_start_is_ignored() {
        let started = Arc::new(AtomicU64::new(0));
        let cancel = Arc::new(AtomicBool::new(false));
        let mut src = Tracked::new(buffer(), 3, started, cancel.clone());
        assert!(src.next().is_some());
        cancel.store(true, Ordering::Release);
        assert_eq!(src.count(), 2);
    }
}
