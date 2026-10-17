import 'package:flutter/foundation.dart';

/// The album's representative audio file. Its revision changes on rescan.
@immutable
class CoverSource {
  const CoverSource({
    required this.albumKey,
    required this.path,
    required this.size,
    required this.modifiedMs,
  });

  final String albumKey;
  final String path;
  final int size;
  final int modifiedMs;

  @override
  bool operator ==(Object other) =>
      other is CoverSource &&
      albumKey == other.albumKey &&
      path == other.path &&
      size == other.size &&
      modifiedMs == other.modifiedMs;

  @override
  int get hashCode => Object.hash(albumKey, path, size, modifiedMs);
}
