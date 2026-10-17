import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/data/sample_library.dart';
import 'package:nyaplayer/dev/preview_hook.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/src/rust/api/core.dart';
import 'package:nyaplayer/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init(); // loads the Rust core (TECH_SPEC §4.1)
  Log.i('main', 'nya_core ${coreVersion()}');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // UI-first phase: a silent fake engine stands in for media_kit (M3).
  final engine = FakePlayerEngine(
    durationOf: (path) =>
        sampleLibrary.trackByPath(path)?.duration ?? const Duration(minutes: 3),
  );

  final container = ProviderContainer(
    overrides: [playerEngineProvider.overrideWithValue(engine)],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NyaPlayerApp(),
    ),
  );
  if (kDebugMode) applyPreviewEnv(container);
}
