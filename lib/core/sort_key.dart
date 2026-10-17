import 'package:nyaplayer/core/pinyin_table.dart';

const _hanFirst = 0x4E00;
const _hanLast = 0x9FFF;

/// Toneless pinyin of a CJK ideograph, or null if it has no reading.
String? pinyinOf(int codePoint) {
  if (codePoint < _hanFirst || codePoint > _hanLast) return null;
  final at = (codePoint - _hanFirst) * 2;
  final v =
      ((pinyinCodes.codeUnitAt(at) - 48) << 6) |
      (pinyinCodes.codeUnitAt(at + 1) - 48);
  return v == 0 ? null : pinyinSyllables[v - 1];
}

/// Folds full-width ASCII (U+FF01..U+FF5E) to its ASCII form.
int _fold(int rune) {
  if (rune >= 0xFF01 && rune <= 0xFF5E) return rune - 0xFEE0;
  if (rune == 0x3000) return 0x20;
  return rune;
}

bool _isDigit(int r) => r >= 0x30 && r <= 0x39;
bool _isLatin(int r) => (r >= 0x61 && r <= 0x7A) || (r >= 0x41 && r <= 0x5A);

/// Sort key for names (TECH_SPEC §7.2): case-insensitive, leading "The "
/// ignored, Chinese ordered by pinyin and mixed freely with Latin letters
/// (so "CATHY" < "曾经" < "CheerS"). Digits come first, other symbols last.
///
/// Characters with several readings use their most common one.
String sortKey(String s) {
  var text = s.trim();
  if (text.length > 4 && text.substring(0, 4).toLowerCase() == 'the ') {
    text = text.substring(4);
  }
  final body = StringBuffer();
  int? first;
  for (final raw in text.runes) {
    final r = _fold(raw);
    final han = pinyinOf(r);
    first ??= han != null ? 0x61 : r;
    if (han != null) {
      body
        ..write(han)
        ..write(' ');
    } else if (_isLatin(r)) {
      body.writeCharCode(r | 0x20); // lower-case
    } else {
      body.writeCharCode(r);
    }
  }
  final rank = first == null
      ? 2
      : _isDigit(first)
      ? 0
      : _isLatin(first)
      ? 1
      : 2;
  return '$rank$body';
}

int compareNames(String a, String b) => sortKey(a).compareTo(sortKey(b));

/// Section letter for index bars: 'A'..'Z', '0' for digits, '#' for the rest.
String indexLetter(String s) {
  final key = sortKey(s);
  if (key.length < 2) return '#';
  switch (key[0]) {
    case '0':
      return '0';
    case '1':
      return key[1].toUpperCase();
    default:
      return '#';
  }
}
