import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/track_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navFolders),
      body: LibraryBuilder(
        builder: (context, library) {
          if (library.folders.isEmpty) {
            return EmptyState(
              icon: Icons.folder_off_outlined,
              title: l10n.emptyLibrary,
            );
          }
          return ListView.builder(
            itemCount: library.folders.length,
            itemBuilder: (context, i) {
              final folder = library.folders[i];
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${folder.path} · ${l10n.songCount(folder.trackCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.go(
                  Uri(
                    path: '/folders/detail',
                    queryParameters: {'path': folder.path},
                  ).toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FolderDetailPage extends ConsumerWidget {
  const FolderDetailPage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.read(queueProvider.notifier);
    return LibraryBuilder(
      builder: (context, library) {
        final tracks = library.tracksInFolder(path);
        final name =
            path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;
        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) => TrackTile(
              track: tracks[i],
              onTap: () => queue.playTracks(tracks, startIndex: i),
            ),
          ),
        );
      },
    );
  }
}
