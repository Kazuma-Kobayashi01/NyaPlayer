import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 10-band centre frequencies in Hz (REQUIREMENTS EQ-01).
const eqBandFrequencies = <int>[
  31,
  62,
  125,
  250,
  500,
  1000,
  2000,
  4000,
  8000,
  16000,
];
const eqMaxGain = 12.0;

@immutable
class EqPreset {
  const EqPreset(this.id, this.gains);

  final String id;
  final List<double> gains;
}

const customPresetId = 'custom';

/// TECH_SPEC §5.3. Display names are localized by id in the UI.
const builtinEqPresets = <EqPreset>[
  EqPreset('flat', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  EqPreset('pop', [-1, 1, 3, 4, 3, 0, -1, -1, 1, 2]),
  EqPreset('rock', [4, 3, 2, 0, -1, -1, 1, 3, 4, 4]),
  EqPreset('jazz', [3, 2, 1, 2, -1, -1, 0, 1, 2, 3]),
  EqPreset('classical', [3, 2, 1, 0, 0, 0, 0, 1, 2, 3]),
  EqPreset('vocal', [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1]),
  EqPreset('bassBoost', [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
  EqPreset('trebleBoost', [0, 0, 0, 0, 0, 1, 2, 4, 5, 6]),
];

@immutable
class EqState {
  const EqState({
    this.enabled = true,
    this.presetId = 'flat',
    this.gains = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.preamp = 0,
    this.autoPreventClipping = true,
  });

  final bool enabled;
  final String presetId;
  final List<double> gains;
  final double preamp;
  final bool autoPreventClipping;

  EqState copyWith({
    bool? enabled,
    String? presetId,
    List<double>? gains,
    double? preamp,
    bool? autoPreventClipping,
  }) {
    return EqState(
      enabled: enabled ?? this.enabled,
      presetId: presetId ?? this.presetId,
      gains: gains ?? this.gains,
      preamp: preamp ?? this.preamp,
      autoPreventClipping: autoPreventClipping ?? this.autoPreventClipping,
    );
  }
}

/// What the audio core needs from [EqState] (TECH_SPEC §5.1): the effective
/// preamp already includes automatic clipping prevention.
@immutable
class EqParams {
  const EqParams({
    required this.enabled,
    required this.gains,
    required this.preamp,
  });

  factory EqParams.fromState(EqState state) {
    final maxBoost = state.gains.fold<double>(0, (m, g) => g > m ? g : m);
    return EqParams(
      enabled: state.enabled,
      gains: List.unmodifiable(state.gains),
      preamp: state.autoPreventClipping ? -maxBoost : state.preamp,
    );
  }

  static const flat = EqParams(
    enabled: false,
    gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    preamp: 0,
  );

  final bool enabled;
  final List<double> gains;
  final double preamp;

  @override
  bool operator ==(Object other) =>
      other is EqParams &&
      other.enabled == enabled &&
      other.preamp == preamp &&
      listEquals(other.gains, gains);

  @override
  int get hashCode => Object.hash(enabled, preamp, Object.hashAll(gains));
}

final eqProvider = NotifierProvider<EqController, EqState>(EqController.new);

/// UI-side EQ state. Not yet connected to the audio filter chain (M6).
class EqController extends Notifier<EqState> {
  @override
  EqState build() => const EqState();

  void setEnabled(bool value) => state = state.copyWith(enabled: value);

  void selectPreset(String id) {
    final preset = builtinEqPresets.firstWhere((p) => p.id == id);
    state = state.copyWith(presetId: id, gains: List.of(preset.gains));
  }

  void setGain(int band, double value) {
    final gains = List.of(state.gains)
      ..[band] = value.clamp(-eqMaxGain, eqMaxGain);
    state = state.copyWith(presetId: _matchPreset(gains), gains: gains);
  }

  void setPreamp(double value) => state = state.copyWith(preamp: value);

  void setAutoPreventClipping(bool value) =>
      state = state.copyWith(autoPreventClipping: value);

  void reset() => state = const EqState();

  String _matchPreset(List<double> gains) {
    for (final p in builtinEqPresets) {
      if (listEquals(p.gains, gains)) return p.id;
    }
    return customPresetId;
  }
}
