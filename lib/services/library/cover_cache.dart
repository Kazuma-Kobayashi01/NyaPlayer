import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/src/rust/api/meta.dart' as rust;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Only file paths stay in Dart state, never full-resolution cover bytes.
@immutable
class CachedCover {
  const CachedCover({required this.thumbnail, required this.large});

  final String thumbnail;
  final String large;
}

typedef CoverReader = Future<Uint8List?> Function(String path);
typedef CoverStateWriter = Future<void> Function(
  CoverSource source,
  bool hasCover,
);

/// Album-level, lazy extraction. Work is deduplicated and serialised so a
/// fast scroll cannot decode many large embedded pictures simultaneously.
class CoverCache {
  CoverCache({
    Future<Directory> Function()? directory,
    CoverReader? readCover,
    this._writeState,
  }) : _directory = directory ?? _defaultDirectory,
       _readCover = readCover ?? ((path) => rust.readCover(path: path));

  final Future<Directory> Function() _directory;
  final CoverReader _readCover;
  final CoverStateWriter? _writeState;
  final _pending = <CoverSource, Future<CachedCover?>>{};
  final _withoutCover = <CoverSource>{};
  // Paths only, bounded by recently requested source revisions. A responsive
  // layout can remount before its auto-disposed FutureProvider resolves again.
  final _resolved = <CoverSource, CachedCover>{};
  Future<void> _tail = Future.value();

  CachedCover? peek(CoverSource source) => _resolved[source];

  static Future<Directory> _defaultDirectory() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'covers'),
  );

  Future<CachedCover?> load(CoverSource source) =>
      _pending.putIfAbsent(source, () => _enqueue(source));

  /// Removes cache revisions no longer referenced by the current library.
  /// Cleanup is serialized with extraction so it cannot remove an in-flight
  /// write. It runs after scans, when the active source list is authoritative.
  Future<void> cleanup(Iterable<CoverSource> activeSources) async {
    final activeFiles = <String, Set<String>>{};
    for (final source in activeSources) {
      if (source.coverState == 2) continue;
      final revision = _revisionFor(source);
      final albumHash = sha1.convert(utf8.encode(source.albumKey)).toString();
      activeFiles.putIfAbsent(revision, () => <String>{}).addAll([
        '$albumHash.ready',
        '${albumHash}_256.jpg',
        '${albumHash}_1024.jpg',
      ]);
    }
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      await previous;
      final root = await _directory();
      if (!await root.exists()) return;
      await for (final entry in root.list(followLinks: false)) {
        if (entry is Directory &&
            !activeFiles.containsKey(p.basename(entry.path))) {
          await entry.delete(recursive: true);
        } else if (entry is File) {
          await entry.delete();
        } else if (entry is Directory) {
          final keep = activeFiles[p.basename(entry.path)]!;
          await for (final child in entry.list(followLinks: false)) {
            if (child is File && !keep.contains(p.basename(child.path))) {
              await child.delete();
            } else if (child is Directory) {
              await child.delete(recursive: true);
            }
          }
        }
      }
    } finally {
      done.complete();
    }
  }

  Future<CachedCover?> _enqueue(CoverSource source) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      await previous;
      final result = await _load(source);
      _resolved.remove(source);
      if (result != null) {
        _resolved[source] = result;
        if (_resolved.length > 128) _resolved.remove(_resolved.keys.first);
      }
      return result;
    } catch (error) {
      // Missing files, revoked access and corrupt images retain placeholders.
      Log.w('CoverCache', 'Cannot load cover for ${source.path}: $error');
      _resolved.remove(source);
      return null;
    } finally {
      unawaited(_pending.remove(source));
      done.complete();
    }
  }

  Future<CachedCover?> _load(CoverSource source) async {
    if (source.coverState == 2) return null;
    if (_withoutCover.contains(source)) return null;
    final directory = await _directory();
    await directory.create(recursive: true);
    final hash = sha1.convert(utf8.encode(source.albumKey)).toString();
    // Revision in the directory keeps old Image.file cache keys distinct
    // after a tag edit. JPEG names remain the album-key hashes (§7.3).
    final revision = _revisionFor(source);
    final folder = Directory(p.join(directory.path, revision));
    final result = CachedCover(
      thumbnail: p.join(folder.path, '${hash}_256.jpg'),
      large: p.join(folder.path, '${hash}_1024.jpg'),
    );
    final complete = File(p.join(folder.path, '$hash.ready'));
    if (await complete.exists() &&
        await File(result.thumbnail).exists() &&
        await File(result.large).exists() &&
        await File(result.thumbnail).length() > 0 &&
        await File(result.large).length() > 0) {
      await _saveState(source, true);
      return result;
    }

    final bytes = await _readCover(source.path);
    if (bytes == null || bytes.isEmpty) {
      _withoutCover.add(source);
      await _saveState(source, false);
      return null;
    }
    final written = await compute(_writeCovers, (
      bytes: bytes,
      thumbnail: result.thumbnail,
      large: result.large,
      complete: complete.path,
    ));
    if (!written) {
      _withoutCover.add(source);
      await _saveState(source, false);
      return null;
    }
    await _saveState(source, true);
    return result;
  }

  Future<void> _saveState(CoverSource source, bool hasCover) async {
    try {
      await _writeState?.call(source, hasCover);
    } catch (error) {
      Log.w('CoverCache', 'Cannot persist cover state: $error');
    }
  }

  String _revisionFor(CoverSource source) => sha1
      .convert(
        utf8.encode(
          jsonEncode(['jpeg-v1', source.path, source.size, source.modifiedMs]),
        ),
      )
      .toString();
}

typedef _CoverJob = ({
  Uint8List bytes,
  String thumbnail,
  String large,
  String complete,
});

/// Decoding, EXIF rotation, resizing and JPEG encoding stay off the UI isolate.
bool _writeCovers(_CoverJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) return false;
  final original = img.bakeOrientation(decoded);
  Directory(p.dirname(job.thumbnail)).createSync(recursive: true);
  for (final target in [(256, job.thumbnail), (1024, job.large)]) {
    final scale = math.min(
      1.0,
      target.$1 / math.max(original.width, original.height),
    );
    final resized = img.copyResize(
      original,
      width: math.max(1, (original.width * scale).round()),
      height: math.max(1, (original.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
    final temporary = File('${target.$2}.tmp');
    temporary.writeAsBytesSync(
      img.encodeJpg(resized, quality: 88),
      flush: true,
    );
    temporary.renameSync(target.$2);
  }
  // Written last: interrupted generations never count as complete.
  File(job.complete).writeAsStringSync('1', flush: true);
  return true;
}
