import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';
import 'package:nyaplayer/services/widgets/macos_widget_bridge.dart';

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
          size: 1,
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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nyaplayer/widget');
  const codec = StandardMethodCodec();
  late FakePlayerEngine engine;
  late ProviderContainer container;
  late MacOSWidgetBridge bridge;
  late _Covers covers;
  final snapshots = <Map<String, dynamic>>[];
  var supported = true;

  QueueController controller() => container.read(queueProvider.notifier);
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 180));
  Future<void> command(
    String action, {
    int index = -1,
    String revision = '',
  }) async {
    final response = Completer<ByteData?>();
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(
        MethodCall('command', {
          'action': action,
          'index': index,
          'queueRevision': revision,
        }),
      ),
      response.complete,
    );
    codec.decodeEnvelope((await response.future)!);
  }

  setUp(() {
    snapshots.clear();
    supported = true;
    engine = FakePlayerEngine(
      durationOf: (_) => const Duration(minutes: 3),
      tick: const Duration(hours: 1),
    );
    container = ProviderContainer(
      overrides: [playerEngineProvider.overrideWithValue(engine)],
    );
    covers = _Covers();
    bridge = MacOSWidgetBridge(container, channel: channel, covers: covers);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'isSupported') return supported;
      if (call.method == 'publishSnapshot') {
        snapshots.add(Map<String, dynamic>.from(call.arguments as Map));
      }
      return null;
    });
  });
  tearDown(() async {
    await bridge.close();
    container.dispose();
    await engine.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'restored queue, metadata and widget controls use the existing engine',
    () async {
      await controller().playTracks([track(1), track(2)]);
      await Future<void>.delayed(Duration.zero);
      await bridge.start();
      expect(snapshots.last['album'], 'Album 1');
      expect(snapshots.last['isPlaying'], isTrue);
      expect(snapshots.last['queue'], hasLength(2));
      await command('togglePlayback');
      expect(engine.isPlaying, isFalse);
      expect(snapshots.last['isPlaying'], isFalse);
      await command('nextTrack');
      expect(engine.index, 1);
      expect(snapshots.last['title'], 'Title 2');
      await command('cycleLoopMode');
      expect(engine.loopMode, LoopMode.all);
      expect(snapshots.last['repeatMode'], 'all');
    },
  );

  test(
    'old queue buttons cannot target a different song after queue replacement',
    () async {
      await controller().playTracks([track(1), track(2)]);
      await bridge.start();
      final previous = snapshots.last['queueRevision'] as String;
      await controller().playTracks([track(3), track(4)]);
      await flush();
      await expectLater(
        command('playQueueItem', index: 1, revision: previous),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'stale_queue'),
        ),
      );
      expect(engine.index, 0);
      await command(
        'playQueueItem',
        index: 1,
        revision: snapshots.last['queueRevision'] as String,
      );
      expect(engine.index, 1);
      expect(engine.isPlaying, isTrue);
    },
  );

  test(
    'shuffle preserves progress and explicit seeks refresh the widget',
    () async {
      await controller().playTracks([track(1), track(2)]);
      await controller().seek(const Duration(seconds: 43));
      await Future<void>.delayed(Duration.zero);
      await bridge.start();
      await command('toggleShuffle');
      expect(snapshots.last['shuffle'], isTrue);
      expect(snapshots.last['positionMs'], 43000);
      await controller().seek(const Duration(seconds: 21));
      await flush();
      expect(snapshots.last['positionMs'], 21000);
      expect(snapshots.last['reload'], isTrue);
    },
  );

  test(
    'late artwork from an earlier track cannot replace the active cover',
    () async {
      final first = track(1, artwork: true);
      final second = track(2, artwork: true);
      await controller().playTracks([first, second]);
      await bridge.start();
      await command('nextTrack');
      covers.requests[second.cover]!.complete(
        const CachedCover(thumbnail: '/new.jpg', large: '/new-big.jpg'),
      );
      await flush();
      covers.requests[first.cover]!.complete(
        const CachedCover(thumbnail: '/old.jpg', large: '/old-big.jpg'),
      );
      await flush();
      expect(snapshots.last['artworkSource'], '/new.jpg');
      expect(snapshots.last['title'], 'Title 2');
    },
  );

  test(
    'closing publishes a paused durable snapshot and stops future updates',
    () async {
      await controller().playTracks([track(1)]);
      await bridge.start();
      await bridge.close();
      expect(snapshots.last['appRunning'], isFalse);
      expect(snapshots.last['isPlaying'], isFalse);
      final count = snapshots.length;
      await controller().pause();
      await flush();
      expect(snapshots, hasLength(count));
    },
  );

  test(
    'rapid controls are serialized against the updated player index',
    () async {
      await controller().playTracks([track(1), track(2), track(3)]);
      await bridge.start();
      await Future.wait([command('nextTrack'), command('nextTrack')]);
      expect(engine.index, 2);
      expect(snapshots.last['title'], 'Title 3');
    },
  );

  test('macOS versions without interactive widgets skip the bridge', () async {
    supported = false;
    await bridge.start();
    expect(snapshots, isEmpty);
  });
}
