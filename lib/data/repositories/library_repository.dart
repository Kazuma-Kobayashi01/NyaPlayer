import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nyaplayer/core/library_keys.dart';
import 'package:nyaplayer/core/sort_key.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AlbumsCompanion, AppDatabase, LibraryRootsCompanion;
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:path/path.dart' as p;

/// Database-backed library and scan locations (LIB-03, SET-01).
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  /// Emits the whole library whenever tracks or albums change. Bursts (a scan
  /// writes many batches) are coalesced.
  ///
  /// Tracks with a known duration under [minDuration] are left out, and so are
  /// albums that would be empty without them (LIB-11).
  Stream<Library> watchLibrary({
    Duration debounce = const Duration(milliseconds: 250),
    Duration minDuration = Duration.zero,
  }) {
    final changes = _db
        .customSelect('SELECT 1', readsFrom: {_db.tracks, _db.albums})
        .watch();
    return _debounced(
      changes,
      debounce,
    ).asyncMap((_) => loadLibrary(minDuration: minDuration));
  }

  Future<Library> loadLibrary({Duration minDuration = Duration.zero}) async {
    final allTrackRows = await _db.select(_db.tracks).get();
    final minMs = minDuration.inMilliseconds;
    // An unknown duration (0) is not "short": the file may just be unreadable.
    // The library shows the better file: an MP3 whose SQ-AI twin sits beside it
    // (SQ-AI, TECH_SPEC §4.8) stays on disk but is left out here.
    final superseded = mp3sWithSqAiTwin([for (final t in allTrackRows) t.path]);
    final trackRows = [
      for (final t in allTrackRows)
        if (!superseded.contains(t.path) &&
            (minMs <= 0 || t.durationMs <= 0 || t.durationMs >= minMs))
          t,
    ];
    final shown = {for (final t in trackRows) ?t.albumId};
    // Albums left without tracks by either filter disappear too.
    final filtered = trackRows.length != allTrackRows.length;
    final albumRows = [
      for (final a in await _db.select(_db.albums).get())
        if (!filtered || shown.contains(a.id)) a,
    ];
    final rowById = {for (final t in allTrackRows) t.id: t};

    final covers = <int, CoverSource>{};
    final albums = <Album>[];
    for (final a in albumRows) {
      final coverRow = a.coverTrackId == null ? null : rowById[a.coverTrackId];
      final cover = coverRow == null
          ? null
          : CoverSource(
              albumKey: a.albumKey,
              path: coverRow.path,
              size: coverRow.size,
              modifiedMs: coverRow.mtime,
              coverState: a.coverState,
            );
      if (cover != null) covers[a.id] = cover;
      albums.add(
        Album(
          id: a.id,
          title: a.title,
          artist: a.albumArtist,
          year: a.year,
          coverSeed: colorSeedFor(a.albumKey),
          cover: cover,
        ),
      );
    }
    albums.sort((x, y) => sortKey(x.title).compareTo(sortKey(y.title)));

    final seeds = {for (final a in albumRows) a.id: colorSeedFor(a.albumKey)};
    final tracks = [
      for (final t in trackRows)
        Track(
          id: t.id,
          title: t.title,
          artist: t.artist,
          albumId: t.albumId ?? -1,
          album: t.album,
          trackNo: t.trackNo ?? 0,
          discNo: t.discNo ?? 1,
          duration: Duration(milliseconds: t.durationMs),
          path: t.path,
          codec: t.codec,
          sampleRate: t.sampleRate ?? 0,
          bitDepth: t.bitDepth ?? 16,
          bitrateKbps: t.bitrate ?? 0,
          channels: t.channels ?? 2,
          year: t.year,
          genre: t.genre.isEmpty ? null : t.genre,
          addedAt: DateTime.fromMillisecondsSinceEpoch(t.addedAt),
          coverSeed: seeds[t.albumId] ?? colorSeedFor(t.path),
          cover: covers[t.albumId],
          hasEmbeddedLyrics: t.hasEmbeddedLyrics,
        ),
    ];
    return Library(tracks: tracks, albums: albums);
  }

  /// Current representative files used by the album cover cache.
  Future<List<CoverSource>> coverSources() async {
    final rows = await _db
        .customSelect(
          '''
          SELECT albums.album_key, tracks.path, tracks.size, tracks.mtime,
                 albums.cover_state
          FROM albums
          JOIN tracks ON tracks.id = albums.cover_track_id
          ''',
          readsFrom: {_db.albums, _db.tracks},
        )
        .get();
    return [
      for (final row in rows)
        CoverSource(
          albumKey: row.read<String>('album_key'),
          path: row.read<String>('path'),
          size: row.read<int>('size'),
          modifiedMs: row.read<int>('mtime'),
          coverState: row.read<int>('cover_state'),
        ),
    ];
  }

  /// Stores the extraction result only if this source is still the album's
  /// current representative; a late result from an older scan is ignored.
  Future<void> setCoverState(
    CoverSource source, {
    required bool hasCover,
  }) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT albums.id, albums.cover_state
          FROM albums
          JOIN tracks ON tracks.id = albums.cover_track_id
          WHERE albums.album_key = ? AND tracks.path = ?
            AND tracks.size = ? AND tracks.mtime = ?
          ''',
          variables: [
            Variable.withString(source.albumKey),
            Variable.withString(source.path),
            Variable.withInt(source.size),
            Variable.withInt(source.modifiedMs),
          ],
          readsFrom: {_db.albums, _db.tracks},
        )
        .get();
    if (rows.isEmpty) return;
    final row = rows.first;
    final value = hasCover ? 1 : 2;
    if (row.read<int>('cover_state') == value) return;
    final albumId = row.read<int>('id');
    await (_db.update(_db.albums)..where((a) => a.id.equals(albumId))).write(
      AlbumsCompanion(coverState: Value(value)),
    );
  }

  // --- scan locations -------------------------------------------------

  Stream<List<LibraryRoot>> watchRoots() =>
      (_db.select(
        _db.libraryRoots,
      )..orderBy([(r) => OrderingTerm.asc(r.id)])).watch().map(
        (rows) => [
          for (final r in rows)
            LibraryRoot(id: r.id, path: r.path, excluded: r.excluded),
        ],
      );

  Future<List<LibraryRoot>> roots() => watchRoots().first;

  /// Adds a scan folder, or a folder to leave out when [excluded]. Returns
  /// false if it is already listed or is covered by an existing entry of the
  /// same kind.
  Future<bool> addRoot(String path, {bool excluded = false}) async {
    final normalized = p.normalize(path);
    final existing = await roots();
    if (existing.any(
      (r) =>
          r.excluded == excluded &&
          (r.path == normalized ||
              (!excluded && p.isWithin(r.path, normalized))),
    )) {
      return false;
    }
    await _db
        .into(_db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            path: normalized,
            excluded: Value(excluded),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }

  Future<void> removeRoot(int id) =>
      (_db.delete(_db.libraryRoots)..where((r) => r.id.equals(id))).go();
}

/// Emits the latest event once [delay] passes without a newer one.
Stream<T> _debounced<T>(Stream<T> source, Duration delay) {
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  var first = true;
  controller = StreamController<T>(
    onListen: () {
      sub = source.listen(
        (event) {
          if (first) {
            first = false;
            controller.add(event);
            return;
          }
          timer?.cancel();
          timer = Timer(delay, () => controller.add(event));
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          unawaited(controller.close());
        },
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () {
      timer?.cancel();
      return sub?.cancel();
    },
  );
  return controller.stream;
}

const _sqAiSuffix = '.sq-ai.flac';

/// The paths in [paths] that are MP3s with an SQ-AI twin: `Song.mp3` when
/// `Song.SQ-AI.flac` is in the same folder. Case does not matter (macOS).
Set<String> mp3sWithSqAiTwin(Iterable<String> paths) {
  final all = paths.toList();
  final twins = {
    for (final path in all)
      if (path.toLowerCase().endsWith(_sqAiSuffix))
        path.toLowerCase().substring(0, path.length - _sqAiSuffix.length),
  };
  if (twins.isEmpty) return const {};
  return {
    for (final path in all)
      if (path.toLowerCase().endsWith('.mp3') &&
          twins.contains(path.toLowerCase().substring(0, path.length - 4)))
        path,
  };
}
