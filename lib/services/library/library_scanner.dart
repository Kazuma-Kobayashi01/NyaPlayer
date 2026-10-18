import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:nyaplayer/core/library_keys.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/services/library/scan_diff.dart';
import 'package:nyaplayer/src/rust/api/meta.dart' as rust;
import 'package:path/path.dart' as p;

/// Reads tags for a batch of files; output order matches input order.
typedef MetadataReader = Future<List<rust.MetaResult>> Function(
  List<String> paths,
);

/// Lists audio files under [roots], skipping [excluded] folders.
typedef FileWalker = Future<WalkResult> Function(
  List<String> roots,
  List<String> excluded,
);

/// Only FLAC and MP3 are in scope (docs/TECH_SPEC.md §7.1, narrowed by
/// REQUIREMENTS FMT).
const audioExtensions = {'.flac', '.mp3'};

@immutable
class WalkResult {
  const WalkResult({required this.files, required this.missingRoots});

  final List<FileStamp> files;

  /// Roots that could not be listed (unmounted drive, revoked access). Their
  /// tracks are kept instead of being treated as deleted.
  final List<String> missingRoots;
}

enum ScanPhase { walking, reading, finishing, done }

@immutable
class ScanProgress {
  const ScanProgress(
    this.phase, {
    this.done = 0,
    this.total = 0,
    this.errors = 0,
  });

  final ScanPhase phase;
  final int done;
  final int total;
  final int errors;

  /// Null while the total is not known yet.
  double? get fraction => total == 0 ? null : done / total;
}

/// Walks on a worker isolate so a big library cannot block the UI thread.
Future<WalkResult> walkInIsolate(List<String> roots, List<String> excluded) =>
    Isolate.run(() => walkAudioFiles(roots, excluded));

WalkResult walkAudioFiles(List<String> roots, List<String> excluded) {
  final skip = excluded.map(p.normalize).toSet();
  final files = <String, FileStamp>{};
  final missing = <String>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) {
      missing.add(root);
      continue;
    }
    try {
      _walkDir(dir, skip, files);
    } on FileSystemException catch (e) {
      Log.w('Scanner', 'Cannot list $root: $e');
      missing.add(root);
    }
  }
  return WalkResult(files: files.values.toList(), missingRoots: missing);
}

void _walkDir(Directory dir, Set<String> skip, Map<String, FileStamp> out) {
  for (final entity in dir.listSync(followLinks: false)) {
    final name = p.basename(entity.path);
    // Hidden entries include macOS "._x.mp3" resource-fork stubs.
    if (name.startsWith('.')) continue;
    if (entity is Directory) {
      if (!skip.contains(p.normalize(entity.path))) {
        try {
          _walkDir(entity, skip, out);
        } on FileSystemException catch (e) {
          Log.w('Scanner', 'Skipping ${entity.path}: $e');
        }
      }
    } else if (entity is File &&
        audioExtensions.contains(p.extension(name).toLowerCase())) {
      final stat = entity.statSync();
      out[entity.path] = FileStamp(
        entity.path,
        stat.size,
        stat.modified.millisecondsSinceEpoch,
      );
    }
  }
}

Future<List<rust.MetaResult>> _rustReader(List<String> paths) =>
    rust.readMetadataBatch(paths: paths);

/// Incremental scanner (LIB-02/04, TECH_SPEC §7.1). Existing rows are updated
/// in place by path so track ids, and therefore playlists, stay stable.
class LibraryScanner {
  LibraryScanner(
    this._db, {
    MetadataReader? reader,
    FileWalker? walker,
    this.batchSize = 50,
  }) : _reader = reader ?? _rustReader,
       _walker = walker ?? walkInIsolate;

  final AppDatabase _db;
  final MetadataReader _reader;
  final FileWalker _walker;
  final int batchSize;

  Stream<ScanProgress> scan() async* {
    yield const ScanProgress(ScanPhase.walking);
    final roots = await _db.select(_db.libraryRoots).get();
    final scanRoots = [
      for (final r in roots)
        if (!r.excluded) r.path,
    ];
    final excluded = [
      for (final r in roots)
        if (r.excluded) r.path,
    ];
    final walk = scanRoots.isEmpty
        ? const WalkResult(files: [], missingRoots: [])
        : await _walker(scanRoots, excluded);

    final known = {
      for (final row in await _db.select(_db.tracks).get())
        row.path: FileStamp(row.path, row.size, row.mtime),
    };
    final diff = diffScan(
      onDisk: {for (final f in walk.files) f.path: f},
      known: known,
      preserve: (path) => walk.missingRoots.any((r) => p.isWithin(r, path)),
    );

    await _remove(diff.removed);

    final toRead = diff.toRead;
    final albums = await _loadAlbumIds();
    final added = diff.added.toSet();
    var done = 0;
    var errors = 0;
    yield ScanProgress(ScanPhase.reading, total: toRead.length);
    for (var i = 0; i < toRead.length; i += batchSize) {
      final batch = toRead.sublist(i, (i + batchSize).clamp(0, toRead.length));
      final results = await _reader([for (final f in batch) f.path]);
      errors += await _write(batch, results, albums, isNew: added);
      done += batch.length;
      yield ScanProgress(
        ScanPhase.reading,
        done: done,
        total: toRead.length,
        errors: errors,
      );
    }

    yield ScanProgress(
      ScanPhase.finishing,
      done: done,
      total: toRead.length,
      errors: errors,
    );
    await _tidy();
    Log.i(
      'Scanner',
      '+${diff.added.length} ~${diff.modified.length} -${diff.removed.length}'
          ' ($errors unreadable)',
    );
    yield ScanProgress(
      ScanPhase.done,
      done: done,
      total: toRead.length,
      errors: errors,
    );
  }

