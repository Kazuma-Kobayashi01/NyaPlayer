import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Where everything sits, as fractions of the square the player gives the
/// cover. The record is a little left of and below the middle so the tonearm
/// has the top-right corner to itself.
@immutable
class TurntableGeometry {
  const TurntableGeometry._();

  static const center = Offset(0.45, 0.56);
  static const recordRadius = 0.405;

  /// The black sleeve ring round the record, as in a real sleeve's cut-out.
  static const frameRadius = 0.43;

  /// The cover is the label: a disc in the middle of the record.
  static const labelRadius = 0.265;

  /// The spindle hole, punched through label and record.
  static const holeRadius = 0.034;

  static const pivot = Offset(0.88, 0.10);
  static const armLength = 0.58;

  /// Where the stylus rests on the first and the last groove.
  static const outerGroove = 0.37;
  static const innerGroove = 0.30;

  /// The tonearm swung off the record, in radians (screen angle: 0 points
  /// right, positive turns clockwise).
  static const restAngle = 74 * math.pi / 180;

  /// The arm's angle with the stylus [progress] (0–1) of the way through the
  /// record: it creeps from the outer groove to the inner one.
  static double playAngle(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final r = outerGroove + (innerGroove - outerGroove) * p;
    final toCentre = center - pivot;
    final d = toCentre.distance;
    // Triangle pivot–centre–stylus with sides d, armLength and r.
    final cosA = (armLength * armLength + d * d - r * r) / (2 * armLength * d);
    final alpha = math.acos(cosA.clamp(-1.0, 1.0));
    return math.atan2(toCentre.dy, toCentre.dx) - alpha;
  }

  /// [engaged] is 0 with the arm resting and 1 with the stylus down.
  static double angle(double progress, double engaged) {
    final t = Curves.easeInOut.transform(engaged.clamp(0.0, 1.0));
    return restAngle + (playAngle(progress) - restAngle) * t;
  }

  /// The tip of the arm for [angle].
  static Offset stylus(double angle) =>
      pivot + Offset(math.cos(angle), math.sin(angle)) * armLength;
}

/// The cover on a record player: a black record with the cover as its label,
/// a hole through the middle, and a tonearm that lowers when music plays,
/// creeps inward as the song goes on and lifts when it stops. The record
/// turns while playing and slows to a halt when paused.
///
/// Fills the square it is given. Stands still (arm and record jump to their
/// places) when the system asks for reduced motion.
class TurntableCover extends StatefulWidget {
  const TurntableCover({super.key, required this.track, required this.playing});

  final Track track;
  final bool playing;

  @override
  State<TurntableCover> createState() => _TurntableCoverState();
}

