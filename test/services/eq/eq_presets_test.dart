import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';

void main() {
  test('every built-in preset has one gain per band, within range', () {
    final ids = <String>{};
    for (final p in builtinEqPresets) {
      expect(ids.add(p.id), isTrue, reason: 'duplicate ${p.id}');
      expect(p.gains, hasLength(eqBandFrequencies.length), reason: p.id);
      for (final g in p.gains) {
        expect(g.abs(), lessThanOrEqualTo(eqMaxGain), reason: p.id);
      }
    }
    expect(builtinEqPresets.first.id, 'flat');
    expect(builtinEqPresets.first.gains.every((g) => g == 0), isTrue);
  });

  test('the bands are 2/3 octave apart, 25 Hz to 16 kHz', () {
    expect(eqBandFrequencies.first, 25);
    expect(eqBandFrequencies.last, 16000);
    expect(eqBandFrequencies, hasLength(15));
    for (var i = 1; i < eqBandFrequencies.length; i++) {
      final ratio = eqBandFrequencies[i] / eqBandFrequencies[i - 1];
      expect(ratio, inInclusiveRange(1.5, 1.7));
    }
  });

  group('10-band settings carry over', () {
    test('resampling keeps a flat curve flat and a boost where it was', () {
      expect(
        resampleEqGains(List.filled(10, 0), legacyEqBandFrequencies),
        eqFlatGains,
      );
      // +6 dB at 1 kHz only.
      final old = [
        for (final hz in legacyEqBandFrequencies) hz == 1000 ? 6.0 : 0.0,
      ];
      final next = resampleEqGains(old, legacyEqBandFrequencies);
      expect(next[eqBandFrequencies.indexOf(1000)], 6.0);
      expect(next.first, 0);
      expect(next.last, 0);
    });

    test('saved state with 10 gains is resampled, not thrown away', () {
      final raw =
          '{"enabled":true,"presetId":"bassBoost",'
          '"gains":[6,5,4,2,0,0,0,0,0,0],"preamp":0,"autoPreventClipping":true}';
      final state = EqState.fromJson(raw);
      expect(state.enabled, isTrue);
      expect(state.gains, hasLength(eqBandFrequencies.length));
      expect(state.gains.first, 6);
      expect(state.gains.last, 0);
    });

    test('anything else with the wrong length falls back to defaults', () {
      final state = EqState.fromJson('{"gains":[1,2,3],"enabled":true}');
      expect(state.enabled, isFalse);
      expect(state.gains, eqFlatGains);
    });
  });
}
