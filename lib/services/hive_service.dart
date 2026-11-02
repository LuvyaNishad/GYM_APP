/// LEON local persistence gateway.
///
/// Every model is stored as a JSON **string** keyed by id, encoded with the
/// `toJson`/`fromJson` that Freezed already generates. That means:
///
/// * no Hive type adapters and no `hive_generator` (which is Dart-3
///   incompatible and was removed from this project);
/// * no `Map<dynamic, dynamic>` casting trap — Hive hands back nested maps as
///   `Map<dynamic, dynamic>`, but `jsonDecode` always yields
///   `Map<String, dynamic>`, which is what `fromJson` expects;
/// * schema changes are just JSON changes, so migrations stay cheap.
///
/// Callers should never touch Hive directly — go through this service.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';

/// Provider that exposes the HiveService singleton.
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

class HiveService {
  const HiveService();

  /// Boxes that hold JSON documents, keyed by model id.
  static const List<String> documentBoxes = <String>[
    AppConstants.hiveBoxWorkouts,
    AppConstants.hiveBoxUser,
    AppConstants.hiveBoxProgress,
    AppConstants.hiveBoxSplits,
    AppConstants.hiveBoxBodyMeasurements,
    AppConstants.hiveBoxCustomExercises,
  ];

  /// Initialise Hive and open every box the app needs.
  ///
  /// Must be awaited before mounting app screens, so that synchronous
  /// reads via [read] / [readAll] are safe from the first frame.
  static Future<void> init({String? storagePath}) async {
    if (storagePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(storagePath);
    }
    // These files are independent. Wait for every open (including failures)
    // before running restore recovery or letting providers read synchronously.
    await Future.wait([
      for (final name in documentBoxes) Hive.openBox<String>(name),
      Hive.openBox<dynamic>(AppConstants.hiveBoxSettings),
    ]);
    final journal = Hive.box<dynamic>(
      AppConstants.hiveBoxSettings,
    ).get('_restore_journal');
    if (journal != null) {
      await const HiveService()._applySnapshot(
        Map<String, dynamic>.from(jsonDecode(journal as String) as Map),
      );
      await Hive.box<dynamic>(
        AppConstants.hiveBoxSettings,
      ).delete('_restore_journal');
    }
  }

  /// Flush and close all boxes. Mainly useful in tests.
  static Future<void> close() => Hive.close();

  Box<String> _documents(String boxName) => Hive.box<String>(boxName);

  Box<dynamic> get _settings => Hive.box<dynamic>(AppConstants.hiveBoxSettings);

