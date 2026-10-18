import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart' show isHiRes;
import 'package:nyaplayer/services/eq/eq_binding.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track _track(int id, {int rate = 44100, int bits = 16}) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: id,
  duration: const Duration(minutes: 3),
  path: '/m/$id.flac',
  codec: 'FLAC',
  sampleRate: rate,
  bitDepth: bits,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

void main() {
  late FakePlayerEngine engine;
  late ProviderContainer container;
  late void Function() close;

  setUp(() {
    engine = FakePlayerEngine(
      durationOf: (p) => const Duration(minutes: 3),
      tick: const Duration(milliseconds: 10),
    );
    container = ProviderContainer(
      overrides: [playerEngineProvider.overrideWithValue(engine)],
    );
    container.read(queueProvider);
    close = bindEqualizer(container, engine, passThrough: isHiRes);
  });

  tearDown(() async {
    close();
    container.dispose();
    await engine.dispose();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'Hi-Res tracks play without the equalizer, plain ones with it',
    () async {
      final plain = _track(1);
      final hires = _track(2, rate: 96000, bits: 24);
      container.read(eqProvider.notifier).setEnabled(true);
      container.read(eqProvider.notifier).selectPreset('bassBoost');
      await container.read(queueProvider.notifier).playTracks([plain, hires]);
      await settle();
      expect(engine.eqParams.enabled, isTrue, reason: 'plain FLAC');
      expect(engine.eqParams.gains.first, greaterThan(0));

      await container.read(queueProvider.notifier).playTracks([hires, plain]);
      await settle();
      expect(engine.eqParams.enabled, isFalse, reason: 'Hi-Res');

      await container.read(queueProvider.notifier).skipNext();
      await settle();
      expect(engine.eqParams.enabled, isTrue, reason: 'back to plain FLAC');
    },
  );

  test('a 96 kHz 16-bit file is Hi-Res too', () async {
    container.read(eqProvider.notifier).setEnabled(true);
    await container.read(queueProvider.notifier).playTracks([
      _track(3, rate: 96000),
    ]);
    await settle();
    expect(engine.eqParams.enabled, isFalse);
  });
}
