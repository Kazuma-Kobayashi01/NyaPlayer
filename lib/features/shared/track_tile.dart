import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/song_info_sheet.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.leadingNumber,
  });

  final Track track;
  final VoidCallback onTap;

  /// Shows the track number instead of the cover (album detail pages).
  final int? leadingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCurrent = ref.watch(
      queueProvider.select((s) => s.current?.id == track.id),
    );
    final isFavorite = ref.watch(
      favoritesProvider.select((f) => f.contains(track.id)),
    );
    final Widget leading;
    if (leadingNumber != null) {
      leading = SizedBox(
        width: 40,
        child: Center(
          child: isCurrent
              ? Icon(Icons.graphic_eq, color: theme.colorScheme.primary)
              : Text(
                  '$leadingNumber',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      );
    } else {
      leading = CoverArt(seed: track.coverSeed, size: 48, radius: 8);
    }

    return ListTile(
      selected: isCurrent,
      selectedTileColor: theme.colorScheme.secondaryContainer.withValues(
        alpha: 0.5,
      ),
      onTap: onTap,
      leading: leading,
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        leadingNumber != null
            ? track.artist
            : '${track.artist} · ${track.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.favorite,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          Text(
            formatDuration(track.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TrackMenuButton(track: track),
        ],
      ),
    );
  }
}

class TrackMenuButton extends ConsumerWidget {
  const TrackMenuButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final queue = ref.read(queueProvider.notifier);
    final isFavorite = ref.watch(
      favoritesProvider.select((f) => f.contains(track.id)),
    );
    void snack(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.playlist_play),
          onPressed: () {
            queue.playNext(track);
            snack(l10n.willPlayNext);
          },
          child: Text(l10n.playNext),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.playlist_add),
          onPressed: () {
            queue.addToQueue(track);
            snack(l10n.addedToQueue);
          },
          child: Text(l10n.addToQueue),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
          ),
          onPressed: () => ref.read(favoritesProvider.notifier).toggle(track),
          child: Text(isFavorite ? l10n.unfavorite : l10n.favorite),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.info_outline),
          onPressed: () => showSongInfo(context, track),
          child: Text(l10n.songInfo),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: l10n.moreOptions,
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// "Play all" + "Shuffle" buttons shown above track lists.
class PlayButtonsRow extends ConsumerWidget {
  const PlayButtonsRow({super.key, required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.read(queueProvider.notifier);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: tracks.isEmpty ? null : () => queue.playTracks(tracks),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.playAll),
        ),

        FilledButton.tonalIcon(
          onPressed: tracks.isEmpty ? null : () => queue.shufflePlay(tracks),
          icon: const Icon(Icons.shuffle),
          label: Text(l10n.shufflePlay),
        ),
      ],
    );
  }
}
