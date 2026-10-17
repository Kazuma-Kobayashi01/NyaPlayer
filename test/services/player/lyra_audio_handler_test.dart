import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/lyra_audio_handler.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track track(int id, {bool artwork = false}) => Track(
  id: id,
  title: 'Title $id',
  artist: 'Artist $id',
  album: 'Album $id',
  albumId: id,
  trackNo: id,
  duration: const Duration(minutes: 3),
  path: '/music/$id.flac',
  codec: 'FLAC',
  sampleRate: 48000,
  bitDepth: 24,
  bitrateKbps: 1000,
  addedAt: DateTime(2026),
  coverSeed: 1,
  cover: artwork
      ? CoverSource(
          albumKey: '$id',
          path: '/music/$id.flac',
          size: 100,
          modifiedMs: 1,
        )
      : null,
);

class _Covers extends CoverCache {
  final requests = <CoverSource, Completer<CachedCover?>>{};
  @override
  Future<CachedCover?> load(CoverSource source) =>
      requests.putIfAbsent(source, Completer<CachedCover?>.new).future;
}

class _Engine extends FakePlayerEngine {
  _Engine()
    : super(
        durationOf: (_) => const Duration(minutes: 3),
        tick: const Duration(hours: 1),
      );
  final positions = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get position => positions.stream;
  @override
  Future<void> seek(Duration position) async {
    await super.seek(position);
    positions.add(currentPosition);
  }

  @override
  Future<void> dispose() async {
    await positions.close();
    await super.dispose();
  }
}

void main() {
  late _Engine engine;
  late ProviderContainer container;
  late LyraAudioHandler handler;
  late _Covers covers;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  QueueController controller() => container.read(queueProvider.notifier);

  setUp(() {
    engine = _Engine();
    covers = _Covers();
    container = ProviderContainer(
      overrides: [
        playerEngineProvider.overrideWithValue(engine),
        coverCacheProvider.overrideWithValue(covers),
      ],
    );
    handler = LyraAudioHandler(container);
  });
  tearDown(() async {
    await handler.dispose();
    container.dispose();
    await engine.dispose();
  });

  test('metadata, queue and remote controls share the active engine', () async {
    final tracks = [track(1), track(2)];
    await controller().playTracks(tracks);
    await flush();
    expect(handler.mediaItem.value?.title, 'Title 1');
    expect(handler.mediaItem.value?.artist, 'Artist 1');
    expect(handler.mediaItem.value?.album, 'Album 1');
    expect(handler.mediaItem.value?.duration, const Duration(minutes: 3));
    expect(handler.queue.value.length, 2);
    expect(handler.playbackState.value.playing, isTrue);
    await handler.pause();
    await handler.pause();
    await flush();
    expect(engine.isPlaying, isFalse);
    expect(handler.playbackState.value.playing, isFalse);
    await handler.play();
    await handler.play();
    await flush();
    expect(engine.isPlaying, isTrue);
    await handler.seek(const Duration(seconds: 30));
    await flush();
    expect(engine.currentPosition, const Duration(seconds: 30));
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(seconds: 30),
    );
    await handler.skipToNext();
    await flush();
    expect(handler.mediaItem.value?.id, tracks[1].path);
    expect(handler.playbackState.value.queueIndex, 1);
    await handler.stop();
    await flush();
    expect(engine.isPlaying, isFalse);
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
  });

  test(
    'removing the task preserves active playback; explicit stop still stops',
    () async {
      await controller().playTracks([track(1), track(2)]);
      await handler.seek(const Duration(seconds: 50));
      await flush();
      await handler.onTaskRemoved();
      await flush();
      expect(engine.isPlaying, isTrue);
      expect(engine.currentPosition, const Duration(seconds: 50));
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.ready,
      );
      await handler.pause();
      await flush();
      await handler.onTaskRemoved();
      expect(engine.isPlaying, isFalse);
      await handler.stop();
      await flush();
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    },
  );

  test('ticks do not flood the OS; small UI seeks and shuffle preserve the timeline', () async {
    await controller().playTracks([track(1), track(2), track(3)]);
    await flush();
    final updates = <PlaybackState>[];
    final subscription = handler.playbackState.listen(updates.add);
    addTearDown(subscription.cancel);
    await flush();
    final before = updates.length;
    engine.positions.add(const Duration(seconds: 40));
    engine.positions.add(const Duration(seconds: 41));
    engine.positions.add(const Duration(seconds: 42));
    await flush();
    expect(updates.length, before);
    await controller().seek(const Duration(milliseconds: 42100));
    await flush();
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(milliseconds: 42100),
    );
    final current = handler.mediaItem.value?.id;
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    await flush();
    expect(handler.mediaItem.value?.id, current);
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(milliseconds: 42100),
    );
    expect(
      handler.playbackState.value.shuffleMode,
      AudioServiceShuffleMode.all,
    );
    expect(engine.isPlaying, isTrue);
  });

  test('late artwork cannot overwrite a new song; publishes a local large cover URI', () async {
    final a = track(1, artwork: true);
    final b = track(2, artwork: true);
    await controller().playTracks([a, b]);
    await flush();
    await handler.skipToNext();
    await flush();
    covers.requests[a.cover]!.complete(
      const CachedCover(
        thumbnail: '/cache/a_256.jpg',
        large: '/cache/a_1024.jpg',
      ),
    );
    await flush();
    expect(handler.mediaItem.value?.id, b.path);
    expect(handler.mediaItem.value?.artUri, isNull);
    covers.requests[b.cover]!.complete(
      const CachedCover(
        thumbnail: '/cache/b_256.jpg',
        large: '/cache/b_1024.jpg',
      ),
    );
    await flush();
    expect(handler.mediaItem.value?.artUri, Uri.file('/cache/b_1024.jpg'));
    expect(handler.queue.value[1].artUri, handler.mediaItem.value?.artUri);
  });
}
