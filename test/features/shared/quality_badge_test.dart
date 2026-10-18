import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';

Track _track({
  String codec = 'FLAC',
  int bitDepth = 16,
  int sampleRate = 44100,
}) => Track(
  id: 1,
  title: 't',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: 1,
  duration: const Duration(minutes: 3),
  path: '/m/1.flac',
  codec: codec,
  sampleRate: sampleRate,
  bitDepth: bitDepth,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

Future<void> _pump(WidgetTester tester, Track track, {double width = 400}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: Center(child: QualityBadge(track: track)),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a plain track gets the chip with the wave icon', (tester) async {
    await _pump(tester, _track());
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    expect(find.text('FLAC · 16-bit / 44.1 kHz'), findsOneWidget);
    expect(find.byType(HiResLogo), findsNothing);
  });

  testWidgets('phone and desktop widths show the very same badge', (
    tester,
  ) async {
    await _pump(tester, _track(), width: 500);
    final narrow = tester.getSize(find.byType(ActionChip));
    await _pump(tester, _track(), width: 1200);
    expect(tester.getSize(find.byType(ActionChip)), narrow);
  });

  testWidgets('the Hi-Res badge shrinks to fit instead of overflowing', (
    tester,
  ) async {
    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000), width: 120);
    expect(tester.takeException(), isNull);
    expect(find.byType(HiResLogo), findsOneWidget);
  });

  testWidgets('Hi-Res gets the gold badge, not the chip', (tester) async {
    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000));
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byType(HiResLogo), findsOneWidget);
    expect(find.text('Hi-Res · 24-bit / 96 kHz'), findsOneWidget);
    expect(tester.getSize(find.byType(HiResLogo)).height, 18);
    expect(tester.getSize(find.byType(InkWell)).height, QualityBadge.height);
  });

  testWidgets('the Hi-Res light moves, and rests when motion is reduced', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000), width: 600);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000, codec: 'WAV'));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await _pump(tester, _track(bitDepth: 24, sampleRate: 192000), width: 600);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('better than CD in either direction is Hi-Res', (tester) async {
    for (final (bits, rate) in const [(24, 44100), (16, 48000), (24, 48000)]) {
      await _pump(tester, _track(bitDepth: bits, sampleRate: rate), width: 600);
      expect(find.byType(HiResLogo), findsOneWidget, reason: '$bits/$rate');
    }
    await _pump(tester, _track());
    expect(find.byType(HiResLogo), findsNothing, reason: 'CD quality');
  });

  testWidgets('the Hi-Res badge has the corners and height of the chip', (
    tester,
  ) async {
    await _pump(tester, _track());
    final chip = find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(Material),
    );
    final chipShape =
        tester.widget<Material>(chip.first).shape! as RoundedRectangleBorder;
    final chipHeight = tester.getSize(chip.first).height;

    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000), width: 600);
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.borderRadius, chipShape.borderRadius);
    expect(tester.getSize(find.byType(InkWell)).height, chipHeight);
  });

  testWidgets('a lossy file is never Hi-Res, however high the numbers', (
    tester,
  ) async {
    await _pump(tester, _track(codec: 'MP3', bitDepth: 24, sampleRate: 96000));
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.byType(HiResLogo), findsNothing);
  });
}
