import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/features/library/playlists_page.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// One playlist: play it, reorder and remove its songs (LIB-13).
///
/// Tapping a song queues *this playlist*, even if the song also lives in the
/// library or in other playlists.
class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final playlist = ref
        .watch(playlistsProvider)
        .value
        ?.where((p) => p.id == playlistId)
        .firstOrNull;
    final tracks =
        ref.watch(playlistTracksProvider(playlistId)).value ?? const [];
    final queue = ref.read(queueProvider.notifier);
    final repo = ref.read(playlistRepositoryProvider);

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.queue_music_outlined,
          title: l10n.loadFailed,
        ),
      );
    }

    final total = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          PlaylistMenuButton(
            playlist: playlist,
            onDeleted: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
      ),
      body: tracks.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_outlined,
              title: l10n.playlistEmpty,
              body: l10n.playlistEmptyBody,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.playlistTracks(tracks.length)} · ${formatDuration(total)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      PlayButtonsRow(tracks: tracks),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: tracks.length,
                    onReorderItem: (from, to) =>
                        repo.move(playlistId, from, to),
                    itemBuilder: (context, i) {
                      final track = tracks[i];
                      return TrackTile(
                        // Songs may repeat, so the position is part of the key.
                        key: ValueKey('$i:${track.id}'),
                        track: track,
                        onTap: () => queue.playTracks(tracks, startIndex: i),
                        menuExtras: [
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.playlist_remove),
                            onPressed: () => repo.removeAt(playlistId, i),
                            child: Text(l10n.removeFromPlaylist),
                          ),
                        ],
                        endAdornment: ReorderableDragStartListener(
                          index: i,
                          child: Tooltip(
                            message: l10n.reorder,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
