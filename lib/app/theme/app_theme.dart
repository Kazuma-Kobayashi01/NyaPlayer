import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';

/// Bundled font families (see pubspec.yaml and assets/fonts/licenses).
const bundledSansFamily = 'Nya HarmonyOS Sans SC';
const bundledSerifFamily = 'Nya EB Garamond';
const bundledSerifCjkFamily = 'Nya Noto Serif SC';

/// EB Garamond has a small x-height and thin strokes, so next to the sans
/// face it looks undersized and pale. Bundled serif text is enlarged slightly
/// and set one weight step heavier.
const bundledSerifSizeFactor = 1.08;

/// How fonts are applied: family, fallback faces and the serif correction.
@immutable
class FontPlan {
  const FontPlan({
    this.family,
    this.fallback,
    this.sizeFactor = 1,
    this.heavier = false,
  });

  final String? family;
  final List<String>? fallback;
  final double sizeFactor;

  /// Shift every text style one weight step heavier.
  final bool heavier;
}

/// Picks the fonts for a style choice (SET-06). With [bundled] off this is
/// the system-font setup the app had before the fonts were bundled.
FontPlan fontPlanFor(AppFont font, {required bool bundled}) {
  final serif = font == AppFont.serif;
  if (bundled) {
    return serif
        ? const FontPlan(
            family: bundledSerifFamily,
            // Latin comes from EB Garamond; Chinese (and kana) from here.
            fallback: [bundledSerifCjkFamily],
            sizeFactor: bundledSerifSizeFactor,
            heavier: true,
          )
        : const FontPlan(family: bundledSansFamily);
  }
  return serif
      ? FontPlan(family: _serifFamily, fallback: _serifFallback)
      : const FontPlan();
}

/// Lets widgets that set absolute font sizes (the lyrics) follow
/// [FontPlan.sizeFactor].
@immutable
class FontTuning extends ThemeExtension<FontTuning> {
  const FontTuning({this.sizeFactor = 1});

  final double sizeFactor;

  @override
  FontTuning copyWith({double? sizeFactor}) =>
      FontTuning(sizeFactor: sizeFactor ?? this.sizeFactor);

  @override
  FontTuning lerp(FontTuning? other, double t) => FontTuning(
    sizeFactor: other == null
        ? sizeFactor
        : sizeFactor + (other.sizeFactor - sizeFactor) * t,
  );
}

FontWeight _heavier(FontWeight? weight) {
  // values[i] is w(100 * (i + 1)), so value ~/ 100 is the next step's index.
  final next = ((weight ?? FontWeight.w400).value ~/ 100).clamp(
    0,
    FontWeight.values.length - 1,
  );
  return FontWeight.values[next];
}

TextStyle? _heavierStyle(TextStyle? s) =>
    s?.copyWith(fontWeight: _heavier(s.fontWeight));

TextTheme _heavierTheme(TextTheme t) => t.copyWith(
  displayLarge: _heavierStyle(t.displayLarge),
  displayMedium: _heavierStyle(t.displayMedium),
  displaySmall: _heavierStyle(t.displaySmall),
  headlineLarge: _heavierStyle(t.headlineLarge),
  headlineMedium: _heavierStyle(t.headlineMedium),
  headlineSmall: _heavierStyle(t.headlineSmall),
  titleLarge: _heavierStyle(t.titleLarge),
  titleMedium: _heavierStyle(t.titleMedium),
  titleSmall: _heavierStyle(t.titleSmall),
  bodyLarge: _heavierStyle(t.bodyLarge),
  bodyMedium: _heavierStyle(t.bodyMedium),
  bodySmall: _heavierStyle(t.bodySmall),
  labelLarge: _heavierStyle(t.labelLarge),
  labelMedium: _heavierStyle(t.labelMedium),
  labelSmall: _heavierStyle(t.labelSmall),
);

// System serif faces (used when bundled fonts are switched off): Times New
// Roman + Songti SC / Mincho on macOS, the system serif + Noto Serif CJK on
// Android.
String get _serifFamily => switch (defaultTargetPlatform) {
  TargetPlatform.macOS || TargetPlatform.iOS => 'Times New Roman',
  _ => 'serif',
};

List<String> get _serifFallback => switch (defaultTargetPlatform) {
  TargetPlatform.macOS ||
  TargetPlatform.iOS => const ['Songti SC', 'Hiragino Mincho ProN'],
  _ => const [
    'Noto Serif CJK SC',
    'Noto Serif SC',
    'Noto Serif CJK JP',
    'serif',
  ],
};

