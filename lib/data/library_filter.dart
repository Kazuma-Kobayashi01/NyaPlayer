import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';

/// Tracks shorter than this are left out of the library (LIB-11): ringtones,
/// sound effects and voice clips rather than music. Zero shows everything.
final minTrackDurationProvider =
    NotifierProvider<MinTrackDurationController, Duration>(
      MinTrackDurationController.new,
    );

/// Offered in the settings dialog, in seconds.
const minTrackDurationChoices = <int>[0, 15, 30, 60, 120, 300];

class MinTrackDurationController extends Notifier<Duration> {
  static const _key = 'library.minDurationSec';
  static const defaultDuration = Duration(minutes: 1);

  @override
  Duration build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<Duration>((_, next) => store.put(_key, '${next.inSeconds}')),
    );
    final seconds = int.tryParse(store.get(_key) ?? '');
    if (seconds == null || seconds < 0) return defaultDuration;
    return Duration(seconds: seconds);
  }

  void set(Duration value) => state = value;
}
