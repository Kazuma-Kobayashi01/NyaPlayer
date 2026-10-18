import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/features/now_playing/player_background.dart';
import 'package:nyaplayer/features/now_playing/pre_blurred_cover.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';

const sourceA = CoverSource(
  albumKey: 'a',
  path: '/music/a.flac',
  size: 1,
  modifiedMs: 1,
);
const sourceB = CoverSource(
  albumKey: 'b',
  path: '/music/b.mp3',
  size: 1,
  modifiedMs: 1,
);

class _ControlledCache extends CoverCache {
  final requests = <CoverSource, Completer<CachedCover?>>{};

  @override
  Future<CachedCover?> load(CoverSource source) =>
      requests.putIfAbsent(source, Completer<CachedCover?>.new).future;
}

void main() {
  testWidgets(
    'resizing and remounting reuse decoded artwork without a blank frame',
    (tester) async {
      late Directory directory;
      late CachedCover files;
      Completer<Directory>? diskGate;
      var reads = 0;
      late CoverCache cache;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('nya_resize_cover_');
        cache = CoverCache(
          directory: () => diskGate?.future ?? Future.value(directory),
          readCover: (_) async {
            reads++;
            return img.encodePng(img.Image(width: 16, height: 16));
          },
        );
        files = (await cache.load(sourceA))!;
      });
      addTearDown(() => directory.delete(recursive: true));
      final container = ProviderContainer(
        overrides: [coverCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(container.dispose);
      Widget view(double size, {bool show = true}) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Center(
            child: show
                ? CoverArt(
                    seed: 1,
                    source: sourceA,
                    size: size,
                    highResolution: true,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpWidget(view(220, show: false));
      await tester.runAsync(
        () => precacheImage(
          ResizeImage(FileImage(File(files.large)), width: 1024),
          tester.element(find.byType(Center).first),
        ),
      );
      await tester.pumpWidget(view(220));
      final decoded = tester.widget<RawImage>(find.byType(RawImage)).image;
      expect(decoded, isNotNull);
      for (final size in [221.0, 300.0, 297.0, 450.0, 280.0]) {
        await tester.pumpWidget(view(size));
        expect(
          tester.widget<RawImage>(find.byType(RawImage)).image,
          same(decoded),
        );
        expect(find.byIcon(Icons.music_note), findsNothing);
      }
      await tester.pumpWidget(view(280, show: false));
      await tester.pump();
      await tester.pump();
      diskGate = Completer<Directory>();
      await tester.pumpWidget(view(320));
      // The re-created async provider is waiting on disk; already resolved paths
      // and decoded frames must still be available in this very first frame.
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(find.byIcon(Icons.music_note), findsNothing);
      expect(reads, 1);
      diskGate.complete(directory);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no embedded source keeps the placeholder without invoking Rust',
    (tester) async {
      final cache = _ControlledCache();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [coverCacheProvider.overrideWithValue(cache)],
          child: const MaterialApp(
            home: Center(child: CoverArt(seed: 1, size: 48)),
          ),
        ),
      );
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(cache.requests, isEmpty);
    },
  );

  testWidgets(
    'late previous-album completion cannot replace the current cover',
    (tester) async {
      final cache = _ControlledCache();
      late Directory directory;
      late CachedCover files;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('nya_cover_widget_');
        final bytes = img.encodePng(img.Image(width: 16, height: 16));
        final small = File('${directory.path}/small.png');
        final large = File('${directory.path}/large.png');
        await small.writeAsBytes(bytes);
        await large.writeAsBytes(bytes);
        files = CachedCover(thumbnail: small.path, large: large.path);
      });
      addTearDown(() async => directory.delete(recursive: true));
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget view(CoverSource source) => ProviderScope(
        overrides: [coverCacheProvider.overrideWithValue(cache)],
        child: MaterialApp(
          home: Center(child: CoverArt(seed: 1, source: source, size: 100)),
        ),
      );
      await tester.pumpWidget(view(sourceA));
      await tester.pumpWidget(view(sourceB));
      cache.requests[sourceA]!.complete(files);
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      // Warm the file image outside FakeAsync before Image.file requests it.
      // Otherwise its initial disk I/O stays in the test's fake event loop.
      await tester.runAsync(() async {
        await precacheImage(
          ResizeImage(FileImage(File(files.thumbnail)), width: 256),
          tester.element(find.byType(CoverArt)),
        );
      });
      cache.requests[sourceB]!.complete(files);
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final resized = image.image as ResizeImage;
      expect(resized.width, 256); // bounded by thumbnail size, even at 3× DPR
      expect((resized.imageProvider as FileImage).file.path, files.thumbnail);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'player backdrop loads a thumbnail, switches to gradient and falls back without art',
    (tester) async {
      final cache = _ControlledCache();
      final container = ProviderContainer(
        overrides: [coverCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(container.dispose);
      late Directory directory;
      late CachedCover files;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('nya_backdrop_');
        final file = File('${directory.path}/cover.png');
        await file.writeAsBytes(
          img.encodePng(img.Image(width: 16, height: 16)),
        );
        files = CachedCover(thumbnail: file.path, large: file.path);
      });
      addTearDown(() => directory.delete(recursive: true));
      final track = Track(
        id: 1,
        title: 't',
        artist: 'a',
        albumId: 1,
        album: 'b',
        trackNo: 1,
        duration: const Duration(minutes: 3),
        path: sourceA.path,
        codec: 'FLAC',
        sampleRate: 48000,
        bitDepth: 24,
        bitrateKbps: 1000,
        addedAt: DateTime(2026),
        coverSeed: 0,
        cover: sourceA,
      );
      Widget view(Track? track, {Brightness brightness = Brightness.light}) =>
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: PlayerBackground(
                track: track,
                child: const Center(child: Text('Controls')),
              ),
            ),
          );
      await tester.pumpWidget(view(track));
      expect(find.byType(PreBlurredCover), findsNothing);
      cache.requests[sourceA]!.complete(files);
      await tester.pump();
      expect(find.byType(PreBlurredCover), findsOneWidget);
      // The cover is blurred once off the frame path; wait for the bitmap.
      final backdrop = find.descendant(
        of: find.byType(PreBlurredCover),
        matching: find.byType(CustomPaint),
      );
      PreBlurredBackdropPainter painter() =>
          tester.widget<CustomPaint>(backdrop).painter!
              as PreBlurredBackdropPainter;
      for (var i = 0; i < 40 && painter().image == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsNothing);
      expect(painter().image, isNotNull);
      // One painter draws the cover and the tints, and asks to be cached.
      expect(tester.widget<CustomPaint>(backdrop).isComplex, isTrue);
      expect(
        tester.getSize(backdrop),
        tester.getSize(find.byType(PlayerBackground)),
      );
      expect(find.text('Controls'), findsOneWidget);
      List<Color> overlayColors() =>
          tester.widget<PreBlurredCover>(find.byType(PreBlurredCover)).overlays;
      var scheme = Theme.of(tester.element(find.byType(PlayerBackground)))
          .colorScheme;
      expect(overlayColors(), contains(scheme.surface.withValues(alpha: 0.50)));
      expect(
        overlayColors(),
        isNot(contains(scheme.scrim.withValues(alpha: 0.10))),
      );
      await tester.pumpWidget(view(track, brightness: Brightness.dark));
      await tester.pumpAndSettle();
      scheme = Theme.of(tester.element(find.byType(PlayerBackground)))
          .colorScheme;
      expect(overlayColors(), contains(scheme.surface.withValues(alpha: 0.48)));
      expect(overlayColors(), contains(scheme.scrim.withValues(alpha: 0.10)));
      container
          .read(themeSettingsProvider.notifier)
          .setPlayerBackground(PlayerBackgroundStyle.gradient);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      container
          .read(themeSettingsProvider.notifier)
          .setPlayerBackground(PlayerBackgroundStyle.blurredCover);
      await tester.pumpWidget(view(null));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Controls'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('missing artwork result leaves a stable placeholder', (
    tester,
  ) async {
    final cache = _ControlledCache();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coverCacheProvider.overrideWithValue(cache)],
        child: const MaterialApp(
          home: Center(child: CoverArt(seed: 1, source: sourceA, size: 48)),
        ),
      ),
    );
    cache.requests[sourceA]!.complete(null);
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
