import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/album_artist_label.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Centred top app bar of the top-level pages. Shows a menu button that opens
/// the navigation drawer on narrow windows, and search (UI-09).
class LibraryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const LibraryAppBar({super.key, required this.title, this.showSearch = true});

  final String title;
  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scanning = ref.watch(scanProvider.select((s) => s.running));
    final openNavigation = ShellScope.openNavigationOf(context);
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final bar = AppBar(
      automaticallyImplyLeading: false,
      leading: openNavigation == null
          ? null
          : IconButton(
              tooltip: l10n.openNavigation,
              icon: const Icon(Icons.menu),
              onPressed: openNavigation,
            ),
      title: Text(
        title,
        style: titleStyle?.copyWith(fontSize: (titleStyle.fontSize ?? 22) - 1),
      ),
      actions: [
        if (showSearch) const LibrarySearchAnchor(),
        const SizedBox(width: 4),
      ],
    );
    if (!scanning) return bar;
    // Scan progress (LIB-05) overlays the bar's bottom edge: no layout shift.
    return Stack(
      children: [
        bar,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LinearProgressIndicator(minHeight: 2),
        ),
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
    return SearchAnchor(
      viewHintText: l10n.searchHint,
      builder: (context, controller) => IconButton(
        tooltip: l10n.search,
        icon: const Icon(Icons.search),
        onPressed: controller.openView,
      ),
      suggestionsBuilder: (context, controller) => librarySearchSuggestions(
        context,
        ref,
        controller.text,
        () => controller.closeView(null),
      ),
    );
  }
}

/// Shared results for the in-page search anchor and the macOS global shortcut.
Future<List<Widget>> librarySearchSuggestions(
  BuildContext context,
  WidgetRef ref,
  String query,
  VoidCallback close,
) async {
  final l10n = AppLocalizations.of(context);
  final router = GoRouter.of(context);
  final queue = ref.read(queueProvider.notifier);
  final library = ref.read(libraryProvider).value;
  if (library == null || query.trim().isEmpty) return const <Widget>[];

  final tracks = await ref.read(trackSearchProvider)(query);
  if (!context.mounted) return const <Widget>[];
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
            source: a.cover,
            size: 40,
            radius: 20,
            icon: Icons.person,
          ),
          title: Text(a.name),
          onTap: () {
            close();
            router.go('/artists/${Uri.encodeComponent(a.name)}');
          },
        ),
    ],
    if (albums.isNotEmpty) ...[
      header(l10n.sectionAlbums),
      for (final a in albums)
        ListTile(
          leading: CoverArt(seed: a.coverSeed, source: a.cover, size: 40),
          title: Text(a.title),
          subtitle: Text(albumArtistLabel(l10n, a)),
          onTap: () {
            close();
            router.go('/albums/${a.id}');
          },
        ),
    ],
    if (tracks.isNotEmpty) ...[
      header(l10n.sectionSongs),
      for (var i = 0; i < tracks.length; i++)
        ListTile(
          leading: CoverArt(
            seed: tracks[i].coverSeed,
            source: tracks[i].cover,
            size: 40,
          ),
          title: Text(tracks[i].title),
          subtitle: Text('${tracks[i].artist} · ${tracks[i].album}'),
          onTap: () {
            close();
            queue.playTracks(tracks, startIndex: i);
          },
        ),
    ],
  ];
}
