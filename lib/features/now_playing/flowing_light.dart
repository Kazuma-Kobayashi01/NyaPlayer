import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Four colours that stand for a cover, one per quadrant, made vivid enough
/// to glow (see [extractCoverPalette]). The thumbnail is read once per file.
final coverPaletteProvider = FutureProvider.family<List<Color>, String>(
  (ref, thumbnailPath) => extractCoverPalette(thumbnailPath),
);

/// Shrinks the image at [path] to 4×4 pixels and averages each quadrant, then
/// lifts saturation and keeps lightness in a band where a soft light on a
/// dark or light surface still reads. Empty when the file cannot be decoded.
Future<List<Color>> extractCoverPalette(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 4,
      targetHeight: 4,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    frame.image.dispose();
    codec.dispose();
    if (data == null || data.lengthInBytes < 4 * 4 * 4) return const [];

    Color pixel(int x, int y) {
      final i = (y * 4 + x) * 4;
      return Color.fromARGB(
        255,
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
    }

    final palette = <Color>[];
    for (final (qx, qy) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      var r = 0, g = 0, b = 0;
      for (var dy = 0; dy < 2; dy++) {
        for (var dx = 0; dx < 2; dx++) {
          final c = pixel(qx * 2 + dx, qy * 2 + dy);
          r += (c.r * 255).round();
          g += (c.g * 255).round();
          b += (c.b * 255).round();
        }
      }
      palette.add(vividLight(Color.fromARGB(255, r ~/ 4, g ~/ 4, b ~/ 4)));
    }
    return palette;
  } catch (_) {
    return const [];
  }
}

/// A colour turned into one that glows: grey stays grey (a monochrome cover
/// should give a monochrome light) while anything with a hue gets a minimum
/// saturation, and lightness is held mid-range.
Color vividLight(Color color) {
  final hsl = HSLColor.fromColor(color);
  final saturation = hsl.saturation < 0.1
      ? hsl.saturation
      : math.max(hsl.saturation, 0.45);
  return hsl
      .withSaturation(saturation.clamp(0.0, 1.0))
      .withLightness(hsl.lightness.clamp(0.36, 0.64))
      .toColor();
}

/// Soft coloured lights drifting slowly over a surface, like light through
/// moving water. Each blob is a radial gradient (so no blur has to be
/// computed per frame) travelling on its own closed path; the paths use
/// whole numbers of laps so the motion loops without a seam. Passing new
/// [colors] fades from the old ones.
///
/// Stands still when [animate] is false or the system asks for reduced
/// motion.
class FlowingLight extends StatefulWidget {
  const FlowingLight({
    super.key,
    required this.colors,
    this.accent,
    this.animate = true,
    this.strength = 1,
  });

  /// One to four colours; blobs take them in turn.
  final List<Color> colors;

  /// An extra, slower light (the gold of a Hi-Res track).
  final Color? accent;
  final bool animate;

  /// Scales the opacity of every light.
  final double strength;

  @override
  State<FlowingLight> createState() => _FlowingLightState();
}

class _FlowingLightState extends State<FlowingLight>
    with TickerProviderStateMixin {
  /// One full lap of the slowest light; the others do 2–3 laps in this time.
  static const _lap = Duration(seconds: 48);

  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: _lap,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: Durations.long4,
    value: 1,
  );
  late List<Color> _from = widget.colors;
  late List<Color> _to = widget.colors;

  @override
  void initState() {
    super.initState();
    // Start somewhere other than the origin so the first frame is already
    // spread out.
    _flow.value = 0.31;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FlowingLight old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.colors, widget.colors)) {
      _from = _blend();
      _to = widget.colors;
      _fade.forward(from: 0);
    }
    _sync();
  }

  void _sync() {
    final moving = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (moving && !_flow.isAnimating) {
      _flow.repeat();
    } else if (!moving && _flow.isAnimating) {
      _flow.stop();
    }
  }

  List<Color> _blend() {
    final n = math.max(_from.length, _to.length);
    return [
      for (var i = 0; i < n; i++)
        Color.lerp(
          _from[i % _from.length],
          _to[i % _to.length],
          Curves.easeInOut.transform(_fade.value),
        )!,
    ];
  }

  @override
  void dispose() {
    _flow.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.colors.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _FlowPainter(
              flow: _flow,
              fade: _fade,
              from: _from,
              to: _to,
              accent: widget.accent,
              alpha: (dark ? 0.46 : 0.40) * widget.strength,
            ),
          ),
        ),
      ),
    );
  }
}

/// (laps in x, laps in y, phase, radius as a share of the long side, weight).
/// Whole laps keep the loop seamless.
const _paths = <(int, int, double, double, double)>[
  (1, 2, 0.00, 0.62, 1.0),
  (2, 1, 0.27, 0.55, 0.9),
  (1, 3, 0.55, 0.50, 0.8),
  (3, 2, 0.81, 0.58, 0.9),
];

class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.flow,
    required this.fade,
    required this.from,
    required this.to,
    required this.accent,
    required this.alpha,
  }) : super(repaint: Listenable.merge([flow, fade]));

  final Animation<double> flow;
  final Animation<double> fade;
  final List<Color> from;
  final List<Color> to;
  final Color? accent;
  final double alpha;

  Color _color(int i) {
    if (from.isEmpty || to.isEmpty) return const Color(0x00000000);
    return Color.lerp(
      from[i % from.length],
      to[i % to.length],
      Curves.easeInOut.transform(fade.value),
    )!;
  }

  void _blob(
    Canvas canvas,
    Size size,
    Color color,
    double x,
    double y,
    double radius,
    double a,
  ) {
    final centre = Offset(x * size.width, y * size.height);
    final rect = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: a * 0.45),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = flow.value;
    final long = size.longestSide;
    for (var i = 0; i < _paths.length; i++) {
      final (kx, ky, phase, radius, weight) = _paths[i];
      final x = 0.5 + 0.42 * math.sin(2 * math.pi * (kx * t + phase));
      final y = 0.5 + 0.42 * math.cos(2 * math.pi * (ky * t + phase));
      _blob(canvas, size, _color(i), x, y, long * radius, alpha * weight);
    }
    final gold = accent;
    if (gold != null) {
      // One lap, on a wide ellipse: slower than everything else.
      final x = 0.5 + 0.38 * math.cos(2 * math.pi * (t + 0.15));
      final y = 0.5 + 0.30 * math.sin(2 * math.pi * (t + 0.15));
      _blob(canvas, size, gold, x, y, long * 0.42, alpha * 0.4);
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.from != from ||
      old.to != to ||
      old.accent != accent ||
      old.alpha != alpha;
}
