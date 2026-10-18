import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AppDatabase, PlaybackStateCompanion;

/// What is remembered about playback between launches (PLAY-05).
@immutable
class SavedPlayback {
  const SavedPlayback({
    required this.queue,
    required this.shuffled,
    required this.currentIndex,
    required this.positionMs,
    required this.loopMode,
    required this.shuffle,
  });

  /// Track ids in the order the user built the queue.
  final List<int> queue;

  /// Track ids in play order while shuffle is on, otherwise empty.
  final List<int> shuffled;

  /// Index into the list that is actually played (see [shuffled]).
  final int currentIndex;
  final int positionMs;

  /// `LoopMode.index`.
  final int loopMode;
  final bool shuffle;

  @override
  bool operator ==(Object other) =>
      other is SavedPlayback &&
      listEquals(other.queue, queue) &&
      listEquals(other.shuffled, shuffled) &&
      other.currentIndex == currentIndex &&
      other.positionMs == positionMs &&
      other.loopMode == loopMode &&
      other.shuffle == shuffle;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(queue),
    Object.hashAll(shuffled),
    currentIndex,
    positionMs,
    loopMode,
    shuffle,
  );
}

abstract class PlaybackStore {
  Future<SavedPlayback?> load();

  void save(SavedPlayback state);

  /// Completes when every save made so far has reached storage.
  Future<void> flush();
}

class MemoryPlaybackStore implements PlaybackStore {
  MemoryPlaybackStore([this.saved]);

  SavedPlayback? saved;

  @override
  Future<SavedPlayback?> load() async => saved;

  @override
  void save(SavedPlayback state) => saved = state;

  @override
  Future<void> flush() async {}
}

/// The single-row `playback_state` table. Saves are written in order in the
/// background.
class DbPlaybackStore implements PlaybackStore {
  DbPlaybackStore(this._db);

  final AppDatabase _db;
  Future<void> _tail = Future.value();

  @override
  Future<SavedPlayback?> load() async {
    final row = await (_db.select(
      _db.playbackState,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    try {
      return SavedPlayback(
        queue: _ids(row.queueJson),
        shuffled: _ids(row.shuffledJson),
        currentIndex: row.currentIndex,
        positionMs: row.positionMs,
        loopMode: row.loopMode,
        shuffle: row.shuffle,
      );
    } catch (e) {
      Log.w('Playback', 'Ignoring unreadable saved playback: $e');
      return null;
    }
  }

  List<int> _ids(String json) => [
    for (final v in jsonDecode(json) as List) (v as num).toInt(),
  ];

  @override
  void save(SavedPlayback state) {
    _tail = _tail.then((_) async {
      try {
        await _db
            .into(_db.playbackState)
            .insertOnConflictUpdate(
              PlaybackStateCompanion.insert(
                id: const Value(1),
                queueJson: Value(jsonEncode(state.queue)),
                shuffledJson: Value(jsonEncode(state.shuffled)),
                currentIndex: Value(state.currentIndex),
                positionMs: Value(state.positionMs),
                loopMode: Value(state.loopMode),
                shuffle: Value(state.shuffle),
              ),
            );
      } catch (e) {
        Log.w('Playback', 'Cannot save playback state: $e');
      }
    });
  }

  @override
  Future<void> flush() => _tail;
}

final playbackStoreProvider = Provider<PlaybackStore>(
  (ref) => MemoryPlaybackStore(),
);
