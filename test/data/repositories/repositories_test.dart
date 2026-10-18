import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/repositories/library_repository.dart';
import 'package:nyaplayer/data/repositories/playlist_repository.dart';

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
