import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Play queue with tap-to-jump, swipe-to-remove and drag-to-reorder (PLAY-02).
class QueueList extends ConsumerWidget {
  const QueueList({super.key, this.physics, this.padding});

  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(queueProvider);
    final queue = ref.read(queueProvider.notifier);

    if (state.queue.isEmpty) {
      return EmptyState(icon: Icons.queue_music, title: l10n.queueEmpty);
    }

    return ReorderableListView.builder(
      physics: physics,
      padding: padding,
      buildDefaultDragHandles: false,
      itemCount: state.queue.length,
      onReorderItem: queue.move,
      itemBuilder: (context, index) {
        final track = state.queue[index];
        final isCurrent = index == state.currentIndex;
        return Dismissible(
          key: ValueKey('$index:${track.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => queue.removeAt(index),
          background: ColoredBox(
            color: theme.colorScheme.errorContainer,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
          child: ListTile(
            selected: isCurrent,
            onTap: () => queue.jumpTo(index),
            leading: CoverArt(seed: track.coverSeed, size: 48),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${track.artist} · ${formatDuration(track.duration)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l10n.queue),
      ),
      body: const QueueList(),
    );
  }
}
