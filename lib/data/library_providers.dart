import 'package:nyaplayer/data/repositories/favorites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/lyrics/lrc_parser.dart';
import 'package:nyaplayer/services/lyrics/lyrics_loader.dart';

/// Sample data by default (widget tests, previews). `main` overrides it with
/// the database-backed library.
final libraryProvider = StreamProvider<Library>((ref) async* {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  yield sampleLibrary;
});

/// Finds tracks for a search query. In-memory by default; `main` overrides it
/// with the FTS5 index of the database (LIB-09).
typedef TrackSearch = Future<List<Track>> Function(String query);

final trackSearchProvider = Provider<TrackSearch>((ref) {
  final library = ref.watch(libraryProvider).value;
  return (query) async => library?.searchTracks(query) ?? const <Track>[];
});

/// Parsed lyrics for a track, cached per track id.
final lyricsProvider = Provider.family<Lyrics, Track>((ref, track) {
  final raw = ref.watch(rawLyricsProvider(track)).value;
  if (raw == null || raw.trim().isEmpty) return Lyrics.empty;
  return LrcParser.parse(raw);
});

/// Favourite track ids, persisted through [favoritesStoreProvider].
final favoritesProvider = NotifierProvider<FavoritesController, Set<int>>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<Set<int>> {
  @override
  Set<int> build() =>
      Set.unmodifiable(ref.read(favoritesStoreProvider).initial);

  void toggle(Track track) {
    final add = !state.contains(track.id);
    state = add ? {...state, track.id} : ({...state}..remove(track.id));
    ref.read(favoritesStoreProvider).set(track.id, favorite: add);
  }
}
