import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nyaplayer/services/eq/eq_presets.dart';

/// First row id of user presets. Ids below it belong to the built-in presets
/// (TECH_SPEC §5.3, `builtin = true`), whose `name` holds their key.
const firstUserEqPresetId = 100;

/// Writes the built-in presets into `eq_presets`, keeping them in step with
/// the table in code. Idempotent; never touches user presets.
Future<void> seedBuiltinEqPresets(DatabaseConnectionUser db) async {
  for (var i = 0; i < builtinEqPresets.length; i++) {
    final preset = builtinEqPresets[i];
    await db.customStatement(
      'INSERT INTO eq_presets (id, name, builtin, gains_json, preamp) '
      'VALUES (?, ?, 1, ?, 0) '
      'ON CONFLICT(id) DO UPDATE SET name = excluded.name, '
      'gains_json = excluded.gains_json WHERE builtin = 1',
      [i + 1, preset.id, jsonEncode(preset.gains)],
    );
  }
}
