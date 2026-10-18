import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// One system media session observes the existing queue; it never opens a
/// second decoder. All remote commands use the same controller as the UI.
class LyraAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  LyraAudioHandler(ProviderContainer container)
    : _controller = container.read(queueProvider.notifier),
      _covers = container.read(coverCacheProvider) {
    _state = container.read(queueProvider);
    final engine = container.read(playerEngineProvider);
    _subscriptions.addAll([
      engine.position.listen(_onPosition),
      engine.completed.listen((completed) {
        if (!completed) return;
        _completed = true;
        _position = _state.current?.duration ?? _position;
        _publish();
      }),
      engine.errors.listen((error) {
        Log.w('player', error);
        _error = error;
        _publish();
      }),
      _controller.seekEvents.listen((position) {
        _position = position;
        _completed = false;
        _error = null;
        _publish();
      }),
    ]);
    _queueSubscription = container.listen(
      queueProvider,
      _syncQueue,
      fireImmediately: true,
    );
  }

  final QueueController _controller;
  final CoverCache _covers;
  final _subscriptions = <StreamSubscription<Object?>>[];
  late final ProviderSubscription<QueueState> _queueSubscription;
  late QueueState _state;
  Duration _position = Duration.zero;
  bool _completed = false;
  bool _stopped = false;
  bool _disposed = false;
  String? _error;
  int _artworkGeneration = 0;

  MediaItem _item(Track track, {Uri? artUri}) => MediaItem(
    id: track.path,
    title: track.title,
    artist: track.artist,
    album: track.album,
    duration: track.duration,
    artUri: artUri,
    extras: {'trackId': track.id},
  );

  void _syncQueue(QueueState? previous, QueueState next) {
    if (_disposed) return;
    _state = next;
    if (previous == null || !identical(previous.queue, next.queue)) {
      queue.add([for (final track in next.queue) _item(track)]);
    }
    if (previous == null || !identical(previous.current, next.current)) {
      _position = Duration.zero;
      _completed = false;
      _stopped = false;
      _error = null;
      final track = next.current;
      final generation = ++_artworkGeneration;
      mediaItem.add(track == null ? null : _item(track));
      if (track?.cover != null) {
        unawaited(_loadArtwork(track!, generation));
      }
    }
    if (next.playing) {
      _stopped = false;
      _completed = false;
      _error = null;
    }
    _publish();
  }

  Future<void> _loadArtwork(Track track, int generation) async {
    try {
      final cover = await _covers.load(track.cover!);
      if (_disposed || generation != _artworkGeneration || cover == null) {
        return;
      }
      final item = _item(track, artUri: Uri.file(cover.large));
      mediaItem.add(item);
      queue.add([
        for (final entry in _state.queue)
          if (entry.path == track.path) item else _item(entry),
      ]);
    } catch (error) {
      Log.w('LyraAudioHandler', 'Cannot publish artwork: $error');
    }
  }

  void _onPosition(Duration position) {
    // Normal ticks only update the local anchor. The OS extrapolates time.
    // Backward discontinuities also cover repeat-one and duplicate tracks.
    final discontinuity =
        position < _position - const Duration(milliseconds: 100);
    _position = position;
    if (discontinuity) _publish();
  }

  void _publish() {
    if (_disposed) return;
    final track = _state.current;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.stop,
          MediaAction.setRepeatMode,
          MediaAction.setShuffleMode,
        },
        processingState: track == null || _stopped
            ? AudioProcessingState.idle
            : _error != null
            ? AudioProcessingState.error
            : _completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
        playing: !_stopped && !_completed && _error == null && _state.playing,
        updatePosition: _position,
        bufferedPosition: track?.duration ?? Duration.zero,
        queueIndex: _state.currentIndex,
        repeatMode: switch (_state.loopMode) {
          LoopMode.none => AudioServiceRepeatMode.none,
          LoopMode.all => AudioServiceRepeatMode.all,
          LoopMode.one => AudioServiceRepeatMode.one,
        },
        shuffleMode: _state.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        errorCode: _error == null ? null : 1,
        errorMessage: _error,
      ),
    );
  }

  @override
  Future<void> play() => _controller.play();
  @override
  Future<void> pause() => _controller.pause();
  @override
  Future<void> seek(Duration position) => _controller.seek(position);
  @override
  Future<void> skipToNext() => _controller.skipNext();
  @override
  Future<void> skipToPrevious() => _controller.skipPrevious();
  @override
  Future<void> skipToQueueItem(int index) => _controller.jumpTo(index);
  @override
  Future<void> fastForward() => seek(_position + const Duration(seconds: 15));
  @override
  Future<void> rewind() => seek(_position - const Duration(seconds: 15));
  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final index = _state.queue.indexWhere((track) => track.path == mediaId);
    if (index < 0) return;
    await skipToQueueItem(index);
    await play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _controller.setLoopMode(switch (repeatMode) {
        AudioServiceRepeatMode.none => LoopMode.none,
        AudioServiceRepeatMode.one => LoopMode.one,
        _ => LoopMode.all,
      });
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if ((shuffleMode != AudioServiceShuffleMode.none) != _state.shuffle) {
      await _controller.toggleShuffle();
    }
  }

  @override
  Future<void> stop() async {
    await pause();
    _stopped = true;
    _publish();
  }

  @override
  Future<void> onTaskRemoved() async {
    // Dismissing the activity is not a stop command. The media foreground
    // service follows system battery policy; there is no restart/keepalive.
  }

  Future<void> dispose() async {
    _disposed = true;
    _artworkGeneration++;
    _queueSubscription.close();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await Future.wait([
      playbackState.close(),
      mediaItem.close(),
      queue.close(),
    ]);
  }
}
