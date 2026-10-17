import 'package:flutter/material.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/song_info_sheet.dart';

/// Lossless codecs that can qualify as Hi-Res.
const _losslessCodecs = {'FLAC', 'ALAC', 'WAV', 'AIFF', 'APE', 'WV'};

/// Hi-Res Audio by the Japan Audio Society definition: lossless, at least
/// 24-bit and 96 kHz (META-07).
bool isHiRes(Track track) =>
    _losslessCodecs.contains(track.codec.toUpperCase()) &&
    track.bitDepth >= 24 &&
    track.sampleRate >= 96000;

/// "FLAC · 24-bit / 48 kHz", or "Hi-Res · 24-bit / 96 kHz" for Hi-Res tracks.
String trackQualityLabel(Track track) =>
    '${isHiRes(track) ? 'Hi-Res' : track.codec} · '
    '${track.bitDepth}-bit / ${formatSampleRate(track.sampleRate)}';

/// The gold Hi-Res Audio mark (Japan Audio Society; file from Wikimedia
/// Commons). A brand asset, so it keeps its own colours.
class HiResLogo extends StatelessWidget {
  const HiResLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/hi_res_audio.png',
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Hi-Res Audio',
    );
  }
}

/// Tappable audio-format label that opens the song info sheet. Hi-Res tracks
/// show the gold mark in place of the wave icon.
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.track, this.tonal = false});

  final Track track;

  /// Filled tonal pill (phone player) instead of an outlined chip.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hiRes = isHiRes(track);
    final label = Text(trackQualityLabel(track));
    if (!tonal) {
      return ActionChip(
        avatar: hiRes
            ? const HiResLogo()
            : const Icon(Icons.graphic_eq, size: 18),
        label: label,
        visualDensity: VisualDensity.compact,
        onPressed: () => showSongInfo(context, track),
      );
    }
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSongInfo(context, track),
        child: Padding(
          padding: EdgeInsets.fromLTRB(hiRes ? 6 : 12, 5, 12, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hiRes) ...[const HiResLogo(), const SizedBox(width: 6)],
              DefaultTextStyle.merge(
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