  Future<Map<String, int>> _loadAlbumIds() async => {
    for (final a in await _db.select(_db.albums).get()) a.albumKey: a.id,
  };

  Future<void> _remove(List<String> paths) async {
    for (var i = 0; i < paths.length; i += 500) {
      final chunk = paths.sublist(i, (i + 500).clamp(0, paths.length));
      await _db.transaction(() async {
        await (_db.delete(_db.tracks)..where((t) => t.path.isIn(chunk))).go();
        await (_db.delete(
          _db.scanErrors,
        )..where((e) => e.path.isIn(chunk))).go();
      });
    }
  }

  /// Returns the number of files whose tags could not be read.
  Future<int> _write(
    List<FileStamp> files,
    List<rust.MetaResult> results,
    Map<String, int> albumIds, {
    required Set<FileStamp> isNew,
  }) async {
    var errors = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final result = results[i];
        final meta = result.meta;
        final fileTitle = p.basenameWithoutExtension(file.path);
        if (meta == null) {
          errors++;
          await _db
              .into(_db.scanErrors)
              .insertOnConflictUpdate(
                ScanErrorsCompanion.insert(
                  path: file.path,
                  message: result.error ?? 'unreadable',
                  at: now,
                ),
              );
        } else {
          await (_db.delete(
            _db.scanErrors,
          )..where((e) => e.path.equals(file.path))).go();
        }

        final artist = meta?.artist ?? '';
        final albumTitle = (meta?.album ?? '').trim().isNotEmpty
            ? meta!.album!.trim()
            : p.basename(p.dirname(file.path));
        // Only the tag: an empty value means "no Album Artist tag", which
        // _tidy uses to derive the album's displayed artist.
        final albumArtist = (meta?.albumArtist ?? '').trim();
        final key = albumKeyFor(
          path: file.path,
          album: meta?.album,
          albumArtist: albumArtist,
        );
        final albumId = albumIds[key] ??= await _db
            .into(_db.albums)
            .insert(
              AlbumsCompanion.insert(
                albumKey: key,
                title: Value(albumTitle),
                albumArtist: Value(albumArtist),
                year: Value(meta?.year),
              ),
            );
        if (artist.trim().isNotEmpty) {
          await _db
              .into(_db.artists)
              .insert(
                ArtistsCompanion.insert(
                  nameKey: normalizeKey(artist),
                  name: artist,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

        final fields = TracksCompanion(
          size: Value(file.size),
          mtime: Value(file.mtime),
          title: Value(
            (meta?.title ?? '').trim().isNotEmpty
                ? meta!.title!.trim()
                : fileTitle,
          ),
          artist: Value(artist),
          albumArtist: Value(albumArtist),
          album: Value(meta?.album ?? ''),
          albumId: Value(albumId),
          trackNo: Value(meta?.trackNo),
          discNo: Value(meta?.discNo),
          year: Value(meta?.year),
          genre: Value(meta?.genre ?? ''),
          durationMs: Value(meta?.durationMs.toInt() ?? 0),
          sampleRate: Value(meta?.sampleRate),
          bitDepth: Value(meta?.bitDepth),
          bitrate: Value(meta?.bitrateKbps),
          channels: Value(meta?.channels),
          codec: Value(
            meta?.codec ?? p.extension(file.path).substring(1).toUpperCase(),
          ),
          hasEmbeddedLyrics: Value((meta?.lyrics ?? '').trim().isNotEmpty),
          metadataError: Value(meta == null),
        );
        await _db
            .into(_db.tracks)
            .insert(
              fields.copyWith(
                path: Value(file.path),
                // Newly seen files keep their file date so "recently added"
                // is meaningful after the first big import.
                addedAt: Value(isNew.contains(file) ? file.mtime : 0),
              ),
              onConflict: DoUpdate((old) => fields, target: [_db.tracks.path]),
            );
      }
    });
    return errors;
  }

  /// Drops albums and artists nothing refers to and re-picks each album's
  /// representative (cover) track.
  Future<void> _tidy() async {
    await _db.transaction(() async {
      await _db.customStatement('''
        UPDATE albums SET cover_track_id = (
          SELECT id FROM tracks WHERE album_id = albums.id
          ORDER BY COALESCE(disc_no, 1), COALESCE(track_no, 0), id LIMIT 1)
      ''');
      // Album artist: the tag if any track has one; otherwise the common
      // track artist; otherwise '' ("various artists", shown localized).
      await _db.customStatement('''
        UPDATE albums SET album_artist = COALESCE(
          (SELECT MIN(album_artist) FROM tracks
            WHERE album_id = albums.id AND album_artist <> ''),
          (SELECT CASE WHEN COUNT(DISTINCT artist) = 1 THEN MIN(artist)
                       ELSE '' END
             FROM tracks WHERE album_id = albums.id),
          '')
      ''');
      await _db.customStatement(
        'DELETE FROM albums WHERE id NOT IN '
        '(SELECT DISTINCT album_id FROM tracks WHERE album_id IS NOT NULL)',
      );
      final names = {
        for (final row
            in await _db
                .customSelect('SELECT DISTINCT artist FROM tracks')
                .get())
          normalizeKey(row.read<String>('artist')),
      };
      final artists = await _db.select(_db.artists).get();
      final stale = [
        for (final a in artists)
          if (!names.contains(a.nameKey)) a.id,
      ];
      if (stale.isNotEmpty) {
        await (_db.delete(_db.artists)..where((a) => a.id.isIn(stale))).go();
      }
    });
  }
}
