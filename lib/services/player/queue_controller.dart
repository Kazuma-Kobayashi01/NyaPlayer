import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/player/player_engine.dart';

final playerEngineProvider = Provider<PlayerEngine>(
  (ref) => throw UnimplementedError('playerEngineProvider must be overridden'),
);

final randomProvider = Provider<Random>((ref) => Random());

/// Position changes fast, so it is kept out of [QueueState].
final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerEngineProvider).position,
);

final queueProvider = NotifierProvider<QueueController, QueueState>(
  QueueController.new,
);

@immutable
class QueueState {
  const QueueState({
    this.queue = const [],
    this.currentIndex,
    this.playing = false,
    this.loopMode = LoopMode.none,
    this.shuffle = false,
  });

  /// Tracks in the order they are actually played (shuffled if [shuffle]).
  final List<Track> queue;
  final int? currentIndex;
  final bool playing;
  final LoopMode loopMode;
  final bool shuffle;

  Track? get current {
    final i = currentIndex;
    if (i == null || i < 0 || i >= queue.length) return null;
    return queue[i];
  }

  QueueState copyWith({
    List<Track>? queue,
    Object? currentIndex = _keep,
    bool? playing,
    LoopMode? loopMode,
    bool? shuffle,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: identical(currentIndex, _keep)
          ? this.currentIndex
          : currentIndex as int?,
      playing: playing ?? this.playing,
      loopMode: loopMode ?? this.loopMode,
      shuffle: shuffle ?? this.shuffle,
    );
  }

  static const _keep = Object();
}

/// Single source of truth for the play queue (TECH_SPEC §4.4). The UI talks to
/// this, never to the engine.
class QueueController extends Notifier<QueueState> {
  late final PlayerEngine _engine;
  List<Track> _original = [];
  Duration _position = Duration.zero;

  static const previousRestartThreshold = Duration(seconds: 3);

  @override
  QueueState build() {
    _engine = ref.read(playerEngineProvider);
    final subs = <StreamSubscription<Object?>>[
      _engine.playing.listen((v) => state = state.copyWith(playing: v)),
      _engine.position.listen((v) => _position = v),
      _engine.currentIndex.listen(
        (v) => state = state.copyWith(currentIndex: v),
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const QueueState();
  }

  List<String> _paths(List<Track> tracks) => [for (final t in tracks) t.path];

  List<Track> _shuffledWithFirst(List<Track> source, Track first) {
    final rest = [...source]..remove(first);
    rest.shuffle(ref.read(randomProvider));
    return [first, ...rest];
  }

  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final start = startIndex.clamp(0, tracks.length - 1);
    _original = List.of(tracks);
    final List<Track> active;
    final int index;
    if (state.shuffle) {
      active = _shuffledWithFirst(_original, tracks[start]);
      index = 0;
    } else {
      active = _original;
      index = start;
    }
    state = state.copyWith(
      queue: List.unmodifiable(active),
      currentIndex: index,
    );
    await _engine.openQueue(_paths(active), startIndex: index);
  }

  /// "Shuffle play": turns shuffle on and starts from a random track.
  Future<void> shufflePlay(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    state = state.copyWith(shuffle: true);
    final first = tracks[ref.read(randomProvider).nextInt(tracks.length)];
    await playTracks(tracks, startIndex: tracks.indexOf(first));
  }

  Future<void> playNext(Track track) async {
    if (state.queue.isEmpty) return playTracks([track]);
    final at = (state.currentIndex ?? -1) + 1;
    final queue = [...state.queue]..insert(at, track);
    final current = state.current;
    final originalAt = current == null
        ? _original.length
        : _original.indexOf(current) + 1;
    _original.insert(originalAt.clamp(0, _original.length), track);
    state = state.copyWith(queue: List.unmodifiable(queue));
    await _engine.insert(at, track.path);
  }

  Future<void> addToQueue(Track track) async {
    if (state.queue.isEmpty) return playTracks([track]);
    _original.add(track);
    state = state.copyWith(queue: List.unmodifiable([...state.queue, track]));
    await _engine.add(track.path);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final queue = [...state.queue];
    final removed = queue.removeAt(index);
    _original.remove(removed);
    state = state.copyWith(queue: List.unmodifiable(queue));
    await _engine.remove(index);
  }

  /// [target] is the item's index in the resulting list (the
  /// [ReorderableListView.onReorderItem] convention).
  Future<void> move(int oldIndex, int target) async {
    final last = state.queue.length - 1;
    if (oldIndex == target || oldIndex < 0 || oldIndex > last) return;
    if (target < 0 || target > last) return;
    final queue = [...state.queue];
    queue.insert(target, queue.removeAt(oldIndex));
    if (!state.shuffle) _original = List.of(queue);
    state = state.copyWith(queue: List.unmodifiable(queue));
    await _engine.move(oldIndex, target);
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    await _engine.jumpTo(index);
  }

  Future<void> togglePlay() async {
    if (state.queue.isEmpty) return;
    if (state.playing) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
  }

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> skipNext() async {
    final i = state.currentIndex;
    if (i == null) return;
    if (i + 1 < state.queue.length) {
      await _engine.jumpTo(i + 1);
    } else if (state.loopMode == LoopMode.all) {
      await _engine.jumpTo(0);
    }
  }

  /// PLAY-06: past 3 s restarts the track, otherwise goes to the previous one.
  Future<void> skipPrevious() async {
    final i = state.currentIndex;
    if (i == null) return;
    if (_position > previousRestartThreshold) {
      await _engine.seek(Duration.zero);
    } else if (i > 0) {
      await _engine.jumpTo(i - 1);
    } else if (state.loopMode == LoopMode.all) {
      await _engine.jumpTo(state.queue.length - 1);
    } else {
      await _engine.seek(Duration.zero);
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    state = state.copyWith(loopMode: mode);
    await _engine.setLoopMode(mode);
  }

  Future<void> cycleLoopMode() => setLoopMode(
    LoopMode.values[(state.loopMode.index + 1) % LoopMode.values.length],
  );

  Future<void> toggleShuffle() async {
    final enabling = !state.shuffle;
    final current = state.current;
    if (state.queue.isEmpty || current == null) {
      state = state.copyWith(shuffle: enabling);
      return;
    }
    final List<Track> active;
    final int index;
    if (enabling) {
      active = _shuffledWithFirst(_original, current);
      index = 0;
    } else {
      active = List.of(_original);
      index = max(0, active.indexOf(current));
    }
    final wasPlaying = state.playing;
    final position = _position;
    state = state.copyWith(
      shuffle: enabling,
      queue: List.unmodifiable(active),
      currentIndex: index,
    );
    await _engine.openQueue(
      _paths(active),
      startIndex: index,
      autoplay: wasPlaying,
    );
    await _engine.seek(position);
  }
}
