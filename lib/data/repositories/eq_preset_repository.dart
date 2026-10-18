import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AppDatabase, EqPreset, EqPresetsCompanion;
import 'package:nyaplayer/data/db/eq_presets_seed.dart';
// The row class of the table is also called EqPreset.
import 'package:nyaplayer/services/eq/eq_presets.dart' hide EqPreset;

/// Presets the user saved (EQ-04). The built-in ones live in code and are
/// mirrored into the table for reference only.
class EqPresetRepository {
  EqPresetRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavedEqPreset>> watch() =>
      (_db.select(_db.eqPresets)
            ..where((p) => p.builtin.equals(false))
            ..orderBy([(p) => OrderingTerm.asc(p.id)]))
          .watch()
          .map((rows) => [for (final r in rows) ?_fromRow(r)]);

  /// Saves a new preset and returns its id.
  Future<int> add(String name, List<double> gains, double preamp) async {
    final top = await _db
        .customSelect('SELECT MAX(id) AS top FROM eq_presets')
        .getSingle();
    final next = (top.read<int?>('top') ?? 0) + 1;
    return _db
        .into(_db.eqPresets)
        .insert(
          EqPresetsCompanion.insert(
            id: Value(next < firstUserEqPresetId ? firstUserEqPresetId : next),
            name: name,
            gainsJson: jsonEncode(gains),
            preamp: Value(preamp),
          ),
        );
  }

  Future<void> rename(int id, String name) =>
      (_db.update(_db.eqPresets)
            ..where((p) => p.id.equals(id) & p.builtin.equals(false)))
          .write(EqPresetsCompanion(name: Value(name)));

  Future<void> delete(int id) => (_db.delete(
    _db.eqPresets,
  )..where((p) => p.id.equals(id) & p.builtin.equals(false))).go();

  SavedEqPreset? _fromRow(EqPreset row) {
    try {
      var gains = [
        for (final g in jsonDecode(row.gainsJson) as List)
          (g as num).toDouble(),
      ];
      // Presets saved by the 10-band version carry over.
      if (gains.length == legacyEqBandFrequencies.length) {
        gains = resampleEqGains(gains, legacyEqBandFrequencies);
      }
      if (gains.length != eqBandFrequencies.length) return null;
      return SavedEqPreset(
        id: row.id,
        name: row.name,
        gains: [for (final g in gains) g.clamp(-eqMaxGain, eqMaxGain)],
        preamp: row.preamp,
      );
    } catch (_) {
      return null;
    }
  }
}
