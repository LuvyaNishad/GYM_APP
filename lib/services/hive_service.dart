/// AEON local persistence gateway.
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';

/// Provider that exposes the HiveService singleton.
final hiveServiceProvider = Provider<HiveService>(
  (ref) => HiveService(workspaceId: HiveService.activeWorkspaceId),
);

class HiveService {
  const HiveService({this.workspaceId = guestWorkspaceId});

  /// A service keeps its owner for its entire lifetime, including queued writes.
  /// The original boxes remain the first guest's workspace after upgrading.
  final String workspaceId;
  static const guestWorkspaceId = 'guest';
  static const _workspaceRegistryName = 'leon_workspaces_v1';
  static String _activeWorkspaceId = guestWorkspaceId;
  static String get activeWorkspaceId => _activeWorkspaceId;
  static final _workspaceEvents = StreamController<String>.broadcast();
  static Stream<String> get workspaceChanges => _workspaceEvents.stream;
  static final _dataEvents = StreamController<String>.broadcast();
  static Stream<String> get dataChanges => _dataEvents.stream;

  static String? get pendingGuestSource =>
      Hive.box<String>(_workspaceRegistryName).get('pending_guest_source');

  static Future<void> stageGuestSource(String id) async {
    _validateWorkspace(id);
    final registry = Hive.box<String>(_workspaceRegistryName);
    await registry.put('pending_guest_source', id);
    await registry.flush();
  }

  static Future<void> clearGuestSource() async {
    final registry = Hive.box<String>(_workspaceRegistryName);
    await registry.delete('pending_guest_source');
    await registry.flush();
  }

  void _changed() => _dataEvents.add(workspaceId);

  String? get ownerUserId => workspaceId.startsWith('account_')
      ? workspaceId.substring('account_'.length)
      : null;

  static String accountWorkspaceId(String userId) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(userId)) {
      throw ArgumentError('Invalid account identifier.');
    }
    return 'account_${userId.toLowerCase()}';
  }

  static void _validateWorkspace(String id) {
    if (id != guestWorkspaceId &&
        !RegExp(r'^guest_[a-z0-9]+$').hasMatch(id) &&
        !(id.startsWith('account_') &&
            accountWorkspaceId(id.substring(8)) == id)) {
      throw ArgumentError('Invalid local workspace.');
    }
  }

  String _boxName(String name) =>
      workspaceId == guestWorkspaceId ? name : '${workspaceId}__$name';

  /// Opens an isolated workspace without selecting it or changing any records.
  static Future<HiveService> openWorkspace(String id) async {
    _validateWorkspace(id);
    final service = HiveService(workspaceId: id);
    await Future.wait([
      for (final name in documentBoxes)
        Hive.openBox<String>(service._boxName(name)),
      Hive.openBox<dynamic>(service._boxName(AppConstants.hiveBoxSettings)),
    ]);
    final journal = service._settings.get('_restore_journal');
    if (journal != null) {
      await service._applySnapshot(
        Map<String, dynamic>.from(jsonDecode(journal as String) as Map),
      );
      await service._settings.delete('_restore_journal');
      await service._settings.flush();
    }
    return service;
  }

  /// Switch only after the caller has settled forms, drafts and account auth.
  /// Old services continue to address their old workspace; no records are moved.
  static Future<void> selectWorkspace(String id) =>
      const HiveService()._write(() async {
        await openWorkspace(id);
        final registry = Hive.box<String>(_workspaceRegistryName);
        await registry.put('active_workspace', id);
        await registry.flush();
        _activeWorkspaceId = id;
        _workspaceEvents.add(id);
      });

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
    final registry = await Hive.openBox<String>(_workspaceRegistryName);
    final selected = registry.get('active_workspace') ?? guestWorkspaceId;
    await openWorkspace(selected);
    _activeWorkspaceId = selected;
  }

  /// Flush and close all boxes. Mainly useful in tests.
  static Future<void> close() async {
    await _writes;
    await Hive.close();
    _activeWorkspaceId = guestWorkspaceId;
  }

  Box<String> _documents(String boxName) => Hive.box<String>(_boxName(boxName));

  Box<dynamic> get _settings =>
      Hive.box<dynamic>(_boxName(AppConstants.hiveBoxSettings));

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
        reconcile?.call(
              Map<String, dynamic>.from(jsonDecode(jsonEncode(before)) as Map),
            ) ??
            replacement,
        beforeBoxWrite: beforeBoxWrite,
      );
      await _settings.delete('_restore_journal');
      await _settings.flush();
      _changed();
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
      final box = _documents(name);
      await box.deleteAll(
        box.keys.where((key) => !entries.containsKey(key)).toList(),
      );
      await box.putAll({
        for (final key in entries.keys)
          if (box.get(key) != jsonEncode(entries[key]))
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
    await _settings.putAll({
      for (final entry in settings.entries)
        if (jsonEncode(_settings.get(entry.key)) != jsonEncode(entry.value))
          entry.key: entry.value,
    });
    await _settings.flush();
  }

  // ── Documents ───────────────────────────────────────────────────────────────

  /// Write a single model, replacing any record with the same [key].
  Future<void> put(String boxName, String key, Map<String, dynamic> json) =>
      _write(() async {
        await _documents(boxName).put(key, jsonEncode(json));
        _changed();
      });

  /// Write many models at once, keyed by [keyOf].
  Future<void> putAll<T>(
    String boxName,
    Iterable<T> models, {
    required String Function(T model) keyOf,
    required Map<String, dynamic> Function(T model) toJson,
  }) => _write(() async {
    await _documents(boxName).putAll(<String, String>{
      for (final model in models) keyOf(model): jsonEncode(toJson(model)),
    });
    _changed();
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

  Future<void> delete(String boxName, String key) => _write(() async {
    await _documents(boxName).delete(key);
    _changed();
  });

  Future<int> clearBox(String boxName) => _write(() async {
    final count = await _documents(boxName).clear();
    _changed();
    return count;
  });

  // ── Settings ────────────────────────────────────────────────────────────────

  /// Persist user-entered data without hiding write failures from its UI.
  Future<void> putSettingChecked(String key, Object? value) => _write(() async {
    await _settings.put(key, value);
    if (key != 'cloud_sync_state_v1') _changed();
  });

  Future<void> deleteSettingChecked(String key) => _write(() async {
    await _settings.delete(key);
    if (key != 'cloud_sync_state_v1') _changed();
  });

  /// Atomically reconcile a cloud response against the latest local values.
  /// The existing restore journal protects every box and the sync metadata.
  Future<void> changeSnapshot(
    Map<String, dynamic> Function(Map<String, dynamic>) change,
  ) => restoreSnapshot(
    const {},
    expectedSnapshot: '',
    fingerprint: (_) => '',
    reconcile: change,
  );

  /// Store a primitive setting. Keys live on [AppConstants].
  Future<void> putSetting(String key, Object? value) async {
    try {
      if (!Hive.isBoxOpen(_boxName(AppConstants.hiveBoxSettings))) return;
      await putSettingChecked(key, value);
    } catch (_) {}
  }

  /// Read a primitive setting, falling back to [fallback] when unset.
  T? getSetting<T>(String key, {T? fallback}) {
    try {
      if (!Hive.isBoxOpen(_boxName(AppConstants.hiveBoxSettings))) {
        return fallback;
      }
      return _settings.get(key, defaultValue: fallback) as T?;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> deleteSetting(String key) async {
    try {
      if (!Hive.isBoxOpen(_boxName(AppConstants.hiveBoxSettings))) return;
      await deleteSettingChecked(key);
    } catch (_) {}
  }
}
