import 'package:nyaplayer/domain/models.dart';

/// Pure-Dart LRC parser. See TECH_SPEC §8.2.
///
/// Supports same-time rows and inline bilingual text. Inline splitting requires
/// a script change as well as a separator, so ordinary word spaces survive.
class LrcParser {
  const LrcParser._();

  static final _timeTag = RegExp(r'\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final _leadingTags = RegExp(
    r'^\s*((?:\[\d+:\d{1,2}(?:[.:]\d{1,3})?\])+)(.*)$',
  );
  static final _metaTag = RegExp(r'^\s*\[([A-Za-z]+):(.*)\]\s*$');
  static final _enhancedTag = RegExp(r'<\d+:\d{1,2}(?:[.:]\d{1,3})?>');
  static final _inlineSeparator = RegExp(
    r'\s*(?://|[|｜]|\\n|<br\s*/?>)\s*|[ \t]+/[ \t]+|[\t\u00a0\u2000-\u200a\u2028\u202f\u205f\u3000]+| {2,}',
    caseSensitive: false,
  );
  static final _han = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]');
  static final _kana = RegExp(r'[\u3041-\u3096\u30a1-\u30fa\uff66-\uff9d]');
  static final _latin = RegExp(r'[A-Za-z\u00c0-\u024f]');
  static final _script = RegExp(
    r'[A-Za-z\u00c0-\u024f\u3041-\u3096\u30a1-\u30fa\uff66-\uff9d\u3400-\u9fff\uf900-\ufaff]',
  );

  static Lyrics parse(String raw) {
    final source = raw.startsWith('﻿') ? raw.substring(1) : raw;
    final rows = source.split(RegExp(r'\r\n|\n|\r'));

    final meta = <String, String>{};
    final entries = <_Entry>[];
    final plain = <String>[];
    var order = 0;
    var previousTimes = <Duration>[];
    var previousText = '';

    for (final row in rows) {
      final m = _leadingTags.firstMatch(row);
      if (m != null) {
        final text = m.group(2)!.replaceAll(_enhancedTag, '').trim();
        previousTimes = [
          for (final t in _timeTag.allMatches(m.group(1)!)) _toDuration(t),
        ];
        previousText = text;
        for (final time in previousTimes) {
          entries.add(_Entry(time, text, order++));
        }
        continue;
      }
      final mm = _metaTag.firstMatch(row);
      if (mm != null) {
        meta[mm.group(1)!.toLowerCase()] = mm.group(2)!.trim();
        previousTimes = [];
        continue;
      }
      final text = row.replaceAll(_enhancedTag, '').trim();
      if (previousTimes.isNotEmpty &&
          _isTranslationPair(_splitInline(previousText).original, text)) {
        for (final time in previousTimes) {
          entries.add(_Entry(time, text, order++));
        }
      } else {
        plain.add(text);
      }
      previousTimes = [];
    }

    if (entries.isEmpty) return _plain(plain, meta);

    final offsetMs = int.tryParse(meta['offset'] ?? '') ?? 0;
    final shifted =
        [
          for (final e in entries)
            _Entry(
              _clampZero(e.time - Duration(milliseconds: offsetMs)),
              e.text,
              e.order,
            ),
        ]..sort((a, b) {
          final c = a.time.compareTo(b.time);
          return c != 0 ? c : a.order.compareTo(b.order);
        });

    final lines = <LyricLine>[];
    var i = 0;
    while (i < shifted.length) {
      var j = i;
      while (j < shifted.length && shifted[j].time == shifted[i].time) {
        j++;
      }
      final time = shifted[i].time;
      final texts = [
        for (var k = i; k < j; k++)
          if (shifted[k].text.isNotEmpty) shifted[k].text,
      ];
      i = j;

      if (texts.isEmpty) {
        lines.add(LyricLine(start: time, text: ''));
      } else {
        final first = _splitInline(texts.first);
        final translations = <String>{
          if (first.translation != null) first.translation!,
        };
        for (final text in texts.skip(1)) {
          final next = _splitInline(text);
          if (next.original != first.original) translations.add(next.original);
          if (next.translation != null) translations.add(next.translation!);
        }
        lines.add(
          LyricLine(
            start: time,
            text: first.original,
            translation: translations.isEmpty ? null : translations.join('\n'),
          ),
        );
      }
    }

    return Lyrics(
      lines: lines,
      synced: true,
      title: meta['ti'],
      artist: meta['ar'],
      album: meta['al'],
      by: meta['by'],
    );
  }

  static Lyrics _plain(List<String> rows, Map<String, String> meta) {
    var start = 0;
    var end = rows.length;
    while (start < end && rows[start].trim().isEmpty) {
      start++;
    }
    while (end > start && rows[end - 1].trim().isEmpty) {
      end--;
    }
    return Lyrics(
      lines: [for (final r in rows.sublist(start, end)) _plainLine(r.trim())],
      synced: false,
      title: meta['ti'],
      artist: meta['ar'],
      album: meta['al'],
      by: meta['by'],
    );
  }

  static ({String original, String? translation}) _splitInline(String text) {
    for (final delimiter in _inlineSeparator.allMatches(text)) {
      final original = text.substring(0, delimiter.start).trim();
      final translation = text.substring(delimiter.end).trim();
      if (_isTranslationPair(original, translation)) {
        return (original: original, translation: translation);
      }
    }
    return (original: text, translation: null);
  }

  static LyricLine _plainLine(String text) {
    final pair = _splitInline(text);
    return LyricLine(
      start: Duration.zero,
      text: pair.original,
      translation: pair.translation,
    );
  }

  static bool _isTranslationPair(String original, String translation) {
    if (original.isEmpty ||
        translation.isEmpty ||
        original.contains(RegExp('[:：]')) ||
        translation.contains(RegExp('[:：]'))) {
      return false;
    }
    final first = _script.firstMatch(translation)?.group(0) ?? '';
    final translatedHan = _han.hasMatch(first) && !_kana.hasMatch(translation);
    final translatedLatin =
        _latin.hasMatch(first) &&
        !_han.hasMatch(translation) &&
        !_kana.hasMatch(translation);
    if (_kana.hasMatch(original)) return translatedHan || translatedLatin;
    if (_latin.hasMatch(original) && !_han.hasMatch(original)) {
      return translatedHan ||
          (_kana.hasMatch(translation) && !_latin.hasMatch(first));
    }
    return _han.hasMatch(original) &&
        !_latin.hasMatch(original) &&
        translatedLatin;
  }

  static Duration _toDuration(RegExpMatch t) {
    final minutes = int.parse(t.group(1)!);
    final seconds = int.parse(t.group(2)!);
    final frac = t.group(3);
    var ms = 0;
    if (frac != null) {
      ms = int.parse(frac.padRight(3, '0'));
    }
    return Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
  }

  static Duration _clampZero(Duration d) => d.isNegative ? Duration.zero : d;
}

class _Entry {
  const _Entry(this.time, this.text, this.order);

  final Duration time;
  final String text;
  final int order;
}
