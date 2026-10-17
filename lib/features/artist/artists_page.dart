import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/features/album/albums_page.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navArtists),
      body: LibraryBuilder(
        builder: (context, library) {
          if (library.artists.isEmpty) {
            return EmptyState(
              icon: Icons.person_outline,
              title: l10n.emptyLibrary,
            );
          }
          return ListView.builder(
            itemCount: library.artists.length,
            itemBuilder: (context, i) {
              final artist = library.artists[i];
              return ListTile(
                leading: CoverArt(
                  seed: artist.coverSeed,
                  source: artist.cover,
                  size: 48,
                  radius: 24,
                  icon: Icons.person,
                ),
                title: Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${l10n.albumCount(artist.albumCount)} · ${l10n.songCount(artist.trackCount)}',
                ),
                onTap: () =>
                    context.go('/artists/${Uri.encodeComponent(artist.name)}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ArtistDetailPage extends ConsumerWidget {
  const ArtistDetailPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final queue = ref.read(queueProvider.notifier);
    return LibraryBuilder(
      builder: (context, library) {
        final tracks = library.tracksOfArtist(name);
        final albums = library.albumsOfArtist(name);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(name)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PlayButtonsRow(tracks: tracks),
                  ),
                ),
              ),
              if (albums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.sectionAlbums,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: albums.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(
                        width: 150,
                        child: AlbumCard(
                          album: albums[i],
                          heroPrefix: 'artist-album',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    l10n.sectionSongs,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, i) => TrackTile(
                  track: tracks[i],
                  onTap: () => queue.playTracks(tracks, startIndex: i),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 16 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
