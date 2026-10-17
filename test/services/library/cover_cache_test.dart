import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:path/path.dart' as p;

const source = CoverSource(
  albumKey: 'artist\u0000album',
  path: '/music/track.flac',
  size: 100,
  modifiedMs: 1,
);

Uint8List picture([int width = 1200, int height = 600]) =>
    img.encodePng(img.Image(width: width, height: height));

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nya_cover_test_');
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'deduplicates extraction, writes both sizes, and reuses disk after restart',
    () async {
      var reads = 0;
      final bytes = picture();
      final cache = CoverCache(
        directory: () async => directory,
        readCover: (_) async {
          reads++;
          return bytes;
        },
      );
      final results = await Future.wait(
        List.generate(10, (_) => cache.load(source)),
      );
      expect(reads, 1);
      final cover = results.first!;
      expect(cache.peek(source), same(cover));
      expect(results.every((value) => identical(value, cover)), isTrue);
      final hash = sha1.convert(utf8.encode(source.albumKey)).toString();
      expect(p.basename(cover.thumbnail), '${hash}_256.jpg');
      expect(p.basename(cover.large), '${hash}_1024.jpg');
      final small = img.decodeJpg(await File(cover.thumbnail).readAsBytes())!;
      final large = img.decodeJpg(await File(cover.large).readAsBytes())!;
      expect((small.width, small.height), (256, 128));
      expect((large.width, large.height), (1024, 512));
      final restarted = CoverCache(
        directory: () async => directory,
        readCover: (_) async {
          fail('Complete disk cache should avoid Rust extraction');
        },
      );
      expect((await restarted.load(source))!.large, cover.large);
    },
  );

  test(
    'missing covers are remembered, but a rescan revision is retried',
    () async {
      var reads = 0;
      final cache = CoverCache(
        directory: () async => directory,
        readCover: (_) async {
          reads++;
          return null;
        },
      );
      expect(await cache.load(source), isNull);
      expect(await cache.load(source), isNull);
      expect(reads, 1);
      const changed = CoverSource(
        albumKey: 'artist\u0000album',
        path: '/music/track.flac',
        size: 100,
        modifiedMs: 2,
      );
      expect(await cache.load(changed), isNull);
      expect(reads, 2);
    },
  );

  test(
    'bad embedded bytes fall back without publishing incomplete files',
    () async {
      final cache = CoverCache(
        directory: () async => directory,
        readCover: (_) async => Uint8List.fromList([1, 2, 3]),
      );
      expect(await cache.load(source), isNull);
      expect(await directory.list(recursive: true).toList(), isEmpty);
    },
  );

  test(
    'read failure does not poison the worker queue or future retries',
    () async {
      var reads = 0;
      final bytes = picture(20, 10);
      final cache = CoverCache(
        directory: () async => directory,
        readCover: (_) async {
          if (++reads == 1) throw const FileSystemException('Access denied');
          return bytes;
        },
      );
      expect(await cache.load(source), isNull);
      final cover = (await cache.load(source))!;
      final decoded = img.decodeJpg(await File(cover.large).readAsBytes())!;
      expect((decoded.width, decoded.height), (20, 10));
    },
  );

  test('changed source has distinct Image.file keys and incomplete cache is repaired', () async {
    final bytes = picture(20, 10);
    var reads = 0;
    final cache = CoverCache(
      directory: () async => directory,
      readCover: (_) async {
        reads++;
        return bytes;
      },
    );
    final before = (await cache.load(source))!;
    const changed = CoverSource(
      albumKey: 'artist\u0000album',
      path: '/music/track.flac',
      size: 101,
      modifiedMs: 2,
    );
    expect(cache.peek(changed), isNull);
    final after = (await cache.load(changed))!;
    expect(before.large, isNot(after.large));
    await File(after.thumbnail).delete();
    expect((await cache.load(changed))!.thumbnail, after.thumbnail);
    expect(await File(after.thumbnail).exists(), isTrue);
    expect(reads, 3);
    expect(cache.peek(changed)?.thumbnail, after.thumbnail);
  });

  test('failed validation discards a previously resolved path', () async {
    var accessible = true;
    final cache = CoverCache(
      directory: () async {
        if (!accessible) throw const FileSystemException('Access denied');
        return directory;
      },
      readCover: (_) async => picture(16, 16),
    );
    await cache.load(source);
    expect(cache.peek(source), isNotNull);
    accessible = false;
    expect(await cache.load(source), isNull);
    expect(cache.peek(source), isNull);
  });

  test(
    'different album requests serialize large embedded-picture work',
    () async {
      final gate = Completer<Uint8List?>();
      final started = <String>[];
      final cache = CoverCache(
        directory: () async => directory,
        readCover: (path) async {
          started.add(path);
          return path == source.path ? gate.future : null;
        },
      );
      final first = cache.load(source);
      const secondSource = CoverSource(
        albumKey: 'second',
        path: '/music/second.mp3',
        size: 1,
        modifiedMs: 1,
      );
      final second = cache.load(secondSource);
      // Wait for the first directory I/O to finish and its extraction to start.
      while (started.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(started, [source.path]);
      gate.complete(null);
      await Future.wait([first, second]);
      expect(started, [source.path, secondSource.path]);
    },
  );
}
