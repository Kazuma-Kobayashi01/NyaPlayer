import 'package:drift/drift.dart';
import 'package:nyaplayer/core/log.dart';

/// Full-text index over title / artist / album (LIB-09, TECH_SPEC §9).
///
/// An FTS5 table with the `trigram` tokenizer finds any substring of three or
/// more characters, which is what Chinese and Japanese text needs (no word
/// boundaries). It is an external-content table: it stores only the index and
/// reads the text back from `tracks`, kept in step by triggers.
///
/// Created with plain SQL rather than as a drift table, so the generated
/// schema does not know about it; `ensureSearchIndex` is idempotent.
const _statements = <String>[
  '''
CREATE VIRTUAL TABLE IF NOT EXISTS track_fts USING fts5(
  title, artist, album,
  content='tracks', content_rowid='id', tokenize='trigram'
)''',
  '''
CREATE TRIGGER IF NOT EXISTS track_fts_ai AFTER INSERT ON tracks BEGIN
  INSERT INTO track_fts(rowid, title, artist, album)
  VALUES (new.id, new.title, new.artist, new.album);
END''',
  '''
CREATE TRIGGER IF NOT EXISTS track_fts_ad AFTER DELETE ON tracks BEGIN
  INSERT INTO track_fts(track_fts, rowid, title, artist, album)
  VALUES ('delete', old.id, old.title, old.artist, old.album);
END''',
  '''
CREATE TRIGGER IF NOT EXISTS track_fts_au AFTER UPDATE OF title, artist, album
ON tracks BEGIN
  INSERT INTO track_fts(track_fts, rowid, title, artist, album)
  VALUES ('delete', old.id, old.title, old.artist, old.album);
  INSERT INTO track_fts(rowid, title, artist, album)
  VALUES (new.id, new.title, new.artist, new.album);
END''',
];

/// Creates the index and its triggers when missing and fills it from the
/// existing tracks. Returns false (and leaves search to the slower `LIKE`
/// fallback) if this SQLite has no FTS5 or no trigram tokenizer.
Future<bool> ensureSearchIndex(DatabaseConnectionUser db) async {
  try {
    final existed = await _hasIndex(db);
    for (final sql in _statements) {
      await db.customStatement(sql);
    }
    if (!existed) {
      await db.customStatement(
        "INSERT INTO track_fts(track_fts) VALUES('rebuild')",
      );
    }
    return true;
  } catch (e) {
    Log.w('Search', 'FTS5 trigram index unavailable, using LIKE: $e');
    return false;
  }
}

Future<bool> _hasIndex(DatabaseConnectionUser db) async {
  final rows = await db
      .customSelect("SELECT 1 FROM sqlite_master WHERE name = 'track_fts'")
      .get();
  return rows.isNotEmpty;
}

/// Ids of tracks whose title, artist or album contains [query] (case
/// insensitive). Queries of three or more characters use the index; shorter
/// ones (a two-character song title is common) scan with `LIKE`.
Future<List<int>> searchTrackIds(
  DatabaseConnectionUser db,
  String query, {
  required bool indexed,
}) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final useIndex = indexed && q.runes.length >= 3;
  final rows = useIndex
      ? await db
            .customSelect(
              'SELECT rowid AS id FROM track_fts WHERE track_fts MATCH ?',
              variables: [Variable<String>(_phrase(q))],
            )
            .get()
      : await db
            .customSelect(
              r"SELECT id FROM tracks WHERE title LIKE ?1 ESCAPE '\' "
              r"OR artist LIKE ?1 ESCAPE '\' OR album LIKE ?1 ESCAPE '\'",
              variables: [Variable<String>('%${_likeEscape(q)}%')],
            )
            .get();
  return [for (final r in rows) r.read<int>('id')];
}

/// An FTS5 phrase: wrapped in quotes with inner quotes doubled, so operators
/// and punctuation in what the user typed are plain text.
String _phrase(String q) => '"${q.replaceAll('"', '""')}"';

String _likeEscape(String q) =>
    q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
