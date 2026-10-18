import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';

/// Whether the "premium glass" material is selected (UI-18).
final glassMaterialProvider = Provider<bool>(
  (ref) => ref.watch(
    themeSettingsProvider.select((s) => s.material == SurfaceMaterial.glass),
  ),
);

/// A surface that is an ordinary opaque Material card in the standard
/// material, and frosted glass in the premium one: translucent, blurring what
/// is behind it, with a faint sheen and a hairline edge.
///
/// Glass only shows its worth over something to blur; the shell paints an
/// `AmbientBackdrop` behind everything while it is selected.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    super.key,
    required this.color,
    required this.borderRadius,
    required this.child,
    this.elevation = 0,
    this.glassOpacity = 0.55,
    this.blur = 28,
  });

  /// The opaque surface colour; in glass it is made translucent.
  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  /// Shadow depth of the opaque card (glass uses a soft fixed shadow when
  /// this is above zero).
  final double elevation;

  /// How much of [color] is left in glass, 0 clear to 1 solid.
  final double glassOpacity;

  /// Blur radius of what is behind the glass.
  final double blur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (!ref.watch(glassMaterialProvider)) {
      return Material(
        color: color,
        elevation: elevation,
        shadowColor: scheme.shadow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glass = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.mirror,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: glassOpacity),
            borderRadius: borderRadius,
            // Light catching the top-left edge of the glass.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceBright.withValues(alpha: dark ? 0.14 : 0.45),
                scheme.surfaceBright.withValues(alpha: 0),
              ],
              stops: const [0, 0.6],
            ),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: dark ? 0.14 : 0.08),
            ),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
    if (elevation <= 0) return glass;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: dark ? 0.35 : 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: glass,
    );
  }
}

/// Makes the Scaffolds and app bars of [child] see-through, for pages that
/// sit on glass or on the ambient backdrop. Everything else about the theme
/// is unchanged.
class SeeThroughPages extends StatelessWidget {
  const SeeThroughPages({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
        ),
      ),
      child: child,
    );
  }
}
