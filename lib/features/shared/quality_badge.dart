import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nyaplayer/app/theme/hires_colors.dart';
import 'package:nyaplayer/core/format.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/song_info_sheet.dart';

/// Lossless codecs that can qualify as Hi-Res.
const _losslessCodecs = {'FLAC', 'ALAC', 'WAV', 'AIFF', 'APE', 'WV'};

/// Hi-Res: lossless and better than CD, i.e. deeper than 16 bits or sampled
/// above 44.1 kHz (META-08; the usual definition of high-resolution audio).
bool isHiRes(Track track) =>
    _losslessCodecs.contains(track.codec.toUpperCase()) &&
    (track.bitDepth > 16 || track.sampleRate > 44100);

/// Plain FLAC: lossless but not Hi-Res (CD quality). It wears the silver-black
/// variant of the Hi-Res badge.
bool isPlainFlac(Track track) =>
    track.codec.toUpperCase() == 'FLAC' && !isHiRes(track);

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

/// Tappable audio-format label that opens the song info sheet; the same on
/// phone and desktop. Hi-Res tracks get the dark-gold [_SweepBadge] and plain
/// FLAC tracks its silver-black twin, each with a one-off sweep of light, in
/// place of the plain chip (which MP3 keeps).
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.track});

  final Track track;

  /// Height layouts should reserve for the badge (the Hi-Res one is the
  /// tallest; the plain chip is a little shorter).
  static const height = 34.0;

  @override
  Widget build(BuildContext context) {
    if (isHiRes(track)) return _SweepBadge(track: track, silver: false);
    if (isPlainFlac(track)) return _SweepBadge(track: track, silver: true);
    return ActionChip(
      avatar: const Icon(Icons.graphic_eq, size: 18),
      label: Text(trackQualityLabel(track)),
      visualDensity: VisualDensity.compact,
      onPressed: () => showSongInfo(context, track),
    );
  }
}

/// The Hi-Res badge (black with a gold hairline edge) and, with [silver], the
/// plain-FLAC one (black with a silver edge), in the same shape as
/// the plain chip. When it appears, or the song changes, a short, dim
/// highlight travels once round the edge and a faint band of light crosses
/// the body; then it rests with no ticker running. (A badge that animated
/// forever kept the whole player page redrawing on every vsync.) Standing
/// still from the start when the system asks for reduced motion.
class _SweepBadge extends StatefulWidget {
  const _SweepBadge({required this.track, required this.silver});

  final Track track;

  /// Silver-black (plain FLAC) instead of black-gold (Hi-Res).
  final bool silver;

  @override
  State<_SweepBadge> createState() => _SweepBadgeState();
}

class _SweepBadgeState extends State<_SweepBadge>
    with SingleTickerProviderStateMixin {
  static const _height = QualityBadge.height;

  /// The corners of the plain chip (the Material 3 chip shape).
  static const _radius = 8.0;

  /// The whole sweep: the edge highlight goes once round and the band
  /// crosses the body in the first half (0.75 s).
  static const _lap = Duration(milliseconds: 1500);

  bool _played = false;

  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: _lap,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A still frame with the light at a pleasant spot when motion is off.
    if (MediaQuery.disableAnimationsOf(context)) {
      _flow
        ..stop()
        ..value = 0.1;
    } else if (!_played) {
      _played = true;
      _flow.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_SweepBadge old) {
    super.didUpdateWidget(old);
    if ((old.track.id != widget.track.id || old.silver != widget.silver) &&
        !MediaQuery.disableAnimationsOf(context)) {
      _flow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.silver ? HiResColors.silver : HiResColors.of(context);
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: colors.text,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    const radius = BorderRadius.all(Radius.circular(_radius));
    return Semantics(
      button: true,
      label: trackQualityLabel(widget.track),
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SweepFlowPainter(colors: colors, flow: _flow),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: () => showSongInfo(context, widget.track),
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.silver)
                        Icon(Icons.graphic_eq, size: 18, color: colors.shine)
                      else
                        const HiResLogo(size: 18),
                      const SizedBox(width: 8),
                      // Squeezed (a huge system font, a tiny window) the
                      // text gives way instead of overflowing.
                      Flexible(
                        child: Text(
                          trackQualityLabel(widget.track),
                          style: style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepFlowPainter extends CustomPainter {
  _SweepFlowPainter({required this.colors, required this.flow})
    : super(repaint: flow);

  final HiResColors colors;
  final Animation<double> flow;

  /// The plain chip's outline is one logical pixel.
  static const _border = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = flow.value;
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_SweepBadgeState._radius),
    );

    // Body: black, a hint of bronze in the middle.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.deep, colors.mid.withValues(alpha: 0.6), colors.deep],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    // A faint band of light that crosses during the first half of the lap
    // and then rests.
    final cross = (t / 0.5).clamp(0.0, 1.0);
    if (cross > 0 && cross < 1) {
      canvas.save();
      canvas.clipRRect(shape);
      final band = size.width * 0.35;
      canvas.translate(-band + (size.width + band * 2) * cross, 0);
      canvas.transform(Matrix4.skewX(-0.4).storage);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, band, size.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              colors.shine.withValues(alpha: 0),
              colors.shine.withValues(alpha: 0.10),
              colors.shine.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, band, size.height)),
      );
      canvas.restore();
    }

    // Edge: a steady dim gold hairline with one short bright stretch going
    // round it.
    final edge = colors.gold.withValues(alpha: 0.55);
    canvas.drawRRect(
      shape.deflate(_border / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _border
        ..shader = SweepGradient(
          colors: [edge, colors.gold, colors.shine, colors.gold, edge, edge],
          stops: const [0, 0.05, 0.09, 0.13, 0.2, 1],
          transform: GradientRotation(2 * math.pi * t),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SweepFlowPainter old) => old.colors != colors;
}
