import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/core/sort_key.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/sr/super_resolution.dart';

/// Whether [track] can be turned into an SQ-AI FLAC: an MP3 (the only format
/// the conversion takes, on every platform).
bool canBecomeSqAi(Track track) => track.codec.toUpperCase() == 'MP3';

/// Pick MP3s from the library to convert to SQ-AI. Songs come from the
/// library, not from a file chooser, so the same page serves every platform.
class SrPickerPage extends ConsumerStatefulWidget {
  const SrPickerPage({super.key});

  @override
  ConsumerState<SrPickerPage> createState() => _SrPickerPageState();
}

class _SrPickerPageState extends ConsumerState<SrPickerPage> {
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(libraryProvider);
    // Songs already being converted are not offered again.
    final busy = {
      for (final job in ref.watch(superResolutionProvider).jobs)
        if (job.active) job.source,
    };
    final songs =
        [
          for (final t in library.value?.tracks ?? const <Track>[])
            if (canBecomeSqAi(t) && !busy.contains(t.path)) t,
        ]..sort((a, b) {
          final byTitle = sortKey(a.title).compareTo(sortKey(b.title));
          return byTitle != 0
              ? byTitle
              : sortKey(a.artist).compareTo(sortKey(b.artist));
        });
    final chosen = {
      for (final t in songs)
        if (_selected.contains(t.id)) t.id,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.srPickerTitle),
        actions: [
          if (songs.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                chosen.length == songs.length
                    ? _selected.clear()
                    : _selected.addAll(songs.map((t) => t.id));
              }),
              child: Text(
                chosen.length == songs.length
                    ? l10n.srSelectNone
                    : l10n.srSelectAll,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: library.isLoading && songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.srPickerEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, i) {
                final t = songs[i];
                return CheckboxListTile(
                  key: ValueKey('sr-pick-${t.id}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: chosen.contains(t.id),
                  onChanged: (on) => setState(() {
                    on == true ? _selected.add(t.id) : _selected.remove(t.id);
                  }),
                  title: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    t.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondary: t.bitrateKbps > 0
                      ? Text('${t.bitrateKbps} kbps')
                      : null,
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: chosen.isEmpty
                ? null
                : () {
                    final paths = [
                      for (final t in songs)
                        if (chosen.contains(t.id)) t.path,
                    ];
                    ref.read(superResolutionProvider.notifier).add(paths);
                    context.pop();
                  },
            child: Text(l10n.srConvertSelected(chosen.length)),
          ),
        ),
      ),
    );
  }
}