class _TurntableCoverState extends State<TurntableCover>
    with TickerProviderStateMixin {
  /// A turn in 4.5 seconds: lively, but slow enough to read the cover.
  static const _turnsPerSecond = 1 / 4.5;

  /// Starts at the current value, so it can be handed over to a slowing-down
  /// simulation without a jump.
  late final AnimationController _spin = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _engage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    reverseDuration: const Duration(milliseconds: 650),
  );

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow(animated: false);
  }

  @override
  void didUpdateWidget(TurntableCover old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) {
      _follow(animated: true);
    } else if (widget.playing && old.track.id != widget.track.id) {
      unawaited(_changeRecord());
    }
  }

  /// Brings the record and the arm to what [TurntableCover.playing] says.
  void _follow({required bool animated}) {
    if (_reducedMotion) {
      _spin.stop();
      _engage.value = widget.playing ? 1 : 0;
      return;
    }
    if (widget.playing) {
      if (_spin.velocity == 0 || !_spin.isAnimating) {
        _spin.animateWith(_Constant(_spin.value, _turnsPerSecond));
      }
      if (animated) {
        unawaited(_engage.forward());
      } else {
        _engage.value = 1;
      }
    } else {
      if (_spin.isAnimating) {
        // The record keeps turning for a moment, like a real one.
        _spin.animateWith(
          FrictionSimulation(0.03, _spin.value, _turnsPerSecond),
        );
      }
      if (animated) {
        unawaited(_engage.reverse());
      } else {
        _engage.value = 0;
      }
    }
  }

  /// A new song: the arm lifts, the label changes and the arm comes down.
  Future<void> _changeRecord() async {
    if (_reducedMotion) return;
    await _engage.animateBack(0, duration: const Duration(milliseconds: 280));
    if (mounted && widget.playing) await _engage.forward();
  }

  @override
  void dispose() {
    _spin.dispose();
    _engage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final label = TurntableGeometry.labelRadius * side;
        final centre = TurntableGeometry.center * side;
        return SizedBox.square(
          dimension: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The soft shadow of the record, with the hole in it.
              Positioned.fill(
                child: CustomPaint(painter: _ShadowPainter(scheme.shadow)),
              ),
              Positioned.fill(child: CustomPaint(painter: _FramePainter())),
              Positioned.fill(
                child: ClipPath(
                  clipper: const TurntableHoleClipper(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RecordPainter()),
                      ),
                      Positioned(
                        left: centre.dx - label,
                        top: centre.dy - label,
                        width: label * 2,
                        height: label * 2,
                        child: RotationTransition(
                          turns: _spin,
                          child: AnimatedSwitcher(
                            duration: Durations.long2,
                            child: CoverArt(
                              key: ValueKey(widget.track.albumId),
                              seed: widget.track.coverSeed,
                              source: widget.track.cover,
                              highResolution: true,
                              radius: 10000,
                            ),
                          ),
                        ),
                      ),
                      // Light on the vinyl does not turn with the record.
                      Positioned.fill(
                        child: CustomPaint(painter: _SheenPainter()),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: _Tonearm(
                  engage: _engage,
                  duration: widget.track.duration,
                  scheme: scheme,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Speed that never changes: a record at its set speed.
class _Constant extends Simulation {
  _Constant(this._start, this._velocity);

  final double _start;
  final double _velocity;

  @override
  double x(double time) => _start + _velocity * time;

  @override
  double dx(double time) => _velocity;

  @override
  bool isDone(double time) => false;
}

/// Cuts the spindle hole out of everything it clips, so the background shows
/// through the middle of the label and the record.
class TurntableHoleClipper extends CustomClipper<Path> {
  const TurntableHoleClipper();

  /// The record with its hole, for a square of side [side].
  static Path pathFor(double side) {
    final centre = TurntableGeometry.center * side;
    return Path.combine(
      PathOperation.difference,
      Path()..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.recordRadius * side,
        ),
      ),
      Path()..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.holeRadius * side,
        ),
      ),
    );
  }

  @override
  Path getClip(Size size) => pathFor(size.shortestSide);

  @override
  bool shouldReclip(TurntableHoleClipper oldClipper) => false;
}

/// A vinyl record is black and its highlights are white: this is a picture of
/// an object, not a UI colour, so it does not come from the colour scheme.
const _vinyl = Color(0xFF0B0B0D);
const _highlight = Color(0xFFFFFFFF);

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter(this.shadow);

  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centre = TurntableGeometry.center * s;
    // The hole goes right through: no shadow falls into it, so the
    // background shows there as it does beyond the rim.
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(-s, -s, s * 3, s * 3)),
        Path()..addOval(
          Rect.fromCircle(
            center: centre,
            radius: TurntableGeometry.holeRadius * s,
          ),
        ),
      ),
    );
    canvas.drawShadow(
      Path()..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.frameRadius * s,
        ),
      ),
      shadow,
      10,
      false,
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.shadow != shadow;
}

/// The black ring of the sleeve behind the record, with the spindle hole
/// cut through it too.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centre = TurntableGeometry.center * s;
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.frameRadius * s,
        ),
      ),
      Path()..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.holeRadius * s,
        ),
      ),
    );
    canvas.drawPath(ring, Paint()..color = _vinyl);
    // A faint sheen on the edge of the sleeve, so it reads as a solid ring.
    canvas.drawCircle(
      centre,
      TurntableGeometry.frameRadius * s - 0.004 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s / 300)
        ..color = _highlight.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}

class _RecordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centre = TurntableGeometry.center * s;
    final radius = TurntableGeometry.recordRadius * s;
    final label = TurntableGeometry.labelRadius * s;
    final disc = Rect.fromCircle(center: centre, radius: radius);

    // Body: black, a touch lighter towards the middle.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(_vinyl, _highlight, 0.10)!,
            _vinyl,
            Color.lerp(_vinyl, _highlight, 0.04)!,
          ],
          stops: const [0, 0.7, 1],
        ).createShader(disc),
    );

    // Grooves: fine rings whose brightness wanders, with a few smooth bands
    // between the tracks.
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, s / 520);
    final first = TurntableGeometry.labelRadius + 0.018;
    final last = TurntableGeometry.recordRadius - 0.016;
    var i = 0;
    for (var r = first; r < last; r += 0.0052, i++) {
      final wander = 0.5 + 0.5 * math.sin(i * 1.9) * math.cos(i * 0.47);
      final band = (r - first) / (last - first);
      final gap = (band - 0.33).abs() < 0.012 || (band - 0.68).abs() < 0.012;
      groove.color = _highlight.withValues(
        alpha: gap ? 0.0 : 0.035 + 0.05 * wander,
      );
      canvas.drawCircle(centre, r * s, groove);
    }

    // The dark ring round the label and the polished rim.
    canvas.drawCircle(centre, label + 0.006 * s, Paint()..color = _vinyl);
    canvas.drawCircle(
      centre,
      radius - s * 0.004,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s / 300)
        ..color = _highlight.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(_RecordPainter old) => false;
}

