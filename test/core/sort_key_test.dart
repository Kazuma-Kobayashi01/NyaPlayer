import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/core/sort_key.dart';

List<String> sorted(List<String> names) => [...names]..sort(compareNames);

void main() {
  group('pinyinOf', () {
    test('common characters', () {
      expect(pinyinOf('冰'.runes.first), 'bing');
      expect(pinyinOf('必'.runes.first), 'bi');
      expect(pinyinOf('步'.runes.first), 'bu');
      expect(pinyinOf('曾'.runes.first), 'ceng');
      expect(pinyinOf('華'.runes.first), 'hua'); // traditional form
    });

    test('non-han characters have no reading', () {
      expect(pinyinOf('a'.runes.first), isNull);
      expect(pinyinOf('あ'.runes.first), isNull);
    });
  });

  group('compareNames', () {
    test('Chinese by pinyin, mixed with English by letters', () {
      expect(sorted(['CheerS', '曾经的你', 'CATHY', '不羁的风', '步步高', '冰雨', '必杀技']), [
        '必杀技',
        '冰雨',
        '步步高',
        '不羁的风',
        'CATHY',
        '曾经的你',
        'CheerS',
      ]);
    });

    test('syllables compare one by one, not as a joined string', () {
      // "bu fen" < "bu shi"; and "ban" (one syllable) after "ba yue".
      expect(sorted(['不是', '不分']), ['不分', '不是']);
      expect(sorted(['半', '八月']), ['八月', '半']);
    });

    test('English is case-insensitive and ignores a leading "The "', () {
      expect(sorted(['banana', 'Apple', 'the Cat']), [
        'Apple',
        'banana',
        'the Cat',
      ]);
      expect(compareNames('The Beatles', 'Beach Boys'), greaterThan(0));
    });

    test('full-width letters sort like ASCII', () {
      expect(sorted(['Ｂob', 'alice']), ['alice', 'Ｂob']);
    });

    test('digits first, then letters, then symbols and kana', () {
      expect(sorted(['(live)', 'ひまわり', 'Zed', '9to5', '爱']), [
        '9to5',
        '爱',
        'Zed',
        '(live)',
        'ひまわり',
      ]);
    });

    test('empty names sort last', () {
      expect(sorted(['', 'a']), ['a', '']);
    });
  });

  group('indexLetter', () {
    test('uses the pinyin initial for Chinese', () {
      expect(indexLetter('冰雨'), 'B');
      expect(indexLetter('曾经'), 'C');
    });

    test('letters, digits and symbols', () {
      expect(indexLetter('cathy'), 'C');
      expect(indexLetter('7 Rings'), '0');
      expect(indexLetter('(live)'), '#');
      expect(indexLetter(''), '#');
    });
  });
}
