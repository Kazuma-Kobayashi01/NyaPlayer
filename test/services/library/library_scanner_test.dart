import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/services/library/library_scanner.dart';
import 'package:nyaplayer/src/rust/api/meta.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late AppDatabase db;
  late List<List<String>> reads;
  late Map<String, TrackMeta?> metaByName;

  LibraryScanner scanner() => LibraryScanner(
    db,
    batchSize: 2,
    reader: (paths) async {
      reads.add(paths);
      return [
        for (final path in paths)
          MetaResult(
            path: path,
            meta: metaByName[p.basename(path)],
            error: metaByName[p.basename(path)] == null ? 'bad tags' : null,
          ),
      ];
    },
  );

  Future<List<ScanProgress>> scan() => scanner().scan().toList();

  File touch(String relative, {String content = 'x'}) {
    final file = File(p.join(tmp.path, relative))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return file;
  }

  TrackMeta meta(String title, {String? album, String? artist}) => TrackMeta(
    title: title,
    artist: artist ?? 'Artist',
    album: album,
    durationMs: BigInt.from(180000),
    codec: 'FLAC',
    hasCover: false,
  );

  Future<List<Track>> tracks() => db.select(db.tracks).get();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nya_scan_');
    db = AppDatabase(NativeDatabase.memory());
    reads = [];
    metaByName = {};
    await db
        .into(db.libraryRoots)
        .insert(LibraryRootsCompanion.insert(path: tmp.path));
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('first scan imports tracks, albums and artists', () async {
    touch('a/1.flac');
    touch('a/2.flac');
    touch('b/3.mp3');
    touch('notes.txt');
    metaByName = {
      '1.flac': meta('One', album: 'Alpha'),
      '2.flac': meta('Two', album: 'Alpha'),
      '3.mp3': meta('Three', album: 'Beta', artist: 'Other'),
    };

    final progress = await scan();

    expect(
      (await tracks()).map((t) => t.title),
      unorderedEquals(['One', 'Two', 'Three']),
    );
    final albums = await db.select(db.albums).get();
    expect(albums.map((a) => a.title), unorderedEquals(['Alpha', 'Beta']));
    expect(
      (await db.select(db.artists).get()).map((a) => a.name),
      unorderedEquals(['Artist', 'Other']),
    );
    expect(progress.last.phase, ScanPhase.done);
    expect(progress.last.total, 3);
    // batchSize 2 over 3 files
    expect(reads.map((r) => r.length), [2, 1]);
    final alpha = albums.firstWhere((a) => a.title == 'Alpha');
    expect(alpha.coverTrackId, isNotNull);
  });

  test('a rescan without changes reads nothing', () async {
    touch('1.flac');
    metaByName = {'1.flac': meta('One', album: 'A')};
    await scan();
    reads.clear();

    await scan();

    expect(reads, isEmpty);
  });

  test(
    'a changed file is re-read in place and keeps its id and history',
    () async {
      final file = touch('1.flac');
      metaByName = {'1.flac': meta('Old', album: 'A')};
      await scan();
      final before = (await tracks()).single;
      await (db.update(db.tracks)..where((t) => t.id.equals(before.id))).write(
        const TracksCompanion(playCount: Value(7)),
      );

      file.writeAsStringSync('longer content');
      file.setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));
      metaByName = {'1.flac': meta('New', album: 'A')};
      await scan();

      final after = (await tracks()).single;
      expect(after.id, before.id);
      expect(after.title, 'New');
      expect(after.playCount, 7);
      expect(after.addedAt, before.addedAt);
    },
  );

  test('deleted files disappear together with their empty album', () async {
    final gone = touch('x/1.flac');
    touch('y/2.flac');
    metaByName = {
      '1.flac': meta('One', album: 'Gone'),
      '2.flac': meta('Two', album: 'Stays'),
    };
    await scan();

    gone.deleteSync();
    await scan();

    expect((await tracks()).map((t) => t.title), ['Two']);
    expect((await db.select(db.albums).get()).map((a) => a.title), ['Stays']);
  });

  test('removed tracks leave playlists but others keep their place', () async {
    final gone = touch('1.flac');
    touch('2.flac');
    metaByName = {
      '1.flac': meta('One', album: 'A'),
      '2.flac': meta('Two', album: 'A'),
    };
    await scan();
    final rows = await tracks();
    final playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'p', createdAt: 0, updatedAt: 0),
        );
    for (var i = 0; i < rows.length; i++) {
      await db
          .into(db.playlistItems)
          .insert(
            PlaylistItemsCompanion.insert(
              playlistId: playlistId,
              position: i,
              trackId: rows[i].id,
            ),
          );
    }

    gone.deleteSync();
    await scan();

    final items = await db.select(db.playlistItems).get();
    expect(items, hasLength(1));
    expect(items.single.trackId, rows.firstWhere((t) => t.title == 'Two').id);
  });

  test('a root that is not available keeps its tracks', () async {
    final dir = await Directory.systemTemp.createTemp('nya_usb_');
    File(p.join(dir.path, '1.flac')).writeAsStringSync('x');
    await db
        .into(db.libraryRoots)
        .insert(LibraryRootsCompanion.insert(path: dir.path));
    metaByName = {'1.flac': meta('Remote', album: 'USB')};
    await scan();
    expect(await tracks(), hasLength(1));

    await dir.delete(recursive: true); // drive "unplugged"
    await scan();

    expect(await tracks(), hasLength(1));
  });

  test('removing a root removes its tracks on the next scan', () async {
    touch('1.flac');
    metaByName = {'1.flac': meta('One', album: 'A')};
    await scan();

    await db.delete(db.libraryRoots).go();
    await scan();

    expect(await tracks(), isEmpty);
    expect(await db.select(db.albums).get(), isEmpty);
  });

  test('excluded folders and hidden files are skipped', () async {
    touch('keep/1.flac');
    touch('skip/2.flac');
    touch('.hidden/3.flac');
    touch('keep/._1.flac'); // macOS resource-fork stub
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            path: p.join(tmp.path, 'skip'),
            excluded: const Value(true),
          ),
        );
    metaByName = {
      '1.flac': meta('One', album: 'A'),
      '2.flac': meta('Two', album: 'A'),
      '3.flac': meta('Three', album: 'A'),
    };

    await scan();

    expect((await tracks()).map((t) => t.title), ['One']);
  });

  test('an unreadable file is kept by file name and recorded', () async {
    touch('Broken Song.mp3');
    metaByName = {'Broken Song.mp3': null};

    final progress = await scan();

    final row = (await tracks()).single;
    expect(row.title, 'Broken Song');
    expect(row.metadataError, isTrue);
    expect(row.codec, 'MP3');
    final errors = await db.select(db.scanErrors).get();
    expect(errors.single.path, row.path);
    expect(progress.last.errors, 1);

    // Once the tags become readable the error is cleared.
    touch(
      'Broken Song.mp3',
      content: 'now longer',
    ).setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));
    metaByName = {'Broken Song.mp3': meta('Fixed', album: 'A')};
    await scan();
    expect(await db.select(db.scanErrors).get(), isEmpty);
    expect((await tracks()).single.metadataError, isFalse);
  });

  test(
    'a collaboration album stays one album and reads "various artists"',
    () async {
      touch('Night/1.flac');
      touch('Night/2.flac');
      metaByName = {
        '1.flac': meta('One', album: 'Night', artist: 'Singer A'),
        '2.flac': meta('Two', album: 'Night', artist: 'Singer B'),
      };

      await scan();

      final albums = await db.select(db.albums).get();
      expect(albums, hasLength(1));
      expect(albums.single.albumArtist, isEmpty);
      expect(
        (await tracks()).map((t) => t.artist),
        unorderedEquals(['Singer A', 'Singer B']),
      );
    },
  );

  test('one artist without an Album Artist tag names the album', () async {
    touch('Solo/1.flac');
    touch('Solo/2.flac');
    metaByName = {
      '1.flac': meta('One', album: 'Solo', artist: 'Singer'),
      '2.flac': meta('Two', album: 'Solo', artist: 'Singer'),
    };

    await scan();

    expect((await db.select(db.albums).get()).single.albumArtist, 'Singer');
  });

  test('the Album Artist tag wins over track artists', () async {
    touch('Comp/1.flac');
    touch('Comp/2.flac');
    metaByName = {
      '1.flac': TrackMeta(
        title: 'One',
        artist: 'X',
        albumArtist: 'Various',
        album: 'Comp',
        durationMs: BigInt.one,
        codec: 'FLAC',
        hasCover: false,
      ),
      '2.flac': TrackMeta(
        title: 'Two',
        artist: 'Y',
        albumArtist: 'Various',
        album: 'Comp',
        durationMs: BigInt.one,
        codec: 'FLAC',
        hasCover: false,
      ),
    };

    await scan();

    final album = (await db.select(db.albums).get()).single;
    expect(album.albumArtist, 'Various');
  });

  test('untagged files group into an album per folder', () async {
    touch('Mix/1.mp3');
    touch('Mix/2.mp3');
    metaByName = {
      '1.mp3': TrackMeta(
        durationMs: BigInt.zero,
        codec: 'MP3',
        hasCover: false,
      ),
      '2.mp3': TrackMeta(
        durationMs: BigInt.zero,
        codec: 'MP3',
        hasCover: false,
      ),
    };

    await scan();

    final albums = await db.select(db.albums).get();
    expect(albums, hasLength(1));
    expect(albums.single.title, 'Mix');
  });
}
