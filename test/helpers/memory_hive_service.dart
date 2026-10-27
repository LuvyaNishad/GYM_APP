import 'dart:async';
import 'dart:convert';
import 'package:leon/services/hive_service.dart';

/// Uses the same JSON boundary as Hive and exposes real asynchronous failures.
class MemoryHiveService extends HiveService {
  final settings = <String, Object?>{};
  final documents = <String, Map<String, String>>{};
  bool failSettings = false, failDocuments = false, failDelete = false;
  Completer<void>? documentGate;
  int documentWrites = 0;

  @override
  T? getSetting<T>(String key, {T? fallback}) =>
      (settings[key] as T?) ?? fallback;
  @override
  Future<void> putSetting(String key, Object? value) =>
      putSettingChecked(key, value);
  @override
  Future<void> putSettingChecked(String key, Object? value) async {
    if (failSettings) throw StateError('settings unavailable');
    settings[key] = value;
  }

  @override
  Future<void> deleteSetting(String key) => deleteSettingChecked(key);
  @override
  Future<void> deleteSettingChecked(String key) async {
    if (failDelete) throw StateError('delete unavailable');
    settings.remove(key);
  }

  @override
  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) async {
    if (documentGate != null) await documentGate!.future;
    if (failDocuments) throw StateError('documents unavailable');
    documentWrites++;
    documents.putIfAbsent(boxName, () => {})[key] = jsonEncode(json);
  }

  @override
  List<T> readAll<T>(
    String boxName,
    T Function(Map<String, dynamic>) fromJson,
  ) => [
    for (final raw in documents[boxName]?.values ?? <String>[])
      fromJson(jsonDecode(raw) as Map<String, dynamic>),
  ];
  @override
  T? read<T>(
    String boxName,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = documents[boxName]?[key];
    return raw == null
        ? null
        : fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String boxName, String key) async {
    if (failDelete) throw StateError('delete unavailable');
    documents[boxName]?.remove(key);
  }
}
