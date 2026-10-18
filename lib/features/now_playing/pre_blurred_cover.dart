import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A cover blurred once and then drawn as a plain bitmap.
///
/// A live full-screen `ImageFilter.blur` (sigma 48) is re-evaluated by the GPU
/// whenever anything above it animates or the page scrolls, which halved the
/// frame rate of the player on Android. Here the blur is applied a single time
/// to a small decode of the cover (cheap, and done off the frame path), and
/// the result is shown stretched with bilinear filtering, which is smooth
/// enough to look the same.
class PreBlurredCover extends StatefulWidget {
  const PreBlurredCover({
    super.key,
    required this.path,
    required this.fallback,
  });

  /// Cover thumbnail file.
  final String path;

  /// Shown until the blur is ready and if the file cannot be decoded.
  final Widget fallback;

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
    final image = _image;
    if (image == null) return widget.fallback;
    return RawImage(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
    );
  }
}
