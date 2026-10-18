import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/settings/library_folders.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class SongsPage extends ConsumerStatefulWidget {
  const SongsPage({super.key});

  @override
  ConsumerState<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends ConsumerState<SongsPage> {
  SongSort _sort = SongSort.title;
  bool _ascending = true;

  String _sortLabel(AppLocalizations l10n, SongSort sort) => switch (sort) {
    SongSort.title => l10n.sortTitle,
    SongSort.artist => l10n.sortArtist,
    SongSort.album => l10n.sortAlbum,
    SongSort.added => l10n.sortAdded,
    SongSort.duration => l10n.sortDuration,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.read(queueProvider.notifier);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navSongs),
      body: LibraryBuilder(
        builder: (context, library) {
          final tracks = sortTracks(
            library.tracks,
            _sort,
            ascending: _ascending,
          );
          if (tracks.isEmpty) {
            final scanning = ref.watch(scanProvider).running;
            return EmptyState(
              icon: Icons.music_off_outlined,
              title: scanning ? l10n.scanWalking : l10n.emptyLibrary,
              body: scanning ? null : l10n.emptyLibraryBody,
              action: scanning
                  ? null
                  : FilledButton.icon(
                      onPressed: () => addLibraryFolder(context, ref),
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(l10n.addFolder),
                    ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.songCount(tracks.length),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    _SortMenu(
                      sort: _sort,
                      ascending: _ascending,
                      labelOf: (s) => _sortLabel(l10n, s),
                      onSort: (s) => setState(() => _sort = s),
                      onAscending: (v) => setState(() => _ascending = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, i) => TrackTile(
                    track: tracks[i],
                    onTap: () => queue.playTracks(tracks, startIndex: i),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.sort,
    required this.ascending,
    required this.labelOf,
    required this.onSort,
    required this.onAscending,
  });

  final SongSort sort;
  final bool ascending;
  final String Function(SongSort) labelOf;
  final ValueChanged<SongSort> onSort;
  final ValueChanged<bool> onAscending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      menuChildren: [
        for (final s in SongSort.values)
          MenuItemButton(
            leadingIcon: Icon(s == sort ? Icons.check : null),
            onPressed: () => onSort(s),
            child: Text(labelOf(s)),
          ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: Icon(ascending ? Icons.check : null),
          onPressed: () => onAscending(true),
          child: Text(l10n.sortAscending),
        ),
        MenuItemButton(
          leadingIcon: Icon(!ascending ? Icons.check : null),
          onPressed: () => onAscending(false),
          child: Text(l10n.sortDescending),
        ),
      ],
      builder: (context, controller, _) => TextButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(
          ascending ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
        ),
        label: Text(labelOf(sort)),
      ),
    );
  }
}
