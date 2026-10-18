import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nyaplayer/features/now_playing/flowing_light.dart';

/// A PNG whose four quadrants are the given colours.
File _png(Directory dir, List<img.Color> quadrants, {String name = 'c.png'}) {
  final image = img.Image(width: 8, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      image.setPixel(x, y, quadrants[(y < 4 ? 0 : 2) + (x < 4 ? 0 : 1)]);
    }
  }
  return File('${dir.path}/$name')..writeAsBytesSync(img.encodePng(image));
}

double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('nya_palette'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('extractCoverPalette', () {
    testWidgets('gives one glowing colour per quadrant', (tester) async {
      final file = _png(dir, [
        img.ColorRgb8(200, 0, 0),
        img.ColorRgb8(0, 200, 0),
        img.ColorRgb8(0, 0, 200),
        img.ColorRgb8(200, 200, 0),
      ]);
      final palette = (await tester.runAsync(
        () => extractCoverPalette(file.path),
      ))!;

      expect(palette, hasLength(4));
      expect(_hue(palette[0]), closeTo(0, 6));
      expect(_hue(palette[1]), closeTo(120, 6));
      expect(_hue(palette[2]), closeTo(240, 6));
      expect(_hue(palette[3]), closeTo(60, 6));
      for (final c in palette) {
        final hsl = HSLColor.fromColor(c);
        expect(hsl.lightness, inInclusiveRange(0.35, 0.65));
        expect(hsl.saturation, greaterThanOrEqualTo(0.44));
      }
    });

    testWidgets('a black and white cover stays grey', (tester) async {
      final file = _png(dir, [
        img.ColorRgb8(0, 0, 0),
        img.ColorRgb8(255, 255, 255),
        img.ColorRgb8(90, 90, 90),
        img.ColorRgb8(180, 180, 180),
      ]);
      final palette = (await tester.runAsync(
        () => extractCoverPalette(file.path),
      ))!;

      expect(palette, hasLength(4));
      for (final c in palette) {
        expect(HSLColor.fromColor(c).saturation, lessThan(0.1));
      }
    });

    testWidgets('a missing or broken file gives nothing instead of failing', (
      tester,
    ) async {
      expect(
        await tester.runAsync(() => extractCoverPalette('${dir.path}/nope')),
        isEmpty,
      );
      final broken = File('${dir.path}/b.png')..writeAsBytesSync([1, 2, 3]);
      expect(
        await tester.runAsync(() => extractCoverPalette(broken.path)),
        isEmpty,
      );
    });
  });

  test('vividLight lifts dull colours and tames extremes', () {
    final dull = HSLColor.fromColor(vividLight(const Color(0xFF3A3F40)));
    expect(dull.lightness, greaterThanOrEqualTo(0.35));
    final white = HSLColor.fromColor(vividLight(const Color(0xFFFFFFFF)));
    expect(white.lightness, lessThanOrEqualTo(0.65));
    final muted = HSLColor.fromColor(vividLight(const Color(0xFF604040)));
    expect(muted.saturation, greaterThanOrEqualTo(0.44));
  });

  group('FlowingLight', () {
    Future<void> pump(
      WidgetTester tester, {
      required List<Color> colors,
      bool animate = true,
      Color? accent,
      int? seed,
    }) => tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: FlowingLight(
            colors: colors,
            animate: animate,
            accent: accent,
            seed: seed,
          ),
        ),
      ),
    );

    void motion(WidgetTester tester, {required bool reduced}) =>
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);

    testWidgets('stands still while a song plays', (tester) async {
      motion(tester, reduced: false);
      await pump(tester, colors: const [Colors.red, Colors.blue], seed: 7);
      await tester.pump(const Duration(seconds: 1));
      // No ticker is left running: the backdrop costs no frames at rest.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a new song moves the lights once, then they rest', (
      tester,
    ) async {
      motion(tester, reduced: false);
      const colors = [Colors.red, Colors.blue];
      await pump(tester, colors: colors, seed: 1);
      await tester.pump(const Duration(seconds: 1));
      await pump(tester, colors: colors, seed: 2);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion or animate off jumps without frames', (
      tester,
    ) async {
      motion(tester, reduced: true);
      const colors = [Colors.red, Colors.blue];
      await pump(tester, colors: colors, seed: 1);
      await pump(tester, colors: colors, seed: 2);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);

      motion(tester, reduced: false);
      await pump(tester, colors: colors, animate: false, seed: 3);
      await pump(tester, colors: colors, animate: false, seed: 4);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('new colours fade in and an empty list draws nothing', (
      tester,
    ) async {
      motion(tester, reduced: false);
      await pump(tester, colors: const [Colors.red], accent: Colors.amber);
      await tester.pump(const Duration(milliseconds: 100));
      await pump(
        tester,
        colors: const [Colors.green, Colors.teal, Colors.cyan],
        accent: Colors.amber,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await pump(tester, colors: const []);
      expect(
        find.descendant(
          of: find.byType(FlowingLight),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });
}
