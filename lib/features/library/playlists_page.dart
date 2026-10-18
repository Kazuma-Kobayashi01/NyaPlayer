import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/playlists/playlist_dialogs.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// User playlists (LIB-13).
class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await promptPlaylistName(
      context,
      title: l10n.newPlaylist,
      confirmLabel: l10n.create,
    );
    if (name == null) return;
    await ref.read(playlistRepositoryProvider).create(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    final createButton = FilledButton.icon(
      onPressed: () => _create(context, ref),
      icon: const Icon(Icons.add),
      label: Text(l10n.newPlaylist),
    );
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navPlaylists),
      body: playlists.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_outlined,
              title: l10n.playlistsEmptyTitle,
              body: l10n.playlistsEmptyBody,
              action: createButton,
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _create(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newPlaylist),
                    ),
                  ),
                ),
                for (final playlist in playlists)
                  _PlaylistTile(playlist: playlist),
              ],
            ),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('playlist-${playlist.id}'),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.queue_music,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l10n.playlistTracks(playlist.trackCount)),
      onTap: () => context.push('/playlists/${playlist.id}'),
      trailing: PlaylistMenuButton(playlist: playlist),
    );
  }
}

/// Rename / delete menu shared by the list and the detail page.
class PlaylistMenuButton extends ConsumerWidget {
  const PlaylistMenuButton({super.key, required this.playlist, this.onDeleted});

  final Playlist playlist;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(playlistRepositoryProvider);
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final name = await promptPlaylistName(
              context,
              initial: playlist.name,
              title: l10n.rename,
              confirmLabel: l10n.save,
            );
            if (name != null) await repo.rename(playlist.id, name);
          },
          child: Text(l10n.rename),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (await confirmDeletePlaylist(context, playlist)) {
              await repo.delete(playlist.id);
              onDeleted?.call();
            }
          },
          child: Text(l10n.delete),
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
