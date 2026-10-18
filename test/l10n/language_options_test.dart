import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/l10n/language_options.dart';

void main() {
  test('the list is the supported languages, sorted by English name', () {
    expect(
      [for (final o in languageOptions) o.label],
      [
        '简体中文（中国）', // Chinese (China)
        '繁體中文（香港）', // Chinese (Hong Kong)
        '繁體中文（台灣）', // Chinese (Taiwan)
        'English (UK)',
        'English (US)',
        'Français', // French
        'Deutsch', // German
        '日本語', // Japanese
        '한국어', // Korean
        'Русский', // Russian
        'Español', // Spanish
      ],
    );
  });

  test('ids are unique and never the system id', () {
    final ids = [for (final o in languageOptions) o.id];
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, isNot(contains(systemLanguageId)));
  });

  test('every option survives save and load', () {
    for (final option in languageOptions) {
      expect(idOfLocale(option.locale), option.id, reason: option.label);
      expect(localeOfId(option.id), option.locale, reason: option.label);
    }
    expect(idOfLocale(null), systemLanguageId);
    expect(localeOfId(systemLanguageId), isNull);
  });

  test('ids stored by older versions still work', () {
    expect(localeOfId('zh'), const Locale('zh'));
    expect(localeOfId('en'), const Locale('en'));
    expect(idOfLocale(const Locale('zh')), 'zh-CN');
    expect(idOfLocale(const Locale('en')), 'en-US');
  });

  test('unknown ids mean "follow the system"', () {
    expect(localeOfId(null), isNull);
    expect(localeOfId('klingon'), isNull);
    expect(localeOfId(''), isNull);
  });

  test('other spellings of a locale map to the nearest option', () {
    Locale tag(String lang, {String? script, String? country}) =>
        Locale.fromSubtags(
          languageCode: lang,
          scriptCode: script,
          countryCode: country,
        );
    expect(idOfLocale(tag('zh', script: 'Hans', country: 'CN')), 'zh-CN');
    expect(idOfLocale(tag('zh', country: 'CN')), 'zh-CN');
    expect(idOfLocale(tag('zh', script: 'Hant')), 'zh-TW');
    expect(idOfLocale(tag('zh', country: 'TW')), 'zh-TW');
    expect(idOfLocale(tag('zh', country: 'HK')), 'zh-HK');
    expect(idOfLocale(tag('zh', country: 'MO')), 'zh-TW');
    expect(idOfLocale(tag('en', country: 'AU')), 'en-US');
    expect(idOfLocale(tag('fr', country: 'CA')), 'fr');
    expect(idOfLocale(tag('pt')), systemLanguageId);
  });
}
