import 'package:drift/drift.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AppDatabase, PlaylistItemsCompanion, PlaylistsCompanion;
import 'package:nyaplayer/domain/models.dart';

/// Custom playlists (LIB-13). Items keep dense, 0-based positions.
class PlaylistRepository {
  PlaylistRepository(this._db);

  final AppDatabase _db;

  int _now() => DateTime.now().millisecondsSinceEpoch;

  Stream<List<Playlist>> watchPlaylists() {
    final count = _db.playlistItems.trackId.count();
    final query =
        _db.select(_db.playlists).join([
            leftOuterJoin(
              _db.playlistItems,
              _db.playlistItems.playlistId.equalsExp(_db.playlists.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.playlists.id])
          ..orderBy([OrderingTerm.asc(_db.playlists.createdAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          Playlist(
            id: r.readTable(_db.playlists).id,
            name: r.readTable(_db.playlists).name,
            trackCount: r.read(count) ?? 0,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              r.readTable(_db.playlists).updatedAt,
            ),
          ),
      ],
    );
  }

  /// Track ids of [playlistId] in playlist order (duplicates allowed).
  Stream<List<int>> watchTrackIds(int playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((i) => i.playlistId.equals(playlistId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .watch()
          .map((rows) => [for (final r in rows) r.trackId]);

  Future<int> create(String name) {
    final now = _now();
    return _db
        .into(_db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: name.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> rename(int id, String name) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(id))).write(
        PlaylistsCompanion(name: Value(name.trim()), updatedAt: Value(_now())),
      );

  Future<void> delete(int id) =>
      (_db.delete(_db.playlists)..where((p) => p.id.equals(id))).go();

  Future<void> addTracks(int playlistId, Iterable<int> trackIds) async {
    final ids = trackIds.toList();
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      final next = await _length(playlistId);
      await _db.batch((b) {
        b.insertAll(_db.playlistItems, [
          for (var i = 0; i < ids.length; i++)
            PlaylistItemsCompanion.insert(
              playlistId: playlistId,
              position: next + i,
              trackId: ids[i],
            ),
        ]);
      });
      await _touch(playlistId);
    });
  }

  Future<void> removeAt(int playlistId, int position) =>
      _db.transaction(() async {
        await (_db.delete(_db.playlistItems)..where(
              (i) =>
                  i.playlistId.equals(playlistId) & i.position.equals(position),
            ))
            .go();
        await _renumber(playlistId);
        await _touch(playlistId);
      });

  /// [target] is the item's index in the resulting list (the
  /// `ReorderableListView.onReorderItem` convention).
  Future<void> move(int playlistId, int oldIndex, int target) =>
      _db.transaction(() async {
        final ids = await _orderedItems(playlistId);
        if (oldIndex < 0 ||
            oldIndex >= ids.length ||
            target < 0 ||
            target >= ids.length ||
            oldIndex == target) {
          return;
        }
        ids.insert(target, ids.removeAt(oldIndex));
        await _rewrite(playlistId, ids);
        await _touch(playlistId);
      });

  Future<int> _length(int playlistId) async {
    final count = _db.playlistItems.trackId.count();
    final row =
        await (_db.selectOnly(_db.playlistItems)
              ..addColumns([count])
              ..where(_db.playlistItems.playlistId.equals(playlistId)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<int>> _orderedItems(int playlistId) async => [
    for (final r
        in await (_db.select(_db.playlistItems)
              ..where((i) => i.playlistId.equals(playlistId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get())
      r.trackId,
  ];

  Future<void> _renumber(int playlistId) async =>
      _rewrite(playlistId, await _orderedItems(playlistId));

  Future<void> _rewrite(int playlistId, List<int> trackIds) async {
    await (_db.delete(
      _db.playlistItems,
    )..where((i) => i.playlistId.equals(playlistId))).go();
    await _db.batch((b) {
      b.insertAll(_db.playlistItems, [
        for (var i = 0; i < trackIds.length; i++)
          PlaylistItemsCompanion.insert(
            playlistId: playlistId,
            position: i,
            trackId: trackIds[i],
          ),
      ]);
    });
  }

  Future<void> _touch(int playlistId) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(_now())),
      );
}
