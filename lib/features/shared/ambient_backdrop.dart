import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/hires_colors.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/features/now_playing/flowing_light.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart' show isHiRes;
import 'package:nyaplayer/services/library/cover_providers.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// The light behind the whole app while the glass material is on: the
/// container colour with soft lights in the colours of the playing cover (or
/// of the theme when nothing plays), drifting if the flowing-light option is
/// on. Frosted glass blurs this.
class AmbientBackdrop extends ConsumerWidget {
  const AmbientBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final track = ref.watch(queueProvider.select((s) => s.current));
    final animate = ref.watch(
      themeSettingsProvider.select((s) => s.flowingLight),
    );
    final source = track?.cover;
    final cover = source == null
        ? null
        : ref.watch(resolvedCoverProvider(source));
    final palette = cover == null
        ? null
        : ref.watch(coverPaletteProvider(cover.thumbnail)).value;
    final colors = palette != null && palette.isNotEmpty
        ? palette
        : [
            scheme.primary,
            scheme.tertiary,
            scheme.secondary,
            scheme.primaryContainer,
          ];
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surfaceContainer),
        FlowingLight(
          colors: colors,
          seed: track?.id,
          animate: animate,
          strength: 0.85,
          accent: track != null && isHiRes(track)
              ? HiResColors.of(context).gold
              : null,
        ),
      ],
    );
  }
}
