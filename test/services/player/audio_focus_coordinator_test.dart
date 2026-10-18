import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/player/audio_focus_coordinator.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
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

class _FakeSession implements AudioFocusSession {
  final interruptionEvents = StreamController<AudioInterruptionEvent>();
  final noisy = StreamController<void>();
  final calls = <bool>[];
  bool grant = true;

  @override
  Future<bool> setActive(bool active) async {
    calls.add(active);
    return active ? grant : true;
  }

  @override
  Stream<AudioInterruptionEvent> get interruptions => interruptionEvents.stream;

  @override
  Stream<void> get becomingNoisy => noisy.stream;

  void interrupt(AudioInterruptionType type, {required bool begin}) =>
      interruptionEvents.add(AudioInterruptionEvent(begin, type));
}

void main() {
  late FakePlayerEngine engine;
  late ProviderContainer container;
  late _FakeSession session;
  late AudioFocusCoordinator coordinator;

  QueueController queue() => container.read(queueProvider.notifier);
  bool playing() => container.read(queueProvider).playing;
  Future<void> settle() => pumpEventQueue();

  setUp(() async {
    engine = FakePlayerEngine(
      durationOf: (_) => const Duration(seconds: 200),
      tick: const Duration(milliseconds: 10),
    );
    container = ProviderContainer(
      overrides: [playerEngineProvider.overrideWithValue(engine)],
    );
    session = _FakeSession();
    container.read(queueProvider);
    coordinator = AudioFocusCoordinator(container, session)..start();
    await queue().playTracks([_t(1), _t(2)]);
    await settle();
  });

  tearDown(() async {
    await coordinator.dispose();
    container.dispose();
    await engine.dispose();
  });

  test('focus is taken when playback starts and given back on pause', () async {
    expect(playing(), isTrue);
    expect(session.calls, [true]);

    await queue().pause();
    await settle();
    expect(session.calls, [true, false]);

    await queue().play();
    await settle();
    expect(session.calls, [true, false, true]);
  });

  test('a refused focus request stops playback again', () async {
    await queue().pause();
    await settle();
    session.grant = false;

    await queue().play();
    await settle();

    expect(playing(), isFalse);
  });

  group('interruptions', () {
    test('a call pauses, keeps the focus and resumes afterwards', () async {
      session.interrupt(AudioInterruptionType.pause, begin: true);
      await settle();
      expect(playing(), isFalse);
      // Giving the focus up here would mean never hearing it come back.
      expect(session.calls, [true]);

      session.interrupt(AudioInterruptionType.pause, begin: false);
      await settle();
      expect(playing(), isTrue);
      expect(session.calls, [true]);
    });

    test('music that was already paused stays paused afterwards', () async {
      await queue().pause();
      await settle();

      session.interrupt(AudioInterruptionType.pause, begin: true);
      session.interrupt(AudioInterruptionType.pause, begin: false);
      await settle();

      expect(playing(), isFalse);
    });

    test(
      'pressing play during the call cancels the automatic resume',
      () async {
        session.interrupt(AudioInterruptionType.pause, begin: true);
        await settle();
        await queue().play();
        await settle();
        await queue().pause();
        await settle();

        session.interrupt(AudioInterruptionType.pause, begin: false);
        await settle();

        expect(playing(), isFalse, reason: 'the user paused last');
      },
    );

    test('another player taking over for good is not undone', () async {
      session.interrupt(AudioInterruptionType.unknown, begin: true);
      await settle();
      expect(playing(), isFalse);

      session.interrupt(AudioInterruptionType.unknown, begin: false);
      await settle();
      expect(playing(), isFalse);
    });

    test('a navigation prompt only lowers the volume', () async {
      session.interrupt(AudioInterruptionType.duck, begin: true);
      await settle();
      expect(playing(), isTrue);
      expect(engine.volume, closeTo(0.3, 1e-9));

      session.interrupt(AudioInterruptionType.duck, begin: false);
      await settle();
      expect(engine.volume, 1);
    });

    test('ducking does nothing while paused', () async {
      await queue().pause();
      await settle();

      session.interrupt(AudioInterruptionType.duck, begin: true);
      await settle();

      expect(engine.volume, 1);
    });
  });

  test('unplugging the headphones pauses', () async {
    session.noisy.add(null);
    await settle();
    expect(playing(), isFalse);
  });
}
