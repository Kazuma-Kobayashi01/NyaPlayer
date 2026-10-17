import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Centred top app bar of the top-level pages. Shows a menu button that opens
/// the navigation drawer on narrow windows, and search (UI-09).
class LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LibraryAppBar({super.key, required this.title, this.showSearch = true});

  final String title;
  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openNavigation = ShellScope.openNavigationOf(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leading: openNavigation == null
          ? null
          : IconButton(
              tooltip: l10n.openNavigation,
              icon: const Icon(Icons.menu),
              onPressed: openNavigation,
            ),
      title: Text(title),
      actions: [
        if (showSearch) const LibrarySearchAnchor(),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// M3 full-screen search view over songs, albums and artists (LIB-09).
class LibrarySearchAnchor extends ConsumerWidget {
  const LibrarySearchAnchor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final queue = ref.read(queueProvider.notifier);

    return SearchAnchor(
      viewHintText: l10n.searchHint,
      builder: (context, controller) => IconButton(
        tooltip: l10n.search,
        icon: const Icon(Icons.search),
        onPressed: controller.openView,
      ),
      suggestionsBuilder: (context, controller) {
        final library = ref.read(libraryProvider).value;
        final query = controller.text;
        if (library == null || query.trim().isEmpty) return const <Widget>[];

        final tracks = library.searchTracks(query);
        final albums = library.searchAlbums(query);
        final artists = library.searchArtists(query);
        if (tracks.isEmpty && albums.isEmpty && artists.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.searchNoResults)),
            ),
          ];
        }

        Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        );

        return [
          if (artists.isNotEmpty) ...[
            header(l10n.sectionArtists),
            for (final a in artists)
              ListTile(
                leading: CoverArt(
                  seed: a.coverSeed,
                  size: 40,
                  radius: 20,
                  icon: Icons.person,
                ),
                title: Text(a.name),
                onTap: () {
                  controller.closeView(null);
                  router.go('/artists/${Uri.encodeComponent(a.name)}');
                },
              ),
          ],
          if (albums.isNotEmpty) ...[
            header(l10n.sectionAlbums),
            for (final a in albums)
              ListTile(
                leading: CoverArt(seed: a.coverSeed, size: 40),
                title: Text(a.title),
                subtitle: Text(a.artist),
                onTap: () {
                  controller.closeView(null);
                  router.go('/albums/${a.id}');
                },
              ),
          ],
          if (tracks.isNotEmpty) ...[
            header(l10n.sectionSongs),
            for (var i = 0; i < tracks.length; i++)
              ListTile(
                leading: CoverArt(seed: tracks[i].coverSeed, size: 40),
                title: Text(tracks[i].title),
                subtitle: Text('${tracks[i].artist} · ${tracks[i].album}'),
                onTap: () {
                  controller.closeView(null);
                  queue.playTracks(tracks, startIndex: i);
                },
              ),
          ],
        ];
      },
    );
  }
}
