import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';

/// Which playback core Android and macOS use (TECH_SPEC §4.7). The engine is created
/// once at startup, so a change takes effect after the app restarts.
enum PlaybackCore {
  /// The platform's decoders: Media3 ExoPlayer on Android (M10-2),
  /// AVAudioEngine on macOS (M10-6). Default.
  system,

  /// The Rust core (symphonia + rodio), kept as a fallback until M10-9.
  rust,
}

const playbackCoreSettingKey = 'playback.core';

/// Reads the saved choice from the settings store.
PlaybackCore savedPlaybackCore(SettingsStore store) => enumByName(
  PlaybackCore.values,
  store.get(playbackCoreSettingKey),
  PlaybackCore.system,
);

final playbackCoreProvider =
    NotifierProvider<PlaybackCoreController, PlaybackCore>(
      PlaybackCoreController.new,
    );

class PlaybackCoreController extends Notifier<PlaybackCore> {
  @override
  PlaybackCore build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<PlaybackCore>(
        (_, next) => store.put(playbackCoreSettingKey, next.name),
      ),
    );
    return savedPlaybackCore(store);
  }

  void set(PlaybackCore core) => state = core;
}
