import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/core/library_keys.dart';

void main() {
  group('normalizeKey', () {
    test('trims, lower-cases and collapses whitespace', () {
      expect(normalizeKey('  The  Beatles '), 'the beatles');
    });

    test('folds full-width characters', () {
      expect(normalizeKey('ＡＢＣ　１２３'), 'abc 123');
    });

    test('leaves CJK text alone', () {
      expect(normalizeKey(' 打上花火 '), '打上花火');
    });
  });

  group('albumKeyFor (LIB-10)', () {
    test('an Album Artist tag groups across folders and ignores case', () {
      final a = albumKeyFor(
        path: '/m/cd1/1.flac',
        album: 'Hits',
        albumArtist: 'Various',
      );
      final b = albumKeyFor(
        path: '/m/cd2/2.flac',
        album: 'hits',
        albumArtist: 'various',
      );
      expect(a, b, reason: 'a compilation or multi-disc set stays together');
    });

    test('without the tag the track artist plays no part', () {
      // Collaboration albums: every track names different artists.
      final a = albumKeyFor(path: '/m/al/1.flac', album: 'Night');
      final b = albumKeyFor(path: '/m/al/2.flac', album: 'Night');
      expect(a, b);
    });

    test('without the tag, folders keep same-named albums apart', () {
      expect(
        albumKeyFor(path: '/m/a/1.flac', album: 'Greatest Hits'),
        isNot(albumKeyFor(path: '/m/b/1.flac', album: 'Greatest Hits')),
      );
    });

    test('a tagged and an untagged album with one title are different', () {
      expect(
        albumKeyFor(path: '/m/a/1.flac', album: 'X', albumArtist: 'Foo'),
        isNot(albumKeyFor(path: '/m/a/2.flac', album: 'X')),
      );
    });

    test('an untagged album groups by folder', () {
      final k1 = albumKeyFor(path: '/m/x/1.mp3');
      final k2 = albumKeyFor(path: '/m/x/2.mp3', album: '  ');
      final k3 = albumKeyFor(path: '/m/y/1.mp3');
      expect(k1, k2);
      expect(k1, isNot(k3));
    });
  });

  test('colorSeedFor is stable and opaque', () {
    expect(colorSeedFor('k'), colorSeedFor('k'));
    expect(colorSeedFor('k') >> 24, 0xFF);
  });
}
