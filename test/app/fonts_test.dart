import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';

/// The resolved theme a widget sees (locale-specific text geometry applied).
Future<ThemeData> _resolve(
  WidgetTester tester, {
  required AppFont font,
  required bool bundled,
  Locale locale = const Locale('en'),
}) async {
  late ThemeData resolved;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: buildTheme(
        ColorScheme.fromSeed(seedColor: Colors.teal),
        font: font,
        bundledFonts: bundled,
      ),
      home: Builder(
        builder: (context) {
          resolved = Theme.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // MaterialApp animates theme changes; wait for the end value.
  await tester.pumpAndSettle();
  return resolved;
}

void main() {
  group('font plan', () {
    test('bundled sans is HarmonyOS Sans with no size or weight change', () {
      final plan = fontPlanFor(AppFont.sans, bundled: true);
      expect(plan.family, bundledSansFamily);
      expect(plan.sizeFactor, 1);
      expect(plan.heavier, isFalse);
    });

    test(
      'bundled serif is EB Garamond, then Noto Serif SC, larger and heavier',
      () {
        final plan = fontPlanFor(AppFont.serif, bundled: true);
        expect(plan.family, bundledSerifFamily);
        expect(plan.fallback, [bundledSerifCjkFamily]);
        expect(plan.sizeFactor, greaterThan(1));
        expect(plan.heavier, isTrue);
      },
    );

    test('with bundled fonts off the system setup is used', () {
      final sans = fontPlanFor(AppFont.sans, bundled: false);
      expect(sans.family, isNull);
      expect(sans.sizeFactor, 1);
      final serif = fontPlanFor(AppFont.serif, bundled: false);
      expect(serif.family, isNot(bundledSerifFamily));
      expect(serif.family, isNotNull);
      expect(serif.fallback, isNot(contains(bundledSerifCjkFamily)));
      expect(serif.heavier, isFalse);
      expect(serif.sizeFactor, 1);
    });
  });

  group('resolved theme', () {
    testWidgets('bundled sans text uses HarmonyOS Sans', (tester) async {
      final theme = await _resolve(tester, font: AppFont.sans, bundled: true);
      for (final style in [
        theme.textTheme.bodyLarge!,
        theme.textTheme.titleLarge!,
        theme.textTheme.labelSmall!,
      ]) {
        expect(style.fontFamily, bundledSansFamily);
      }
    });

    testWidgets(
      'bundled serif is bigger and a step heavier than bundled sans',
      (tester) async {
        final sans = await _resolve(tester, font: AppFont.sans, bundled: true);
        final serif = await _resolve(
          tester,
          font: AppFont.serif,
          bundled: true,
        );
        final tuning = serif.extension<FontTuning>()!;
        expect(tuning.sizeFactor, bundledSerifSizeFactor);
        expect(sans.extension<FontTuning>()!.sizeFactor, 1);

        for (final pick in <TextStyle Function(TextTheme)>[
          (t) => t.bodyLarge!,
          (t) => t.bodyMedium!,
          (t) => t.titleLarge!,
          (t) => t.labelMedium!,
        ]) {
          final a = pick(sans.textTheme);
          final b = pick(serif.textTheme);
          expect(b.fontFamily, bundledSerifFamily);
          expect(b.fontFamilyFallback, contains(bundledSerifCjkFamily));
          expect(b.fontSize!, greaterThan(a.fontSize!));
          expect(
            b.fontWeight!.value,
            a.fontWeight!.value + 100,
            reason: 'one weight step heavier',
          );
        }
      },
    );

    testWidgets('the global size reduction still applies', (tester) async {
      final plain = await _resolve(tester, font: AppFont.sans, bundled: false);
      // Material's bodyLarge is 16; the app takes 1pt off.
      expect(plain.textTheme.bodyLarge!.fontSize, 15);
    });

    testWidgets('the same applies to Chinese text geometry', (tester) async {
      final serif = await _resolve(
        tester,
        font: AppFont.serif,
        bundled: true,
        locale: const Locale('zh'),
      );
      expect(serif.textTheme.bodyLarge!.fontFamily, bundledSerifFamily);
      expect(serif.textTheme.bodyLarge!.fontFamilyFallback, [
        bundledSerifCjkFamily,
      ]);
    });

    testWidgets('bundled fonts off: no bundled family anywhere', (
      tester,
    ) async {
      for (final font in AppFont.values) {
        final theme = await _resolve(tester, font: font, bundled: false);
        final family = theme.textTheme.bodyLarge!.fontFamily;
        expect(family, isNot(anyOf(bundledSansFamily, bundledSerifFamily)));
        expect(theme.extension<FontTuning>()!.sizeFactor, 1);
      }
    });
  });

  group('the setting', () {
    test('defaults to using the bundled fonts', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(themeSettingsProvider).useBundledFonts, isTrue);
    });

    test(
      'is remembered and an old install without the key gets the default',
      () {
        final store = MemorySettingsStore();
        ProviderContainer container() {
          final c = ProviderContainer(
            overrides: [settingsStoreProvider.overrideWithValue(store)],
          );
          addTearDown(c.dispose);
          return c;
        }

        expect(container().read(themeSettingsProvider).useBundledFonts, isTrue);
        expect(store.get('theme.bundledFonts'), isNull);

        container()
            .read(themeSettingsProvider.notifier)
            .setUseBundledFonts(false);
        expect(store.get('theme.bundledFonts'), 'false');
        expect(
          container().read(themeSettingsProvider).useBundledFonts,
          isFalse,
        );

        container()
            .read(themeSettingsProvider.notifier)
            .setUseBundledFonts(true);
        expect(container().read(themeSettingsProvider).useBundledFonts, isTrue);
      },
    );
  });

  group('bundled files', () {
    const fontFiles = [
      'HarmonyOS_Sans_SC_Regular.ttf',
      'HarmonyOS_Sans_SC_Medium.ttf',
      'HarmonyOS_Sans_SC_Bold.ttf',
      'EBGaramond-400.ttf',
      'EBGaramond-500.ttf',
      'EBGaramond-600.ttf',
      'EBGaramond-700.ttf',
      'NotoSerifSC-500.ttf',
      'NotoSerifSC-700.ttf',
    ];

    test('every font file is in the asset bundle and non-trivial', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final name in fontFiles) {
        final data = await rootBundle.load('assets/fonts/$name');
        expect(data.lengthInBytes, greaterThan(100000), reason: name);
        // TrueType magic number.
        expect(data.getUint32(0), 0x00010000, reason: name);
      }
    });

    test('licence texts travel with the fonts', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final harmony = await rootBundle.loadString(
        'assets/fonts/licenses/HarmonyOS-Sans.txt',
      );
      expect(harmony, contains('HarmonyOS Sans Fonts License Agreement'));
      for (final name in ['EB-Garamond-OFL.txt', 'Noto-Serif-SC-OFL.txt']) {
        final text = await rootBundle.loadString('assets/fonts/licenses/$name');
        expect(text, contains('SIL OPEN FONT LICENSE'), reason: name);
      }
    });
  });
}
