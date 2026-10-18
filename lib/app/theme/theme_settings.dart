import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/l10n/language_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ColorSource { wallpaper, fixed }

enum AppFont { sans, serif }

enum PlayerBackgroundStyle { gradient, blurredCover }

enum ProgressStyle { material, classic, slim, wave }

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
    this.playerBackground = PlayerBackgroundStyle.blurredCover,
    this.progressStyle = ProgressStyle.material,
    this.useBundledFonts = true,
  });

  final ThemeMode mode;
  final ColorSource source;
  final Color seed;
  final AppFont font;
  final PlayerBackgroundStyle playerBackground;
  final ProgressStyle progressStyle;

  /// Use the fonts shipped with the app (HarmonyOS Sans / EB Garamond +
  /// Noto Serif SC) instead of the system's (SET-06).
  final bool useBundledFonts;

  ThemeSettings copyWith({
    ThemeMode? mode,
    ColorSource? source,
    Color? seed,
    AppFont? font,
    PlayerBackgroundStyle? playerBackground,
    ProgressStyle? progressStyle,
    bool? useBundledFonts,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      source: source ?? this.source,
      seed: seed ?? this.seed,
      font: font ?? this.font,
      playerBackground: playerBackground ?? this.playerBackground,
      progressStyle: progressStyle ?? this.progressStyle,
      useBundledFonts: useBundledFonts ?? this.useBundledFonts,
    );
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsController, ThemeSettings>(
      ThemeSettingsController.new,
    );

class ThemeSettingsController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<ThemeSettings>((previous, next) {
        void save(String key, String value) => store.put(key, value);
        if (previous?.mode != next.mode) save('theme.mode', next.mode.name);
        if (previous?.source != next.source) {
          save('theme.source', next.source.name);
        }
        if (previous?.seed != next.seed) {
          save('theme.seed', '${next.seed.toARGB32()}');
        }
        if (previous?.font != next.font) save('theme.font', next.font.name);
        if (previous?.playerBackground != next.playerBackground) {
          save('player.background', next.playerBackground.name);
        }
        if (previous?.progressStyle != next.progressStyle) {
          save('player.progressStyle', next.progressStyle.name);
        }
        if (previous?.useBundledFonts != next.useBundledFonts) {
          save('theme.bundledFonts', '${next.useBundledFonts}');
        }
      }),
    );
    const defaults = ThemeSettings();
    return ThemeSettings(
      mode: enumByName(
        ThemeMode.values,
        store.get('theme.mode'),
        defaults.mode,
      ),
      source: enumByName(
        ColorSource.values,
        store.get('theme.source'),
        defaults.source,
      ),
      seed: Color(
        int.tryParse(store.get('theme.seed') ?? '') ?? defaults.seed.toARGB32(),
      ),
      font: enumByName(AppFont.values, store.get('theme.font'), defaults.font),
      playerBackground: enumByName(
        PlayerBackgroundStyle.values,
        store.get('player.background'),
        defaults.playerBackground,
      ),
      progressStyle: enumByName(
        ProgressStyle.values,
        store.get('player.progressStyle'),
        defaults.progressStyle,
      ),
      useBundledFonts: boolOr(
        store.get('theme.bundledFonts'),
        defaults.useBundledFonts,
      ),
    );
  }

  void setMode(ThemeMode mode) => state = state.copyWith(mode: mode);
  void setSource(ColorSource source) => state = state.copyWith(source: source);
  void setSeed(Color seed) => state = state.copyWith(seed: seed);
  void setFont(AppFont font) => state = state.copyWith(font: font);
  void setPlayerBackground(PlayerBackgroundStyle style) =>
      state = state.copyWith(playerBackground: style);
  void setProgressStyle(ProgressStyle style) =>
      state = state.copyWith(progressStyle: style);
  void setUseBundledFonts(bool value) =>
      state = state.copyWith(useBundledFonts: value);
}

/// `null` follows the system language.
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<Locale?>(
        (_, next) => store.put('ui.locale', idOfLocale(next)),
      ),
    );
    // Ids from older versions ('zh', 'en') are understood too.
    return localeOfId(store.get('ui.locale'));
  }

  void set(Locale? locale) => state = locale;
}
