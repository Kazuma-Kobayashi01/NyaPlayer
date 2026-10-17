import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Title, artist, favourite toggle and a tappable format chip.
class TrackHeader extends ConsumerWidget {
  const TrackHeader({
    super.key,
    required this.track,
    this.showQuality = true,
    this.showFavorite = true,
  });

  final Track track;
  final bool showQuality;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showQuality) ...[
                const SizedBox(height: 8),
                QualityBadge(track: track),
              ],
            ],
          ),
        ),
        if (showFavorite) FavoriteButton(track: track),
      ],
    );
  }
}

/// Heart toggle for a track; used in the top row of every player layout.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFavorite = ref.watch(
      favoritesProvider.select((f) => f.contains(track.id)),
    );
    return IconButton(
      tooltip: isFavorite ? l10n.unfavorite : l10n.favorite,
      isSelected: isFavorite,
      icon: const Icon(Icons.favorite_outline),
      selectedIcon: const Icon(Icons.favorite),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(track),
    );
  }
}

class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, required this.duration, this.inline = false});

  final Duration duration;

  /// Times on both sides of the slider in one row, instead of below it.
  final bool inline;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final maxMs = widget.duration.inMilliseconds.toDouble();
    final max = maxMs <= 0 ? 1.0 : maxMs;
    final value = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(
      0.0,
      max,
    );
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final elapsed = Text(
      formatDuration(Duration(milliseconds: value.round())),
      style: labelStyle,
    );
    final total = Text(formatDuration(widget.duration), style: labelStyle);
    final slider = Slider(
      value: value,
      max: max,
      onChanged: (v) => setState(() => _dragValue = v),
      onChangeEnd: (v) {
        ref
            .read(queueProvider.notifier)
            .seek(Duration(milliseconds: v.round()));
        setState(() => _dragValue = null);
      },
    );

    if (widget.inline) {
      return Row(
        children: [
          SizedBox(
            width: 48,
            child: Align(alignment: Alignment.centerRight, child: elapsed),
          ),
          Expanded(child: slider),
          SizedBox(width: 48, child: total),
        ],
      );
    }
    return Column(
      children: [
        slider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [elapsed, total],
          ),
        ),
      ],
    );
  }
}

class TransportControls extends ConsumerWidget {
  const TransportControls({
    super.key,
    this.large = true,
    this.showModes = true,
    this.tonalSkip = true,
    this.spacing,
  });

  final bool large;

  /// Gap between buttons. When set the buttons sit together in the centre;
  /// when null they are spread evenly across the available width.
  final double? spacing;

  /// Shuffle and repeat on either side of the transport buttons.
  final bool showModes;

  /// Tonal circles behind previous/next; plain icons when false.
  final bool tonalSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(queueProvider);
    final queue = ref.read(queueProvider.notifier);
    final skipSize = large ? 48.0 : 42.0;

    Widget skip(IconData icon, String tooltip, VoidCallback onPressed) {
      final style = IconButton.styleFrom(minimumSize: Size.square(skipSize));
      return tonalSkip
          ? IconButton.filledTonal(
              iconSize: 24,
              style: style,
              tooltip: tooltip,
              icon: Icon(icon),
              onPressed: onPressed,
            )
          : IconButton(
              iconSize: 30,
              style: style,
              tooltip: tooltip,
              icon: Icon(icon),
              onPressed: onPressed,
            );
    }

    return Row(
      mainAxisSize: spacing == null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: spacing == null
          ? MainAxisAlignment.spaceEvenly
          : MainAxisAlignment.center,
      spacing: spacing ?? 0,
      children: [
        if (showModes) ShuffleButton(state: state),
        skip(Icons.skip_previous, l10n.previous, queue.skipPrevious),
        _PlayPauseButton(
          playing: state.playing,
          large: large,
          tooltip: state.playing ? l10n.pause : l10n.play,
          onPressed: queue.togglePlay,
        ),
        skip(Icons.skip_next, l10n.next, queue.skipNext),
        if (showModes) RepeatButton(state: state),
      ],
    );
  }
}

class ShuffleButton extends ConsumerWidget {
  const ShuffleButton({super.key, required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      iconSize: 22,
      isSelected: state.shuffle,
      tooltip: state.shuffle ? l10n.shuffleOn : l10n.shuffleOff,
      icon: const Icon(Icons.shuffle),
      selectedIcon: const Icon(Icons.shuffle_on),
      onPressed: ref.read(queueProvider.notifier).toggleShuffle,
    );
  }
}

class RepeatButton extends ConsumerWidget {
  const RepeatButton({super.key, required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (icon, tip) = switch (state.loopMode) {
      LoopMode.none => (Icons.repeat, l10n.repeatOff),
      LoopMode.all => (Icons.repeat_on, l10n.repeatAll),
      LoopMode.one => (Icons.repeat_one_on, l10n.repeatOne),
    };
    return IconButton(
      iconSize: 22,
      isSelected: state.loopMode != LoopMode.none,
      tooltip: tip,
      icon: Icon(icon),
      onPressed: ref.read(queueProvider.notifier).cycleLoopMode,
    );
  }
}

/// Wide filled play button whose corners morph between a pill (paused) and a
/// rounded square (playing), in the spirit of Material 3 Expressive.
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.large,
    required this.tooltip,
    required this.onPressed,
  });

  final bool playing;
  final bool large;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final width = large ? 84.0 : 68.0;
    final height = large ? 62.0 : 50.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: playing ? height * 0.3 : height / 2),
      duration: Durations.medium2,
      curve: Easing.emphasizedDecelerate,
      builder: (context, radius, child) => SizedBox(
        width: width,
        height: height,
        child: Tooltip(
          message: tooltip,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: child,
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: Durations.short4,
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          key: ValueKey(playing),
          size: large ? 32 : 26,
        ),
      ),
    );
  }
}
