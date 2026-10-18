import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart' hide Track;
import 'package:nyaplayer/data/repositories/playback_repository.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/playback_persistence.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track _t(int id) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: id,
  duration: const Duration(seconds: 200),
  path: '/m/$id.flac',
  codec: 'FLAC',
  sampleRate: 44100,
  bitDepth: 16,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

class _CountingStore extends MemoryPlaybackStore {
  int saves = 0;

  @override
  void save(SavedPlayback state) {
    saves++;
    super.save(state);
  }
}

void main() {
  group('DbPlaybackStore', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('nothing saved yet', () async {
      expect(await DbPlaybackStore(db).load(), isNull);
    });

    test('round-trips and keeps only the latest state', () async {
      final store = DbPlaybackStore(db);
      store.save(
        const SavedPlayback(
          queue: [1, 2, 3],
          shuffled: [],
          currentIndex: 1,
          positionMs: 5,
          loopMode: 0,
          shuffle: false,
        ),
      );
      const latest = SavedPlayback(
        queue: [4, 2, 9],
        shuffled: [2, 9, 4],
        currentIndex: 2,
        positionMs: 61000,
        loopMode: 2,
        shuffle: true,
      );
      store.save(latest);
      await store.flush();

      expect(await DbPlaybackStore(db).load(), latest);
      expect(await db.select(db.playbackState).get(), hasLength(1));
    });

    test('unreadable data is ignored instead of crashing the start', () async {
      await db.customStatement(
        "INSERT INTO playback_state (id, queue_json) VALUES (1, 'oops')",
      );
      expect(await DbPlaybackStore(db).load(), isNull);
    });
  });

  group('restore and save', () {
    late FakePlayerEngine engine;
    late ProviderContainer container;
    late _CountingStore store;
    late Map<int, Track> library;

    QueueController ctl() => container.read(queueProvider.notifier);
    QueueState st() => container.read(queueProvider);
    List<int> ids() => st().queue.map((t) => t.id).toList();
    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 5));

    ProviderContainer newContainer() {
      engine = FakePlayerEngine(
        durationOf: (_) => const Duration(seconds: 200),
        tick: const Duration(milliseconds: 10),
      );
      final c = ProviderContainer(
        overrides: [
          playerEngineProvider.overrideWithValue(engine),
          randomProvider.overrideWithValue(Random(1)),
        ],
      );
      c.read(queueProvider);
      return c;
    }

    setUp(() {
      store = _CountingStore();
      library = {for (var i = 1; i <= 6; i++) i: _t(i)};
      container = newContainer();
    });

    tearDown(() async {
      container.dispose();
      await engine.dispose();
    });

    PlaybackPersistence persistence({
      Duration positionInterval = const Duration(milliseconds: 60),
    }) => PlaybackPersistence(
      container,
      store,
      debounce: const Duration(milliseconds: 30),
      positionInterval: positionInterval,
    )..start();

    /// Simulates quitting and starting again with the same saved state.
    Future<void> relaunch() async {
      container.dispose();
      await engine.dispose();
      container = newContainer();
    }

    test(
      'restores queue, track and position without starting playback',
      () async {
        final p = persistence();
        await ctl().playTracks([
          for (var i = 1; i <= 5; i++) library[i]!,
        ], startIndex: 2);
        await ctl().seek(const Duration(seconds: 42));
        await ctl().setLoopMode(LoopMode.all);
        await ctl().pause();
        await p.flush();
        p.dispose();

        await relaunch();
        await ctl().restore(store.saved!, library.get);
        await pump();

        expect(ids(), [1, 2, 3, 4, 5]);
        expect(st().currentIndex, 2);
        expect(st().current!.id, 3);
        expect(st().playing, isFalse, reason: 'PLAY-05: never auto-starts');
        expect(engine.isPlaying, isFalse);
        expect(engine.index, 2);
        expect(engine.currentPosition, const Duration(seconds: 42));
        expect(st().loopMode, LoopMode.all);
        expect(engine.loopMode, LoopMode.all);
        expect(ctl().position, const Duration(seconds: 42));

        await ctl().play();
        expect(engine.isPlaying, isTrue);
      },
    );

    test(
      'restores a shuffled queue in the same order and can unshuffle',
      () async {
        final p = persistence();
        await ctl().playTracks([
          for (var i = 1; i <= 6; i++) library[i]!,
        ], startIndex: 3);
        await ctl().toggleShuffle();
        final shuffledOrder = ids();
        final currentId = st().current!.id;
        await ctl().pause();
        await p.flush();
        p.dispose();
        expect(shuffledOrder, isNot([1, 2, 3, 4, 5, 6]));

        await relaunch();
        await ctl().restore(store.saved!, library.get);
        await pump();

        expect(st().shuffle, isTrue);
        expect(ids(), shuffledOrder);
        expect(st().current!.id, currentId);
        await ctl().toggleShuffle();
        expect(ids(), [
          1,
          2,
          3,
          4,
          5,
          6,
        ], reason: 'original order is remembered too');
      },
    );

    test(
      'tracks that left the library are dropped and the position follows',
      () async {
        const saved = SavedPlayback(
          queue: [1, 2, 3, 4, 5],
          shuffled: [],
          currentIndex: 3,
          positionMs: 30000,
          loopMode: 0,
          shuffle: false,
        );
        library
          ..remove(1)
          ..remove(3);

        await ctl().restore(saved, library.get);
        await pump();

        expect(ids(), [2, 4, 5]);
        expect(st().current!.id, 4, reason: 'still the same song');
        expect(engine.currentPosition, const Duration(seconds: 30));
      },
    );

    test(
      'if the current track is gone the next one starts from the top',
      () async {
        const saved = SavedPlayback(
          queue: [1, 2, 3, 4],
          shuffled: [],
          currentIndex: 1,
          positionMs: 30000,
          loopMode: 0,
          shuffle: false,
        );
        library.remove(2);

        await ctl().restore(saved, library.get);
        await pump();

        expect(ids(), [1, 3, 4]);
        expect(st().current!.id, 3);
        expect(engine.currentPosition, Duration.zero);
      },
    );

    test('a saved queue past the end clamps to the last track', () async {
      const saved = SavedPlayback(
        queue: [1, 2, 3],
        shuffled: [],
        currentIndex: 2,
        positionMs: 0,
        loopMode: 0,
        shuffle: false,
      );
      library.remove(3);

      await ctl().restore(saved, library.get);

      expect(ids(), [1, 2]);
      expect(st().currentIndex, 1);
    });

    test('nothing is restored when every track is gone', () async {
      const saved = SavedPlayback(
        queue: [7, 8],
        shuffled: [],
        currentIndex: 0,
        positionMs: 0,
        loopMode: 0,
        shuffle: false,
      );

      await ctl().restore(saved, library.get);

      expect(st().queue, isEmpty);
      expect(engine.paths, isEmpty);
    });

    test(
      'a shuffle flag without a saved order falls back to the plain queue',
      () async {
        const saved = SavedPlayback(
          queue: [1, 2, 3],
          shuffled: [],
          currentIndex: 1,
          positionMs: 0,
          loopMode: 0,
          shuffle: true,
        );

        await ctl().restore(saved, library.get);

        expect(st().shuffle, isFalse);
        expect(ids(), [1, 2, 3]);
      },
    );

    test('restore never replaces what the user already started', () async {
      await ctl().playTracks([library[6]!]);
      await ctl().restore(
        const SavedPlayback(
          queue: [1, 2],
          shuffled: [],
          currentIndex: 0,
          positionMs: 0,
          loopMode: 0,
          shuffle: false,
        ),
        library.get,
      );
      expect(ids(), [6]);
    });

    test('an out-of-range position is clamped to the track', () async {
      await ctl().restore(
        const SavedPlayback(
          queue: [1],
          shuffled: [],
          currentIndex: 0,
          positionMs: 99999999,
          loopMode: 0,
          shuffle: false,
        ),
        library.get,
      );
      expect(engine.currentPosition, const Duration(seconds: 200));
    });

    test('queue edits are saved once after a pause in editing', () async {
      final p = persistence(positionInterval: const Duration(minutes: 1));
      await ctl().playTracks([for (var i = 1; i <= 3; i++) library[i]!]);
      await ctl().addToQueue(library[4]!);
      await ctl().addToQueue(library[5]!);
      expect(store.saves, 0, reason: 'debounced');

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(store.saves, 1);
      expect(store.saved!.queue, [1, 2, 3, 4, 5]);
      p.dispose();
    });

    test('pausing saves the exact position straight away', () async {
      final p = persistence();
      await ctl().playTracks([library[1]!]);
      await ctl().seek(const Duration(seconds: 77));
      await ctl().pause();
      await pump();

      expect(store.saved!.positionMs, 77000);
      p.dispose();
    });

    test('while playing the position is refreshed periodically', () async {
      final p = persistence();
      await ctl().playTracks([library[1]!]);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final first = store.saved!.positionMs;
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(store.saved!.positionMs, greaterThan(first));
      await ctl().pause();
      p.dispose();
    });

    test('identical state is not written twice', () async {
      final p = persistence();
      await ctl().playTracks([library[1]!]);
      await ctl().pause();
      await pump();
      final saves = store.saves;

      await p.flush();
      await p.flush();

      expect(store.saves, saves);
      p.dispose();
    });

    test('the track index and loop mode are saved', () async {
      final p = persistence();
      await ctl().playTracks([for (var i = 1; i <= 4; i++) library[i]!]);
      await ctl().skipNext();
      await ctl().setLoopMode(LoopMode.one);
      await ctl().pause();
      await p.flush();

      expect(store.saved!.currentIndex, 1);
      expect(store.saved!.loopMode, LoopMode.one.index);
      p.dispose();
    });
  });
}

extension on Map<int, Track> {
  Track? get(int id) => this[id];
}
