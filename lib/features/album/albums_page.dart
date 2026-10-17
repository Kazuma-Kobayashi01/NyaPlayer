import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/core/sort_key.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navAlbums),
      body: LibraryBuilder(
        builder: (context, library) {
          if (library.albums.isEmpty) {
            return EmptyState(
              icon: Icons.album_outlined,
              title: l10n.emptyLibrary,
            );
          }
          final albums = [...library.albums]
            ..sort((a, b) => compareNames(a.title, b.title));
          final bottom = MediaQuery.paddingOf(context).bottom;
          final textScaler = MediaQuery.textScalerOf(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              // Square cover plus two text lines: the tile height follows the
              // tile width, so a fixed aspect ratio would overflow (or leave
              // gaps) as the window is resized.
              const padding = 16.0;
              const spacing = 8.0;
              final columns =
                  ((constraints.maxWidth - 2 * padding + spacing) /
                          (200 + spacing))
                      .ceil()
                      .clamp(2, 12);
              final tileWidth =
                  (constraints.maxWidth -
                      2 * padding -
                      (columns - 1) * spacing) /
                  columns;
              // card padding 4+4, gap 8, title + artist lines.
              final tileHeight = tileWidth - 8 + 16 + textScaler.scale(44);
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding,
                  padding,
                  padding + bottom,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  mainAxisExtent: tileHeight,
                ),
                itemCount: albums.length,
                itemBuilder: (context, i) => AlbumCard(album: albums[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.heroPrefix = 'album-grid',
  });

  final Album album;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go('/albums/${album.id}'),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: CoverArt(
                seed: album.coverSeed,
                radius: 16,
                heroTag: '$heroPrefix-${album.id}',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