/// Two soft wedges of light across the grooves, fixed in place.
class _SheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centre = TurntableGeometry.center * s;
    final radius = TurntableGeometry.recordRadius * s;
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: centre, radius: radius))
      ..addOval(
        Rect.fromCircle(
          center: centre,
          radius: TurntableGeometry.labelRadius * s + 0.006 * s,
        ),
      );
    final clear = _highlight.withValues(alpha: 0);
    final wedge = _highlight.withValues(alpha: 0.2);
    canvas.drawPath(
      ring,
      Paint()
        ..shader = SweepGradient(
          center: Alignment(
            TurntableGeometry.center.dx * 2 - 1,
            TurntableGeometry.center.dy * 2 - 1,
          ),
          colors: [clear, clear, wedge, clear, clear, wedge, clear, clear],
          stops: const [0, 0.043, 0.083, 0.123, 0.543, 0.583, 0.623, 1],
        ).createShader(Offset.zero & size),
    );
    // The thickness of the label seen at the edge of the hole.
    canvas.drawCircle(
      centre,
      TurntableGeometry.holeRadius * s + 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s / 300)
        ..color = _vinyl.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => false;
}

/// The tonearm. Watches the playback position itself so that only the arm
/// repaints as the song goes on.
class _Tonearm extends ConsumerWidget {
  const _Tonearm({
    required this.engage,
    required this.duration,
    required this.scheme,
  });

  final Animation<double> engage;
  final Duration duration;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = duration.inMilliseconds;
    final progress = total <= 0 ? 0.0 : position.inMilliseconds / total;
    return CustomPaint(
      painter: TonearmPainter(
        engage: engage,
        progress: progress.clamp(0.0, 1.0),
        scheme: scheme,
      ),
    );
  }
}

class TonearmPainter extends CustomPainter {
  TonearmPainter({
    required this.engage,
    required this.progress,
    required this.scheme,
  }) : super(repaint: engage);

  final Animation<double> engage;
  final double progress;
  final ColorScheme scheme;

  /// The angle the arm is drawn at right now.
  double get angle => TurntableGeometry.angle(progress, engage.value);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final lowered = Curves.easeInOut.transform(engage.value);
    final theta = angle;
    final dir = Offset(math.cos(theta), math.sin(theta));
    final pivot = TurntableGeometry.pivot * s;
    final tip = pivot + dir * (TurntableGeometry.armLength * s);
    final neck = pivot + dir * (TurntableGeometry.armLength * s * 0.86);
    final back = pivot - dir * (0.105 * s);

    final metal = scheme.outline;
    final shine = scheme.outlineVariant;
    final dark = scheme.inverseSurface;

    // Shadow of the arm on the record: close and sharp with the stylus down,
    // far and soft with the arm lifted.
    final lift = (1 - lowered);
    final shadowShift = const Offset(0.010, 0.014) * s * (1 + 2.2 * lift);
    canvas.drawLine(
      pivot + shadowShift,
      tip + shadowShift,
      Paint()
        ..color = scheme.shadow.withValues(alpha: 0.32 - 0.12 * lift)
        ..strokeWidth = 0.018 * s
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          s * (0.006 + 0.01 * lift),
        ),
    );

    // Counterweight behind the pivot.
    canvas.drawLine(
      pivot,
      back,
      Paint()
        ..color = metal
        ..strokeWidth = 0.024 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pivot - dir * (0.055 * s),
      back,
      Paint()
        ..color = dark
        ..strokeWidth = 0.036 * s
        ..strokeCap = StrokeCap.butt,
    );

    // The shaft, with a light line along it.
    canvas.drawLine(
      pivot,
      neck,
      Paint()
        ..color = metal
        ..strokeWidth = 0.016 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pivot + Offset(-dir.dy, dir.dx) * (-0.003 * s),
      neck + Offset(-dir.dy, dir.dx) * (-0.003 * s),
      Paint()
        ..color = shine
        ..strokeWidth = 0.005 * s
        ..strokeCap = StrokeCap.round,
    );

    // Headshell and stylus.
    canvas.save();
    canvas.translate(neck.dx, neck.dy);
    canvas.rotate(theta);
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -0.004 * s,
        -0.021 * s,
        (TurntableGeometry.armLength * 0.14) * s,
        0.042 * s,
      ),
      Radius.circular(0.008 * s),
    );
    canvas.drawRRect(head, Paint()..color = dark);
    canvas.drawRRect(
      head.deflate(0.004 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.003 * s
        ..color = shine.withValues(alpha: 0.7),
    );
    canvas.restore();
    canvas.drawCircle(tip, 0.006 * s, Paint()..color = scheme.primary);

    // The pivot: a dark collar with a bright cap.
    canvas.drawCircle(pivot, 0.05 * s, Paint()..color = dark);
    canvas.drawCircle(
      pivot,
      0.034 * s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [shine, metal],
        ).createShader(Rect.fromCircle(center: pivot, radius: 0.034 * s)),
    );
  }

  @override
  bool shouldRepaint(TonearmPainter old) =>
      old.progress != progress || old.scheme != scheme;
}
