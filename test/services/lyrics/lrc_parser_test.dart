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
}
