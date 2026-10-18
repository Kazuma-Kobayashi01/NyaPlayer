import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('schema', () {
    test(
      'a database created fresh matches the committed v2 snapshot',
      () async {
        final connection = await verifier.startAt(2);
        final db = AppDatabase(connection);
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 2);
      },
    );

    test('v1 upgrades to v2 and keeps its rows', () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        "INSERT INTO tracks (path, size, mtime, title) VALUES ('/a.flac', 5, 123, 'Kept')",
      );
      schema.rawDatabase.execute(
        "INSERT INTO playlists (name, created_at, updated_at) VALUES ('p', 0, 0)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 2);

      final track = (await db.select(db.tracks).get()).single;
      expect(track.title, 'Kept');
      // Forces a rescan so albums are regrouped with the new rules (LIB-10).
      expect(track.mtime, -1);
      expect((await db.select(db.playlists).get()).single.name, 'p');
      expect(await db.select(db.favorites).get(), isEmpty);
    });
  });

  group('constraints', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> addTrack(String path, {int? albumId}) => db
        .into(db.tracks)
        .insert(TracksCompanion.insert(path: path, albumId: Value(albumId)));

    test('track path is unique', () async {
      await addTrack('/a.flac');
      expect(() => addTrack('/a.flac'), throwsA(isA<SqliteException>()));
    });

    test(
      'deleting an album detaches its tracks instead of deleting them',
      () async {
        final albumId = await db
            .into(db.albums)
            .insert(AlbumsCompanion.insert(albumKey: 'k'));
        final trackId = await addTrack('/a.flac', albumId: albumId);

        await (db.delete(db.albums)..where((a) => a.id.equals(albumId))).go();

        final track = await (db.select(
          db.tracks,
        )..where((t) => t.id.equals(trackId))).getSingle();
        expect(track.albumId, isNull);
      },
    );

    test('deleting a track removes it from playlists', () async {
      final trackId = await addTrack('/a.flac');
      final playlistId = await db
          .into(db.playlists)
          .insert(
            PlaylistsCompanion.insert(name: 'p', createdAt: 0, updatedAt: 0),
          );
      await db
          .into(db.playlistItems)
          .insert(
            PlaylistItemsCompanion.insert(
              playlistId: playlistId,
              position: 0,
              trackId: trackId,
            ),
          );

      await (db.delete(db.tracks)..where((t) => t.id.equals(trackId))).go();

      expect(await db.select(db.playlistItems).get(), isEmpty);
    });

    test('playback_state only allows the single row with id 1', () async {
      await db.into(db.playbackState).insert(PlaybackStateCompanion.insert());
      final row = await db.select(db.playbackState).getSingle();
      expect(row.id, 1);
      expect(row.queueJson, '[]');

      expect(
        () => db
            .into(db.playbackState)
            .insert(PlaybackStateCompanion.insert(id: const Value(2))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('favorites are unique per track and follow track deletion', () async {
      final id = await addTrack('/a.flac');
      await db
          .into(db.favorites)
          .insert(FavoritesCompanion.insert(trackId: Value(id), addedAt: 1));
      expect(
        () => db
            .into(db.favorites)
            .insert(FavoritesCompanion.insert(trackId: Value(id), addedAt: 2)),
        throwsA(isA<SqliteException>()),
      );
      await (db.delete(db.tracks)..where((t) => t.id.equals(id))).go();
      expect(await db.select(db.favorites).get(), isEmpty);
    });

    test('settings behaves as a key-value store', () async {
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'theme', value: 'dark'),
          );
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'theme', value: 'light'),
          );
      final rows = await db.select(db.settings).get();
      expect(rows.single.value, 'light');
    });
  });
}
