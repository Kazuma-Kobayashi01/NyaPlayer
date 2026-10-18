import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Keeps the engine's equalizer in step with the EQ settings (TECH_SPEC §5)
/// and with the current track: [passThrough] tracks (Hi-Res) play without the
/// equalizer so they stay untouched. Returns the subscriptions' closer.
void Function() bindEqualizer(
  ProviderContainer container,
  PlayerEngine engine, {
  required bool Function(Track track) passThrough,
}) {
  EqParams? sent;
  void apply() {
    final state = container.read(eqProvider);
    final track = container.read(queueProvider).current;
    var params = EqParams.fromState(state);
    if (track != null && passThrough(track)) {
      params = EqParams(
        enabled: false,
        gains: params.gains,
        preamp: params.preamp,
      );
    }
    if (params == sent) return;
    sent = params;
    engine.setEqualizer(params);
  }

  final subs = <ProviderSubscription<Object?>>[
    container.listen<EqState>(eqProvider, (_, _) => apply()),
    container.listen<bool>(
      queueProvider.select((s) {
        final track = s.current;
        return track != null && passThrough(track);
      }),
      (_, _) => apply(),
    ),
  ];
  apply();
  return () {
    for (final sub in subs) {
      sub.close();
    }
  };
}
