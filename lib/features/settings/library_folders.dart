import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/library/library_scanner.dart';
import 'package:nyaplayer/services/platform/folder_picker.dart';
import 'package:nyaplayer/services/platform/music_permission.dart';

/// Makes sure the app may read audio files, asking the system if it still
/// can (Android). When it cannot, explains why and offers the settings page.
Future<bool> ensureMusicAccess(BuildContext context, WidgetRef ref) async {
  final permission = ref.read(musicPermissionProvider);
  var access = await permission.status();
  if (access == MusicAccess.denied) access = await permission.request();
  if (access == MusicAccess.granted) return true;
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final canOpenSettings = access == MusicAccess.permanentlyDenied;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.musicPermissionTitle),
      content: Text(l10n.musicPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
        if (canOpenSettings)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              permission.openSettings();
            },
            child: Text(l10n.musicPermissionSettings),
          ),
      ],
    ),
  );
  return false;
}

/// Asks the system for folders, stores them as scan locations (or excluded
/// folders) and rescans (LIB-01, SET-01). Returns whether anything was added.
Future<bool> addLibraryFolder(
  BuildContext context,
  WidgetRef ref, {
  bool excluded = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  // Leaving a folder out reads nothing, so it needs no permission.
  if (!excluded && !await ensureMusicAccess(context, ref)) return false;

  final List<String> paths;
  try {
    paths = await ref
        .read(folderPickerProvider)
        .pickDirectories(
          title: excluded ? l10n.excludeFolder : l10n.addFolder,
          message: excluded ? l10n.pickExcludeMessage : l10n.pickFolderMessage,
          prompt: excluded ? l10n.excludeFolder : l10n.addFolder,
        );
  } on FolderPickException catch (e) {
    Log.w('Folders', 'Unusable folder choice: $e');
    say(l10n.folderNotUsable);
    return false;
  } catch (e) {
    Log.w('Folders', 'Folder picker failed: $e');
    say(l10n.folderPickFailed);
    return false;
  }
  if (paths.isEmpty) return false;

  final repository = ref.read(libraryRepositoryProvider);
  var added = 0;
  for (final path in paths) {
    if (await repository.addRoot(path, excluded: excluded)) added++;
  }
  if (added == 0) {
    say(l10n.folderAlreadyAdded);
    return false;
  }
  unawaited(ref.read(scanProvider.notifier).scan());
  return true;
}

String? scanStatusText(AppLocalizations l10n, ScanState state) {
  if (state.failed) return l10n.scanFailed;
  final progress = state.progress;
  if (progress == null) return null;
  return switch (progress.phase) {
    ScanPhase.walking => l10n.scanWalking,
    ScanPhase.reading =>
      progress.total == 0
          ? l10n.scanWalking
          : l10n.scanReading(progress.done, progress.total),
    ScanPhase.finishing => l10n.scanFinishing,
    ScanPhase.done =>
      progress.errors > 0
          ? l10n.scanDoneWithErrors(progress.errors)
          : l10n.scanDone,
  };
}

/// Scan locations with add / exclude / remove / rescan, and scan progress.
class LibraryFoldersTile extends ConsumerWidget {
  const LibraryFoldersTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roots = ref.watch(rootsProvider).value ?? const [];
    final scan = ref.watch(scanProvider);
    final status = scanStatusText(l10n, scan);
    final hasScanRoot = roots.any((r) => !r.excluded);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.libraryFolders, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 2),
          Text(
            l10n.libraryFoldersHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (roots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.libraryNoFolders,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final root in roots)
            ListTile(
              key: ValueKey('root-${root.id}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                root.excluded
                    ? Icons.folder_off_outlined
                    : Icons.folder_outlined,
                color: root.excluded ? theme.colorScheme.error : null,
              ),
              title: Text(
                root.path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: root.excluded ? Text(l10n.excludedTag) : null,
              trailing: IconButton(
                tooltip: l10n.removeFolder,
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await ref.read(libraryRepositoryProvider).removeRoot(root.id);
                  unawaited(ref.read(scanProvider.notifier).scan());
                },
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => addLibraryFolder(context, ref),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.addFolder),
              ),
              if (hasScanRoot)
                OutlinedButton.icon(
                  onPressed: () =>
                      addLibraryFolder(context, ref, excluded: true),
                  icon: const Icon(Icons.folder_off_outlined),
                  label: Text(l10n.excludeFolder),
                ),
              OutlinedButton.icon(
                onPressed: scan.running
                    ? null
                    : () => ref.read(scanProvider.notifier).scan(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.rescan),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            if (scan.running)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: LinearProgressIndicator(value: scan.progress?.fraction),
              ),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
