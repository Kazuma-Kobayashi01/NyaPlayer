import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// Asks for a playlist name. Null when cancelled or left blank.
Future<String?> promptPlaylistName(
  BuildContext context, {
  String? initial,
  required String title,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _NameDialog(initial: initial, title: title, confirmLabel: confirmLabel),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.initial,
    required this.title,
    required this.confirmLabel,
  });

  final String? initial;
  final String title;
  final String confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    Navigator.of(context).pop(name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.playlistName,
          hintText: l10n.playlistNameHint,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

Future<bool> confirmDeletePlaylist(
  BuildContext context,
  Playlist playlist,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deletePlaylistTitle),
      content: Text(l10n.deletePlaylistBody(playlist.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Bottom sheet that adds [tracks] to an existing or a new playlist.
Future<void> showAddToPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  if (tracks.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(playlistRepositoryProvider);

  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final playlists = ref.watch(playlistsProvider).value ?? const [];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.newPlaylist),
                  onTap: () => Navigator.of(context).pop('new'),
                ),
                for (final playlist in playlists)
                  ListTile(
                    key: ValueKey('add-to-${playlist.id}'),
                    leading: const Icon(Icons.queue_music_outlined),
                    title: Text(playlist.name),
                    subtitle: Text(l10n.playlistTracks(playlist.trackCount)),
                    onTap: () => Navigator.of(context).pop(playlist),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (choice == null || !context.mounted) return;

  late final int id;
  late final String name;
  if (choice is Playlist) {
    id = choice.id;
    name = choice.name;
  } else {
    final entered = await promptPlaylistName(
      context,
      title: l10n.newPlaylist,
      confirmLabel: l10n.create,
    );
    if (entered == null) return;
    id = await repo.create(entered);
    name = entered;
  }
  await repo.addTracks(id, [for (final t in tracks) t.id]);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.addedToPlaylist(name))));
}
