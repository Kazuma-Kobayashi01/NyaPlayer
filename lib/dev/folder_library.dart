import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/src/rust/api/meta.dart' as rust;

/// Debug-only (M0 test harness, not the M2 scanner): builds a [Library] from
/// the FLAC/MP3 files under [root], reading tags with the Rust core. No
/// database or incremental scan. Cover bytes are loaded lazily by CoverCache.
Future<Library> loadFolderLibrary(String root) async {
  final paths = <String>[];
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final ext = p.extension(entity.path).toLowerCase();
    if (ext == '.flac' || ext == '.mp3') paths.add(entity.path);
  }
  paths.sort();

  final results = await rust.readMetadataBatch(paths: paths);
  final albumIds = <String, int>{};
  final covers = <String, CoverSource>{};
  final albums = <Album>[];
  final tracks = <Track>[];
  for (final result in results) {
    final meta = result.meta;
    if (meta == null) continue;
    final title = meta.title ?? p.basenameWithoutExtension(result.path);
    final artist = meta.artist ?? 'Unknown artist';
    final albumTitle = meta.album ?? p.basename(p.dirname(result.path));
    final albumArtist = meta.albumArtist ?? artist;
    final key = '${albumArtist.toLowerCase()}\u0000${albumTitle.toLowerCase()}';
    final seed = _seedFor(key);
    final stat = await File(result.path).stat();
    final cover = covers.putIfAbsent(
      key,
      () => CoverSource(
        albumKey: key,
        path: result.path,
        size: stat.size,
        modifiedMs: stat.modified.millisecondsSinceEpoch,
      ),
    );
    final albumId = albumIds.putIfAbsent(key, () {
      final id = albums.length + 1;
      albums.add(
        Album(
          id: id,
          title: albumTitle,
          artist: albumArtist,
          year: meta.year,
          coverSeed: seed,
          cover: cover,
        ),
      );
      return id;
    });
    tracks.add(
      Track(
        id: tracks.length + 1,
        title: title,
        artist: artist,
        albumId: albumId,
        album: albumTitle,
        trackNo: meta.trackNo ?? 0,
        discNo: meta.discNo ?? 1,
        duration: Duration(milliseconds: meta.durationMs.toInt()),
        path: result.path,
        codec: meta.codec,
        sampleRate: meta.sampleRate ?? 0,
        bitDepth: meta.bitDepth ?? 16,
        bitrateKbps: meta.bitrateKbps ?? 0,
        channels: meta.channels ?? 2,
        addedAt: stat.modified,
        coverSeed: seed,
        cover: cover,
        year: meta.year,
        genre: meta.genre,
        lyrics: meta.lyrics,
      ),
    );
  }
  return Library(tracks: tracks, albums: albums);
}

/// Stable placeholder colour per album until real covers exist (M2).
int _seedFor(String key) {
  var h = 0x811C9DC5;
  for (final unit in key.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return 0xFF000000 | (h & 0x00FFFFFF);
}
