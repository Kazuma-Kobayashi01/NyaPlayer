import 'package:path/path.dart' as p;

/// Trim, fold full-width ASCII, lower-case and collapse whitespace
/// (TECH_SPEC §7.2; an NFKC approximation that needs no dependency).
String normalizeKey(String s) {
  final out = StringBuffer();
  var pendingSpace = false;
  for (final raw in s.trim().runes) {
    var r = raw;
    if (r >= 0xFF01 && r <= 0xFF5E) r -= 0xFEE0;
    if (r == 0x3000) r = 0x20;
    final isSpace = r == 0x20 || r == 0x09 || r == 0x0A || r == 0x0D;
    if (isSpace) {
      pendingSpace = out.isNotEmpty;
      continue;
    }
    if (pendingSpace) out.write(' ');
    pendingSpace = false;
    out.write(String.fromCharCode(r).toLowerCase());
  }
  return out.toString();
}

/// Album grouping key (LIB-10).
///
/// * With an Album Artist tag: that artist + album title, wherever the files
///   are, so a compilation or a multi-disc set stays together.
/// * Without it the per-track artist is *not* used (features, collaborations
///   and "A/B" artists would split one album): the folder + album title is.
/// * Without an album title the folder alone is the album, so untagged folders
///   can still be browsed as albums.
String albumKeyFor({required String path, String? album, String? albumArtist}) {
  final title = (album ?? '').trim();
  final dir = p.dirname(path);
  if (title.isEmpty) return 'dir\u0000$dir';
  final owner = (albumArtist ?? '').trim();
  if (owner.isEmpty) return 'dir\u0000$dir\u0000${normalizeKey(title)}';
  return '${normalizeKey(owner)}\u0000${normalizeKey(title)}';
}

/// Placeholder colour seed per album (stable FNV-1a hash).
int colorSeedFor(String key) {
  var h = 0x811C9DC5;
  for (final unit in key.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return 0xFF000000 | (h & 0x00FFFFFF);
}
