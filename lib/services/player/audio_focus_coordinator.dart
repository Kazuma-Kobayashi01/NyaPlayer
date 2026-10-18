import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// The part of the system audio session the coordinator needs. A seam so the
/// rules can be tested without Android.
abstract interface class AudioFocusSession {
  /// Asks for (or gives up) audio focus. False if the system refused.
  Future<bool> setActive(bool active);

  Stream<AudioInterruptionEvent> get interruptions;

  /// Headphones unplugged or Bluetooth dropped: the output turned loud.
  Stream<void> get becomingNoisy;
}

class SystemAudioFocusSession implements AudioFocusSession {
  SystemAudioFocusSession._(this._session);

  final AudioSession _session;

  /// Configures the session for music playback.
  static Future<SystemAudioFocusSession> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    return SystemAudioFocusSession._(session);
  }

  @override
  Future<bool> setActive(bool active) => _session.setActive(active);

  @override
  Stream<AudioInterruptionEvent> get interruptions =>
      _session.interruptionEventStream;

  @override
  Stream<void> get becomingNoisy => _session.becomingNoisyEventStream;
}

/// Audio focus and interruptions (TECH_SPEC §4.6, SYS-04, SYS-05).
///
/// The Rust core does not talk to the system audio session, so this does:
/// focus is taken when playback starts and given back when the user pauses;
/// a call or another player pauses playback and resumes it when the
/// interruption ends; a navigation prompt only lowers the volume; unplugging
/// the headphones pauses.
class AudioFocusCoordinator {
  AudioFocusCoordinator(
    this._container,
    this._session, {
    this.duckedVolume = 0.3,
  });

  final ProviderContainer _container;
  final AudioFocusSession _session;

  /// Volume while another app speaks over the music (a navigation prompt).
  final double duckedVolume;

  final _subscriptions = <StreamSubscription<Object?>>[];
  ProviderSubscription<bool>? _playing;
  bool _holdingFocus = false;
  bool _interrupted = false;
  bool _resumeWhenDone = false;
  bool _ducked = false;

  QueueController get _queue => _container.read(queueProvider.notifier);

  void start() {
    _playing = _container.listen(
      queueProvider.select((s) => s.playing),
      (_, playing) => unawaited(_onPlayingChanged(playing)),
    );
    _subscriptions
      ..add(_session.interruptions.listen(_onInterruption))
      ..add(
        _session.becomingNoisy.listen((_) {
          Log.i('Focus', 'Output became noisy, pausing');
          unawaited(_queue.pause());
        }),
      );
  }

  Future<void> dispose() async {
    _playing?.close();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _onPlayingChanged(bool playing) async {
    if (playing) {
      // The user (or a media key) started playback while we were waiting for
      // an interruption to end: that is a decision, not something to undo.
      _resumeWhenDone = false;
      _interrupted = false;
      if (_holdingFocus) return;
      final granted = await _session.setActive(true);
      if (granted) {
        _holdingFocus = true;
      } else {
        Log.w('Focus', 'Audio focus refused, not playing');
        await _queue.pause();
      }
      return;
    }
    // Paused. During an interruption the focus is already gone and must stay
    // in the session, or the system would never tell us it came back.
    if (_interrupted || !_holdingFocus) return;
    _holdingFocus = false;
    await _session.setActive(false);
  }

  void _onInterruption(AudioInterruptionEvent event) {
    final playing = _container.read(queueProvider).playing;
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (playing) {
            _ducked = true;
            unawaited(_setVolume(duckedVolume));
          }
        case AudioInterruptionType.pause:
          _interrupted = true;
          _resumeWhenDone = playing;
          if (playing) unawaited(_queue.pause());
        case AudioInterruptionType.unknown:
          // Focus lost for good (another player took over): stay paused.
          _interrupted = false;
          _resumeWhenDone = false;
          _holdingFocus = false;
          if (playing) unawaited(_queue.pause());
      }
      return;
    }
    switch (event.type) {
      case AudioInterruptionType.duck:
        if (_ducked) {
          _ducked = false;
          unawaited(_setVolume(1));
        }
      case AudioInterruptionType.pause:
        final resume = _resumeWhenDone;
        _interrupted = false;
        _resumeWhenDone = false;
        if (resume) unawaited(_queue.play());
      case AudioInterruptionType.unknown:
        break;
    }
  }

  Future<void> _setVolume(double volume) =>
      _container.read(playerEngineProvider).setVolume(volume);
}
