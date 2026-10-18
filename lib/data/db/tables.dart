import 'package:drift/drift.dart';

// Tables mirror TECH_SPEC §9. Timestamps are epoch milliseconds.

@TableIndex(name: 'idx_tracks_album_id', columns: {#albumId})
@TableIndex(name: 'idx_tracks_title', columns: {#title})
@TableIndex(name: 'idx_tracks_artist', columns: {#artist})
@TableIndex(name: 'idx_tracks_added_at', columns: {#addedAt})
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  IntColumn get size => integer().withDefault(const Constant(0))();
  IntColumn get mtime => integer().withDefault(const Constant(0))();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get artist => text().withDefault(const Constant(''))();
  TextColumn get albumArtist => text().withDefault(const Constant(''))();
  TextColumn get album => text().withDefault(const Constant(''))();
  IntColumn get albumId => integer().nullable().references(
    Albums,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get trackNo => integer().nullable()();
  IntColumn get discNo => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().withDefault(const Constant(''))();

  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get channels => integer().nullable()();
  TextColumn get codec => text().withDefault(const Constant(''))();

  BoolColumn get hasEmbeddedLyrics =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sidecarLrcPath => text().nullable()();
  TextColumn get folderCoverPath => text().nullable()();
  BoolColumn get metadataError =>
      boolean().withDefault(const Constant(false))();

  IntColumn get addedAt => integer().withDefault(const Constant(0))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayedAt => integer().nullable()();
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get albumKey => text().unique()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get albumArtist => text().withDefault(const Constant(''))();
  IntColumn get year => integer().nullable()();

  /// 0 unknown, 1 has cover, 2 no cover (TECH_SPEC §7.3).
  IntColumn get coverState => integer().withDefault(const Constant(0))();
  IntColumn get coverTrackId => integer().nullable()();
}

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameKey => text().unique()();
  TextColumn get name => text()();
}

/// P1 multi-artist support.
class TrackArtists extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId =>
      integer().references(Artists, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {trackId, artistId};
}

class LibraryRoots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  BoolColumn get excluded => boolean().withDefault(const Constant(false))();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class PlaylistItems extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {playlistId, position};
}

/// Added in schema v2 (not in the original §9 list).
class Favorites extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};
}

class EqPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get builtin => boolean().withDefault(const Constant(false))();
  TextColumn get gainsJson => text()();
  RealColumn get preamp => real().withDefault(const Constant(0))();
}

/// Single-row table; `id` is always 1.
class PlaybackState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get queueJson => text().withDefault(const Constant('[]'))();
  TextColumn get shuffledJson => text().withDefault(const Constant('[]'))();
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get loopMode => integer().withDefault(const Constant(0))();
  BoolColumn get shuffle => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class ScanErrors extends Table {
  TextColumn get path => text()();
  TextColumn get message => text()();
  IntColumn get at => integer()();

  @override
  Set<Column> get primaryKey => {path};
}
