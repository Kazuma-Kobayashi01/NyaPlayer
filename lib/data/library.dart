import 'package:nyaplayer/core/sort_key.dart';
import 'package:nyaplayer/domain/models.dart';

enum SongSort { title, artist, album, added, duration }

List<Track> sortTracks(
  Iterable<Track> tracks,
  SongSort sort, {
  bool ascending = true,
}) {
  int cmp(Track a, Track b) {
    switch (sort) {
      case SongSort.title:
        return sortKey(a.title).compareTo(sortKey(b.title));
      case SongSort.artist:
        final c = sortKey(a.artist).compareTo(sortKey(b.artist));
        return c != 0 ? c : sortKey(a.title).compareTo(sortKey(b.title));
      case SongSort.album:
        final c = sortKey(a.album).compareTo(sortKey(b.album));
        if (c != 0) return c;
        final d = a.discNo.compareTo(b.discNo);
        return d != 0 ? d : a.trackNo.compareTo(b.trackNo);
      case SongSort.added:
        return a.addedAt.compareTo(b.addedAt);
      case SongSort.duration:
        return a.duration.compareTo(b.duration);
    }
  }

  final list = tracks.toList()..sort(cmp);
  return ascending ? list : list.reversed.toList();
}

/// Immutable snapshot of the library, with the lookups the UI needs.
class Library {
  Library({required List<Track> tracks, required List<Album> albums})
    : tracks = List.unmodifiable(tracks),
      albums = List.unmodifiable(albums),
      _albumById = {for (final a in albums) a.id: a},
      _trackByPath = {for (final t in tracks) t.path: t};

  final List<Track> tracks;
  final List<Album> albums;
  final Map<int, Album> _albumById;
  final Map<String, Track> _trackByPath;

  Album? albumById(int id) => _albumById[id];
  Track? trackByPath(String path) => _trackByPath[path];

  List<Track> tracksOfAlbum(int albumId) =>
      sortTracks(tracks.where((t) => t.albumId == albumId), SongSort.album);

  late final List<ArtistSummary> artists = _buildArtists();

  List<ArtistSummary> _buildArtists() {
    final byName = <String, List<Track>>{};
    for (final t in tracks) {
      byName.putIfAbsent(t.artist, () => []).add(t);
    }
    final result = [
      for (final e in byName.entries)
        ArtistSummary(
          name: e.key,
          trackCount: e.value.length,
          albumCount: e.value.map((t) => t.albumId).toSet().length,
          coverSeed: e.value.first.coverSeed,
          cover: e.value.first.cover,
        ),
    ]..sort((a, b) => sortKey(a.name).compareTo(sortKey(b.name)));
    return List.unmodifiable(result);
  }

  List<Track> tracksOfArtist(String name) =>
      sortTracks(tracks.where((t) => t.artist == name), SongSort.album);

  List<Album> albumsOfArtist(String name) {
    final ids = tracks
        .where((t) => t.artist == name)
        .map((t) => t.albumId)
        .toSet();
    return albums.where((a) => ids.contains(a.id)).toList();
  }

  late final List<FolderSummary> folders = _buildFolders();

  List<FolderSummary> _buildFolders() {
    final counts = <String, int>{};
    for (final t in tracks) {
      counts.update(t.folder, (v) => v + 1, ifAbsent: () => 1);
    }
    final result = [
      for (final e in counts.entries)
        FolderSummary(path: e.key, trackCount: e.value),
    ]..sort((a, b) => a.path.compareTo(b.path));
    return List.unmodifiable(result);
  }

  List<Track> tracksInFolder(String path) =>
      sortTracks(tracks.where((t) => t.folder == path), SongSort.title);

  /// Case-insensitive substring search over title / artist / album.
  List<Track> searchTracks(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return tracks
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q) ||
              t.album.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Album> searchAlbums(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return albums
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ArtistSummary> searchArtists(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return artists.where((a) => a.name.toLowerCase().contains(q)).toList();
  }
}
