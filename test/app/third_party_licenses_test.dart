import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/theme/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the Rust crates linked into the app are all on the licence page',
    () async {
      final entries = await rustCrateLicenses().toList();
      final packages = entries.expand((e) => e.packages).toSet();
      // Spot checks across what the native library really pulls in.
      expect(packages.any((p) => p.startsWith('lofty ')), isTrue);
      expect(packages.any((p) => p.startsWith('symphonia ')), isTrue);
      expect(packages.any((p) => p.startsWith('flutter_rust_bridge ')), isTrue);
      for (final e in entries) {
        expect(e.paragraphs, isNotEmpty, reason: '${e.packages}');
      }
      // MPL-2.0 text travels with symphonia.
      final symphonia = entries.firstWhere(
        (e) => e.packages.any((p) => p.startsWith('symphonia ')),
      );
      expect(
        symphonia.paragraphs.map((p) => p.text).join('\n'),
        contains('Mozilla Public License'),
      );
    },
  );

  test('Media3 and the Hi-Res mark are listed', () async {
    final entries = await nativeLicenses().toList();
    expect(entries.expand((e) => e.packages), contains('Hi-Res Audio logo'));
    expect(
      entries.expand((e) => e.packages),
      contains('Apollo (AI super-resolution model)'),
    );
    expect(
      entries.expand((e) => e.packages),
      contains('AndroidX Media3 (ExoPlayer)'),
    );
  });
}
