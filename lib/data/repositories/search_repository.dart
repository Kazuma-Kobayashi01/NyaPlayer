import 'package:nyaplayer/data/db/app_database.dart' show AppDatabase;
import 'package:nyaplayer/data/db/search_index.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/domain/models.dart';

/// Track search backed by the FTS5 trigram index (LIB-09).
class SearchRepository {
  SearchRepository(this._db);

  final AppDatabase _db;

  /// Tracks of [library] matching [query], best matches first. Tracks the
  /// library hides (for instance under the minimum length) never show up.
  Future<List<Track>> tracks(Library library, String query) async {
    final ids = await searchTrackIds(_db, query, indexed: _db.searchIndexed);
    return rankSearchResults([
      for (final id in ids) ?library.trackById(id),
    ], query);
  }
}
