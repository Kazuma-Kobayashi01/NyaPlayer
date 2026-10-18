import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'eq_presets_seed.dart';
import 'search_index.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tracks,
    Albums,
    Artists,
    TrackArtists,
    LibraryRoots,
    Playlists,
    PlaylistItems,
    EqPresets,
    PlaybackState,
    Settings,
    ScanErrors,
    Favorites,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            // Application support, not the default documents folder (which
            // is the user's ~/Documents on macOS).
            driftDatabase(
              name: 'nyaplayer',
              native: const DriftNativeOptions(
                databaseDirectory: getApplicationSupportDirectory,
              ),
            ),
      );

  /// Bump together with a step in [migration]. Never drop and recreate the
  /// database: it holds playlists (TECH_SPEC §9).
  @override
  int get schemaVersion => 3;

  /// Whether the FTS5 trigram search index exists (see `search_index.dart`).
  bool searchIndexed = false;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      searchIndexed = await ensureSearchIndex(this);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(favorites);
        // Album grouping rules changed (LIB-10). Forget file stamps so the
        // next scan re-reads every file and regroups it.
        await customStatement('UPDATE tracks SET mtime = -1');
      }
      if (from < 3) {
        searchIndexed = await ensureSearchIndex(this);
        // Tags of old MP3s are now repaired from GBK / Shift-JIS (META-06):
        // read every file again to pick that up.
        await customStatement('UPDATE tracks SET mtime = -1');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (!details.wasCreated && !details.hadUpgrade) {
        searchIndexed = await ensureSearchIndex(this);
      }
      await seedBuiltinEqPresets(this);
    },
  );
}
