import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';

/// Shared by the player bar's thumbnail and the full player's square cover so
/// the cover flies between them when the player opens and closes (UI-11).
const nowPlayingCoverHeroTag = 'now-playing-cover';

/// Cached embedded artwork, with a Material placeholder while absent/loading.
class CoverArt extends ConsumerWidget {
  const CoverArt({
    super.key,
    required this.seed,
    this.size,
    this.radius = 12,
    this.heroTag,
    this.icon = Icons.music_note,
    this.source,
    this.highResolution = false,
  });

  final int seed;

  /// Square edge length; fills the parent's bounds when null.
  final double? size;
  final double radius;
  final Object? heroTag;
  final IconData icon;
  final CoverSource? source;
  final bool highResolution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = this.source;
    final cover = source == null
        ? null
        : ref.watch(resolvedCoverProvider(source));
    final scheme = schemeFromSeed(seed, Theme.of(context).brightness);
    Widget art = LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.biggest.shortestSide;
        final placeholder = DecoratedBox(
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
        if (cover == null) return placeholder;
        final limit = highResolution ? 1024 : 256;
        return Image.file(
          File(highResolution ? cover.large : cover.thumbnail),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          // Files are already bounded at these two sizes. A pixel-dependent
          // decode key discards the displayed image on every resize frame.
          cacheWidth: limit,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => placeholder,
        );
      },
    );
    art = ClipRRect(borderRadius: BorderRadius.circular(radius), child: art);
    if (heroTag != null) {
      art = Hero(
        tag: heroTag!,
        flightShuttleBuilder: _coverShuttle,
        child: art,
      );
    }
    if (size != null) art = SizedBox.square(dimension: size, child: art);
    return ExcludeSemantics(child: art);
  }
}

/// The flying cover keeps the destination's picture but rounds its corners
/// from one end's radius to the other's, instead of jumping to the final one.
Widget _coverShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  ClipRRect clipOf(BuildContext c) => (c.widget as Hero).child as ClipRRect;
  final from = clipOf(fromHeroContext);
  final to = clipOf(toHeroContext);
  // The animation is the route's: it runs 0 -> 1 on push and 1 -> 0 on pop,
  // 1 being the open player. So the open player's radius is the "end".
  final pushing = direction == HeroFlightDirection.push;
  final closed = (pushing ? from : to).borderRadius;
  final open = (pushing ? to : from).borderRadius;
  return AnimatedBuilder(
    animation: animation,
    builder: (_, child) => ClipRRect(
      borderRadius:
          BorderRadiusGeometry.lerp(closed, open, animation.value) ??
          to.borderRadius,
      child: child,
    ),
    child: to.child,
  );
}
