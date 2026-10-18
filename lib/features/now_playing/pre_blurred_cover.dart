import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A cover blurred once and then drawn as a plain bitmap, with the tint
/// layers on top, all in one painter.
///
/// A live full-screen `ImageFilter.blur` (sigma 48) is re-evaluated by the GPU
/// whenever anything above it animates or the page scrolls, which halved the
/// frame rate of the player on Android. Here the blur is applied a single time
/// to a small decode of the cover (cheap, and done off the frame path), and
/// the result is shown stretched with bilinear filtering, which is smooth
/// enough to look the same.
///
/// The picture is marked complex so the raster cache keeps it as a texture:
/// the backdrop never changes while a song plays, and redrawing the scaled
/// bitmap plus tints every frame was a large part of the GPU cost of
/// scrolling the lyrics on top of it.
class PreBlurredCover extends StatefulWidget {
  const PreBlurredCover({
    super.key,
    required this.path,
    this.overlays = const [],
    this.scale = 1.0,
  });

  /// Cover thumbnail file.
  final String path;

  /// Translucent colours painted over the cover, bottom first. They are also
  /// painted while the blur is not ready, so the tint never pops in.
  final List<Color> overlays;

  /// Enlargement around the centre, to hide the blurred edges.
  final double scale;

  /// Decode width in pixels. Small on purpose: the result is upscaled.
  static const decodeWidth = 160;

  /// Blur radius in decoded pixels. The old live blur was 48 logical pixels
  /// on a phone-sized backdrop, i.e. roughly 7 px of a 160 px decode.
  static const sigma = 7.0;

  @override
  State<PreBlurredCover> createState() => _PreBlurredCoverState();
}

class _PreBlurredCoverState extends State<PreBlurredCover> {
  ui.Image? _image;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PreBlurredCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    ui.Image? blurred;
    try {
      final bytes = await File(widget.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: PreBlurredCover.decodeWidth,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      blurred = await _blur(frame.image);
      frame.image.dispose();
    } on Object {
      blurred = null;
    }
    if (!mounted || generation != _generation) {
      blurred?.dispose();
      return;
    }
    final previous = _image;
    setState(() => _image = blurred);
    // The old bitmap may still be in the frame being built; free it after.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  static Future<ui.Image> _blur(ui.Image source) async {
    final width = source.width;
    final height = source.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: PreBlurredCover.sigma,
          sigmaY: PreBlurredCover.sigma,
          tileMode: TileMode.mirror,
        ),
    );
    canvas.drawImage(source, Offset.zero, Paint());
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      isComplex: true,
      painter: PreBlurredBackdropPainter(
        image: _image,
        scale: widget.scale,
        overlays: widget.overlays,
      ),
    );
  }
}

/// Draws the blurred cover (cover-fitted, enlarged around the centre) and the
/// tint colours over it.
@visibleForTesting
class PreBlurredBackdropPainter extends CustomPainter {
  const PreBlurredBackdropPainter({
    required this.image,
    required this.scale,
    required this.overlays,
  });

  final ui.Image? image;
  final double scale;
  final List<Color> overlays;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final image = this.image;
    if (image != null) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-size.width / 2, -size.height / 2);
      paintImage(
        canvas: canvas,
        rect: rect,
        image: image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
      canvas.restore();
    }
    for (final color in overlays) {
      canvas.drawRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(PreBlurredBackdropPainter old) =>
      old.image != image ||
      old.scale != scale ||
      !listEquals(old.overlays, overlays);
}
