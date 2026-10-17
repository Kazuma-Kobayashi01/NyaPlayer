import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';

/// Applies the cover-derived colours to [child] when the colour source is
/// "follow cover"; otherwise leaves the app theme untouched.
class PlayerThemeScope extends ConsumerWidget {
  const PlayerThemeScope({super.key, required this.seed, required this.child});

  final int? seed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    if (settings.source != ColorSource.cover) return child;
    return CoverTheme(seed: seed, font: settings.font, child: child);
  }
}
