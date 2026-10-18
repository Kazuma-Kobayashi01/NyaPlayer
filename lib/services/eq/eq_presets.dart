import 'package:flutter/foundation.dart';

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

/// Prefix of [EqState.presetId] for a preset the user saved.
const userPresetPrefix = 'user:';

/// The row id behind a `user:<id>` preset id, or null for any other id.
int? userPresetIdOf(String presetId) => presetId.startsWith(userPresetPrefix)
    ? int.tryParse(presetId.substring(userPresetPrefix.length))
    : null;

/// A preset the user saved (EQ-04).
@immutable
class SavedEqPreset {
  const SavedEqPreset({
    required this.id,
    required this.name,
    required this.gains,
    this.preamp = 0,
  });

  final int id;
  final String name;
  final List<double> gains;
  final double preamp;

  String get presetId => '$userPresetPrefix$id';
}
