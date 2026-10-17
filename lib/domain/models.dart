import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumId,
    required this.album,
    required this.trackNo,
    required this.duration,
    required this.path,
    required this.codec,
    required this.sampleRate,
    required this.bitDepth,
    required this.bitrateKbps,
    required this.addedAt,
    required this.coverSeed,
    this.discNo = 1,
    this.channels = 2,
    this.year,
    this.genre,
    this.lyrics,
  });

  final int id;
  final String title;
  final String artist;
  final int albumId;
  final String album;
  final int trackNo;
  final int discNo;
  final Duration duration;
  final String path;
  final String codec;
  final int sampleRate;
  final int bitDepth;
  final int bitrateKbps;
  final int channels;
  final int? year;
  final String? genre;

  /// Raw embedded lyrics text (LRC or plain), if any.
  final String? lyrics;
  final DateTime addedAt;

  /// ARGB seed used for the generated placeholder cover / cover theme.
  final int coverSeed;

  String get folder => p.posix.dirname(path);

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverSeed,
    this.year,
  });

  final int id;
  final String title;
  final String artist;
  final int? year;
  final int coverSeed;
}

@immutable
class ArtistSummary {
  const ArtistSummary({
    required this.name,
    required this.trackCount,
    required this.albumCount,
    required this.coverSeed,
  });

  final String name;
  final int trackCount;
  final int albumCount;
  final int coverSeed;
}

@immutable
class FolderSummary {
  const FolderSummary({required this.path, required this.trackCount});

  final String path;
  final int trackCount;

  String get name => p.posix.basename(path);
}

@immutable
class LyricLine {
  const LyricLine({required this.start, required this.text, this.translation});

  final Duration start;
  final String text;
  final String? translation;

  /// Blank line, shown as an instrumental break marker.
  bool get isInterlude => text.isEmpty;
}

@immutable
class Lyrics {
  const Lyrics({
    required this.lines,
    required this.synced,
    this.title,
    this.artist,
    this.album,
    this.by,
  });

  static const empty = Lyrics(lines: [], synced: false);

  final List<LyricLine> lines;

  /// False for plain-text lyrics without timestamps.
  final bool synced;
  final String? title;
  final String? artist;
  final String? album;
  final String? by;

  bool get isEmpty => lines.isEmpty;

  /// Index of the line being sung at [position], or -1 before the first line.
  int indexAt(Duration position) {
    if (!synced || lines.isEmpty) return -1;
    var lo = 0;
    var hi = lines.length - 1;
    var result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].start <= position) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }
}
