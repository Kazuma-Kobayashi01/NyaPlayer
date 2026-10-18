import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/repositories/playback_repository.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Saves the queue, current track and position (PLAY-05).
///
/// A burst of queue edits is saved once, one second after the last one.
/// While playing the position is also saved every [positionInterval], and
/// pausing saves right away. [flush] is for app exit.
class PlaybackPersistence {
  PlaybackPersistence(
    this._container,
    this._store, {
    this.debounce = const Duration(seconds: 1),
    this.positionInterval = const Duration(seconds: 10),
  });

  final ProviderContainer _container;
  final PlaybackStore _store;
  final Duration debounce;
  final Duration positionInterval;

  ProviderSubscription<QueueState>? _subscription;
  Timer? _debounce;
  Timer? _periodic;
  SavedPlayback? _lastSaved;

  void start() {
    _subscription = _container.listen<QueueState>(queueProvider, (
      previous,
      next,
    ) {
      if (previous == null) return;
      final structural =
          !identical(previous.queue, next.queue) ||
          previous.currentIndex != next.currentIndex ||
          previous.loopMode != next.loopMode ||
          previous.shuffle != next.shuffle;
      if (previous.playing != next.playing) {
        _periodic?.cancel();
        _periodic = next.playing
            ? Timer.periodic(positionInterval, (_) => _save())
            : null;
        if (!next.playing) {
          _save(); // pausing: the position is exact now
          return;
        }
      }
      if (structural) {
        _debounce?.cancel();
        _debounce = Timer(debounce, _save);
      }
    });
  }

  SavedPlayback _snapshot() {
    final controller = _container.read(queueProvider.notifier);
    final state = _container.read(queueProvider);
    return SavedPlayback(
      queue: [for (final t in controller.originalQueue) t.id],
      shuffled: state.shuffle ? [for (final t in state.queue) t.id] : const [],
      currentIndex: state.currentIndex ?? 0,
      positionMs: controller.position.inMilliseconds,
      loopMode: state.loopMode.index,
      shuffle: state.shuffle,
    );
  }

  void _save() {
    _debounce?.cancel();
    final snapshot = _snapshot();
    if (snapshot == _lastSaved) return;
    _lastSaved = snapshot;
    _store.save(snapshot);
  }

  /// Saves immediately and waits until it is stored.
  Future<void> flush() {
    _save();
    return _store.flush();
  }

  void dispose() {
    _debounce?.cancel();
    _periodic?.cancel();
    _subscription?.close();
  }
}
