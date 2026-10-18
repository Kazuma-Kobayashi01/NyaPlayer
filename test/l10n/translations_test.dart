import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/l10n/language_options.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/app_$name.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Placeholder names used by a message, e.g. {count}, {name}.
Set<String> _placeholders(String message) => {
  for (final m in RegExp(r'\{(\w+)[,}]').allMatches(message)) m.group(1)!,
};

void main() {
  // zh is the template; every other file must keep up with it, because gen-l10n
  // silently falls back to the template (Chinese) for a missing key.
  final template = _arb('zh');
  final templateKeys = _keys(template)..remove('@@locale');

  // Languages that must translate everything. zh_Hant_HK is derived from
  // plain zh by gen-l10n (not from zh_Hant), so it has to be complete too.
  const complete = [
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'ru',
    'zh_Hant',
    'zh_Hant_HK',
  ];

  for (final name in complete) {
    test(
      'app_$name.arb translates every message, with the same placeholders',
      () {
        final arb = _arb(name);
        final keys = _keys(arb)..remove('@@locale');
        expect(
          templateKeys.difference(keys),
          isEmpty,
          reason: 'missing in $name',
        );
        expect(
          keys.difference(templateKeys),
          isEmpty,
          reason: 'unknown in $name',
        );
        for (final key in templateKeys) {
          final text = arb[key] as String;
          expect(text.trim(), isNotEmpty, reason: '$name/$key is blank');
          expect(
            _placeholders(text),
            _placeholders(template[key] as String),
            reason: '$name/$key placeholders',
          );
          expect(
            '{'.allMatches(text).length,
            '}'.allMatches(text).length,
            reason: '$name/$key braces',
          );
        }
      },
    );
  }

  test('app_en_GB.arb only overrides existing messages', () {
    final arb = _arb('en_GB');
    expect(_keys(arb)..remove('@@locale'), isNotEmpty);
    expect((_keys(arb)..remove('@@locale')).difference(templateKeys), isEmpty);
  });

  test('every supported locale can be chosen in the language list', () {
    // zh_Hant has no country: it is reached through Taiwan (and Hong Kong has
    // its own file).
    for (final locale in AppLocalizations.supportedLocales) {
      final reachable = languageOptions.any(
        (o) =>
            o.locale.languageCode == locale.languageCode &&
            o.locale.scriptCode == locale.scriptCode &&
            (locale.countryCode == null ||
                o.locale.countryCode == locale.countryCode),
      );
      expect(reachable, isTrue, reason: '$locale is not in the language list');
    }
  });

  test('every language in the list has a translation to load', () {
    for (final option in languageOptions) {
      expect(
        () => lookupAppLocalizations(option.locale),
        returnsNormally,
        reason: option.label,
      );
    }
  });

  group('loaded texts', () {
    AppLocalizations of(Locale l) => lookupAppLocalizations(l);

    test(
      'every supported locale builds every message, placeholders filled',
      () {
        for (final locale in AppLocalizations.supportedLocales) {
          final l = of(locale);
          final texts = <String>[
            l.songCount(1),
            l.songCount(2),
            l.songCount(5),
            l.songCount(21),
            l.albumCount(3),
            l.playlistTracks(7),
            l.discLabel(2),
            l.bitDepthValue(24),
            l.bitrateValue(320),
            l.lyricsFontSizeRange(10, 40),
            l.addedToPlaylist('Mix'),
            l.deletePlaylistBody('Mix'),
            l.scanReading(3, 9),
            l.scanDoneWithErrors(1),
            l.scanDoneWithErrors(4),
            l.navSongs,
            l.settingsLanguage,
            l.musicPermissionBody,
          ];
          for (final t in texts) {
            expect(t.trim(), isNotEmpty, reason: '$locale');
            expect(t, isNot(contains('{')), reason: '$locale: "$t"');
          }
          expect(l.addedToPlaylist('Mix'), contains('Mix'), reason: '$locale');
          expect(l.scanReading(3, 9), allOf(contains('3'), contains('9')));
        }
      },
    );

    test('each language really is in that language', () {
      expect(of(const Locale('de')).navSettings, 'Einstellungen');
      expect(of(const Locale('fr')).navSettings, 'Réglages');
      expect(of(const Locale('es')).navSettings, 'Ajustes');
      expect(of(const Locale('ja')).navSettings, '設定');
      expect(of(const Locale('ko')).navSettings, '설정');
      expect(of(const Locale('ru')).navSettings, 'Настройки');
      expect(of(const Locale('zh')).navSettings, '设置');
      expect(of(const Locale('en')).navSettings, 'Settings');
    });

    test('Russian plurals follow one / few / many', () {
      final ru = of(const Locale('ru'));
      expect(ru.songCount(1), '1 песня');
      expect(ru.songCount(2), '2 песни');
      expect(ru.songCount(5), '5 песен');
      expect(ru.songCount(21), '21 песня');
      expect(ru.songCount(12), '12 песен');
      expect(ru.scanDoneWithErrors(3), contains('3 файла'));
    });

    test('regional variants differ where the language does', () {
      const hans = Locale('zh');
      const tw = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      const hk = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      );
      // Taiwan resolves to the Traditional file (it has none of its own).
      expect(of(tw.copyWithoutCountry()).navPlaylists, '播放清單');
      expect(of(hk).navPlaylists, '播放列表');
      expect(of(hk).navFolders, '檔案夾');
      expect(of(tw.copyWithoutCountry()).navFolders, '資料夾');
      expect(of(hans).navFolders, '文件夹');
      // Traditional characters, not Simplified, in both.
      expect(of(hk).playAll, '播放全部');
      expect(of(hk).onboardingChoose, '選擇音樂檔案夾');
      expect(of(const Locale('en')).navFavorites, 'Favorites');
      expect(of(const Locale('en', 'GB')).navFavorites, 'Favourites');
      expect(
        of(const Locale('en', 'GB')).navSongs,
        'Songs',
        reason: 'untouched messages come from plain English',
      );
    });
  });
}

extension on Locale {
  Locale copyWithoutCountry() =>
      Locale.fromSubtags(languageCode: languageCode, scriptCode: scriptCode);
}
