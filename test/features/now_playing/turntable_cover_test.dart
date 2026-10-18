import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/now_playing/turntable_cover.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track _track(int id, {int albumId = 1}) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: albumId,
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

/// A square of [side] in the middle of a screen, playing at [position].
Widget _app(
  Track track, {
  required bool playing,
  Duration position = Duration.zero,
  double side = 400,
  Stream<Duration>? positions,
}) => ProviderScope(
  // An override cannot be swapped by pumping again, so a test that moves the
  // position passes a stream it keeps feeding.
  overrides: [
    positionProvider.overrideWith((ref) => positions ?? Stream.value(position)),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: side,
          child: TurntableCover(track: track, playing: playing),
        ),
      ),
    ),
  ),
);

void motion(WidgetTester tester, {required bool reduced}) =>
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduced);

TonearmPainter _arm(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<TonearmPainter>()
    .single;

double _distanceFromCentre(Offset unit) =>
    (unit - TurntableGeometry.center).distance;

void main() {
  group('geometry', () {
    test('the stylus starts on the outer groove and ends on the inner one', () {
      final start = TurntableGeometry.stylus(TurntableGeometry.playAngle(0));
      final end = TurntableGeometry.stylus(TurntableGeometry.playAngle(1));
      expect(
        _distanceFromCentre(start),
        closeTo(TurntableGeometry.outerGroove, 1e-6),
      );
      expect(
        _distanceFromCentre(end),
        closeTo(TurntableGeometry.innerGroove, 1e-6),
      );
      // Always on the grooves: outside the label, inside the rim.
      for (var p = 0.0; p <= 1; p += 0.1) {
        final r = _distanceFromCentre(
          TurntableGeometry.stylus(TurntableGeometry.playAngle(p)),
        );
        expect(r, greaterThan(TurntableGeometry.labelRadius));
        expect(r, lessThan(TurntableGeometry.recordRadius));
      }
    });

    test('the arm moves inward steadily as the song goes on', () {
      var previous = TurntableGeometry.playAngle(0);
      for (var p = 0.1; p <= 1; p += 0.1) {
        final angle = TurntableGeometry.playAngle(p);
        expect(angle, greaterThan(previous));
        previous = angle;
      }
      // Out-of-range progress is clamped, not extrapolated.
      expect(TurntableGeometry.playAngle(-1), TurntableGeometry.playAngle(0));
      expect(TurntableGeometry.playAngle(2), TurntableGeometry.playAngle(1));
    });

    test('the sleeve ring stays inside the square it is given', () {
      const c = TurntableGeometry.center;
      const f = TurntableGeometry.frameRadius;
      expect(c.dx - f, greaterThanOrEqualTo(0));
      expect(c.dy - f, greaterThanOrEqualTo(0));
      expect(c.dx + f, lessThanOrEqualTo(1));
      expect(c.dy + f, lessThanOrEqualTo(1));
      expect(f, greaterThan(TurntableGeometry.recordRadius));
      expect(TurntableGeometry.holeRadius, greaterThan(0.03));
    });

    test('at rest the stylus is clear of the record', () {
      final rest = TurntableGeometry.stylus(TurntableGeometry.restAngle);
      expect(
        _distanceFromCentre(rest),
        greaterThan(TurntableGeometry.recordRadius + 0.05),
      );
      expect(TurntableGeometry.angle(0.5, 0), TurntableGeometry.restAngle);
      expect(
        TurntableGeometry.angle(0.5, 1),
        closeTo(TurntableGeometry.playAngle(0.5), 1e-9),
      );
    });

    test('the arm swings at least 15 degrees to come down', () {
      final swing =
          (TurntableGeometry.playAngle(0) - TurntableGeometry.restAngle).abs();
      expect(swing, greaterThan(15 * math.pi / 180));
    });
  });

  group('the hole', () {
    final path = TurntableHoleClipper.pathFor(400);
    Offset at(double unitX, double unitY) => Offset(unitX * 400, unitY * 400);
    final c = TurntableGeometry.center;

    test('the middle is punched out, the rest of the record is not', () {
      expect(path.contains(at(c.dx, c.dy)), isFalse);
      expect(
        path.contains(at(c.dx + TurntableGeometry.holeRadius * 0.9, c.dy)),
        isFalse,
      );
      expect(
        path.contains(at(c.dx + TurntableGeometry.holeRadius * 1.5, c.dy)),
        isTrue,
        reason: 'the label is right up to the hole',
      );
      expect(path.contains(at(c.dx + 0.2, c.dy)), isTrue, reason: 'the label');
      expect(path.contains(at(c.dx + 0.36, c.dy)), isTrue, reason: 'grooves');
      expect(
        path.contains(at(c.dx + TurntableGeometry.recordRadius + 0.02, c.dy)),
        isFalse,
        reason: 'outside the record',
      );
    });
  });

  group('on screen', () {
    testWidgets('the cover is the label, centred, with the hole cut out', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_track(1), playing: false));
      final box = tester.getRect(find.byType(TurntableCover));
      final label = tester.getRect(find.byType(CoverArt));
      final centre = box.topLeft + TurntableGeometry.center * box.width;

      expect(label.center.dx, closeTo(centre.dx, 0.5));
      expect(label.center.dy, closeTo(centre.dy, 0.5));
      expect(
        label.width,
        closeTo(TurntableGeometry.labelRadius * 2 * box.width, 0.5),
      );
      // The label is clipped by a path with the hole in it.
      final clip = tester.widget<ClipPath>(
        find.ancestor(
          of: find.byType(CoverArt),
          matching: find.byType(ClipPath),
        ),
      );
      expect(clip.clipper, isA<TurntableHoleClipper>());
    });

    testWidgets('the arm is down with the song and rests when paused', (
      tester,
    ) async {
      motion(tester, reduced: true);
      const half = Duration(seconds: 100);
      await tester.pumpWidget(_app(_track(1), playing: true, position: half));
      await tester.pump();
      expect(
        _arm(tester).angle,
        closeTo(TurntableGeometry.playAngle(0.5), 1e-9),
      );

      await tester.pumpWidget(_app(_track(1), playing: false, position: half));
      await tester.pump();
      expect(_arm(tester).angle, closeTo(TurntableGeometry.restAngle, 1e-9));
    });

    testWidgets('the arm creeps inward with the playback position', (
      tester,
    ) async {
      motion(tester, reduced: true);
      final positions = StreamController<Duration>();
      addTearDown(positions.close);
      await tester.pumpWidget(
        _app(_track(1), playing: true, positions: positions.stream),
      );
      positions.add(Duration.zero);
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      final start = _arm(tester).angle;

      positions.add(const Duration(seconds: 190));
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      expect(_arm(tester).angle, greaterThan(start));
    });

    testWidgets('standing still when motion is reduced', (tester) async {
      motion(tester, reduced: true);
      await tester.pumpWidget(_app(_track(1), playing: true));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('the arm comes down, the record turns, both stop on pause', (
      tester,
    ) async {
      motion(tester, reduced: false);
      await tester.pumpWidget(_app(_track(1), playing: false));
      await tester.pump();
      expect(_arm(tester).engage.value, 0);

      await tester.pumpWidget(_app(_track(1), playing: true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_arm(tester).engage.value, inExclusiveRange(0, 1));
      await tester.pump(const Duration(seconds: 2));
      expect(_arm(tester).engage.value, 1);
      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: 'the record keeps turning',
      );

      await tester.pumpWidget(_app(_track(1), playing: false));
      await tester.pump(const Duration(seconds: 2));
      expect(_arm(tester).engage.value, 0);
      // The record slows down and stops; nothing keeps animating after that.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a new song lifts the arm and puts it down again', (
      tester,
    ) async {
      motion(tester, reduced: false);
      await tester.pumpWidget(_app(_track(1), playing: true));
      await tester.pump(const Duration(seconds: 2));
      expect(_arm(tester).engage.value, 1);

      await tester.pumpWidget(_app(_track(2, albumId: 2), playing: true));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_arm(tester).engage.value, lessThan(1), reason: 'lifting');
      await tester.pump(const Duration(milliseconds: 200));
      expect(_arm(tester).engage.value, lessThan(0.2), reason: 'lifted');
      await tester.pump(const Duration(seconds: 2));
      expect(_arm(tester).engage.value, 1, reason: 'down again');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a new cover fades in without rebuilding the player', (
      tester,
    ) async {
      motion(tester, reduced: true);
      await tester.pumpWidget(_app(_track(1), playing: true));
      final state = tester.state(find.byType(TurntableCover));
      await tester.pumpWidget(_app(_track(2, albumId: 2), playing: true));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.state(find.byType(TurntableCover)), same(state));
    });

    testWidgets('fits any square without overflowing', (tester) async {
      for (final side in [120.0, 260.0, 520.0]) {
        await tester.pumpWidget(_app(_track(1), playing: true, side: side));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
