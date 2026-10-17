import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';

/// Serif text uses each platform's own serif faces (nothing is bundled):
/// Times New Roman + Songti SC / Mincho on macOS, the system serif + Noto
/// Serif CJK on Android.
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
ThemeData buildTheme(ColorScheme scheme, {AppFont font = AppFont.sans}) {
  final serif = font == AppFont.serif;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: serif ? _serifFamily : null,
    fontFamilyFallback: serif ? _serifFallback : null,
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

/// Re-themes [child] with the colours of the current cover and animates the
/// change when the track switches (UI-04, TECH_SPEC §10.1).
class CoverTheme extends StatelessWidget {
  const CoverTheme({
    super.key,
    required this.seed,
    required this.child,
    this.font = AppFont.sans,
  });

  final int? seed;
  final AppFont font;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final seed = this.seed;
    if (seed == null) return child;
    return AnimatedTheme(
      data: buildTheme(schemeFromSeed(seed, base.brightness), font: font),
      duration: Durations.medium4,
      curve: Easing.emphasizedDecelerate,
      child: child,
    );
  }
}
