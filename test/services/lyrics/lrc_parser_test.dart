import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/services/lyrics/lrc_parser.dart';

void main() {
  group('time tags', () {
    test('parses mm:ss, mm:ss.x, mm:ss.xx, mm:ss.xxx and mm:ss:xx', () {
      final l = LrcParser.parse(
        '[00:01]a\n[00:02.5]b\n[00:03.25]c\n[00:04.125]d\n[00:05:50]e',
      );
      expect(l.synced, isTrue);
      expect(l.lines.map((e) => e.start.inMilliseconds), [
        1000,
        2500,
        3250,
        4125,
        5500,
      ]);
    });

    test('minutes may exceed 99', () {
      final l = LrcParser.parse('[100:00.00]late');
      expect(l.lines.single.start, const Duration(minutes: 100));
    });

    test('one line with several timestamps expands and sorts', () {
      final l = LrcParser.parse('[00:30.00][00:10.00]chorus\n[00:20.00]verse');
      expect(l.lines.map((e) => e.text), ['chorus', 'verse', 'chorus']);
      expect(l.lines.map((e) => e.start.inSeconds), [10, 20, 30]);
    });

    test('strips BOM and handles CRLF', () {
      final l = LrcParser.parse('﻿[00:01.00]a\r\n[00:02.00]b\r\n');
      expect(l.lines.map((e) => e.text), ['a', 'b']);
    });
  });

  group('metadata', () {
    test('reads ti/ar/al/by and keeps them out of the lines', () {
      final l = LrcParser.parse(
        '[ti:Song]\n[ar:Artist]\n[al:Album]\n[by:me]\n[00:01.00]x',
      );
      expect(
        (l.title, l.artist, l.album, l.by),
        ('Song', 'Artist', 'Album', 'me'),
      );
      expect(l.lines, hasLength(1));
    });

    test('positive offset makes lyrics appear earlier', () {
      final l = LrcParser.parse('[offset:500]\n[00:10.00]x');
      expect(l.lines.single.start, const Duration(milliseconds: 9500));
    });

    test('negative offset delays lyrics and result never goes below zero', () {
      final l = LrcParser.parse('[offset:-1000]\n[00:00.50]a\n[00:05.00]b');
      expect(l.lines[0].start, const Duration(milliseconds: 1500));
      expect(l.lines[1].start, const Duration(seconds: 6));
      final early = LrcParser.parse('[offset:5000]\n[00:01.00]a');
      expect(early.lines.single.start, Duration.zero);
    });
  });

  group('text handling', () {
    test('whitespace-only lines become interludes', () {
      final l = LrcParser.parse('[00:01.00]a\n[00:05.00]   \n[00:09.00]b');
      expect(l.lines[1].isInterlude, isTrue);
    });

    test('enhanced word tags are stripped', () {
      final l = LrcParser.parse('[00:01.00]<00:01.00>he<00:01.50>llo');
      expect(l.lines.single.text, 'hello');
    });

    test('plain text without timestamps is unsynced', () {
      final l = LrcParser.parse('\nline one\n\nline two\n');
      expect(l.synced, isFalse);
      expect(l.lines.map((e) => e.text), ['line one', '', 'line two']);
      expect(l.indexAt(const Duration(seconds: 5)), -1);
    });

    test('empty input gives empty lyrics', () {
      expect(LrcParser.parse('').isEmpty, isTrue);
    });
  });

  group('bilingual: same timestamp, original first', () {
    test('second line at the same time is the translation', () {
      final l = LrcParser.parse('[00:01.00]hello\n[00:01.00]你好\n[00:05.00]bye');
      expect(l.lines, hasLength(2));
      expect(l.lines[0].text, 'hello');
      expect(l.lines[0].translation, '你好');
      expect(l.lines[1].translation, isNull);
    });

    test('blank line sharing a timestamp does not become a translation', () {
      final l = LrcParser.parse('[00:01.00]   \n[00:01.00]title\n[00:05.00]x');
      expect(l.lines.first.text, 'title');
      expect(l.lines.first.translation, isNull);
    });
  });

  group('indexAt', () {
    final l = LrcParser.parse('[00:05.00]a\n[00:10.00]b\n[00:15.00]c');

    test('is -1 before the first line', () {
      expect(l.indexAt(const Duration(seconds: 2)), -1);
    });

    test('finds the last line that has started', () {
      expect(l.indexAt(const Duration(seconds: 5)), 0);
      expect(l.indexAt(const Duration(milliseconds: 9999)), 0);
      expect(l.indexAt(const Duration(seconds: 10)), 1);
      expect(l.indexAt(const Duration(minutes: 5)), 2);
    });
  });

  group('inline and continuation translations', () {
    final separators = [
      '\u2009',
      '\u2003',
      '\u3000',
      '\u00a0',
      '\t',
      '  ',
      '//',
      ' | ',
      '｜',
      ' / ',
      r'\n',
      '<br>',
      '<BR />',
    ];
    for (var i = 0; i < separators.length; i++) {
      test('inline delimiter $i separates English and Chinese', () {
        final l = LrcParser.parse(
          '[00:01.25]A lantern in the snow${separators[i]}雪中的灯',
        );
        expect(l.lines.single.text, 'A lantern in the snow');
        expect(l.lines.single.translation, '雪中的灯');
        expect(l.lines.single.start, const Duration(milliseconds: 1250));
      });
    }

    test(
      'thin-space Japanese and Chinese format preserves Japanese spaces',
      () {
        final l = LrcParser.parse('[00:01]そらのうた きみのこえ\u2009天空的歌 你的声音');
        expect(l.lines.single.text, 'そらのうた きみのこえ');
        expect(l.lines.single.translation, '天空的歌 你的声音');
      },
    );

    test(
      'does not split ordinary spaces, same-language fragments or credits',
      () {
        final originals = [
          'A lantern in the snow',
          'A lantern  in the snow',
          'そらのうた\u3000きみのこえ',
          '海风 | 星光',
          '制作 Producer：someone\u2009某某',
          '歌手/person',
          'A voice (live)',
          'http://example.test/path',
        ];
        final l = LrcParser.parse(
          [
            for (var i = 0; i < originals.length; i++)
              '[00:${i + 1}]${originals[i]}',
          ].join('\n'),
        );
        expect(l.lines.map((l) => l.text), originals);
        expect(l.lines.every((l) => l.translation == null), isTrue);
      },
    );

    test(
      'translation can follow a multi-tag line without its own timestamp',
      () {
        final l = LrcParser.parse('[00:10][00:30]A lantern\n一盏灯\n[00:50]Next');
        expect(l.lines.map((l) => l.start.inSeconds), [10, 30, 50]);
        expect(l.lines.take(2).map((l) => l.translation), ['一盏灯', '一盏灯']);
      },
    );

    test('same-language untimed text is not guessed to be a translation', () {
      final l = LrcParser.parse('[00:10]A lantern\nA note\n[00:20]Next');
      expect(l.lines.first.translation, isNull);
    });

    test(
      'mixed inline and repeated timestamp translations are deduplicated',
      () {
        final l = LrcParser.parse(
          '[00:01]A lantern\u2009一盏灯\n[00:01]一盏灯\n[00:01]A lantern\u2009一盏灯',
        );
        expect(l.lines.single.text, 'A lantern');
        expect(l.lines.single.translation, '一盏灯');
      },
    );

    test('plain text supports inline translation and Chinese to English', () {
      final l = LrcParser.parse('一盏灯 | A lantern\n下一段');
      expect(l.synced, isFalse);
      expect(l.lines.first.text, '一盏灯');
      expect(l.lines.first.translation, 'A lantern');
      expect(l.lines.last.translation, isNull);
    });

    test('English word gaps before the actual thin space are retained', () {
      final l = LrcParser.parse('[00:01]A lantern  in the snow\u2009雪中的灯');
      expect(l.lines.single.text, 'A lantern  in the snow');
      expect(l.lines.single.translation, '雪中的灯');
    });
  });
}