/// Builds the Material 3 [ThemeData] from a [ColorScheme]. All widgets take
/// their colours from the scheme; nothing is hard-coded.
ThemeData buildTheme(
  ColorScheme scheme, {
  AppFont font = AppFont.sans,
  bool bundledFonts = true,
}) {
  final plan = fontPlanFor(font, bundled: bundledFonts);
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: plan.family,
    fontFamilyFallback: plan.fallback,
    extensions: [FontTuning(sizeFactor: plan.sizeFactor)],
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: scheme.surface,
    // The top bar keeps the page colour while content scrolls under it; the
    // M3 scrolled-under tint looked like a random colour shift (and differs
    // from the macOS title bar).
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.secondaryContainer,
      tileHeight: 52,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 10,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // 2024 Material 3 visuals for sliders and progress indicators.
    // ignore: deprecated_member_use
    sliderTheme: const SliderThemeData(year2023: false),
    // ignore: deprecated_member_use
    progressIndicatorTheme: const ProgressIndicatorThemeData(year2023: false),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
  // Sizes are resolved from the locale's text geometry at Theme.of(context),
  // so adjust each script category before that merge (including CJK).
  final typography = theme.typography;
  TextTheme tuned(TextTheme t) {
    final sized = t.apply(fontSizeFactor: plan.sizeFactor, fontSizeDelta: -1);
    return plan.heavier ? _heavierTheme(sized) : sized;
  }

  return theme.copyWith(
    typography: typography.copyWith(
      englishLike: tuned(typography.englishLike),
      dense: tuned(typography.dense),
      tall: tuned(typography.tall),
    ),
  );
}

/// Rebuilds a [ColorScheme] from the system palette returned by
/// `dynamic_color`. Since 2.1.0 that package returns the ColorScheme type of
/// the standalone `material_ui` package, which is a different class from
/// `flutter/material.dart`'s, so every role is copied across one by one.
/// Typed `dynamic` so no extra package has to be imported.
ColorScheme adoptSystemScheme(dynamic s) {
  return ColorScheme(
    brightness: s.brightness as Brightness,
    primary: s.primary as Color,
    onPrimary: s.onPrimary as Color,
    primaryContainer: s.primaryContainer as Color,
    onPrimaryContainer: s.onPrimaryContainer as Color,
    primaryFixed: s.primaryFixed as Color,
    primaryFixedDim: s.primaryFixedDim as Color,
    onPrimaryFixed: s.onPrimaryFixed as Color,
    onPrimaryFixedVariant: s.onPrimaryFixedVariant as Color,
    secondary: s.secondary as Color,
    onSecondary: s.onSecondary as Color,
    secondaryContainer: s.secondaryContainer as Color,
    onSecondaryContainer: s.onSecondaryContainer as Color,
    secondaryFixed: s.secondaryFixed as Color,
    secondaryFixedDim: s.secondaryFixedDim as Color,
    onSecondaryFixed: s.onSecondaryFixed as Color,
    onSecondaryFixedVariant: s.onSecondaryFixedVariant as Color,
    tertiary: s.tertiary as Color,
    onTertiary: s.onTertiary as Color,
    tertiaryContainer: s.tertiaryContainer as Color,
    onTertiaryContainer: s.onTertiaryContainer as Color,
    tertiaryFixed: s.tertiaryFixed as Color,
    tertiaryFixedDim: s.tertiaryFixedDim as Color,
    onTertiaryFixed: s.onTertiaryFixed as Color,
    onTertiaryFixedVariant: s.onTertiaryFixedVariant as Color,
    error: s.error as Color,
    onError: s.onError as Color,
    errorContainer: s.errorContainer as Color,
    onErrorContainer: s.onErrorContainer as Color,
    surface: s.surface as Color,
    onSurface: s.onSurface as Color,
    surfaceDim: s.surfaceDim as Color,
    surfaceBright: s.surfaceBright as Color,
    surfaceContainerLowest: s.surfaceContainerLowest as Color,
    surfaceContainerLow: s.surfaceContainerLow as Color,
    surfaceContainer: s.surfaceContainer as Color,
    surfaceContainerHigh: s.surfaceContainerHigh as Color,
    surfaceContainerHighest: s.surfaceContainerHighest as Color,
    onSurfaceVariant: s.onSurfaceVariant as Color,
    outline: s.outline as Color,
    outlineVariant: s.outlineVariant as Color,
    shadow: s.shadow as Color,
    scrim: s.scrim as Color,
    inverseSurface: s.inverseSurface as Color,
    onInverseSurface: s.onInverseSurface as Color,
    inversePrimary: s.inversePrimary as Color,
    surfaceTint: s.surfaceTint as Color,
  );
}

final _schemeCache = <(int, Brightness), ColorScheme>{};

/// Colour scheme generated from a cover seed, memoised (HCT is not free).
ColorScheme schemeFromSeed(int seed, Brightness brightness) {
  return _schemeCache.putIfAbsent(
    (seed, brightness),
    () => ColorScheme.fromSeed(seedColor: Color(seed), brightness: brightness),
  );
}
