import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final queue = ref.read(queueProvider.notifier);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navFavorites),
      body: LibraryBuilder(
        builder: (context, library) {
          final tracks = library.tracks
              .where((t) => favorites.contains(t.id))
              .toList();
          if (tracks.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: l10n.favoritesEmptyTitle,
              body: l10n.favoritesEmptyBody,
            );
          }
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) => TrackTile(
              track: tracks[i],
              onTap: () => queue.playTracks(tracks, startIndex: i),
            ),
          );
        },
      ),
    );
  }
}
