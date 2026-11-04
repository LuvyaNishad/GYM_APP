import 'dart:convert';
import 'dart:math';

import 'backup_service.dart';
import 'hive_service.dart';

typedef JsonMap = Map<String, dynamic>;

bool cloudValuesEqual(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (key) => b.containsKey(key) && cloudValuesEqual(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        Iterable<int>.generate(
          a.length,
        ).every((i) => cloudValuesEqual(a[i], b[i]));
  }
  return a == b;
}

String newCloudMutationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

JsonMap _map(Object? value) => value is Map
    ? Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map)
    : <String, dynamic>{};

abstract class CloudTransport {
  String? get currentUserId;
  Future<List<JsonMap>> pull(String owner, int afterSequence);
  Future<List<JsonMap>> push(String owner, List<JsonMap> changes);
}

class CloudSyncSummary {
  const CloudSyncSummary({
    required this.pending,
    required this.conflicts,
    this.lastSyncedAt,
  });
  final int pending;
  final Map<String, JsonMap> conflicts;
  final DateTime? lastSyncedAt;
}

/// Full records remain in Hive while offline. The last server version and
/// durable request receipts let the engine derive edits/deletions after restart.
class CloudSyncEngine {
  CloudSyncEngine(this.hive, this.transport, {this.onRemoteApplied});
  final HiveService hive;
  final CloudTransport transport;
  final void Function()? onRemoteApplied;
  static const metadataKey = 'cloud_sync_state_v1';

  static String key(String collection, String id) =>
      jsonEncode([collection, id]);

  static Map<String, JsonMap> records(JsonMap snapshot) {
    final result = <String, JsonMap>{};
    final documents = snapshot['documents'] as Map;
    for (final collection in HiveService.documentBoxes) {
      for (final entry in (documents[collection] as Map).entries) {
        result[key(collection, entry.key as String)] = _map(entry.value);
      }
    }
    final settings = snapshot['settings'] as Map;
    for (final name in BackupService.settingsKeys) {
      if (settings.containsKey(name)) {
        result[key('settings', name)] = {'value': settings[name]};
      }
    }
    return result;
  }

  static JsonMap metadata(JsonMap snapshot) =>
      _map((snapshot['settings'] as Map)[metadataKey]);

  CloudSyncSummary get summary {
    final snapshot = hive.snapshot();
    final meta = metadata(snapshot);
    final local = records(snapshot);
    final base = _map(meta['records']);
    final conflicts = _map(meta['conflicts']);
    final dirty = {
      ...local.keys,
      ...base.keys,
    }.where((k) => !cloudValuesEqual(local[k], _map(base[k])['data'])).toSet();
    dirty.addAll(_map(meta['requests']).keys);
    dirty.addAll(conflicts.keys);
    return CloudSyncSummary(
      pending: dirty.length,
      conflicts: conflicts.map((k, v) => MapEntry(k, _map(v))),
      lastSyncedAt: DateTime.tryParse(meta['last_synced_at'] as String? ?? ''),
    );
  }

  String _owner() {
    final owner = hive.ownerUserId;
    if (owner == null || owner != transport.currentUserId) {
      throw StateError('Sign in to this workspace before syncing.');
    }
    return owner;
  }

  Future<void> synchronize() async {
    final owner = _owner();
    // Resolve requests that may already have reached the server before pulling.
    await _flush(owner);
    await _pull(owner);
    await hive.changeSnapshot((snapshot) {
      final meta = metadata(snapshot);
      final local = records(snapshot);
      final base = _map(meta['records']);
      final conflicts = _map(meta['conflicts']);
      final requests = _map(meta['requests']);
      for (final k in {...local.keys, ...base.keys}) {
        final remote = _map(base[k]);
        if (conflicts.containsKey(k) ||
            requests.containsKey(k) ||
            cloudValuesEqual(local[k], remote['data'])) {
          continue;
        }
        final parts = jsonDecode(k) as List;
        requests[k] = {
          'mutation_id': newCloudMutationId(),
          'collection': parts[0],
          'record_key': parts[1],
          'expected_revision': remote['revision'] ?? 0,
          'data': local[k],
        };
      }
      meta['requests'] = requests;
      (snapshot['settings'] as Map)[metadataKey] = meta;
      return snapshot;
    });
    await _flush(owner);
    await _pull(owner);
    _owner();
    await hive.changeSnapshot((snapshot) {
      final meta = metadata(snapshot);
      meta['last_synced_at'] = DateTime.now().toUtc().toIso8601String();
      (snapshot['settings'] as Map)[metadataKey] = meta;
      return snapshot;
    });
  }

