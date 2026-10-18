import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart'
    show AppDatabase, SettingsCompanion;

/// Key-value user settings (the `settings` table). The whole table is read
/// once at startup, so reads are synchronous; writes go to the database in
/// order, in the background.
abstract class SettingsStore {
  String? get(String key);

  void put(String key, String value);

  /// Debug previews switch this off so their forced theme/font settings do
  /// not overwrite the developer's real ones.
  bool persist = true;
}

class MemorySettingsStore extends SettingsStore {
  MemorySettingsStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? get(String key) => _values[key];

  @override
  void put(String key, String value) => _values[key] = value;
}

class DbSettingsStore extends SettingsStore {
  DbSettingsStore._(this._db, this._values);

  final AppDatabase _db;
  final Map<String, String> _values;
  Future<void> _tail = Future.value();

  static Future<DbSettingsStore> open(AppDatabase db) async {
    final rows = await db.select(db.settings).get();
    return DbSettingsStore._(db, {for (final r in rows) r.key: r.value});
  }

  @override
  String? get(String key) => _values[key];

  @override
  void put(String key, String value) {
    if (_values[key] == value) return;
    _values[key] = value;
    if (!persist) return;
    _tail = _tail.then((_) async {
      try {
        await _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion.insert(key: key, value: value),
            );
      } catch (e) {
        Log.w('Settings', 'Cannot save $key: $e');
      }
    });
  }

  /// Completes when every write made so far has reached the database.
  Future<void> flush() => _tail;
}

/// In memory unless `main` overrides it with a [DbSettingsStore].
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => MemorySettingsStore(),
);

/// For `Notifier.listenSelf`, which also reports the initial state: only real
/// changes should be saved, so defaults are never written out and a newer
/// version can still change them.
void Function(T? previous, T next) skipInitial<T>(
  void Function(T? previous, T next) onChange,
) {
  var first = true;
  return (previous, next) {
    if (first) {
      first = false;
      return;
    }
    onChange(previous, next);
  };
}

/// Looks up an enum value by name; unknown or missing names give [fallback]
/// (a setting written by a newer version must not break startup).
T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

double doubleOr(String? raw, double fallback) =>
    double.tryParse(raw ?? '') ?? fallback;

bool boolOr(String? raw, bool fallback) => switch (raw) {
  'true' => true,
  'false' => false,
  _ => fallback,
};
