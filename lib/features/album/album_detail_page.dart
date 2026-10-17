import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/player_theme.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class AlbumDetailPage extends StatelessWidget {
  const AlbumDetailPage({super.key, required this.albumId});

  final int albumId;

  @override
  Widget build(BuildContext context) {
    return LibraryBuilder(
      builder: (context, library) {
        final album = library.albumById(albumId);
        if (album == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.album_outlined,
              title: AppLocalizations.of(context).loadFailed,
            ),
          );
        }
        return PlayerThemeScope(
          seed: album.coverSeed,
          child: _AlbumBody(
            album: album,
            tracks: library.tracksOfAlbum(album.id),
          ),
        );
      },
    );
  }
}

class _AlbumBody extends ConsumerWidget {
  const _AlbumBody({required this.album, required this.tracks});

  final Album album;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final queue = ref.read(queueProvider.notifier);
    final total = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final multiDisc = tracks.map((t) => t.discNo).toSet().length > 1;
    final cover = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
      child: AspectRatio(
        aspectRatio: 1,
        child: CoverArt(
          seed: album.coverSeed,
          radius: 28,
          heroTag: 'album-grid-${album.id}',
        ),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(album.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          album.artist,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (album.year != null) '${album.year}',
            l10n.songCount(tracks.length),
            formatDuration(total),
          ].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        PlayButtonsRow(tracks: tracks),
      ],
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, title: Text(album.title)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 560) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        cover,
                        const SizedBox(width: 24),
                        Expanded(child: info),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: cover),
                      const SizedBox(height: 16),
                      info,
                    ],
                  );
                },
              ),
            ),
          ),
          SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) {
              final t = tracks[i];
              final showDisc =
                  multiDisc && (i == 0 || tracks[i - 1].discNo != t.discNo);
              final tile = TrackTile(
                track: t,
                leadingNumber: t.trackNo,
                onTap: () => queue.playTracks(tracks, startIndex: i),
              );
              if (!showDisc) return tile;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      l10n.discLabel(t.discNo),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  tile,
                ],
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
