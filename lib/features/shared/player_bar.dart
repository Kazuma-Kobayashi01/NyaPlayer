import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/theme/player_theme.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Player bar that takes the place of the bottom navigation bar (UI-06).
/// Tapping it opens the full player. On phones it floats above the content as
/// a rounded card ([floating]); on wider windows it is docked.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key, this.floating = false});

  final bool floating;

  /// Space a floating bar takes at the bottom (card + margins), excluding the
  /// system inset. Pages add it to their bottom padding so nothing hides
  /// behind the card.
  static const floatingInset = 72.0 + 12 + 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(queueProvider.select((s) => s.current));
    return PlayerThemeScope(
      seed: track?.coverSeed,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final content = track == null
              ? const _IdleBar()
              : _ActiveBar(track: track);
          if (!floating) {
            return Material(
              color: scheme.surfaceContainer,
              child: Stack(
                children: [
                  if (track != null)
                    Positioned.fill(
                      child: _BlurredCover(seed: track.coverSeed),
                    ),
                  SafeArea(top: false, child: content),
                ],
              ),
            );
          }
          return SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Material(
                color: scheme.surfaceContainerHigh,
                elevation: 4,
                shadowColor: scheme.shadow,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: track == null
                    ? content
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: _BlurredCover(seed: track.coverSeed),
                          ),
                          content,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IdleBar extends StatelessWidget {
  const _IdleBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.notPlaying,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.play,
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ActiveBar extends ConsumerWidget {
  const _ActiveBar({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final playing = ref.watch(queueProvider.select((s) => s.playing));
    final queue = ref.read(queueProvider.notifier);
    final roomy = MediaQuery.sizeOf(context).width >= 600;

    return InkWell(
      onTap: () => context.push('/now-playing'),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            const SizedBox(width: 12),
            CoverArt(seed: track.coverSeed, size: 48, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _BarProgress(duration: track.duration),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (roomy)
              IconButton(
                tooltip: l10n.previous,
                icon: const Icon(Icons.skip_previous),
                onPressed: queue.skipPrevious,
              ),
            IconButton.filledTonal(
              tooltip: playing ? l10n.pause : l10n.play,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: queue.togglePlay,
            ),
            IconButton(
              tooltip: l10n.next,
              icon: const Icon(Icons.skip_next),
              onPressed: queue.skipNext,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// The cover stretched over the whole bar and blurred until only its colours
/// remain, under a translucent surface scrim that keeps the text readable.
class _BlurredCover extends StatelessWidget {
  const _BlurredCover({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 40,
                sigmaY: 40,
                tileMode: TileMode.mirror,
              ),
              child: Transform.scale(
                scale: 1.6,
                child: CoverArt(seed: seed, radius: 0),
              ),
            ),
          ),
          ColoredBox(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _BarProgress extends ConsumerWidget {
  const _BarProgress({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = duration.inMilliseconds;
    return LinearProgressIndicator(
      value: total <= 0 ? 0 : (position.inMilliseconds / total).clamp(0.0, 1.0),
      minHeight: 3,
      borderRadius: BorderRadius.circular(2),
      backgroundColor: Theme.of(context).colorScheme.onSurface
          .withValues(alpha: 0.12),
    );
  }
}
