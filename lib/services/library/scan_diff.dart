import 'package:flutter/foundation.dart';

/// What the scanner knows about one audio file without opening it.
@immutable
class FileStamp {
  const FileStamp(this.path, this.size, this.mtime);

  final String path;
  final int size;

  /// Milliseconds since epoch.
  final int mtime;

  @override
  bool operator ==(Object other) =>
      other is FileStamp &&
      other.path == path &&
      other.size == size &&
      other.mtime == mtime;

  @override
  int get hashCode => Object.hash(path, size, mtime);
}

/// Result of comparing the files on disk with the database (LIB-04).
@immutable
class ScanDiff {
  const ScanDiff({
    required this.added,
    required this.modified,
    required this.removed,
  });

  final List<FileStamp> added;
  final List<FileStamp> modified;

  /// Paths in the database that are no longer on disk.
  final List<String> removed;

  bool get isEmpty => added.isEmpty && modified.isEmpty && removed.isEmpty;

  /// Files that need their tags (re)read.
  List<FileStamp> get toRead => [...added, ...modified];
}

/// Pure function. [onDisk] and [known] map path to stamp. Paths in
/// [preserve] (for example under an unmounted root) are never reported as
/// removed.
ScanDiff diffScan({
  required Map<String, FileStamp> onDisk,
  required Map<String, FileStamp> known,
  bool Function(String path)? preserve,
}) {
  final added = <FileStamp>[];
  final modified = <FileStamp>[];
  for (final entry in onDisk.entries) {
    final old = known[entry.key];
    if (old == null) {
      added.add(entry.value);
    } else if (old.size != entry.value.size || old.mtime != entry.value.mtime) {
      modified.add(entry.value);
    }
  }
  final removed = [
    for (final path in known.keys)
      if (!onDisk.containsKey(path) && !(preserve?.call(path) ?? false)) path,
  ];
  return ScanDiff(added: added, modified: modified, removed: removed);
}
