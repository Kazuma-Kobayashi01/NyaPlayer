import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/src/rust/api/meta.dart' as rust;

/// Reads the embedded lyrics text of a file (LRC or plain), or null.
typedef RawLyricsReader = Future<String?> Function(String path);

final rawLyricsReaderProvider = Provider<RawLyricsReader>(
  (ref) =>
      (path) async => (await rust.readMetadata(path: path)).lyrics,
);

/// Lyrics are not kept in the database: they are read from the file when a
/// track is shown (TECH_SPEC §8.1).
final rawLyricsProvider = FutureProvider.autoDispose.family<String?, Track>((
  ref,
  track,
) async {
  if (track.lyrics != null) return track.lyrics;
  if (!track.hasEmbeddedLyrics) return null;
  try {
    return await ref.watch(rawLyricsReaderProvider)(track.path);
  } catch (e) {
    Log.w('Lyrics', 'Cannot read lyrics of ${track.path}: $e');
    return null;
  }
});
