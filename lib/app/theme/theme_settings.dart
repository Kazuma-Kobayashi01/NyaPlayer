import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ColorSource { cover, wallpaper, fixed }

enum AppFont { sans, serif }

/// Selectable fixed seed colours (SET-02). These are theme inputs, not UI colours.
const seedColorChoices = <Color>[
  Color(0xFF6750A4),
  Color(0xFF006A6A),
  Color(0xFF386A20),
  Color(0xFF8B5000),
  Color(0xFFB3261E),
  Color(0xFF00629D),
  Color(0xFF984061),
];

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.source = ColorSource.wallpaper,
    this.seed = const Color(0xFF6750A4),
    this.font = AppFont.sans,
  });

  final ThemeMode mode;
  final ColorSource source;
  final Color seed;
  final AppFont font;

  ThemeSettings copyWith({
    ThemeMode? mode,
    ColorSource? source,
    Color? seed,
    AppFont? font,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      source: source ?? this.source,
      seed: seed ?? this.seed,
      font: font ?? this.font,
    );
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsController, ThemeSettings>(
      ThemeSettingsController.new,
    );

class ThemeSettingsController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => const ThemeSettings();

  void setMode(ThemeMode mode) => state = state.copyWith(mode: mode);
  void setSource(ColorSource source) => state = state.copyWith(source: source);
  void setSeed(Color seed) => state = state.copyWith(seed: seed);
  void setFont(AppFont font) => state = state.copyWith(font: font);
}

/// `null` follows the system language.
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;
}
