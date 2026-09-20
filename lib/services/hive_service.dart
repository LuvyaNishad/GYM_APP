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
final hiveServiceProvider = Provider<HiveService>((ref) => const HiveService());

class HiveService {
  const HiveService();

  /// Boxes that hold JSON documents, keyed by model id.
  static const List<String> _documentBoxes = <String>[
    AppConstants.hiveBoxWorkouts,
    AppConstants.hiveBoxUser,
    AppConstants.hiveBoxProgress,
    AppConstants.hiveBoxSplits,
  ];

  /// Initialise Hive and open every box the app needs.
  ///
  /// Must be awaited during bootstrap, before `runApp`, so that synchronous
  /// reads via [read] / [readAll] are safe from the first frame.
  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in _documentBoxes) {
      await Hive.openBox<String>(name);
    }
    // Settings hold primitives (bool/int/String), not JSON documents.
    await Hive.openBox<dynamic>(AppConstants.hiveBoxSettings);
  }

  /// Flush and close all boxes. Mainly useful in tests.
  static Future<void> close() => Hive.close();

  Box<String> _documents(String boxName) => Hive.box<String>(boxName);

  Box<dynamic> get _settings => Hive.box<dynamic>(AppConstants.hiveBoxSettings);

  // ── Documents ───────────────────────────────────────────────────────────────

  /// Write a single model, replacing any record with the same [key].
  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) =>
      _documents(boxName).put(key, jsonEncode(json));

  /// Write many models at once, keyed by [keyOf].
  Future<void> putAll<T>(
    String boxName,
    Iterable<T> models, {
    required String Function(T model) keyOf,
    required Map<String, dynamic> Function(T model) toJson,
  }) =>
      _documents(boxName).putAll(<String, String>{
        for (final model in models) keyOf(model): jsonEncode(toJson(model)),
      });

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
    for (final raw in _documents(boxName).values) {
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
      _documents(boxName).delete(key);

  Future<int> clearBox(String boxName) => _documents(boxName).clear();

  // ── Settings ────────────────────────────────────────────────────────────────

  /// Store a primitive setting. Keys live on [AppConstants].
  Future<void> putSetting(String key, Object? value) =>
      _settings.put(key, value);

  /// Read a primitive setting, falling back to [fallback] when unset.
  T? getSetting<T>(String key, {T? fallback}) =>
      _settings.get(key, defaultValue: fallback) as T?;

  Future<void> deleteSetting(String key) => _settings.delete(key);
}
