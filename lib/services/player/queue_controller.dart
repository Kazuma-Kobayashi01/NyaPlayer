import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/repositories/playback_repository.dart';
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
  final _seekEvents = StreamController<Duration>.broadcast();

  /// Explicit UI/system seeks, distinct from normal playback position ticks.
  Stream<Duration> get seekEvents => _seekEvents.stream;

  static const previousRestartThreshold = Duration(seconds: 3);

  /// The queue in the order the user built it (before shuffling).
  List<Track> get originalQueue => List.unmodifiable(_original);

  /// Latest playback position reported by the engine.
  Duration get position => _position;

  /// Brings back the queue of a previous run, paused (PLAY-05, TECH_SPEC
  /// §4.4). [lookup] resolves track ids; tracks that no longer exist are
  /// dropped. Does nothing if something is already queued.
  Future<void> restore(
    SavedPlayback saved,
    Track? Function(int id) lookup,
  ) async {
    if (state.queue.isNotEmpty) return;
    final original = [for (final id in saved.queue) ?lookup(id)];
    if (original.isEmpty) return;

    var shuffle = saved.shuffle && saved.shuffled.isNotEmpty;
    final playOrder = shuffle ? saved.shuffled : saved.queue;
    final active = shuffle
        ? [for (final id in playOrder) ?lookup(id)]
        : original;
    if (active.isEmpty) return;

    // Survivors before the saved position keep it in line; if the saved
    // track itself is gone the next surviving one takes its place.
    var index = 0;
    var currentSurvived = false;
    for (var i = 0; i < playOrder.length; i++) {
      final exists = lookup(playOrder[i]) != null;
      if (i == saved.currentIndex) {
        currentSurvived = exists;
        break;
      }
      if (exists) index++;
    }
    index = index.clamp(0, active.length - 1);
    shuffle = shuffle && active.length == original.length;

    final loop =
        LoopMode.values[saved.loopMode.clamp(0, LoopMode.values.length - 1)];
    _original = List.of(original);
    state = state.copyWith(
      queue: List.unmodifiable(shuffle ? active : original),
      currentIndex: index,
      loopMode: loop,
      shuffle: shuffle,
    );
    await _engine.setLoopMode(loop);
    await _engine.openQueue(
      _paths(state.queue),
      startIndex: index,
      autoplay: false,
    );
    if (currentSurvived && saved.positionMs > 0) {
      await seek(Duration(milliseconds: saved.positionMs));
    }
  }

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
      unawaited(_seekEvents.close());
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
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (state.queue.isNotEmpty && !state.playing) await _engine.play();
  }

  Future<void> pause() => _engine.pause();

  Future<void> seek(Duration position) async {
    final duration = state.current?.duration ?? Duration.zero;
    final bounded = Duration(
      milliseconds: position.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    await _engine.seek(bounded);
    _seekEvents.add(bounded);
  }

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
      await seek(Duration.zero);
    } else if (i > 0) {
      await _engine.jumpTo(i - 1);
    } else if (state.loopMode == LoopMode.all) {
      await _engine.jumpTo(state.queue.length - 1);
    } else {
      await seek(Duration.zero);
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
    final previous = state.queue;
    final currentIndex = state.currentIndex!;
    final List<int> order;
    if (enabling) {
      order = [
        for (var i = 0; i < previous.length; i++)
          if (i != currentIndex) i,
      ]..shuffle(ref.read(randomProvider));
      order.insert(0, currentIndex);
    } else {
      // Match occurrences rather than indexOf: the same song can occur more
      // than once in a queue, and the playing instance must stay the same.
      final positions = <Track, Queue<int>>{};
      for (var i = 0; i < previous.length; i++) {
        (positions[previous[i]] ??= Queue<int>()).add(i);
      }
      order = [for (final track in _original) positions[track]!.removeFirst()];
    }
    final active = [for (final i in order) previous[i]];
    state = state.copyWith(
      shuffle: enabling,
      queue: List.unmodifiable(active),
      currentIndex: order.indexOf(currentIndex),
    );
    await _engine.reorder(order);
  }
}
