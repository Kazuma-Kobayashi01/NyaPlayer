import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/theme/hires_colors.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';

Track _track({
  int id = 1,
  String codec = 'FLAC',
  int bitDepth = 16,
  int sampleRate = 44100,
  String path = '/m/1.flac',
}) => Track(
  id: id,
  title: 't',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: 1,
  duration: const Duration(minutes: 3),
  path: path,
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
  testWidgets('a lossy track gets the plain chip with the wave icon', (
    tester,
  ) async {
    await _pump(tester, _track(codec: 'MP3'));
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    expect(find.text('MP3 · 16-bit / 44.1 kHz'), findsOneWidget);
    expect(find.byType(HiResLogo), findsNothing);
  });

  testWidgets('plain FLAC is called SQ and gets the silver-black badge', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    expect(isPlainFlac(_track()), isTrue);
    expect(
      isPlainFlac(_track(bitDepth: 24)),
      isFalse,
      reason: 'that is Hi-Res',
    );
    expect(isPlainFlac(_track(codec: 'MP3')), isFalse);
    await _pump(tester, _track(), width: 600);
    expect(find.byType(ActionChip), findsNothing);
    expect(
      find.byType(HiResLogo),
      findsNothing,
      reason: 'the gold mark is Hi-Res only',
    );
    expect(find.text('SQ · 16-bit / 44.1 kHz'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.graphic_eq));
    expect(icon.color, HiResColors.silver.shine);
    final painters = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(QualityBadge),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      painters.any((p) => p.painter.toString().contains('_SweepFlowPainter')),
      isTrue,
    );
    // The sweep is a one-off, like the Hi-Res one: it ends and nothing ticks.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('an AI-made FLAC is SQ-AI with the tech-blue badge', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    final ai = _track(path: '/m/Song.SQ-AI.flac');
    expect(isAiSr(ai), isTrue);
    expect(isAiSr(_track(path: '/m/Song.sq-ai.FLAC')), isTrue, reason: 'case');
    expect(isAiSr(_track()), isFalse);
    expect(isAiSr(_track(path: '/m/Song.SQ-AI.mp3', codec: 'MP3')), isFalse);
    expect(isPlainFlac(ai), isFalse, reason: 'SQ-AI is not plain SQ');
    expect(isHiRes(ai), isFalse, reason: '16-bit / 44.1 kHz');

    await _pump(tester, ai, width: 600);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byType(HiResLogo), findsNothing);
    expect(find.text('SQ-AI · 16-bit / 44.1 kHz'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
    expect(icon.color, HiResColors.techBlue.shine);
    // It is blue, not the silver of SQ.
    expect(
      HiResColors.techBlue.gold.b,
      greaterThan(HiResColors.techBlue.gold.r),
    );

    // Same shape and size as the other badges, and the same one-off sweep.
    final size = tester.getSize(find.byType(InkWell));
    await _pump(tester, _track(), width: 600);
    expect(tester.getSize(find.byType(InkWell)).height, size.height);
    await _pump(tester, ai, width: 600);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('silver and gold badges share size and shape', (tester) async {
    await _pump(tester, _track(), width: 600);
    final silverSize = tester.getSize(find.byType(InkWell));
    final silverShape = tester
        .widget<InkWell>(find.byType(InkWell))
        .borderRadius;
    await _pump(tester, _track(bitDepth: 24, sampleRate: 96000), width: 600);
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).borderRadius,
      silverShape,
    );
    expect(tester.getSize(find.byType(InkWell)).height, silverSize.height);
  });

  testWidgets('phone and desktop widths show the very same badge', (
    tester,
  ) async {
    await _pump(tester, _track(codec: 'MP3'), width: 500);
    final narrow = tester.getSize(find.byType(ActionChip));
    await _pump(tester, _track(codec: 'MP3'), width: 1200);
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

  testWidgets('the Hi-Res light plays once per song, then no ticker runs', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    Future<void> hiRes(int id) => _pump(
      tester,
      _track(id: id, bitDepth: 24, sampleRate: 96000),
      width: 600,
    );
    await hiRes(1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 2)); // past the 1.5 s sweep
    expect(tester.binding.hasScheduledFrame, isFalse);

    await hiRes(2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'new song');
    await tester.pump(const Duration(seconds: 2));
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
    await _pump(tester, _track(codec: 'MP3'));
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
