import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Display options of the lyrics view, set from the player menu.
@immutable
class LyricsSettings {
  const LyricsSettings({
    this.fontSize = defaultFontSize,
    this.lineHeight = defaultLineHeight,
    this.centered = false,
    this.showTranslation = true,
  });

  static const defaultFontSize = 20.0;
  static const defaultLineHeight = 1.2;
  static const minLineHeight = 1.0;
  static const maxLineHeight = 2.0;
  static const minFontSize = 10.0;
  static const maxFontSize = 40.0;

  /// Size of a regular lyric line in logical pixels; the current line is
  /// drawn slightly larger and the translation slightly smaller.
  final double fontSize;
  final double lineHeight;
  final bool centered;
  final bool showTranslation;

  LyricsSettings copyWith({
    double? fontSize,
    double? lineHeight,
    bool? centered,
    bool? showTranslation,
  }) {
    return LyricsSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      centered: centered ?? this.centered,
      showTranslation: showTranslation ?? this.showTranslation,
    );
  }
}

final lyricsSettingsProvider =
    NotifierProvider<LyricsSettingsController, LyricsSettings>(
      LyricsSettingsController.new,
    );

class LyricsSettingsController extends Notifier<LyricsSettings> {
  @override
  LyricsSettings build() => const LyricsSettings();

  void setFontSize(double size) => state = state.copyWith(
    fontSize: size.clamp(
      LyricsSettings.minFontSize,
      LyricsSettings.maxFontSize,
    ),
  );
  void setLineHeight(double height) => state = state.copyWith(
    lineHeight: height.clamp(
      LyricsSettings.minLineHeight,
      LyricsSettings.maxLineHeight,
    ),
  );
  void setCentered(bool value) => state = state.copyWith(centered: value);
  void setShowTranslation(bool value) =>
      state = state.copyWith(showTranslation: value);
}
