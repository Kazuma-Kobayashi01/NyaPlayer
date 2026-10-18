import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/hires_colors.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/features/now_playing/flowing_light.dart';
import 'package:nyaplayer/features/now_playing/pre_blurred_cover.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart' show isHiRes;
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';

/// Shared by the compact, expanded and persistent players. Only the backdrop
/// repaints for artwork changes; playback controls stay outside the blur layer.
class PlayerBackground extends ConsumerWidget {
  const PlayerBackground({
    super.key,
    required this.track,
    required this.child,
    this.translucent = false,
  });

  final Track? track;
  final Widget child;

  /// Lets what is behind the player (the glass material's ambient light)
  /// shine through the backdrop.
  final bool translucent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = ref.watch(
      themeSettingsProvider.select((s) => s.playerBackground),
    );
    final flowing = ref.watch(
      themeSettingsProvider.select((s) => s.flowingLight),
    );
    final source = track?.cover;
    final cover = style == PlayerBackgroundStyle.blurredCover && source != null
        ? ref.watch(resolvedCoverProvider(source))
        : null;
    // The light takes its colours from the cover when the cover is the
    // backdrop, and from the theme otherwise.
    final palette = cover == null
        ? null
        : ref.watch(coverPaletteProvider(cover.thumbnail)).value;
    final lightColors = palette != null && palette.isNotEmpty
        ? palette
        : [
            scheme.primary,
            scheme.tertiary,
            scheme.secondary,
            scheme.primaryContainer,
          ];
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primaryContainer.withValues(alpha: 0.55),
              scheme.surface,
            ),
            scheme.surface,
            Color.alphaBlend(
              scheme.tertiaryContainer.withValues(alpha: 0.35),
              scheme.surface,
            ),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: translucent ? 0.6 : 1,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: Durations.long4,
                      child: cover == null
                          ? KeyedSubtree(
                              key: const ValueKey('gradient'),
                              child: gradient,
                            )
                          : Stack(
                              key: ValueKey(cover.thumbnail),
                              fit: StackFit.expand,
                              children: [
                                gradient,
                                PreBlurredCover(
                                  path: cover.thumbnail,
                                  scale: 1.3,
                                  overlays: [
                                    scheme.surface.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.48
                                          : 0.50,
                                    ),
                                    if (theme.brightness == Brightness.dark)
                                      scheme.scrim.withValues(alpha: 0.10),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (flowing)
          Positioned.fill(
            child: FlowingLight(
              colors: lightColors,
              seed: track?.id,
              accent: track != null && isHiRes(track!)
                  ? HiResColors.of(context).gold
                  : null,
            ),
          ),
        child,
      ],
    );
  }
}
