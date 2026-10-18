import 'package:flutter/widgets.dart';

/// A language the user can pick in settings (SET-01 "Language").
@immutable
class LanguageOption {
  const LanguageOption({
    required this.id,
    required this.locale,
    required this.label,
  });

  /// What is stored in settings.
  final String id;
  final Locale locale;

  /// The language's own name with the region in brackets, e.g.
  /// `English (US)`, `简体中文（中国）`. Never translated: a user who cannot
  /// read the current language must still find theirs.
  final String label;
}

const _hantTw = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'TW',
);
const _hantHk = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'HK',
);

/// Sorted by the English name of the language (Chinese, English, French,
/// German, Japanese, Korean, Russian, Spanish), regions alphabetically.
/// "Follow the system" is not in the list: it is `null` and is shown first.
const languageOptions = <LanguageOption>[
  LanguageOption(id: 'zh-CN', locale: Locale('zh'), label: '简体中文（中国）'),
  LanguageOption(id: 'zh-HK', locale: _hantHk, label: '繁體中文（香港）'),
  LanguageOption(id: 'zh-TW', locale: _hantTw, label: '繁體中文（台灣）'),
  LanguageOption(
    id: 'en-GB',
    locale: Locale('en', 'GB'),
    label: 'English (UK)',
  ),
  LanguageOption(id: 'en-US', locale: Locale('en'), label: 'English (US)'),
  LanguageOption(id: 'fr', locale: Locale('fr'), label: 'Français'),
  LanguageOption(id: 'de', locale: Locale('de'), label: 'Deutsch'),
  LanguageOption(id: 'ja', locale: Locale('ja'), label: '日本語'),
  LanguageOption(id: 'ko', locale: Locale('ko'), label: '한국어'),
  LanguageOption(id: 'ru', locale: Locale('ru'), label: 'Русский'),
  LanguageOption(id: 'es', locale: Locale('es'), label: 'Español'),
];

const systemLanguageId = 'system';

/// The option for a stored id. Ids written by older versions (`zh`, `en`)
/// still work; anything unknown means "follow the system".
LanguageOption? languageOptionOfId(String? id) {
  final fixed = switch (id) {
    'zh' => 'zh-CN',
    'en' => 'en-US',
    _ => id,
  };
  for (final option in languageOptions) {
    if (option.id == fixed) return option;
  }
  return null;
}

/// The option that best describes [locale] (`null` is the system option).
LanguageOption? languageOptionOfLocale(Locale? locale) {
  if (locale == null) return null;
  for (final option in languageOptions) {
    if (option.locale == locale) return option;
  }
  switch (locale.languageCode) {
    case 'zh':
      final traditional =
          locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      if (!traditional) return languageOptionOfId('zh-CN');
      return languageOptionOfId(locale.countryCode == 'HK' ? 'zh-HK' : 'zh-TW');
    case 'en':
      return languageOptionOfId(locale.countryCode == 'GB' ? 'en-GB' : 'en-US');
    default:
      return languageOptionOfId(locale.languageCode);
  }
}

String idOfLocale(Locale? locale) =>
    languageOptionOfLocale(locale)?.id ?? systemLanguageId;

Locale? localeOfId(String? id) => languageOptionOfId(id)?.locale;
