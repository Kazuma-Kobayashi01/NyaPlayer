import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AppDatabase, FavoritesCompanion;

/// Favourite track ids (LIB-16). Loaded once at startup; changes are written
/// to the database in order, in the background.
abstract class FavoritesStore {
  Set<int> get initial;

  void set(int trackId, {required bool favorite});
}

class MemoryFavoritesStore implements FavoritesStore {
  MemoryFavoritesStore([Set<int>? initial]) : initial = {...?initial};

  @override
  final Set<int> initial;

  @override
  void set(int trackId, {required bool favorite}) =>
      favorite ? initial.add(trackId) : initial.remove(trackId);
}

class DbFavoritesStore implements FavoritesStore {
  DbFavoritesStore._(this._db, this.initial);

  final AppDatabase _db;
  Future<void> _tail = Future.value();

  @override
  final Set<int> initial;

  static Future<DbFavoritesStore> open(AppDatabase db) async {
    final rows = await db.select(db.favorites).get();
    return DbFavoritesStore._(db, {for (final r in rows) r.trackId});
  }

  @override
  void set(int trackId, {required bool favorite}) {
    _tail = _tail.then((_) async {
      try {
        if (favorite) {
          await _db
              .into(_db.favorites)
              .insert(
                FavoritesCompanion.insert(
                  trackId: Value(trackId),
                  addedAt: DateTime.now().millisecondsSinceEpoch,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        } else {
          await (_db.delete(
            _db.favorites,
          )..where((f) => f.trackId.equals(trackId))).go();
        }
      } catch (e) {
        Log.w('Favorites', 'Cannot save favorite $trackId: $e');
      }
    });
  }

  Future<void> flush() => _tail;
}

final favoritesStoreProvider = Provider<FavoritesStore>(
  (ref) => MemoryFavoritesStore(),
);
