import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track _t(int id, {int seconds = 200}) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: id,
  duration: Duration(seconds: seconds),
  path: '/m/$id.flac',
  codec: 'FLAC',
  sampleRate: 44100,
  bitDepth: 16,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

void main() {
  late FakePlayerEngine engine;
  late ProviderContainer container;
  late List<Track> tracks;

  QueueController ctl() => container.read(queueProvider.notifier);
  QueueState st() => container.read(queueProvider);
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() {
    tracks = [for (var i = 1; i <= 5; i++) _t(i)];
    engine = FakePlayerEngine(
      durationOf: (p) => const Duration(seconds: 200),
      tick: const Duration(milliseconds: 10),
    );
    container = ProviderContainer(
      overrides: [
        playerEngineProvider.overrideWithValue(engine),
        randomProvider.overrideWithValue(Random(42)),
      ],
    );
    container.read(queueProvider); // build and subscribe
  });

  tearDown(() async {
    container.dispose();
    await engine.dispose();
  });

  List<int> ids() => st().queue.map((t) => t.id).toList();

  test('playTracks opens the queue at the chosen index and plays', () async {
    await ctl().playTracks(tracks, startIndex: 2);
    await pump();
    expect(ids(), [1, 2, 3, 4, 5]);
    expect(st().currentIndex, 2);
    expect(st().current!.id, 3);
    expect(st().playing, isTrue);
    expect(engine.paths.length, 5);
  });

  test('togglePlay pauses and resumes', () async {
    await ctl().playTracks(tracks);
    await ctl().togglePlay();
    await pump();
    expect(st().playing, isFalse);
    await ctl().togglePlay();
    await pump();
    expect(st().playing, isTrue);
  });

  group('skip', () {
    test('next moves forward and stops at the end without loop', () async {
      await ctl().playTracks(tracks, startIndex: 3);
      await ctl().skipNext();
      await pump();
      expect(st().currentIndex, 4);
      await ctl().skipNext();
      await pump();
      expect(st().currentIndex, 4);
    });

    test('next wraps with loop all', () async {
      await ctl().playTracks(tracks, startIndex: 4);
      await ctl().setLoopMode(LoopMode.all);
      await ctl().skipNext();
      await pump();
      expect(st().currentIndex, 0);
    });

    test('previous restarts the track after 3 seconds', () async {
      await ctl().playTracks(tracks, startIndex: 2);
      await engine.seek(const Duration(seconds: 10));
      await pump();
      await ctl().skipPrevious();
      await pump();
      expect(st().currentIndex, 2);
      expect(engine.currentPosition, Duration.zero);
    });

    test('previous goes back when within 3 seconds', () async {
      await ctl().playTracks(tracks, startIndex: 2);
      await engine.seek(const Duration(seconds: 1));
      await pump();
      await ctl().skipPrevious();
      await pump();
      expect(st().currentIndex, 1);
    });

    test(
      'previous at the first track restarts it; wraps with loop all',
      () async {
        await ctl().playTracks(tracks);
        await ctl().skipPrevious();
        await pump();
        expect(st().currentIndex, 0);
        await ctl().setLoopMode(LoopMode.all);
        await ctl().skipPrevious();
        await pump();
        expect(st().currentIndex, 4);
      },
    );
  });

  group('queue edits', () {
    test('playNext inserts after the current track', () async {
      await ctl().playTracks(tracks, startIndex: 1);
      await ctl().playNext(_t(9));
      await pump();
      expect(ids(), [1, 2, 9, 3, 4, 5]);
      expect(st().currentIndex, 1);
      expect(engine.paths[2], '/m/9.flac');
    });

    test('addToQueue appends', () async {
      await ctl().playTracks(tracks);
      await ctl().addToQueue(_t(9));
      expect(ids().last, 9);
      expect(engine.paths.last, '/m/9.flac');
    });

    test('addToQueue on an empty queue starts playing it', () async {
      await ctl().addToQueue(_t(7));
      await pump();
      expect(ids(), [7]);
      expect(st().playing, isTrue);
    });

    test(
      'removing a track before the current one keeps the current track',
      () async {
        await ctl().playTracks(tracks, startIndex: 3);
        await ctl().removeAt(0);
        await pump();
        expect(ids(), [2, 3, 4, 5]);
        expect(st().current!.id, 4);
        expect(st().currentIndex, 2);
      },
    );

    test('removing the current track moves on to the next one', () async {
      await ctl().playTracks(tracks, startIndex: 1);
      await ctl().removeAt(1);
      await pump();
      expect(st().current!.id, 3);
    });

    test('removing the last remaining track empties the queue', () async {
      await ctl().playTracks([tracks.first]);
      await ctl().removeAt(0);
      await pump();
      expect(st().queue, isEmpty);
      expect(st().current, isNull);
      expect(st().playing, isFalse);
    });

    test('move keeps following the current track', () async {
      await ctl().playTracks(tracks, startIndex: 1);
      await ctl().move(3, 0);
      await pump();
      expect(ids(), [4, 1, 2, 3, 5]);
      expect(st().current!.id, 2);
      await ctl().move(0, 4);
      await pump();
      expect(ids(), [1, 2, 3, 5, 4]);
      expect(st().current!.id, 2);
    });

    test('jumpTo selects the item', () async {
      await ctl().playTracks(tracks);
      await ctl().jumpTo(3);
      await pump();
      expect(st().current!.id, 4);
    });
  });

  group('shuffle', () {
    test(
      'enabling keeps the current track first and the same set of tracks',
      () async {
        await ctl().playTracks(tracks, startIndex: 2);
        await ctl().toggleShuffle();
        await pump();
        expect(st().shuffle, isTrue);
        expect(st().currentIndex, 0);
        expect(st().current!.id, 3);
        expect(ids()..sort(), [1, 2, 3, 4, 5]);
      },
    );

    test(
      'disabling restores the original order around the current track',
      () async {
        await ctl().playTracks(tracks, startIndex: 2);
        await ctl().toggleShuffle();
        await ctl().skipNext();
        await pump();
        final current = st().current!;
        await ctl().toggleShuffle();
        await pump();
        expect(ids(), [1, 2, 3, 4, 5]);
        expect(st().current, current);
        expect(st().currentIndex, current.id - 1);
      },
    );

    test('toggling preserves playback position and play state', () async {
      await ctl().playTracks(tracks);
      await engine.seek(const Duration(seconds: 42));
      await pump();
      await ctl().toggleShuffle();
      await pump();
      expect(engine.currentPosition, const Duration(seconds: 42));
      expect(st().playing, isTrue);
    });

    test('toggling while paused stays paused', () async {
      await ctl().playTracks(tracks);
      await ctl().togglePlay();
      await pump();
      await ctl().toggleShuffle();
      await pump();
      expect(st().playing, isFalse);
    });

    for (final paused in [false, true]) {
      test(
        'shuffle never emits a reset or changes play state (paused=$paused)',
        () async {
          await ctl().playTracks(tracks, startIndex: 2);
          await engine.seek(const Duration(seconds: 42));
          if (paused) await engine.pause();
          await pump();
          final positions = <Duration>[];
          final playing = <bool>[];
          final posSub = engine.position.listen(positions.add);
          final playSub = engine.playing.listen(playing.add);
          addTearDown(posSub.cancel);
          addTearDown(playSub.cancel);
          for (var i = 0; i < 8; i++) {
            await ctl().toggleShuffle();
            await pump();
            expect(st().current!.id, 3);
            expect(engine.paths[engine.index!], tracks[2].path);
            expect(
              engine.currentPosition,
              greaterThanOrEqualTo(const Duration(seconds: 42)),
            );
            expect(engine.isPlaying, !paused);
          }
          expect(
            positions,
            everyElement(greaterThanOrEqualTo(const Duration(seconds: 42))),
          );
          expect(playing, isEmpty);
        },
      );
    }

    test(
      'shuffle preserves the playing occurrence of repeated songs',
      () async {
        await ctl().playTracks([
          tracks[0],
          tracks[1],
          tracks[0],
          tracks[2],
        ], startIndex: 2);
        await pump();
        await ctl().toggleShuffle();
        await pump();
        expect(engine.index, 0);
        expect(st().currentIndex, engine.index);
        await ctl().toggleShuffle();
        await pump();
        expect(engine.paths, [
          tracks[0].path,
          tracks[1].path,
          tracks[0].path,
          tracks[2].path,
        ]);
        expect(st().currentIndex, engine.index);
        expect(st().current, tracks[0]);
      },
    );

    test('shufflePlay turns shuffle on and starts the queue', () async {
      await ctl().shufflePlay(tracks);
      await pump();
      expect(st().shuffle, isTrue);
      expect(st().queue.length, 5);
      expect(st().playing, isTrue);
    });

    test('shuffle toggled before anything plays only sets the flag', () async {
      await ctl().toggleShuffle();
      expect(st().shuffle, isTrue);
      await ctl().playTracks(tracks, startIndex: 2);
      await pump();
      expect(st().current!.id, 3);
      expect(st().currentIndex, 0);
    });
  });

  group('loop mode', () {
    test('cycles none -> all -> one -> none and reaches the engine', () async {
      expect(st().loopMode, LoopMode.none);
      await ctl().cycleLoopMode();
      expect(st().loopMode, LoopMode.all);
      expect(engine.loopMode, LoopMode.all);
      await ctl().cycleLoopMode();
      expect(st().loopMode, LoopMode.one);
      await ctl().cycleLoopMode();
      expect(st().loopMode, LoopMode.none);
    });
  });
}
