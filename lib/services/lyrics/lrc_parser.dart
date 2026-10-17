import 'package:nyaplayer/domain/models.dart';

/// Pure-Dart LRC parser. See TECH_SPEC §8.2.
///
/// Bilingual lyrics follow the usual convention: lines sharing one timestamp
/// are original + translation, first line first. Files that list them the
/// other way round are treated as bad data, not special-cased.
class LrcParser {
  const LrcParser._();

  static final _timeTag = RegExp(r'\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final _leadingTags = RegExp(
    r'^\s*((?:\[\d+:\d{1,2}(?:[.:]\d{1,3})?\])+)(.*)$',
  );
  static final _metaTag = RegExp(r'^\s*\[([A-Za-z]+):(.*)\]\s*$');
  static final _enhancedTag = RegExp(r'<\d+:\d{1,2}(?:[.:]\d{1,3})?>');

  static Lyrics parse(String raw) {
    final source = raw.startsWith('﻿') ? raw.substring(1) : raw;
    final rows = source.split(RegExp(r'\r\n|\n|\r'));

    final meta = <String, String>{};
    final entries = <_Entry>[];
    final plain = <String>[];
    var order = 0;

    for (final row in rows) {
      final m = _leadingTags.firstMatch(row);
      if (m != null) {
        final text = m.group(2)!.replaceAll(_enhancedTag, '').trim();
        for (final t in _timeTag.allMatches(m.group(1)!)) {
          entries.add(_Entry(_toDuration(t), text, order++));
        }
        continue;
      }
      final mm = _metaTag.firstMatch(row);
      if (mm != null) {
        meta[mm.group(1)!.toLowerCase()] = mm.group(2)!.trim();
        continue;
      }
      plain.add(row.replaceAll(_enhancedTag, '').trimRight());
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
      } else if (texts.length == 1) {
        lines.add(LyricLine(start: time, text: texts.first));
      } else {
        lines.add(
          LyricLine(
            start: time,
            text: texts.first,
            translation: texts.sublist(1).join('\n'),
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
      lines: [
        for (final r in rows.sublist(start, end))
          LyricLine(start: Duration.zero, text: r.trim()),
      ],
      synced: false,
      title: meta['ti'],
      artist: meta['ar'],
      album: meta['al'],
      by: meta['by'],
    );
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