  Future<void> _flush(String owner) async {
    while (true) {
      _owner();
      final queued = _map(metadata(hive.snapshot())['requests']);
      if (queued.isEmpty) return;
      final batch = queued.values.take(100).map(_map).toList();
      final responses = await transport.push(owner, batch);
      _owner();
      final expected = batch.map((v) => v['mutation_id']).toSet();
      if (responses.length != batch.length ||
          responses
              .map((v) => v['mutation_id'])
              .toSet()
              .difference(expected)
              .isNotEmpty ||
          responses.map((v) => v['mutation_id']).toSet().length !=
              expected.length) {
        throw const FormatException(
          'Incomplete cloud acknowledgement. Retry syncing.',
        );
      }
      await hive.changeSnapshot((snapshot) {
        final meta = metadata(snapshot);
        final requests = _map(meta['requests']);
        final base = _map(meta['records']);
        final conflicts = _map(meta['conflicts']);
        final local = records(snapshot);
        for (final response in responses) {
          final record = _map(response['record']);
          _validateRecord(record);
          final k = key(
            record['collection'] as String,
            record['record_key'] as String,
          );
          if (_map(requests[k])['mutation_id'] != response['mutation_id']) {
            throw const FormatException(
              'Cloud acknowledgement targets another record.',
            );
          }
          if (!['applied', 'conflict'].contains(response['status'])) {
            throw const FormatException('Unexpected cloud response.');
          }
          if (response['status'] == 'applied' &&
              !cloudValuesEqual(record['data'], _map(requests[k])['data'])) {
            throw const FormatException(
              'Cloud acknowledgement changed the upload.',
            );
          }
          if (response['status'] == 'applied' ||
              cloudValuesEqual(local[k], record['data'])) {
            base[k] = record;
            conflicts.remove(k);
          } else if (response['status'] == 'conflict') {
            conflicts[k] = record;
          } else {
            throw const FormatException('Unexpected cloud response.');
          }
          requests.remove(k);
        }
        meta.addAll({
          'records': base,
          'requests': requests,
          'conflicts': conflicts,
        });
        (snapshot['settings'] as Map)[metadataKey] = meta;
        return snapshot;
      });
    }
  }

  Future<void> _pull(String owner) async {
    while (true) {
      _owner();
      final cursor =
          (metadata(hive.snapshot())['cursor'] as num?)?.toInt() ?? 0;
      final page = await transport.pull(owner, cursor);
      _owner();
      if (page.isEmpty) return;
      var changed = false;
      await hive.changeSnapshot((snapshot) {
        final meta = metadata(snapshot);
        final base = _map(meta['records']);
        final conflicts = _map(meta['conflicts']);
        final local = records(snapshot);
        var nextCursor = cursor;
        for (final record in page) {
          _validateRecord(record);
          final sequence = (record['sequence'] as num).toInt();
          if (sequence <= nextCursor) {
            throw const FormatException('Invalid cloud page order.');
          }
          nextCursor = sequence;
          final k = key(
            record['collection'] as String,
            record['record_key'] as String,
          );
          final previous = _map(base[k]);
          if (cloudValuesEqual(local[k], record['data'])) {
            base[k] = record;
            conflicts.remove(k);
          } else if (cloudValuesEqual(local[k], previous['data']) &&
              !conflicts.containsKey(k)) {
            _writeRecord(snapshot, record);
            base[k] = record;
            changed = true;
          } else if ((previous['revision'] ?? 0) != record['revision']) {
            conflicts[k] = record;
          }
        }
        meta.addAll({
          'records': base,
          'conflicts': conflicts,
          'cursor': nextCursor,
        });
        (snapshot['settings'] as Map)[metadataKey] = meta;
        if (changed) BackupService.validatePortableSnapshot(snapshot);
        return snapshot;
      });
      if (changed) onRemoteApplied?.call();
    }
  }

  /// Choosing the phone version bases its next upload on the reviewed revision.
  /// Choosing the cloud version replaces only that specific local record.
  Future<void> resolveConflict(
    String recordKey, {
    required bool useLocal,
    int? reviewedRevision,
  }) async {
    _owner();
    await hive.changeSnapshot((snapshot) {
      final meta = metadata(snapshot);
      final conflicts = _map(meta['conflicts']);
      final remote = _map(conflicts[recordKey]);
      if (remote.isEmpty) {
        throw StateError('This conflict is already resolved.');
      }
      if (reviewedRevision != null && remote['revision'] != reviewedRevision) {
        throw StateError('The cloud version changed. Review it again.');
      }
      final base = _map(meta['records']);
      base[recordKey] = remote;
      conflicts.remove(recordKey);
      if (!useLocal) _writeRecord(snapshot, remote);
      meta.addAll({'records': base, 'conflicts': conflicts});
      (snapshot['settings'] as Map)[metadataKey] = meta;
      BackupService.validatePortableSnapshot(snapshot);
      return snapshot;
    });
    onRemoteApplied?.call();
  }

  static void _validateRecord(JsonMap record) {
    final collection = record['collection'];
    final id = record['record_key'];
    if (!(HiveService.documentBoxes.contains(collection) ||
            collection == 'settings') ||
        id is! String ||
        id.isEmpty ||
        record['revision'] is! int ||
        (record['revision'] as int) < 0 ||
        record['sequence'] is! int ||
        (record['sequence'] as int) < 0 ||
        (record['data'] != null && record['data'] is! Map) ||
        (collection == 'settings' &&
            !BackupService.settingsKeys.contains(id))) {
      throw const FormatException('Unsupported cloud record.');
    }
  }

  static void _writeRecord(JsonMap snapshot, JsonMap record) {
    final collection = record['collection'] as String;
    final id = record['record_key'] as String;
    final payload = record['data'];
    final target = collection == 'settings'
        ? snapshot['settings'] as Map
        : (snapshot['documents'] as Map)[collection] as Map;
    if (payload == null) {
      target.remove(id);
    } else {
      target[id] = collection == 'settings'
          ? (payload as Map)['value']
          : payload;
    }
  }
}
