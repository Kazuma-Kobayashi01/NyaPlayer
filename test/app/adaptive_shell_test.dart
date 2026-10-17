import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/app/layout/phone_drawer.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/features/album/albums_page.dart';
import 'package:nyaplayer/app/start_page.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/lyrics/lyrics_view.dart';
import 'package:nyaplayer/features/now_playing/now_playing_panel.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/now_playing/now_playing_page.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/features/queue/queue_sheet.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/player_bar.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Future<FakePlayerEngine> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final engine = FakePlayerEngine(
    durationOf: (p) =>
        sampleLibrary.trackByPath(p)?.duration ?? const Duration(minutes: 3),
  );
  addTearDown(engine.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [playerEngineProvider.overrideWithValue(engine)],
      child: const NyaPlayerApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  return engine;
}

void main() {
  testWidgets('phone: drawer behind a menu button, player docked at bottom', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.byType(PhoneDrawer), findsNothing);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneDrawer), findsOneWidget);
    for (final label in [
      'Songs',
      'Favorites',
      'Albums',
      'Artists',
      'Folders',
      'Playlists',
      'Settings',
    ]) {
      expect(
        find.descendant(
          of: find.byType(PhoneDrawer),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('no overflow menu in the top bar', (tester) async {
    await _pumpApp(tester, const Size(400, 800));
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.more_vert),
      ),
      findsNothing,
    );
  });

  testWidgets('desktop: permanent sidebar and bottom player bar', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(900, 800));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byType(NowPlayingPanel), findsNothing);
  });

  testWidgets('wide desktop: sidebar and now-playing panel', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NowPlayingPanel), findsOneWidget);
    expect(find.byType(PlayerBar), findsNothing);

    // The panel opens on the cover; lyrics and queue are behind the toggle.
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(LyricsView), findsNothing);
    expect(find.byType(QueueList), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPanel)),
    );
    await container.read(queueProvider.notifier).togglePlay();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('tapping a song fills the player bar', (tester) async {
    final engine = await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
      findsOneWidget,
    );
    await engine.pause(); // stop the fake engine's periodic timer
  });

  testWidgets('favourites page lists toggled songs', (tester) async {
    await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsNothing);
    expect(find.byIcon(Icons.favorite), findsWidgets);
  });

  testWidgets('full player fits a 360dp phone without overflow', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(360, 740));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Player menu'), findsOneWidget);
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('full player fits a short 360x640 phone without overflow', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(360, 640));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Player menu'), findsOneWidget);
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('phone player has no title; actions live in the menu', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    // Phones close the player with the system back gesture.
    expect(find.byTooltip('Collapse'), findsNothing);
    expect(find.text('Now playing'), findsNothing);
    expect(find.byTooltip('Player menu'), findsOneWidget);
    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    for (final label in ['Lyrics', 'Queue', 'Equalizer', 'Song info']) {
      expect(find.widgetWithText(MenuItemButton, label), findsOneWidget);
    }
    expect(find.text('Lyrics settings'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('phone player swipes between cover and lyrics', (tester) async {
    final engine = await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(LyricsView), findsNothing);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsView), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsView), findsNothing);
  });

  testWidgets('narrow desktop player keeps a close button', (tester) async {
    final engine = await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byTooltip('Collapse'), findsOneWidget);
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('expand button opens the immersive player; Esc closes it', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Expand player'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(find.byTooltip('Player menu'), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);

    // Lyrics / queue live in a toggle outside the menu.
    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MenuItemButton, 'Queue'), findsNothing);
    expect(find.widgetWithText(MenuItemButton, 'Lyrics'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Queue').last);
    await tester.pumpAndSettle();
    expect(find.byType(QueueList), findsOneWidget);
    expect(find.byType(LyricsView), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(QueueList), findsNothing); // back on the shell
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('disc cover spins only while playing', (tester) async {
    final engine = await _pumpApp(tester, const Size(1400, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPanel)),
    );
    container.read(coverShapeProvider.notifier).set(CoverShape.disc);
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 600));
    AnimationController spinner() =>
        tester
                .widgetList<RotationTransition>(
                  find.descendant(
                    of: find.byType(PlayerArtwork),
                    matching: find.byType(RotationTransition),
                  ),
                )
                .first
                .turns
            as AnimationController;
    expect(spinner().isAnimating, isTrue);

    await engine.pause();
    await tester.pump(const Duration(milliseconds: 100));
    expect(spinner().isAnimating, isFalse);
  });

  testWidgets('font setting switches the theme between sans and serif', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1000, 800));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavigationDrawer)),
    );
    String? family() =>
        Theme.of(tester.element(find.byType(NavigationDrawer)))
            .textTheme
            .bodyMedium
            ?.fontFamily;

    final sans = family();
    container.read(themeSettingsProvider.notifier).setFont(AppFont.serif);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(family(), isNot(sans));
    expect(family(), 'serif');
    container.read(themeSettingsProvider.notifier).setFont(AppFont.sans);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(family(), sans);
  });

  testWidgets('phone: the player bar floats above the list', (tester) async {
    await _pumpApp(tester, const Size(400, 800));
    final card = tester.getRect(
      find
          .descendant(
            of: find.byType(PlayerBar),
            matching: find.byType(Material),
          )
          .first,
    );
    // Floating: lifted off the bottom edge and inset from both sides.
    expect(card.bottom, lessThanOrEqualTo(800 - 12));
    expect(card.left, greaterThan(0));
    expect(card.right, lessThan(400));
  });

  testWidgets('the app opens on the configured start page', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final engine = FakePlayerEngine(
      durationOf: (_) => const Duration(minutes: 3),
    );
    addTearDown(engine.dispose);
    final container = ProviderContainer(
      overrides: [playerEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    container.read(startPageProvider.notifier).set(StartPage.albums);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NyaPlayerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(AppBar, 'Albums'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Songs'), findsNothing);
  });

  testWidgets('lyrics font size is typed into a dialog', (tester) async {
    final engine = await _pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 300));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPanel)),
    );
    expect(container.read(lyricsSettingsProvider).fontSize, 22);

    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lyrics settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Font size · 22 pt'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '18');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(container.read(lyricsSettingsProvider).fontSize, 18);
  });

  testWidgets('phone player: swipe up opens the queue, pull down closes it', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(400, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Afterglow'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(QueueSheet), findsNothing);

    // Swipe up on the cover.
    await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(QueueSheet), findsOneWidget);
    expect(tester.getTopLeft(find.byType(QueueSheet)).dy, lessThan(1));

    // A small drag that does not pass halfway springs back open.
    await tester.drag(find.byType(QueueList), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.byType(QueueSheet), findsOneWidget);

    // List is at the top: pulling down closes the sheet.
    await tester.fling(find.byType(QueueList), const Offset(0, 500), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(QueueSheet), findsNothing);

    // Back closes the open sheet before leaving the player.
    await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(QueueSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QueueSheet), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
  });

  test('Hi-Res needs lossless, 24-bit and 96 kHz', () {
    Track make(String codec, int bits, int rate) => Track(
      id: 1,
      title: 't',
      artist: 'a',
      albumId: 1,
      album: 'b',
      trackNo: 1,
      duration: const Duration(minutes: 3),
      path: '/t.flac',
      codec: codec,
      sampleRate: rate,
      bitDepth: bits,
      bitrateKbps: 1000,
      addedAt: DateTime(2024),
      coverSeed: 0,
    );
    expect(isHiRes(make('FLAC', 24, 96000)), isTrue);
    expect(isHiRes(make('FLAC', 24, 192000)), isTrue);
    expect(isHiRes(make('FLAC', 24, 48000)), isFalse);
    expect(isHiRes(make('FLAC', 16, 96000)), isFalse);
    expect(isHiRes(make('MP3', 24, 96000)), isFalse);
    expect(trackQualityLabel(make('FLAC', 24, 96000)), startsWith('Hi-Res'));
    expect(trackQualityLabel(make('FLAC', 24, 48000)), startsWith('FLAC'));
  });

  for (final size in const [Size(400, 800), Size(1000, 800), Size(1500, 900)]) {
    testWidgets('albums grid does not overflow at ${size.width.toInt()}dp', (
      tester,
    ) async {
      await _pumpApp(tester, size);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      container.read(routerProvider).go('/albums');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(AlbumCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  test('desktop layout follows orientation, panel needs room', () {
    expect(useDesktopLayout(const Size(400, 800)), isFalse);
    expect(useDesktopLayout(const Size(800, 360)), isTrue); // landscape phone
    expect(useDesktopLayout(const Size(900, 1200)), isTrue); // wide portrait
    expect(useSidePanel(const Size(800, 360)), isFalse);
    expect(useSidePanel(const Size(1000, 600)), isTrue);
    expect(useSidePanel(const Size(1170, 700)), isTrue);
    expect(useSidePanel(const Size(1000, 440)), isFalse);
    expect(useImmersivePlayer(const Size(640, 360)), isTrue);
    expect(useImmersivePlayer(const Size(400, 800)), isFalse);
  });

  for (final size in const [
    Size(640, 360),
    Size(800, 360),
    Size(900, 412),
    Size(1000, 600),
    Size(1170, 700),
  ]) {
    testWidgets(
      'landscape ${size.width.toInt()}x${size.height.toInt()}: shell and '
      'player fit without overflow',
      (tester) async {
        final engine = await _pumpApp(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.byType(PhoneDrawer), findsNothing);
        await tester.tap(find.text('Afterglow').first);
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(
          find.byType(NowPlayingPanel),
          useSidePanel(size) ? findsOneWidget : findsNothing,
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(NyaPlayerApp)),
        );
        unawaited(container.read(routerProvider).push('/now-playing'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Collapse'), findsOneWidget);
        await engine.pause();
        await tester.pump(const Duration(milliseconds: 800));
      },
    );
  }
}
