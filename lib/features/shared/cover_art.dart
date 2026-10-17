import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';

/// Generated Material placeholder cover (META-04). Real embedded artwork
/// replaces this once the cover cache exists (M2).
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.seed,
    this.size,
    this.radius = 12,
    this.heroTag,
    this.icon = Icons.music_note,
  });

  final int seed;

  /// Square edge length; fills the parent's bounds when null.
  final double? size;
  final double radius;
  final Object? heroTag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = schemeFromSeed(seed, Theme.of(context).brightness);
    Widget art = LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.biggest.shortestSide;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primaryContainer, scheme.tertiaryContainer],
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: edge.isFinite ? math.max(16, edge * 0.42) : 48,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        );
      },
    );
    art = ClipRRect(borderRadius: BorderRadius.circular(radius), child: art);
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    if (size != null) art = SizedBox.square(dimension: size, child: art);
    return ExcludeSemantics(child: art);
  }
}
