import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:nyaplayer/app/theme/app_theme.dart'
    show bundledSansFamily, bundledSerifFamily;
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/lyrics/lyrics_view.dart';
import 'package:nyaplayer/features/now_playing/flowing_light.dart';
import 'package:nyaplayer/features/now_playing/turntable_cover.dart';
import 'package:nyaplayer/features/now_playing/now_playing_panel.dart';
import 'package:nyaplayer/features/shared/ambient_backdrop.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/now_playing/now_playing_page.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/features/queue/queue_sheet.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/player_bar.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';
import 'package:nyaplayer/features/settings/settings_page.dart';
import 'package:nyaplayer/l10n/language_options.dart';
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
      overrides: [
        playerEngineProvider.overrideWithValue(engine),
        // These tests do not exercise scan locations; a drift stream would
        // leave a timer pending when the tree is torn down.
        rootsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const NyaPlayerApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  return engine;
}

void main() {
  testWidgets(
    'native status menu follows playback while the window renders no frames',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('nyaplayer/commands'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('nyaplayer/commands'),
          null,
        ),
      );
      final engine = await _pumpApp(tester, const Size(1400, 900));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      final queue = container.read(queueProvider.notifier);
      await queue.playTracks(sampleLibrary.tracks.take(2).toList());
      await tester.pump();
      await engine.pause();
      await tester
          .idle(); // Flush state callbacks, without drawing a window frame.
      final paused =
          calls.lastWhere((call) => call.method == 'statusMenu').arguments
              as Map;
      expect(paused['playPause'], 'Play');
      expect(paused['hasTrack'], isTrue);
      ServicesBinding.instance.channelBuffers.push(
        'nyaplayer/commands',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('togglePlayback'),
        ),
        (_) {},
      );
      await tester.idle();
      expect(engine.isPlaying, isTrue);
      final playing =
          calls.lastWhere((call) => call.method == 'statusMenu').arguments
              as Map;
      expect(playing['playPause'], 'Pause');
      await engine.pause();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'all progress styles seek through the same queue without changing playback on selection',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      final track = sampleLibrary.tracks.first;
      final queue = container.read(queueProvider.notifier);
      await queue.playTracks([track]);
      await engine.pause();
      await tester.pumpAndSettle();
      for (final style in ProgressStyle.values) {
        await queue.seek(const Duration(seconds: 30));
        await tester.pump();
        container.read(themeSettingsProvider.notifier).setProgressStyle(style);
        await tester.pumpAndSettle();
        expect(engine.currentPosition, const Duration(seconds: 30));
        expect(engine.isPlaying, isFalse);
        await tester.tapAt(tester.getCenter(find.byType(Slider)));
        await tester.pumpAndSettle();
        expect(
          engine.currentPosition.inMilliseconds,
          closeTo(track.duration.inMilliseconds / 2, 2000),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

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
    expect(find.byType(NavigationPanel), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byType(NowPlayingPanel), findsNothing);
  });

  testWidgets('wide desktop: sidebar and now-playing panel', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));
    expect(find.byType(NavigationPanel), findsOneWidget);
    expect(find.byType(NowPlayingPanel), findsOneWidget);
    expect(find.byType(PlayerBar), findsNothing);
    // The panel opens on the cover; lyrics and queue are behind the toggle.
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 800));
    final expandButton = find.ancestor(
      of: find.byIcon(Icons.open_in_full),
      matching: find.byType(IconButton),
    );
    expect(tester.getSize(expandButton).width, 34);
    expect(tester.getSize(expandButton).height, 34);
    expect(find.byType(LyricsView), findsNothing);
    expect(find.byType(QueueList), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPanel)),
    );
    await container.read(queueProvider.notifier).togglePlay();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('tablet: the wide layout stays clear of the system bars', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
    tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 32);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await _pumpApp(tester, const Size(1400, 900));
    // Flutter tests run as Android: sidebar, list and panel sit between the
    // status bar and the gesture bar.
    expect(tester.getTopLeft(find.byType(NavigationPanel)).dy, 48);
    final panel = tester.getRect(find.byType(NowPlayingPanel));
    expect(panel.top, greaterThanOrEqualTo(48));
    expect(panel.bottom, lessThanOrEqualTo(900 - 32));
  });

  testWidgets('macOS: the cards sit beside the title bar, not below it', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      tester.view.padding = const FakeViewPadding(top: 28);
      tester.view.viewPadding = const FakeViewPadding(top: 28);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pumpApp(tester, const Size(1400, 900));
      // The sidebar starts below the traffic lights.
      expect(
        tester.getTopLeft(find.byType(NavigationPanel)).dy,
        greaterThanOrEqualTo(28),
      );
      expect(tester.getRect(find.byType(NowPlayingPanel)).top, lessThan(28));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  group('player background light and glass material', () {
    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(NyaPlayerApp)));

    testWidgets('the flowing light is on by default and can be switched off', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(1400, 900));
      expect(find.byType(FlowingLight), findsOneWidget);

      containerOf(tester)
          .read(themeSettingsProvider.notifier)
          .setFlowingLight(false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FlowingLight), findsNothing);
    });

    testWidgets('the immersive player has the flowing light too', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(400, 800));
      unawaited(containerOf(tester).read(routerProvider).push('/now-playing'));
      await tester.pumpAndSettle();
      expect(find.byType(FlowingLight), findsWidgets);
    });

    testWidgets('standard material has no glass and no ambient light', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(1400, 900));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(AmbientBackdrop), findsNothing);
    });

    testWidgets('premium glass frosts the wide layout over an ambient light', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(1400, 900));
      containerOf(tester)
          .read(themeSettingsProvider.notifier)
          .setMaterial(SurfaceMaterial.glass);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AmbientBackdrop), findsOneWidget);
      // Sidebar cards, the library card and the player panel.
      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('premium glass frosts the phone layout and its player bar', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(400, 800));
      containerOf(tester)
          .read(themeSettingsProvider.notifier)
          .setMaterial(SurfaceMaterial.glass);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AmbientBackdrop), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlayerBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('both options are in the settings and take effect at once', (
      tester,
    ) async {
      await _pumpApp(tester, const Size(1000, 800));
      final container = containerOf(tester);
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first;

      final flowing = find.widgetWithText(
        SwitchListTile,
        'Flowing light background',
      );
      await tester.scrollUntilVisible(flowing, 300, scrollable: scrollable);
      // Mid-screen, clear of the floating player bar.
      await Scrollable.ensureVisible(tester.element(flowing), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(flowing);
      await tester.pumpAndSettle();
      expect(container.read(themeSettingsProvider).flowingLight, isFalse);

      final glass = find.text('Premium glass');
      await tester.scrollUntilVisible(glass, -300, scrollable: scrollable);
      await Scrollable.ensureVisible(tester.element(glass), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(glass);
      await tester.pumpAndSettle();
      expect(
        container.read(themeSettingsProvider).material,
        SurfaceMaterial.glass,
      );
      expect(find.byType(AmbientBackdrop), findsOneWidget);
    });
  });

  group('turntable cover style', () {
    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(NyaPlayerApp)));

    testWidgets('the desktop panel shows the record player', (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TurntableCover), findsNothing);

      containerOf(tester)
          .read(coverShapeProvider.notifier)
          .set(CoverShape.turntable);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TurntableCover), findsOneWidget);
      expect(tester.takeException(), isNull);
      await engine.pause();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('the phone player shows it too and keeps it between songs', (
      tester,
    ) async {
      final engine = await _pumpApp(tester, const Size(400, 800));
      final container = containerOf(tester);
      container.read(coverShapeProvider.notifier).set(CoverShape.turntable);
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 600));
      unawaited(container.read(routerProvider).push('/now-playing'));
      await tester.pumpAndSettle();

      final turntable = tester.state(find.byType(TurntableCover));
      await container.read(queueProvider.notifier).skipNext();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(TurntableCover)), same(turntable));
      expect(tester.takeException(), isNull);
      await engine.pause();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('it can be chosen in the settings', (tester) async {
      await _pumpApp(tester, const Size(1000, 800));
      final container = containerOf(tester);
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      final option = find.text('Turntable');
      await tester.scrollUntilVisible(option, 300, scrollable: scrollable);
      await Scrollable.ensureVisible(tester.element(option), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(container.read(coverShapeProvider), CoverShape.turntable);
    });
  });

  testWidgets('desktop sidebar stays expanded and library stops widening', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('nyaplayer/commands'),
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('nyaplayer/commands'),
        null,
      ),
    );
    await _pumpApp(tester, const Size(1400, 900));
    final bar = find.widgetWithText(AppBar, 'Songs');
    final width = tester.getSize(bar).width;
    final playerWidth = tester.getSize(find.byType(NowPlayingPanel)).width;
    tester.view.physicalSize = const Size(1800, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationPanel), findsOneWidget);
    expect(tester.getSize(bar).width, width);
    expect(
      tester.getSize(find.byType(NowPlayingPanel)).width,
      greaterThan(playerWidth),
    );
    expect(tester.getSize(find.byType(NavigationPanel)).width, sidebarWidth);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(calls.any((call) => call.method == 'sidebarControl'), isFalse);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

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
    expect(find.text('Playing'), findsNothing);
    expect(find.byTooltip('Player menu'), findsOneWidget);
    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    for (final label in ['Equalizer', 'Song info']) {
      expect(find.widgetWithText(MenuItemButton, label), findsOneWidget);
    }
    expect(find.widgetWithText(MenuItemButton, 'Lyrics'), findsNothing);
    expect(find.widgetWithText(MenuItemButton, 'Queue'), findsNothing);
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

  testWidgets(
    'a big window gets a bigger cover and more air, never a runaway gap',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 300));
      await engine.pause();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      unawaited(container.read(routerProvider).push('/now-playing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      final sizes = const [
        Size(1400, 900), // an ordinary window: the reference look
        Size(1920, 1080), // 16:9 full screen
        Size(2200, 1200),
        Size(3200, 1400),
      ];
      final covers = <double>[];
      final gaps = <double>[];
      for (final size in sizes) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        final page = find.byType(NowPlayingPage);
        final art = tester.getRect(
          find.descendant(of: page, matching: find.byType(PlayerArtwork)),
        );
        final lyrics = tester.getRect(
          find.descendant(of: page, matching: find.byType(LyricsView)),
        );
        covers.add(art.width);
        gaps.add(lyrics.left - art.right);
        expect(gaps.last, lessThan(260), reason: 'runaway gap at $size');
        // The cover + lyrics group stays centred in the window.
        expect(
          (art.left + lyrics.right) / 2,
          closeTo(size.width / 2, 60),
          reason: 'at $size',
        );
        expect(tester.takeException(), isNull);
      }
      // Unchanged in an ordinary window.
      expect(covers[0], 520);
      expect(gaps[0], lessThan(60));
      // Bigger screens give a bigger cover and more space, step by step.
      for (var i = 1; i < sizes.length; i++) {
        expect(covers[i], greaterThan(covers[i - 1]), reason: '${sizes[i]}');
        expect(gaps[i], greaterThan(gaps[i - 1] + 20), reason: '${sizes[i]}');
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'player buttons and progress bar are neutral grey-white, not the theme colour',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      container.read(themeSettingsProvider.notifier)
        ..setSource(ColorSource.fixed)
        ..setSeed(seedColorChoices[4]); // a strongly red theme
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 300));
      await container.read(queueProvider.notifier).toggleShuffle();
      await tester.pumpAndSettle();
      final primary = Theme.of(tester.element(find.byType(NowPlayingPanel)))
          .colorScheme
          .primary;
      expect(HSLColor.fromColor(primary).saturation, greaterThan(0.3));

      bool neutral(Color c) => HSLColor.fromColor(c).saturation < 0.01;

      final slider = tester.element(find.byType(Slider).first);
      final sliderTheme = SliderTheme.of(slider);
      expect(neutral(sliderTheme.activeTrackColor!), isTrue);
      expect(neutral(sliderTheme.thumbColor!), isTrue);
      expect(neutral(sliderTheme.inactiveTrackColor!), isTrue);

      IconButton button(String tooltip) => tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byTooltip(tooltip).first,
              matching: find.byType(IconButton),
            )
            .first,
      );
      Color colour(String tooltip, [Set<WidgetState> states = const {}]) =>
          button(tooltip).style!.foregroundColor!.resolve(states)!;

      expect(neutral(colour('Pause')), isTrue);
      expect(neutral(colour('Next')), isTrue);
      expect(neutral(colour('Previous')), isTrue);
      // Shuffle is on: bright. Repeat is off: dimmer. Both grey.
      final shuffleOn = colour('Shuffle: on', {WidgetState.selected});
      final repeatOff = colour('Repeat: off');
      expect(neutral(shuffleOn), isTrue);
      expect(neutral(repeatOff), isTrue);
      expect(repeatOff.a, lessThan(shuffleOn.a));

      await engine.pause();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the built-in fonts switch in settings changes the app font', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1000, 800));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NyaPlayerApp)),
    );
    String? family() =>
        Theme.of(tester.element(find.byType(Scaffold).first))
            .textTheme
            .bodyMedium!
            .fontFamily;
    expect(container.read(themeSettingsProvider).useBundledFonts, isTrue);
    expect(family(), bundledSansFamily);

    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'Use built-in fonts');
    // The settings list builds lazily; scroll until the row exists.
    await tester.scrollUntilVisible(
      toggle,
      300,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(container.read(themeSettingsProvider).useBundledFonts, isFalse);
    expect(family(), isNot(bundledSansFamily));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the language is chosen in a dialog and applied at once', (
    tester,
  ) async {
    // Tall enough that the whole list is built.
    await _pumpApp(tester, const Size(1000, 1500));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NyaPlayerApp)),
    );
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();

    Future<void> openDialog(String tileTitle) async {
      final tile = find.widgetWithText(ListTile, tileTitle);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    // The current value is shown on the row, and the dialog lists "System"
    // first, then every language by its own name in English-name order.
    // The settings list is lazy and the Android-only playback core tile sits
    // above the language row, so scroll the row into the built range first.
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Language'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('System'), findsWidgets);
    await openDialog('Language');
    final rows = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(ListTile),
    );
    final labels = [
      for (final e in rows.evaluate())
        ((e.widget as ListTile).title as Text).data,
    ];
    expect(labels, ['System', for (final o in languageOptions) o.label]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('language-system')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
      reason: 'the system option is the current one',
    );

    // Cancelling changes nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), isNull);

    // German applies immediately, to this page too.
    await openDialog('Language');
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), const Locale('de'));
    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Deutsch'), findsOneWidget, reason: 'shown on the row');

    // Reopened (now in German) the current language carries the tick.
    await openDialog('Sprache');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('language-de')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('繁體中文（台灣）'));
    await tester.pumpAndSettle();
    expect(
      container.read(localeProvider),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
    );
    expect(find.text('設定'), findsWidgets);

    await openDialog('語言');
    await tester.tap(find.text('English (UK)'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), const Locale('en', 'GB'));
    expect(find.text('Settings'), findsWidgets);

    // Back to following the system.
    await openDialog('Language');
    await tester.tap(find.byKey(const ValueKey('language-system')));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop lyrics keep breathing room inside artwork and quality bounds',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 300));
      await engine.pause();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      unawaited(container.read(routerProvider).push('/now-playing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      for (final size in [const Size(1400, 900), const Size(1000, 600)]) {
        tester.view.physicalSize = size;
        for (final scale in [1.0, 1.5]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 800));
          final page = find.byType(NowPlayingPage);
          final lyrics = find.descendant(
            of: page,
            matching: find.byType(LyricsView),
          );
          final art = find.descendant(
            of: page,
            matching: find.byType(PlayerArtwork),
          );
          final badge = find.descendant(
            of: page,
            matching: find.byType(QualityBadge),
          );
          expect(
            tester.getRect(lyrics).top,
            greaterThan(tester.getRect(art).top + 7.9),
          );
          expect(
            tester.getRect(lyrics).bottom,
            lessThan(tester.getRect(badge).bottom - 7.9),
          );
          expect(tester.getSize(lyrics).width, lessThanOrEqualTo(560));
          expect(tester.takeException(), isNull);
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('font setting switches the theme between sans and serif', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1000, 800));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavigationPanel)),
    );
    String? family() =>
        Theme.of(tester.element(find.byType(NavigationPanel)))
            .textTheme
            .bodyMedium
            ?.fontFamily;

    final settings = container.read(themeSettingsProvider.notifier);
    Future<void> apply() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Default: the bundled fonts.
    expect(family(), bundledSansFamily);
    settings.setFont(AppFont.serif);
    await apply();
    expect(family(), bundledSerifFamily);
    settings.setFont(AppFont.sans);
    await apply();
    expect(family(), bundledSansFamily);

    // Bundled fonts off: back to the system fonts, as before they existed.
    settings.setUseBundledFonts(false);
    await apply();
    final systemSans = family();
    expect(systemSans, isNot(bundledSansFamily));
    settings.setFont(AppFont.serif);
    await apply();
    expect(family(), isNot(systemSans));
    expect(family(), 'serif');
    settings.setFont(AppFont.sans);
    await apply();
    expect(family(), systemSans);
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

  testWidgets('lyrics font size and line spacing are typed into dialogs', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    await engine.pause();
    await tester.pump(const Duration(milliseconds: 300));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPanel)),
    );
    expect(container.read(lyricsSettingsProvider).fontSize, 20);

    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lyrics settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Font size · 20 pt'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '22');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(container.read(lyricsSettingsProvider).fontSize, 22);
    expect(container.read(lyricsSettingsProvider).lineHeight, 1.2);
    await tester.tap(find.byTooltip('Player menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lyrics settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Line spacing · 1.2 ×'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0.5');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '1.9');
    await tester.pump();
    await tester.tap(find.byTooltip('+0.1'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(container.read(lyricsSettingsProvider).lineHeight, 2);
    expect(container.read(lyricsSettingsProvider).fontSize, 22);
    expect(tester.takeException(), isNull);
    // Larger line spacing still reserves enough room in a short phone layout.
    tester.view.physicalSize = const Size(360, 640);
    unawaited(container.read(routerProvider).push('/now-playing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics advancing off screen do not pull the phone player over', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(400, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NyaPlayerApp)),
    );
    final track = sampleLibrary.tracks.firstWhere(
      (t) => t.title == 'Harbor Lights',
    );
    final queue = container.read(queueProvider.notifier);
    await queue.playTracks([track]);
    await tester.pump();
    await engine.pause();
    unawaited(container.read(routerProvider).push('/now-playing'));
    await tester.pumpAndSettle();

    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    // The lyrics page is built ahead of the swipe (so it does not jump in
    // mid-gesture) ...
    expect(find.byType(LyricsView, skipOffstage: false), findsOneWidget);
    expect(pages.page, 0);
    // ... and its "scroll to the current line" must not carry the page view
    // with it, neither when the song changes nor as the line advances.
    for (final seconds in [20, 60, 100]) {
      await queue.seek(Duration(seconds: seconds));
      await tester.pumpAndSettle();
      expect(pages.page, 0, reason: 'line at ${seconds}s');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opening paused lyrics reveals a larger current line and live spacing keeps it centred',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      final track = sampleLibrary.tracks.firstWhere(
        (t) => t.title == 'Harbor Lights',
      );
      final queue = container.read(queueProvider.notifier);
      await queue.playTracks([track]);
      await tester.pump(); // mount the seek bar and its position subscription
      await engine.pause();
      await queue.seek(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      final lyrics = container.read(lyricsProvider(track));
      final text =
          lyrics.lines[lyrics.indexAt(const Duration(seconds: 60))].text;
      unawaited(container.read(routerProvider).push('/now-playing'));
      await tester.pumpAndSettle();
      final active = find.descendant(
        of: find.byType(LyricsView),
        matching: find.text(text),
      );
      expect(active, findsOneWidget);
      TextStyle style() => DefaultTextStyle.of(tester.element(active)).style;
      expect(style().fontSize, closeTo(26, 0.001)); // 20 × 1.15 + 3
      expect(style().height, 1.2);
      expect(
        tester.getCenter(active).dy,
        closeTo(tester.getCenter(find.byType(LyricsView)).dy, 1),
      );
      container.read(lyricsSettingsProvider.notifier).setLineHeight(2);
      await tester.pumpAndSettle();
      expect(style().height, 2);
      expect(
        tester.getCenter(active).dy,
        closeTo(tester.getCenter(find.byType(LyricsView)).dy, 1),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('inline translation renders separately and its toggle hides it', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(1400, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NyaPlayerApp)),
    );
    final track = Track(
      id: 999,
      title: 'Bilingual fixture',
      artist: 'A',
      albumId: 999,
      album: 'B',
      trackNo: 1,
      duration: const Duration(minutes: 3),
      path: '/fixture.flac',
      codec: 'FLAC',
      sampleRate: 48000,
      bitDepth: 24,
      bitrateKbps: 1000,
      addedAt: DateTime(2026),
      coverSeed: 0,
      lyrics: '[00:00]A lantern\u2009一盏灯\n[00:10]Next line',
    );
    await container.read(queueProvider.notifier).playTracks([track]);
    await engine.pause();
    await tester.pumpAndSettle();
    expect(find.text('一盏灯'), findsOneWidget); // compact preview
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    await engine.seek(const Duration(seconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await engine.seek(Duration.zero);
    await tester.pumpAndSettle();
    unawaited(container.read(routerProvider).push('/now-playing'));
    await tester.pumpAndSettle();
    final view = find.byType(LyricsView);
    final original = find.descendant(
      of: view,
      matching: find.text('A lantern'),
    );
    final translated = find.descendant(of: view, matching: find.text('一盏灯'));
    expect(original, findsOneWidget);
    expect(translated, findsOneWidget);
    expect(
      tester.getRect(translated).top,
      greaterThan(tester.getRect(original).bottom),
    );
    expect(
      tester.widget<Text>(translated).style!.fontSize,
      lessThan(DefaultTextStyle.of(tester.element(original)).style.fontSize!),
    );
    container.read(lyricsSettingsProvider.notifier).setShowTranslation(false);
    await tester.pumpAndSettle();
    expect(translated, findsNothing);
    expect(original, findsOneWidget);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.text('一盏灯'), findsNothing);
    expect(find.text('Next line'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  Future<void> command(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets(
    'macOS settings shortcut preserves player and native menu uses same entry',
    (tester) async {
      final engine = await _pumpApp(tester, const Size(1400, 900));
      await tester.tap(find.text('Afterglow').first);
      await tester.pump(const Duration(milliseconds: 300));
      await engine.pause();
      await tester.tap(find.byTooltip('Expand player'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      final router = container.read(routerProvider);

      await command(tester, LogicalKeyboardKey.comma);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.last.route.path,
        '/preferences',
      );
      await command(tester, LogicalKeyboardKey.comma);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(NowPlayingPage), findsOneWidget);

      ServicesBinding.instance.channelBuffers.push(
        'nyaplayer/commands',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('openSettings'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Keyboard shortcuts'),
        400,
        scrollable: find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Keyboard shortcuts'));
      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('macOS playback and search shortcuts respect text editing', (
    tester,
  ) async {
    final engine = await _pumpApp(tester, const Size(1000, 800));
    await tester.tap(find.text('Afterglow').first);
    await tester.pump(const Duration(milliseconds: 300));
    final initial = engine.index!;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.isPlaying, isFalse);
    await command(tester, LogicalKeyboardKey.arrowRight);
    expect(engine.index, initial + 1);
    await command(tester, LogicalKeyboardKey.arrowLeft);
    expect(engine.index, initial);

    await command(tester, LogicalKeyboardKey.keyF);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Afterglow');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Afterglow'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await command(tester, LogicalKeyboardKey.arrowRight);
    expect(engine.isPlaying, isFalse);
    expect(engine.index, initial);
    // Back returns to the library without changing playback.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.isPlaying, isTrue);
    await engine.pause();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
    'background choice is available in settings and survives theme changes',
    (tester) async {
      await _pumpApp(tester, const Size(400, 800));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      expect(
        container.read(themeSettingsProvider).playerBackground,
        PlayerBackgroundStyle.blurredCover,
      );
      await tester.scrollUntilVisible(
        find.text('Theme gradient'),
        400,
        scrollable: find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Theme gradient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme gradient'));
      await tester.pumpAndSettle();
      container.read(themeSettingsProvider.notifier).setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        container.read(themeSettingsProvider).playerBackground,
        PlayerBackgroundStyle.gradient,
      );
      await tester.tap(find.text('Blurred cover'));
      await tester.pumpAndSettle();
      expect(
        container.read(themeSettingsProvider).playerBackground,
        PlayerBackgroundStyle.blurredCover,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shortcut help is shown only for the supported platform',
    (tester) async {
      await _pumpApp(tester, const Size(400, 800));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NyaPlayerApp)),
      );
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      final list = find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      var sawHelp = false;
      for (var i = 0; i < 20; i++) {
        sawHelp |= find.text('Keyboard shortcuts').evaluate().isNotEmpty;
        final state = tester.state<ScrollableState>(list);
        if (state.position.extentAfter == 0) break;
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(sawHelp, defaultTargetPlatform == TargetPlatform.macOS);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  test('Hi-Res is lossless and better than CD quality', () {
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
    // CD quality, 16-bit / 44.1 kHz, is the line.
    expect(isHiRes(make('FLAC', 16, 44100)), isFalse);
    expect(isHiRes(make('FLAC', 16, 32000)), isFalse);
    // Anything above it in either direction is Hi-Res.
    expect(isHiRes(make('FLAC', 24, 44100)), isTrue);
    expect(isHiRes(make('FLAC', 16, 48000)), isTrue);
    expect(isHiRes(make('FLAC', 24, 48000)), isTrue);
    expect(isHiRes(make('FLAC', 24, 96000)), isTrue);
    expect(isHiRes(make('FLAC', 24, 192000)), isTrue);
    // Lossy is never Hi-Res, however high the numbers.
    expect(isHiRes(make('MP3', 24, 96000)), isFalse);
    expect(isHiRes(make('MP3', 16, 48000)), isFalse);
    expect(trackQualityLabel(make('FLAC', 24, 96000)), startsWith('Hi-Res'));
    expect(trackQualityLabel(make('FLAC', 24, 48000)), startsWith('Hi-Res'));
    expect(trackQualityLabel(make('FLAC', 16, 44100)), startsWith('FLAC'));
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
    expect(useSidePanel(const Size(1100, 600)), isTrue);
    expect(useSidePanel(const Size(1000, 600)), isTrue);
    expect(useDesktopLayout(const Size(720, 960)), isTrue);
    expect(useSidePanel(const Size(960, 1100)), isTrue);
    expect(useSidePanel(const Size(800, 900)), isFalse);
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
    Size(720, 960),
    Size(960, 1100),
  ]) {
    testWidgets(
      'layout ${size.width.toInt()}x${size.height.toInt()}: shell and '
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
