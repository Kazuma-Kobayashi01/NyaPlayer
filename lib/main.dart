import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/dev/folder_library.dart';
import 'package:nyaplayer/dev/preview_hook.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';
import 'package:nyaplayer/services/player/rust_player_engine.dart';
import 'package:nyaplayer/src/rust/api/core.dart';
import 'package:nyaplayer/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init(); // loads the Rust core (TECH_SPEC §4.1)
  Log.i('main', 'nya_core ${coreVersion()}');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Until the scanner and database exist (M2), real playback is a debug-only
  // harness: NYA_MUSIC_DIR=<folder> loads that folder with the Rust core and
  // plays through the Rust engine. Otherwise the sample library and a silent
  // fake engine drive the UI.
  final musicDir = kDebugMode ? Platform.environment['NYA_MUSIC_DIR'] : null;
  final PlayerEngine engine;
  final List<Override> overrides;
  if (musicDir != null) {
    Log.i('main', 'real playback from $musicDir');
    engine = RustPlayerEngine();
    overrides = [
      playerEngineProvider.overrideWithValue(engine),
      libraryProvider.overrideWith((ref) => loadFolderLibrary(musicDir)),
    ];
  } else {
    engine = FakePlayerEngine(
      durationOf: (path) =>
          sampleLibrary.trackByPath(path)?.duration ??
          const Duration(minutes: 3),
    );
    overrides = [playerEngineProvider.overrideWithValue(engine)];
  }

  final container = ProviderContainer(overrides: overrides);
  // The equalizer UI writes eqProvider; the engine follows it (TECH_SPEC §5).
  container.listen<EqState>(
    eqProvider,
    (_, state) => engine.setEqualizer(EqParams.fromState(state)),
    fireImmediately: true,
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NyaPlayerApp(),
    ),
  );
  if (kDebugMode) applyPreviewEnv(container);
}
