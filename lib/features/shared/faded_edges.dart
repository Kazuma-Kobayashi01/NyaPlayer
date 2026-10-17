import 'package:flutter/material.dart';

/// Fades the top and bottom edges of scrolling content to transparent.
///
/// The fade is a fixed [extent] in logical pixels (not a share of the height),
/// so it looks the same in a short phone pane and a tall desktop one. Content
/// that should be fully visible at the ends of its scroll range needs at
/// least [extent] of padding there; see [fadePadding].
class FadedEdges extends StatelessWidget {
  const FadedEdges({super.key, required this.child, this.extent = fadeExtent});

  static const fadeExtent = 32.0;

  /// Vertical padding that keeps the first and last rows clear of the fade.
  static const fadePadding = EdgeInsets.symmetric(vertical: fadeExtent);

  final Widget child;
  final double extent;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final share = rect.height <= 0
            ? 0.0
            : (extent / rect.height).clamp(0.0, 0.45);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          stops: [0, share, 1 - share, 1],
        ).createShader(rect);
      },
      child: child,
    );
  }
}
