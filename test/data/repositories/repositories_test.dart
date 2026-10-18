import 'package:nyaplayer/services/eq/eq_presets.dart' hide EqPreset;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/repositories/eq_preset_repository.dart';
import 'package:nyaplayer/data/repositories/library_repository.dart';
import 'package:nyaplayer/data/repositories/playlist_repository.dart';
import 'package:nyaplayer/data/repositories/search_repository.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late PlaylistRepository playlists;

  Future<int> addTrack(String path, {String title = 't', int? albumId}) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          path: path,
          title: Value(title),
          albumId: Value(albumId),
        ),
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    library = LibraryRepository(db);
    playlists = PlaylistRepository(db);
  });
  tearDown(() => db.close());

  group('scan locations', () {
    test('adds, lists and removes roots', () async {
      expect(await library.addRoot('/music'), isTrue);
      expect(await library.addRoot('/other', excluded: true), isTrue);
      final roots = await library.roots();
      expect(roots.map((r) => r.path), ['/music', '/other']);
      expect(roots.map((r) => r.excluded), [false, true]);

      await library.removeRoot(roots.first.id);
      expect((await library.roots()).map((r) => r.path), ['/other']);
    });

    test(
      'duplicates and folders inside an existing root are refused',
      () async {
        await library.addRoot('/music');
        expect(await library.addRoot('/music/'), isFalse);
        expect(await library.addRoot('/music/rock'), isFalse);
        expect(await library.addRoot('/musical'), isTrue);
        // The same folder may be excluded even though it is also scanned.
        expect(await library.addRoot('/music/rock', excluded: true), isTrue);
      },
    );
  });

  test('loadLibrary maps rows to the UI model', () async {
    final albumId = await db
        .into(db.albums)
        .insert(
          AlbumsCompanion.insert(
            albumKey: 'k',
            title: const Value('Album'),
            albumArtist: const Value('Band'),
          ),
        );
    final id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/m/a/1.flac',
            title: const Value('Song'),
            artist: const Value('Band'),
            album: const Value('Album'),
            albumId: Value(albumId),
            durationMs: const Value(61000),
            size: const Value(5),
            mtime: const Value(9),
            hasEmbeddedLyrics: const Value(true),
          ),
        );
    await (db.update(db.albums)..where((a) => a.id.equals(albumId))).write(
      AlbumsCompanion(coverTrackId: Value(id)),
    );

    final lib = await library.loadLibrary();

    final track = lib.trackById(id)!;
    expect(track.title, 'Song');
    expect(track.duration, const Duration(seconds: 61));
    expect(track.hasEmbeddedLyrics, isTrue);
    expect(track.cover?.path, '/m/a/1.flac');
    expect(track.cover?.size, 5);
    expect(lib.albumById(albumId)!.title, 'Album');
    expect(lib.tracksOfAlbum(albumId).single.id, id);
  });

  test('watchLibrary emits again after a change', () async {
    final stream = library.watchLibrary(
      debounce: const Duration(milliseconds: 5),
    );
    final counts = <int>[];
    final sub = stream.listen((lib) => counts.add(lib.tracks.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await addTrack('/a.flac');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(counts.first, 0);
    expect(counts.last, 1);
  });

  group('minimum track length (LIB-11)', () {
    Future<int> addTimed(String path, int ms, {int? albumId}) => db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: path,
            title: Value(path),
            durationMs: Value(ms),
            albumId: Value(albumId),
          ),
        );

    test('hides tracks that are shorter, keeps unknown durations', () async {
      await addTimed('/short', 20000);
      await addTimed('/exact', 60000);
      await addTimed('/long', 200000);
      await addTimed('/unknown', 0);

      final all = await library.loadLibrary();
      expect(all.tracks, hasLength(4));

      final filtered = await library.loadLibrary(
        minDuration: const Duration(minutes: 1),
      );
      expect(filtered.tracks.map((t) => t.title).toSet(), {
        '/exact',
        '/long',
        '/unknown',
      });
    });

    test('an album left without tracks disappears too', () async {
      final shortOnly = await db
          .into(db.albums)
          .insert(AlbumsCompanion.insert(albumKey: 'a'));
      final mixed = await db
          .into(db.albums)
          .insert(AlbumsCompanion.insert(albumKey: 'b'));
      await addTimed('/s1', 10000, albumId: shortOnly);
      await addTimed('/s2', 10000, albumId: mixed);
      await addTimed('/l2', 180000, albumId: mixed);

      final filtered = await library.loadLibrary(
        minDuration: const Duration(minutes: 1),
      );
      expect(filtered.albums.map((a) => a.id), [mixed]);
    });
  });

  group('track search (LIB-09)', () {
    test('finds tracks through the index, best match first', () async {
      await addTrack('/1', title: 'Blue Sky');
      await addTrack('/2', title: 'Sky High');
      await addTrack('/3', title: 'Other');
      // Touch the database so the index exists, then search the loaded
      // library the way the app does.
      final lib = await library.loadLibrary();
      final hits = await SearchRepository(db).tracks(lib, 'sky');
      expect(hits.map((t) => t.title), ['Sky High', 'Blue Sky']);
    });

    test('tracks the library hides are not returned', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              path: '/s',
              title: const Value('Tiny jingle'),
              durationMs: const Value(5000),
            ),
          );
      final lib = await library.loadLibrary(
        minDuration: const Duration(minutes: 1),
      );
      expect(await SearchRepository(db).tracks(lib, 'jingle'), isEmpty);
    });
  });

  group('SQ-AI twins', () {
    test(
      'an MP3 with its SQ-AI FLAC beside it is left out of the library',
      () async {
        await addTrack('/m/a/Song.mp3', title: 'Song');
        await addTrack('/m/a/Song.SQ-AI.flac', title: 'Song');
        await addTrack('/m/a/Other.mp3', title: 'Other');
        // Same name in another folder is a different song.
        await addTrack('/m/b/Song.mp3', title: 'Song B');
        final lib = await library.loadLibrary();
        expect(lib.tracks.map((t) => t.path), [
          '/m/a/Song.SQ-AI.flac',
          '/m/a/Other.mp3',
          '/m/b/Song.mp3',
        ]);
      },
    );

    test('the MP3 comes back when the SQ-AI file is gone', () async {
      await addTrack('/m/a/Song.mp3');
      expect((await library.loadLibrary()).tracks, hasLength(1));
      final twin = await addTrack('/m/a/Song.SQ-AI.flac');
      expect(
        (await library.loadLibrary()).tracks.single.path,
        endsWith('.flac'),
      );
      await (db.delete(db.tracks)..where((t) => t.id.equals(twin))).go();
      expect((await library.loadLibrary()).tracks.single.path, '/m/a/Song.mp3');
    });

    test('matching ignores case, and only MP3s are replaced', () {
      expect(
        mp3sWithSqAiTwin([
          '/M/Song.MP3',
          '/m/song.sq-ai.FLAC',
          '/m/song.flac',
          '/m/lone.mp3',
        ]),
        {'/M/Song.MP3'},
      );
      expect(mp3sWithSqAiTwin(['/m/a.mp3', '/m/b.flac']), isEmpty);
      // A plain FLAC of the same name is not a twin.
      expect(mp3sWithSqAiTwin(['/m/a.mp3', '/m/a.flac']), isEmpty);
    });

    test(
      'an album whose only track was the replaced MP3 does not linger',
      () async {
        final a = await db
            .into(db.albums)
            .insert(
              AlbumsCompanion.insert(
                albumKey: 'old',
                title: const Value('Old tags'),
              ),
            );
        final b = await db
            .into(db.albums)
            .insert(
              AlbumsCompanion.insert(
                albumKey: 'new',
                title: const Value('New tags'),
              ),
            );
        await addTrack('/m/a/Song.mp3', albumId: a);
        await addTrack('/m/a/Song.SQ-AI.flac', albumId: b);
        final lib = await library.loadLibrary();
        expect(lib.albums.map((x) => x.title), ['New tags']);
      },
    );
  });

  group('EQ presets (EQ-04)', () {
    test('saves, renames and deletes user presets only', () async {
      final repo = EqPresetRepository(db);
      // Opening the database seeded the built-in rows; they are not listed.
      await db.select(db.eqPresets).get();
      expect(await repo.watch().first, isEmpty);

      final gains = [for (var i = 0; i < 15; i++) i - 7.0];
      final id = await repo.add('Mine', gains, -2);
      expect(id, greaterThanOrEqualTo(100));

      var list = await repo.watch().first;
      expect(list.single.name, 'Mine');
      expect(list.single.gains, gains);
      expect(list.single.preamp, -2);
      expect(list.single.presetId, 'user:$id');

      await repo.rename(id, 'Renamed');
      expect((await repo.watch().first).single.name, 'Renamed');

      // Built-in rows cannot be renamed or deleted through the repository.
      await repo.rename(1, 'Hacked');
      await repo.delete(1);
      final flat = await (db.select(
        db.eqPresets,
      )..where((p) => p.id.equals(1))).getSingle();
      expect(flat.name, 'flat');

      await repo.delete(id);
      list = await repo.watch().first;
      expect(list, isEmpty);
    });

    test('a preset saved by the 10-band version is carried over', () async {
      final repo = EqPresetRepository(db);
      final id = await repo.add('Old', [for (var i = 0; i < 10; i++) 6.0], 0);
      final saved = (await repo.watch().first).singleWhere((p) => p.id == id);
      expect(saved.gains, hasLength(eqBandFrequencies.length));
      expect(saved.gains, everyElement(6.0));
    });

    test('ids of new presets never collide with the built-in ones', () async {
      final repo = EqPresetRepository(db);
      await db.select(db.eqPresets).get();
      final a = await repo.add('A', List.filled(15, 0), 0);
      final b = await repo.add('B', List.filled(15, 0), 0);
      expect(b, a + 1);
      expect(a, greaterThanOrEqualTo(100));
    });
  });

  group('playlists', () {
    late int a, b, c;

    setUp(() async {
      a = await addTrack('/a.flac');
      b = await addTrack('/b.flac');
      c = await addTrack('/c.flac');
    });

    Future<List<int>> ids(int playlist) =>
        playlists.watchTrackIds(playlist).first;

    test('creates, renames, lists with counts and deletes', () async {
      final id = await playlists.create('  Road trip ');
      await playlists.addTracks(id, [a, b]);
      var list = await playlists.watchPlaylists().first;
      expect(list.single.name, 'Road trip');
      expect(list.single.trackCount, 2);

      await playlists.rename(id, 'Night');
      list = await playlists.watchPlaylists().first;
      expect(list.single.name, 'Night');

      await playlists.delete(id);
      expect(await playlists.watchPlaylists().first, isEmpty);
      expect(await db.select(db.playlistItems).get(), isEmpty);
    });

    test('empty playlists are listed with a zero count', () async {
      await playlists.create('Empty');
      expect((await playlists.watchPlaylists().first).single.trackCount, 0);
    });

    test('appends in order and allows the same song twice', () async {
      final id = await playlists.create('p');
      await playlists.addTracks(id, [c, a]);
      await playlists.addTracks(id, [c]);
      expect(await ids(id), [c, a, c]);
    });

    test('removeAt closes the gap', () async {
      final id = await playlists.create('p');
      await playlists.addTracks(id, [a, b, c]);
      await playlists.removeAt(id, 1);
      expect(await ids(id), [a, c]);
      final positions = (await db.select(db.playlistItems).get()).map(
        (i) => i.position,
      );
      expect(positions, unorderedEquals([0, 1]));
    });

    test('move follows the reorderable list convention', () async {
      final id = await playlists.create('p');
      await playlists.addTracks(id, [a, b, c]);
      await playlists.move(id, 0, 2);
      expect(await ids(id), [b, c, a]);
      await playlists.move(id, 2, 0);
      expect(await ids(id), [a, b, c]);
      await playlists.move(id, 1, 1); // no-op
      await playlists.move(id, 5, 0); // out of range: ignored
      expect(await ids(id), [a, b, c]);
    });

    test('a song deleted from the library leaves every playlist', () async {
      final p1 = await playlists.create('1');
      final p2 = await playlists.create('2');
      await playlists.addTracks(p1, [a, b]);
      await playlists.addTracks(p2, [b, c]);

      await (db.delete(db.tracks)..where((t) => t.id.equals(b))).go();

      expect(await ids(p1), [a]);
      expect(await ids(p2), [c]);
    });

    test('lists are independent', () async {
      final p1 = await playlists.create('1');
      final p2 = await playlists.create('2');
      await playlists.addTracks(p1, [a]);
      await playlists.addTracks(p2, [b]);
      await playlists.removeAt(p1, 0);
      expect(await ids(p1), isEmpty);
      expect(await ids(p2), [b]);
    });
  });
}
