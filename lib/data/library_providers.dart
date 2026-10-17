import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/lyrics/lrc_parser.dart';

/// Replaced by the drift-backed repository in M2.
final libraryProvider = FutureProvider<Library>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return sampleLibrary;
});

/// Parsed lyrics for a track, cached per track id.
final lyricsProvider = Provider.family<Lyrics, Track>((ref, track) {
  final raw = track.lyrics;
  if (raw == null || raw.trim().isEmpty) return Lyrics.empty;
  return LrcParser.parse(raw);
});

/// Favourite track ids. In memory for now; persisted with the database (M2).
final favoritesProvider = NotifierProvider<FavoritesController, Set<int>>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void toggle(Track track) {
    state = state.contains(track.id)
        ? ({...state}..remove(track.id))
        : {...state, track.id};
  }
}
