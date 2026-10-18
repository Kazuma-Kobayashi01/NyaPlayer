import 'package:nyaplayer/data/db/database_providers.dart'
    show eqPresetRepositoryProvider;
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/services/eq/eq_presets.dart';

export 'package:nyaplayer/services/eq/eq_presets.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class EqState {
  const EqState({
    this.enabled = false,
    this.presetId = 'flat',
    this.gains = eqFlatGains,
    this.preamp = 0,
    this.autoPreventClipping = true,
  });

  final bool enabled;
  final String presetId;
  final List<double> gains;
  final double preamp;
  final bool autoPreventClipping;

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'presetId': presetId,
    'gains': gains,
    'preamp': preamp,
    'autoPreventClipping': autoPreventClipping,
  };

  /// Tolerant of missing or damaged data: anything unusable gives defaults.
  factory EqState.fromJson(String? raw) {
    const defaults = EqState();
    if (raw == null) return defaults;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      var gains = [for (final g in map['gains'] as List) (g as num).toDouble()];
      // Settings saved by the 10-band version carry over.
      if (gains.length == legacyEqBandFrequencies.length) {
        gains = resampleEqGains(gains, legacyEqBandFrequencies);
      }
      if (gains.length != eqBandFrequencies.length) return defaults;
      return EqState(
        enabled: map['enabled'] as bool? ?? defaults.enabled,
        presetId: map['presetId'] as String? ?? customPresetId,
        gains: [for (final g in gains) g.clamp(-eqMaxGain, eqMaxGain)],
        preamp: (map['preamp'] as num?)?.toDouble() ?? 0,
        autoPreventClipping:
            map['autoPreventClipping'] as bool? ?? defaults.autoPreventClipping,
      );
    } catch (_) {
      return defaults;
    }
  }

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

  static const flat = EqParams(enabled: false, gains: eqFlatGains, preamp: 0);

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

/// EQ state. The current state is persisted as JSON; named custom presets
/// and the preset UI follow in M6.
class EqController extends Notifier<EqState> {
  static const _key = 'eq.state';

  @override
  EqState build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<EqState>(
        (_, next) => store.put(_key, jsonEncode(next.toJson())),
      ),
    );
    return EqState.fromJson(store.get(_key));
  }

  void setEnabled(bool value) => state = state.copyWith(enabled: value);

  void selectPreset(String id) {
    final preset = builtinEqPresets.firstWhere((p) => p.id == id);
    state = state.copyWith(presetId: id, gains: List.of(preset.gains));
  }

  /// Applies a preset the user saved earlier.
  void selectSaved(SavedEqPreset preset) => state = state.copyWith(
    presetId: preset.presetId,
    gains: List.of(preset.gains),
    preamp: preset.preamp,
  );

  /// Saves the current curve under [name] and selects it (EQ-04).
  Future<void> saveCurrent(String name) async {
    final gains = List.of(state.gains);
    final preamp = state.preamp;
    final id = await ref
        .read(eqPresetRepositoryProvider)
        .add(name, gains, preamp);
    state = state.copyWith(presetId: '$userPresetPrefix$id');
  }

  Future<void> renameSaved(int id, String name) =>
      ref.read(eqPresetRepositoryProvider).rename(id, name);

  /// Deletes a saved preset. If it was selected the curve stays as it is,
  /// now unnamed.
  Future<void> deleteSaved(int id) async {
    await ref.read(eqPresetRepositoryProvider).delete(id);
    if (userPresetIdOf(state.presetId) == id) {
      state = state.copyWith(presetId: customPresetId);
    }
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
