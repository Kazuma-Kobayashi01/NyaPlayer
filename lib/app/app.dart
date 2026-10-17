import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/app/app_commands.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/app/window_chrome.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

class NyaPlayerApp extends ConsumerWidget {
  const NyaPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // The whole app follows the system palette unless a fixed colour is
        // chosen. Blurred artwork is independent of the control colours.
        final useSystem = settings.source != ColorSource.fixed;
        final light = useSystem && lightDynamic != null
            ? adoptSystemScheme(lightDynamic.harmonized())
            : ColorScheme.fromSeed(seedColor: settings.seed);
        final dark = useSystem && darkDynamic != null
            ? adoptSystemScheme(darkDynamic.harmonized())
            : ColorScheme.fromSeed(
                seedColor: settings.seed,
                brightness: Brightness.dark,
              );

        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(light, font: settings.font),
          darkTheme: buildTheme(dark, font: settings.font),
          themeMode: settings.mode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => TitlebarInset(
            child: AppCommands(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
