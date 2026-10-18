import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:audio_service/audio_service.dart';
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/app/desktop_lifecycle.dart';
import 'package:nyaplayer/app/theme/font_licenses.dart';
import 'package:nyaplayer/app/router.dart' show needsOnboardingProvider;
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library_filter.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/data/repositories/favorites_repository.dart';
import 'package:nyaplayer/data/repositories/library_repository.dart';
import 'package:nyaplayer/data/repositories/playback_repository.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/services/player/playback_persistence.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/dev/preview_hook.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/audio_focus_coordinator.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';
import 'package:nyaplayer/services/player/rust_player_engine.dart';
import 'package:nyaplayer/services/player/lyra_audio_handler.dart';
import 'package:nyaplayer/services/widgets/macos_widget_bridge.dart';
import 'package:nyaplayer/src/rust/api/core.dart';
import 'package:nyaplayer/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init(); // loads the Rust core (TECH_SPEC §4.1)
  Log.i('main', 'nya_core ${coreVersion()}');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  registerFontLicenses();

  // Real playback and the database-backed library by default. Debug builds
  // can set NYA_SAMPLE=1 for the silent fake engine with sample data, and
  // NYA_MUSIC_DIR=<folder> to add that folder as a scan location.
  final useSample = kDebugMode && Platform.environment['NYA_SAMPLE'] == '1';
  final PlayerEngine engine;
  final List<Override> overrides;
  // Pending settings/favourites writes, awaited before the app exits.
  Future<void> Function() flushStores = () async {};
  // Restores the previous queue (paused) and starts remembering playback.
  Future<void> Function(ProviderContainer) restorePlayback = (_) async {};
  if (useSample) {
    engine = FakePlayerEngine(
      durationOf: (path) =>
          sampleLibrary.trackByPath(path)?.duration ??
          const Duration(minutes: 3),
    );
    overrides = [playerEngineProvider.overrideWithValue(engine)];
  } else {
    engine = RustPlayerEngine();
    final database = AppDatabase();
    final repository = LibraryRepository(database);
    final devDir = kDebugMode ? Platform.environment['NYA_MUSIC_DIR'] : null;
    if (devDir != null) {
      Log.i('main', 'adding scan location from NYA_MUSIC_DIR: $devDir');
      await repository.addRoot(devDir);
    }
    final needsOnboarding = (await repository.roots()).isEmpty;
    final settings = await DbSettingsStore.open(database);
    final favorites = await DbFavoritesStore.open(database);
    final playback = DbPlaybackStore(database);
    PlaybackPersistence? persistence;
    flushStores = () => Future.wait([
      settings.flush(),
      favorites.flush(),
      ?persistence?.flush(),
    ]);
    restorePlayback = (container) async {
      final saved = await playback.load();
      if (saved != null) {
        final library = await repository.loadLibrary();
        await container
            .read(queueProvider.notifier)
            .restore(saved, library.trackById);
        Log.i('main', 'restored ${saved.queue.length} queued tracks, paused');
      }
      persistence = PlaybackPersistence(container, playback)..start();
    };
    overrides = [
      settingsStoreProvider.overrideWithValue(settings),
      favoritesStoreProvider.overrideWithValue(favorites),
      playerEngineProvider.overrideWithValue(engine),
      databaseProvider.overrideWithValue(database),
      libraryProvider.overrideWith(
        (ref) => ref
            .watch(libraryRepositoryProvider)
            .watchLibrary(minDuration: ref.watch(minTrackDurationProvider)),
      ),
      trackSearchProvider.overrideWith((ref) {
        final repository = ref.watch(searchRepositoryProvider);
        final library = ref.watch(libraryProvider).value;
        return (query) async =>
            library == null ? const [] : repository.tracks(library, query);
      }),
      needsOnboardingProvider.overrideWithValue(needsOnboarding),
    ];
  }

  final container = ProviderContainer(overrides: overrides);
  MacOSWidgetBridge? widgets;
  LyraAudioHandler? handler;
  if (Platform.isMacOS || Platform.isAndroid) {
    handler = await AudioService.init(
      builder: () => LyraAudioHandler(container),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.kazuma.nyaplayer.playback',
        androidNotificationChannelName: 'NyaPlayer',
        androidNotificationIcon: 'drawable/ic_stat_music',
        androidStopForegroundOnPause: true,
        artDownscaleWidth: 1024,
        artDownscaleHeight: 1024,
      ),
    );
    Log.i('main', 'System media session ready');
  }
  if (Platform.isMacOS) {
    final lifecycle = DesktopLifecycle(
      onExit: () async {
        try {
          await widgets?.close();
          await flushStores();
          await handler?.stop();
        } finally {
          try {
            await handler?.dispose();
          } finally {
            await engine.dispose();
            container.dispose();
          }
        }
      },
    );
    await lifecycle.initialize();
  }
  if (Platform.isAndroid) {
    // Calls, other players and unplugged headphones (TECH_SPEC §4.6).
    final session = await SystemAudioFocusSession.create();
    AudioFocusCoordinator(container, session).start();
  }
  // The equalizer UI writes eqProvider; the engine follows it (TECH_SPEC §5).
  container.listen<EqState>(
    eqProvider,
    (_, state) => engine.setEqualizer(EqParams.fromState(state)),
    fireImmediately: true,
  );
  await restorePlayback(container);
  if (Platform.isMacOS) {
    widgets = MacOSWidgetBridge(container);
    await widgets.start();
  }
  if (!useSample) unawaited(container.read(scanProvider.notifier).scan());
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NyaPlayerApp(),
    ),
  );
  if (kDebugMode) applyPreviewEnv(container);
}
