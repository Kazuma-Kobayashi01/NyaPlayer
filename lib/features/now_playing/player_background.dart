import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';

/// Shared by the compact, expanded and persistent players. Only the backdrop
/// repaints for artwork changes; playback controls stay outside the blur layer.
class PlayerBackground extends ConsumerWidget {
  const PlayerBackground({super.key, required this.track, required this.child});

  final Track? track;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = ref.watch(
      themeSettingsProvider.select((s) => s.playerBackground),
    );
    final source = track?.cover;
    final cover = style == PlayerBackgroundStyle.blurredCover && source != null
        ? ref.watch(resolvedCoverProvider(source))
        : null;
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
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 48,
                                  sigmaY: 48,
                                  tileMode: TileMode.mirror,
                                ),
                                child: Transform.scale(
                                  scale: 1.3,
                                  child: Image.file(
                                    File(cover.thumbnail),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 256,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, _, _) => gradient,
                                  ),
                                ),
                              ),
                              ColoredBox(
                                color: scheme.surface.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.48
                                      : 0.50,
                                ),
                              ),
                              if (theme.brightness == Brightness.dark)
                                ColoredBox(
                                  color: scheme.scrim.withValues(alpha: 0.10),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
