import 'package:flutter/material.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// Song info bottom sheet (META-07).
Future<void> showSongInfo(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SongInfoSheet(track: track),
  );
}

class _SongInfoSheet extends StatelessWidget {
  const _SongInfoSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      (l10n.infoAlbum, track.album),
      (l10n.infoArtist, track.artist),
      (l10n.infoTrackNo, '${track.trackNo}'),
      if (track.year != null) (l10n.infoYear, '${track.year}'),
      if (track.genre != null) (l10n.infoGenre, track.genre!),
      (l10n.infoDuration, formatDuration(track.duration)),
      (l10n.infoFormat, track.codec),
      (l10n.infoSampleRate, formatSampleRate(track.sampleRate)),
      (l10n.infoBitDepth, l10n.bitDepthValue(track.bitDepth)),
      (l10n.infoBitrate, l10n.bitrateValue(track.bitrateKbps)),
      (
        l10n.infoChannels,
        track.channels == 1 ? l10n.channelsMono : l10n.channelsStereo,
      ),
      (l10n.infoPath, track.path),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
