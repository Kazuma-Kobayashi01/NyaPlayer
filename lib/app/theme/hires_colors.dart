import 'package:flutter/material.dart';

/// The black-gold palette of the Hi-Res badge and the light that runs along
/// its edge: near-black with antique gold, nothing glittery. Hi-Res Audio is a gold mark by definition (see `HiResLogo`), so these
/// are brand colours rather than scheme roles: they live here, in the theme,
/// and widgets read them through [HiResColors.of].
@immutable
class HiResColors extends ThemeExtension<HiResColors> {
  const HiResColors({
    this.deep = const Color(0xFF0F0D08),
    this.mid = const Color(0xFF2C2514),
    this.gold = const Color(0xFFA98B3F),
    this.shine = const Color(0xFFE4D09C),
    this.text = const Color(0xFFD8C48F),
  });

  /// Near-black: the body of the badge.
  final Color deep;

  /// Dark bronze between the body and the gold.
  final Color mid;

  /// Antique gold of the border and of the light behind a Hi-Res cover.
  final Color gold;

  /// Champagne of the brightest highlight.
  final Color shine;

  /// Lettering on the badge.
  final Color text;

  static const standard = HiResColors();

  /// The silver-black variant worn by plain (CD-quality or lossy-sized) FLAC
  /// files: the same badge and sweep as Hi-Res, in cool near-black with
  /// brushed silver. Here [gold] is the silver of the border, and [shine] the
  /// brightest highlight.
  static const silver = HiResColors(
    deep: Color(0xFF0D0E10),
    mid: Color(0xFF24272C),
    gold: Color(0xFF9EA4AC),
    shine: Color(0xFFE8EBEF),
    text: Color(0xFFCDD2D9),
  );

  /// The tech-blue variant worn by FLAC files the AI super-resolution made
  /// from MP3s (SQ-AI): deep navy with an electric-blue edge and an icy
  /// highlight. [gold] is the blue of the border here.
  static const techBlue = HiResColors(
    deep: Color(0xFF060C17),
    mid: Color(0xFF0E2747),
    gold: Color(0xFF2C8FEA),
    shine: Color(0xFFA8DBFF),
    text: Color(0xFF7FC3FF),
  );

  static HiResColors of(BuildContext context) =>
      Theme.of(context).extension<HiResColors>() ?? standard;

  @override
  HiResColors copyWith({
    Color? deep,
    Color? mid,
    Color? gold,
    Color? shine,
    Color? text,
  }) => HiResColors(
    deep: deep ?? this.deep,
    mid: mid ?? this.mid,
    gold: gold ?? this.gold,
    shine: shine ?? this.shine,
    text: text ?? this.text,
  );

  @override
  HiResColors lerp(HiResColors? other, double t) => other == null
      ? this
      : HiResColors(
          deep: Color.lerp(deep, other.deep, t)!,
          mid: Color.lerp(mid, other.mid, t)!,
          gold: Color.lerp(gold, other.gold, t)!,
          shine: Color.lerp(shine, other.shine, t)!,
          text: Color.lerp(text, other.text, t)!,
        );
}