  static Future<void> _writes = Future.value();
  Future<T> _write<T>(Future<T> Function() action) {
    final result = _writes.catchError((Object _) {}).then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  /// Strict reads for backups: a corrupt record must never silently disappear.
  Map<String, dynamic> snapshot() => {
    'documents': {
      for (final name in documentBoxes)
        name: {
          for (final key in _documents(name).keys)
            key.toString(): Map<String, dynamic>.from(
              jsonDecode(_documents(name).get(key)!) as Map,
            ),
        },
    },
    'settings': {
      for (final key in _settings.keys)
        if (key != '_restore_journal') key.toString(): _settings.get(key),
    },
  };

  Future<Map<String, dynamic>> flushedSnapshot() => _write(() async {
    for (final name in documentBoxes) {
      await _documents(name).flush();
    }
    await _settings.flush();
    return snapshot();
  });

  /// Journal the old store before changing any box. Interrupted restores roll
  /// back during bootstrap; failed writes roll back before reporting failure.
  Future<void> restoreSnapshot(
    Map<String, dynamic> replacement, {
    required String expectedSnapshot,
    String Function(Map<String, dynamic>)? fingerprint,
    Map<String, dynamic> Function(Map<String, dynamic>)? reconcile,
    Future<void> Function(String box)? beforeBoxWrite,
  }) => _write(() async {
    final before = snapshot();
    if ((fingerprint?.call(before) ?? jsonEncode(before)) != expectedSnapshot) {
      throw StateError(
        'Data changed since the preview. Review the backup again.',
      );
    }
    await _settings.put('_restore_journal', jsonEncode(before));
    await _settings.flush();
    try {
      await _applySnapshot(
        reconcile?.call(before) ?? replacement,
        beforeBoxWrite: beforeBoxWrite,
      );
      await _settings.delete('_restore_journal');
      await _settings.flush();
    } catch (_) {
      await _applySnapshot(before);
      await _settings.delete('_restore_journal');
      await _settings.flush();
      rethrow;
    }
  });

  Future<void> _applySnapshot(
    Map<String, dynamic> value, {
    Future<void> Function(String box)? beforeBoxWrite,
  }) async {
    final documents = value['documents'] as Map;
    for (final name in documentBoxes) {
      await beforeBoxWrite?.call(name);
      final entries = documents[name] as Map;
      await _documents(name).clear();
      await _documents(name).putAll({
        for (final key in entries.keys)
          key.toString(): jsonEncode(entries[key]),
      });
      await _documents(name).flush();
    }
    final settings = Map<String, dynamic>.from(value['settings'] as Map);
    await _settings.deleteAll(
      _settings.keys
          .where(
            (key) => key != '_restore_journal' && !settings.containsKey(key),
          )
          .toList(),
    );
    await _settings.putAll(settings);
    await _settings.flush();
  }

  // ── Documents ───────────────────────────────────────────────────────────────

  /// Write a single model, replacing any record with the same [key].
  Future<void> put(String boxName, String key, Map<String, dynamic> json) =>
      _write(() => _documents(boxName).put(key, jsonEncode(json)));

  /// Write many models at once, keyed by [keyOf].
  Future<void> putAll<T>(
    String boxName,
    Iterable<T> models, {
    required String Function(T model) keyOf,
    required Map<String, dynamic> Function(T model) toJson,
  }) => _write(
    () => _documents(boxName).putAll(<String, String>{
      for (final model in models) keyOf(model): jsonEncode(toJson(model)),
    }),
  );

  /// Read one model, or null when absent.
  ///
  /// Throws if the stored record can't be decoded — a targeted read failing is
  /// a real error worth surfacing.
  T? read<T>(
    String boxName,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = _documents(boxName).get(key);
    if (raw == null) return null;
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Read every model in a box.
  ///
  /// Records that fail to decode are skipped rather than thrown, so a single
  /// stale record left behind by a schema change can't stop the app from
  /// opening. Use [read] when a missing or corrupt record should be an error.
  List<T> readAll<T>(
    String boxName,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final models = <T>[];
    Box<String> box;
    try {
      box = _documents(boxName);
    } catch (_) {
      return models;
    }
    for (final raw in box.values) {
      try {
        models.add(fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    return models;
  }

  /// Whether a record exists for [key].
  bool contains(String boxName, String key) =>
      _documents(boxName).containsKey(key);

  Future<void> delete(String boxName, String key) =>
      _write(() => _documents(boxName).delete(key));

  Future<int> clearBox(String boxName) =>
      _write(() => _documents(boxName).clear());

  // ── Settings ────────────────────────────────────────────────────────────────

  /// Persist user-entered data without hiding write failures from its UI.
  Future<void> putSettingChecked(String key, Object? value) =>
      _write(() => _settings.put(key, value));

  Future<void> deleteSettingChecked(String key) =>
      _write(() => _settings.delete(key));

  /// Store a primitive setting. Keys live on [AppConstants].
  Future<void> putSetting(String key, Object? value) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxSettings)) return;
      await putSettingChecked(key, value);
    } catch (_) {}
  }

  /// Read a primitive setting, falling back to [fallback] when unset.
  T? getSetting<T>(String key, {T? fallback}) {
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxSettings)) return fallback;
      return _settings.get(key, defaultValue: fallback) as T?;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> deleteSetting(String key) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxSettings)) return;
      await deleteSettingChecked(key);
    } catch (_) {}
  }
}
