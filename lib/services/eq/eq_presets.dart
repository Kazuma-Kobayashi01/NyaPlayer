import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 15-band centre frequencies in Hz, two-thirds of an octave apart (the
/// standard 15-band graphic equalizer; REQUIREMENTS EQ-01).
const eqBandFrequencies = <int>[
  25,
  40,
  63,
  100,
  160,
  250,
  400,
  630,
  1000,
  1600,
  2500,
  4000,
  6300,
  10000,
  16000,
];

/// The earlier 10-band layout. Saved settings and user presets from that
/// version are resampled onto [eqBandFrequencies] when they are read.
const legacyEqBandFrequencies = <int>[
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

/// Flat response, one zero per band.
const eqFlatGains = <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

/// Resamples a curve defined at [from] frequencies onto [eqBandFrequencies]
/// (linear in dB over log-frequency, flat beyond the ends). Used to carry
/// 10-band settings over.
List<double> resampleEqGains(List<double> gains, List<int> from) {
  assert(gains.length == from.length);
  double at(int hz) {
    final x = math.log(hz);
    if (x <= math.log(from.first)) return gains.first;
    if (x >= math.log(from.last)) return gains.last;
    for (var i = 0; i < from.length - 1; i++) {
      final a = math.log(from[i]);
      final b = math.log(from[i + 1]);
      if (x >= a && x <= b) {
        return gains[i] + (gains[i + 1] - gains[i]) * (x - a) / (b - a);
      }
    }
    return gains.last;
  }

  return [
    for (final hz in eqBandFrequencies)
      double.parse(at(hz).toStringAsFixed(1)).clamp(-eqMaxGain, eqMaxGain),
  ];
}

@immutable
class EqPreset {
  const EqPreset(this.id, this.gains);

  final String id;
  final List<double> gains;
}

const customPresetId = 'custom';

/// TECH_SPEC §5.3. Display names are localized by id in the UI.
///
/// The first eight are ours; from `club` to `techno` they are the classic
/// Winamp / VLC curves (VLC's `equalizer_presets.h`, clamped to +-12 dB and
/// resampled to 15 bands); `loudness` is a low-volume loudness compensation.
const builtinEqPresets = <EqPreset>[
  EqPreset('flat', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  EqPreset('pop', [
    -1,
    -0.3,
    1,
    2.4,
    3.4,
    4,
    3.3,
    2,
    0,
    -0.7,
    -1,
    -1,
    0.3,
    1.3,
    2,
  ]),
  EqPreset('rock', [
    4,
    3.6,
    3,
    2.3,
    1.3,
    0,
    -0.7,
    -1,
    -1,
    0.4,
    1.6,
    3,
    3.7,
    4,
    4,
  ]),
  EqPreset('jazz', [
    3,
    2.6,
    2,
    1.3,
    1.4,
    2,
    0,
    -1,
    -1,
    -0.3,
    0.3,
    1,
    1.7,
    2.3,
    3,
  ]),
  EqPreset('classical', [
    3,
    2.6,
    2,
    1.3,
    0.6,
    0,
    0,
    0,
    0,
    0,
    0.3,
    1,
    1.7,
    2.3,
    3,
  ]),
  EqPreset('vocal', [
    -2,
    -2,
    -2,
    -1.3,
    -0.3,
    1,
    2.4,
    3.3,
    4,
    3.3,
    2.4,
    1,
    0.3,
    -0.3,
    -1,
  ]),
  EqPreset('bassBoost', [6, 5.6, 5, 4.3, 3.3, 2, 0.6, 0, 0, 0, 0, 0, 0, 0, 0]),
  EqPreset('trebleBoost', [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0.3,
    1,
    1.7,
    2.6,
    4,
    4.7,
    5.3,
    6,
  ]),
  EqPreset('club', [
    0,
    0,
    0.2,
    5.5,
    7.1,
    5.6,
    5.6,
    5.6,
    5.6,
    4,
    2.2,
    0,
    0,
    0,
    0,
  ]),
  EqPreset('dance', [
    9.6,
    8.7,
    7.1,
    3.9,
    1.5,
    0,
    0,
    -1.9,
    -5.6,
    -6.7,
    -7.2,
    -7.2,
    -2.5,
    0,
    0,
  ]),
  EqPreset('fullBass', [
    -8,
    -1.5,
    9.6,
    9.6,
    8.2,
    5.6,
    2.9,
    -0.3,
    -4,
    -6.7,
    -8.8,
    -10.4,
    -10.9,
    -11.2,
    -11.2,
  ]),
  EqPreset('fullBassTreble', [
    7.2,
    6.6,
    5.5,
    1.8,
    -2.6,
    -7.2,
    -5.6,
    -2.7,
    1.6,
    5.9,
    9,
    11.2,
    11.7,
    12,
    12,
  ]),
  EqPreset('fullTreble', [
    -9.6,
    -9.6,
    -9.6,
    -9.6,
    -7.6,
    -4,
    0.3,
    5.3,
    11.2,
    11.7,
    12,
    12,
    12,
    12,
    12,
  ]),
  EqPreset('headphones', [
    4.8,
    7.2,
    11.1,
    7.4,
    2.5,
    -3.2,
    -2.7,
    -1.1,
    1.6,
    3.8,
    6.3,
    9.6,
    11.2,
    12,
    12,
  ]),
  EqPreset('largeHall', [
    10.4,
    10.4,
    10.3,
    7.1,
    5.6,
    5.6,
    1.8,
    -1.6,
    -4.8,
    -4.8,
    -4.8,
    -4.8,
    -1.7,
    0,
    0,
  ]),
  EqPreset('live', [
    -4.8,
    -3,
    0.1,
    2.7,
    4.6,
    5.6,
    5.6,
    5.6,
    5.6,
    4.5,
    3.5,
    2.4,
    2.4,
    2.4,
    2.4,
  ]),
  EqPreset('party', [7.2, 7.2, 7, 2.3, 0, 0, 0, 0, 0, 0, 0, 0, 4.7, 7.2, 7.2]),
  EqPreset('reggae', [
    0,
    0,
    0,
    0,
    -2,
    -5.6,
    -1.8,
    2.1,
    6.4,
    6.4,
    4.3,
    0,
    0,
    0,
    0,
  ]),
  EqPreset('ska', [
    -2.4,
    -3.3,
    -4.8,
    -4.3,
    -2.6,
    0,
    2.7,
    4.5,
    5.6,
    7.8,
    9.1,
    9.6,
    10.6,
    10.7,
    9.6,
  ]),
  EqPreset('soft', [
    4.8,
    3.6,
    1.6,
    0.5,
    -0.9,
    -2.4,
    -0.8,
    1.3,
    4,
    6.7,
    8.5,
    9.6,
    10.6,
    11.5,
    12,
  ]),
  EqPreset('softRock', [
    4,
    4,
    4,
    2.9,
    1.5,
    0,
    -2.7,
    -4.5,
    -5.6,
    -4,
    -2.2,
    0,
    1.6,
    4.5,
    8.8,
  ]),
  EqPreset('techno', [
    8,
    7.1,
    5.5,
    1.8,
    -2,
    -5.6,
    -5.1,
    -3.2,
    0,
    5.4,
    8.5,
    9.6,
    9.6,
    9.3,
    8.8,
  ]),
  EqPreset('loudness', [
    6,
    5.3,
    4,
    2.6,
    1.3,
    0,
    0,
    0,
    0,
    0,
    0.3,
    1,
    2.3,
    3.3,
    4,
  ]),
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
