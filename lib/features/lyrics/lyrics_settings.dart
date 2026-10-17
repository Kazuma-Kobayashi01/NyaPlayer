import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Display options of the lyrics view, set from the player menu.
@immutable
class LyricsSettings {
  const LyricsSettings({
    this.fontSize = defaultFontSize,
    this.centered = false,
    this.showTranslation = true,
  });

  static const defaultFontSize = 22.0;
  static const minFontSize = 10.0;
  static const maxFontSize = 40.0;

  /// Size of a regular lyric line in logical pixels; the current line is
  /// drawn slightly larger and the translation slightly smaller.
  final double fontSize;
  final bool centered;
  final bool showTranslation;

  LyricsSettings copyWith({
    double? fontSize,
    bool? centered,
    bool? showTranslation,
  }) {
    return LyricsSettings(
      fontSize: fontSize ?? this.fontSize,
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
  void setCentered(bool value) => state = state.copyWith(centered: value);
  void setShowTranslation(bool value) =>
      state = state.copyWith(showTranslation: value);
}
