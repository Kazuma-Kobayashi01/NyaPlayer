import 'package:flutter/material.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// Placeholder until playlists (LIB-13, P1) are implemented.
class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navPlaylists),
      body: EmptyState(
        icon: Icons.queue_music_outlined,
        title: l10n.playlistsEmptyTitle,
        body: l10n.playlistsEmptyBody,
      ),
    );
  }
}
