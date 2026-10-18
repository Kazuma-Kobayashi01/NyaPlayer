import 'package:nyaplayer/services/eq/eq_presets.dart' hide EqPreset;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/db/search_index.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('schema', () {
    // The FTS5 search index is created with plain SQL, so the snapshot does
    // not list it (or its shadow tables): extra tables are expected.
    test(
      'a database created fresh matches the committed v3 snapshot',
      () async {
        final connection = await verifier.startAt(3);
        final db = AppDatabase(connection);
        addTearDown(db.close);
        await verifier.migrateAndValidate(
          db,
          3,
          options: const ValidationOptions(validateDropped: false),
        );
      },
    );

    test('v1 upgrades to v3, keeps its rows and indexes them', () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        "INSERT INTO tracks (path, size, mtime, title) VALUES ('/a.flac', 5, 123, 'Kept')",
      );
      schema.rawDatabase.execute(
        "INSERT INTO playlists (name, created_at, updated_at) VALUES ('p', 0, 0)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(
        db,
        3,
        options: const ValidationOptions(validateDropped: false),
      );

      final track = (await db.select(db.tracks).get()).single;
      expect(track.title, 'Kept');
      // Forces a rescan so albums are regrouped with the new rules (LIB-10).
      expect(track.mtime, -1);
      expect((await db.select(db.playlists).get()).single.name, 'p');
      expect(await db.select(db.favorites).get(), isEmpty);
      // The search index was built from the rows that were already there.
      expect(db.searchIndexed, isTrue);
      expect(await searchTrackIds(db, 'Kept', indexed: true), [track.id]);
    });

    test('v2 upgrades to v3 with a search index', () async {
      final schema = await verifier.schemaAt(2);
      schema.rawDatabase.execute(
        "INSERT INTO tracks (path, size, mtime, title, artist) VALUES ('/b.flac', 5, 1, '打上花火', 'DAOKO')",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(
        db,
        3,
        options: const ValidationOptions(validateDropped: false),
      );

      expect(db.searchIndexed, isTrue);
      expect(await searchTrackIds(db, '上花火', indexed: true), hasLength(1));
      // Every file is read again, so repaired tags (META-06) are picked up.
      expect((await db.select(db.tracks).get()).single.mtime, -1);
    });
  });

  group('search index', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> add(String title, {String artist = '', String album = ''}) => db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/$title-$artist-$album',
            title: Value(title),
            artist: Value(artist),
            album: Value(album),
          ),
        );

    Future<List<int>> find(String q) async {
      // Touching the database first runs the migration that builds the index.
      await db.select(db.tracks).get();
      return searchTrackIds(db, q, indexed: db.searchIndexed);
    }

    test('FTS5 with the trigram tokenizer is available', () async {
      await db.select(db.tracks).get();
      expect(db.searchIndexed, isTrue);
    });

    test(
      'finds CJK substrings and ignores case, in title, artist and album',
      () async {
        final a = await add('打上花火', artist: 'DAOKO/米津玄師');
        final b = await add('Blue', album: 'Thank You Blue');
        await add('Other');

        expect(await find('上花火'), [a]);
        expect(await find('米津玄'), [a]);
        expect(await find('daoko'), [a]);
        expect(await find('thank you'), [b]);
        expect(await find('BLUE'), [b]);
        expect(await find('nothing here'), isEmpty);
      },
    );

    test('one and two character queries fall back to LIKE', () async {
      final a = await add('十年', artist: '陈奕迅');
      await add('Other');
      expect(await find('十年'), [a]);
      expect(await find('十'), [a]);
      expect(await find('迅'), [a]);
    });

    test('quotes and wildcards in the query are plain text', () async {
      final a = await add('100% "Real" _love_');
      await add('Other');
      expect(await find('"Real"'), [a]);
      expect(await find('100%'), [a]);
      expect(await find('_love_'), [a]);
      expect(await find('%'), [a]);
      expect(await find('AND OR NOT'), isEmpty);
    });

    test('follows updates and deletions of tracks', () async {
      final id = await add('Old title');
      expect(await find('Old title'), [id]);

      await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
        const TracksCompanion(title: Value('Brand new')),
      );
      expect(await find('Old title'), isEmpty);
      expect(await find('Brand new'), [id]);

      await (db.delete(db.tracks)..where((t) => t.id.equals(id))).go();
      expect(await find('Brand new'), isEmpty);
    });

    test('built-in EQ presets are written once and kept up to date', () async {
      final rows = await db.select(db.eqPresets).get();
      expect(rows.where((r) => r.builtin).map((r) => r.name), [
        for (final p in builtinEqPresets) p.id,
      ]);
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
