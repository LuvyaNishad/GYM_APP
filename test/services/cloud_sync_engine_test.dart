import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/cloud_sync_engine.dart';
import 'package:leon/services/hive_service.dart';
import '../helpers/memory_hive_service.dart';

const owner = '11111111-1111-4111-8111-111111111111';
JsonMap clone(Object? value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

class WorkspaceMemory extends MemoryHiveService {
  @override
  String? get ownerUserId => owner;
  bool failSnapshot = false;
  @override
  JsonMap snapshot() => {
    'documents': {
      for (final box in HiveService.documentBoxes)
        box: {
          for (final entry
              in documents[box]?.entries ?? <MapEntry<String, String>>[])
            entry.key: jsonDecode(entry.value),
        },
    },
    'settings': clone(settings),
  };
  @override
  Future<void> changeSnapshot(JsonMap Function(JsonMap) change) async {
    final next = change(snapshot());
    if (failSnapshot) throw StateError('Simulated disk failure');
    for (final box in HiveService.documentBoxes) {
      documents[box] = (next['documents'][box] as Map).map(
        (k, v) => MapEntry(k as String, jsonEncode(v)),
      );
    }
    settings.clear();
    settings.addAll(clone(next['settings']));
  }
}

class FakeCloud extends CloudTransport {
  @override
  String? currentUserId = owner;
  final rows = <String, JsonMap>{};
  final receipts = <String, JsonMap>{};
  int sequence = 0;
  bool dropReply = false;
  Completer<void>? pushGate;
  Completer<void>? pushStarted;
  @override
  Future<List<JsonMap>> pull(String user, int afterSequence) async {
    if (user != currentUserId) throw StateError('Account changed');
    return rows.values
        .where((r) => (r['sequence'] as int) > afterSequence)
        .map(clone)
        .toList()
      ..sort((a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int));
  }

  @override
  Future<List<JsonMap>> push(String user, List<JsonMap> changes) async {
    if (pushStarted?.isCompleted == false) pushStarted!.complete();
    await pushGate?.future;
    if (user != currentUserId) throw StateError('Account changed');
    final responses = <JsonMap>[];
    for (final change in changes) {
      final mutation = change['mutation_id'] as String;
      if (receipts.containsKey(mutation)) {
        responses.add(clone(receipts[mutation]));
        continue;
      }
      final key = CloudSyncEngine.key(
        change['collection'] as String,
        change['record_key'] as String,
      );
      final before = rows[key];
      final conflict =
          (before?['revision'] ?? 0) != change['expected_revision'];
      final record = conflict
          ? before ??
                {
                  'collection': change['collection'],
                  'record_key': change['record_key'],
                  'data': null,
                  'revision': 0,
                  'sequence': 0,
                }
          : {
              'collection': change['collection'],
              'record_key': change['record_key'],
              'data': change['data'],
              'revision': (before?['revision'] as int? ?? 0) + 1,
              'sequence': ++sequence,
            };
      if (!conflict) rows[key] = clone(record);
      final response = {
        'mutation_id': mutation,
        'status': conflict ? 'conflict' : 'applied',
        'record': record,
      };
      receipts[mutation] = clone(response);
      responses.add(clone(response));
    }
    if (dropReply) {
      dropReply = false;
      throw StateError('Response lost after commit');
    }
    return responses;
  }
}

WorkoutModel workout(double load, {String id = 'workout'}) => WorkoutModel(
  id: id,
  userId: owner,
  name: 'Push',
  date: DateTime(2026, 11, 4),
  exercises: [
    WorkoutExercise(
      exerciseId: 'bench',
      exerciseName: 'Bench',
      muscleGroup: 'Chest',
      rpe: 8,
      isWarmup: true,
      sets: [
        WorkoutSet(
          reps: 8,
          weightKg: load,
          weightKgRight: load + 1,
          repsRight: 7,
          rpe: 8.5,
        ),
      ],
    ),
    const WorkoutExercise(
      exerciseId: 'bench',
      exerciseName: 'Bench',
      muscleGroup: 'Chest',
      supersetGroupId: 'pair',
      sets: [WorkoutSet(reps: 6, weightKg: 30, isWarmup: true)],
    ),
  ],
);
Future<void> save(HiveService hive, double load, {String id = 'workout'}) =>
    hive.put('workouts', id, workout(load, id: id).toJson());
double weight(HiveService hive) => hive
    .read('workouts', 'workout', WorkoutModel.fromJson)!
    .exercises
    .first
    .sets
    .first
    .weightKg;

void main() {
  late WorkspaceMemory a, b;
  late FakeCloud remote;
  late CloudSyncEngine first, second;
  setUp(() {
    a = WorkspaceMemory();
    b = WorkspaceMemory();
    remote = FakeCloud();
    first = CloudSyncEngine(a, remote);
    second = CloudSyncEngine(b, remote);
  });

  test(
    'round trip preserves entire models, repeated exercises and preferences',
    () async {
      await save(a, 40.25);
      const profile = UserModel(
        id: owner,
        email: '',
        displayName: 'Athlete',
        availablePlates: [1.25, 2.5],
        audioCuesEnabled: false,
        hapticFeedbackEnabled: false,
        trainingDaysPerWeek: 3,
        startingWeightKg: 72,
        goalDirection: 'lose',
        sex: 'male',
        experienceLevel: 'intermediate',
      );
      await a.put('user', 'local', profile.toJson());
      await a.putSettingChecked('active_session_data', {'private': 'draft'});
      await a.putSettingChecked('step_boot_base', 123456);
      await a.putSettingChecked('exercise_favorites_v1', ['bench']);
      await first.synchronize();
      await second.synchronize();
      expect(
        b.read('workouts', 'workout', WorkoutModel.fromJson),
        workout(40.25),
      );
      expect(b.read('user', 'local', UserModel.fromJson), profile);
      expect(b.getSetting<List>('exercise_favorites_v1'), ['bench']);
      expect(b.getSetting<Map>('active_session_data'), isNull);
      expect(b.getSetting<int>('step_boot_base'), isNull);
      expect(first.summary.pending, 0);
    },
  );

  test(
    'independent offline records converge and deletions propagate',
    () async {
      await save(a, 40);
      await first.synchronize();
      await second.synchronize();
      await save(a, 50, id: 'second');
      await save(b, 60, id: 'third');
      await first.synchronize();
      await second.synchronize();
      await first.synchronize();
      expect(
        CloudSyncEngine.records(a.snapshot()),
        CloudSyncEngine.records(b.snapshot()),
      );
      await a.delete('workouts', 'workout');
      expect(first.summary.pending, 1);
      await first.synchronize();
      await second.synchronize();
      expect(b.read('workouts', 'workout', WorkoutModel.fromJson), isNull);
      expect(
        remote.rows[CloudSyncEngine.key('workouts', 'workout')]!['data'],
        isNull,
      );
    },
  );

  test(
    'same-record edits retain both versions until explicit resolution',
    () async {
      await save(a, 40);
      await first.synchronize();
      await second.synchronize();
      await save(a, 50);
      await save(b, 60);
      await first.synchronize();
      await second.synchronize();
      expect(weight(b), 60);
      expect(second.summary.conflicts.length, 1);
      final key = CloudSyncEngine.key('workouts', 'workout');
      expect(
        WorkoutModel.fromJson(
          clone(second.summary.conflicts[key]!['data']),
        ).exercises.first.sets.first.weightKg,
        50,
      );
      await second.resolveConflict(key, useLocal: true);
      await second.synchronize();
      await first.synchronize();
      expect(weight(a), 60);
      expect(first.summary.pending, 0);
      expect(second.summary.pending, 0);
    },
  );

  test(
    'choosing cloud deletion explicitly removes a conflicting local edit',
    () async {
      await save(a, 40);
      await first.synchronize();
      await second.synchronize();
      await a.delete('workouts', 'workout');
      await save(b, 60);
      await first.synchronize();
      await second.synchronize();
      expect(weight(b), 60);
      await second.resolveConflict(
        CloudSyncEngine.key('workouts', 'workout'),
        useLocal: false,
      );
      expect(b.read('workouts', 'workout', WorkoutModel.fromJson), isNull);
      expect(second.summary.pending, 0);
    },
  );

  test(
    'edits during upload survive acknowledgement and remain pending',
    () async {
      await save(a, 40);
      remote.pushGate = Completer<void>();
      remote.pushStarted = Completer<void>();
      final pending = first.synchronize();
      await remote.pushStarted!.future;
      await save(a, 80);
      remote.pushGate!.complete();
      await pending;
      expect(weight(a), 80);
      expect(first.summary.pending, 1);
      await first.synchronize();
      await second.synchronize();
      expect(weight(b), 80);
    },
  );

  test(
    'lost response retries exactly once then receives newer remote edit',
    () async {
      await save(a, 40);
      remote.dropReply = true;
      await expectLater(first.synchronize(), throwsStateError);
      expect(first.summary.pending, 1);
      await second.synchronize();
      await save(b, 55);
      await second.synchronize();
      final revision = remote.rows.values.single['revision'];
      await first.synchronize();
      expect(weight(a), 55);
      expect(remote.rows.values.single['revision'], revision);
      expect(first.summary.pending, 0);
    },
  );

  test(
    'account switch during request cannot send old workspace to new user',
    () async {
      await save(a, 40);
      remote.pushGate = Completer<void>();
      remote.pushStarted = Completer<void>();
      final pending = first.synchronize();
      final failure = expectLater(pending, throwsStateError);
      await remote.pushStarted!.future;
      remote.currentUserId = 'another-user';
      remote.pushGate!.complete();
      await failure;
      expect(remote.rows, isEmpty);
      expect(weight(a), 40);
      expect(first.summary.pending, 1);
    },
  );

  test(
    'failed downloaded write retains local snapshot and cursor for retry',
    () async {
      await save(a, 40);
      await first.synchronize();
      final before = b.snapshot();
      b.failSnapshot = true;
      await expectLater(second.synchronize(), throwsStateError);
      expect(b.snapshot(), before);
      b.failSnapshot = false;
      await second.synchronize();
      expect(weight(b), 40);
    },
  );

  test(
    'invalid cloud payload is rejected before replacing any local data',
    () async {
      remote.rows['bad'] = {
        'collection': 'workouts',
        'record_key': 'bad',
        'data': {'id': 'bad'},
        'revision': 1,
        'sequence': 1,
      };
      final before = b.snapshot();
      await expectLater(second.synchronize(), throwsA(anything));
      expect(b.snapshot(), before);
    },
  );

  test(
    'real Hive restart retains offline request and resolves lost reply',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'leon_cloud_restart_',
      );
      addTearDown(() async {
        await HiveService.close();
        await directory.delete(recursive: true);
      });
      await HiveService.init(storagePath: directory.path);
      final workspace = HiveService.accountWorkspaceId(owner);
      var hive = await HiveService.openWorkspace(workspace);
      await HiveService.selectWorkspace(workspace);
      var engine = CloudSyncEngine(hive, remote);
      await save(hive, 40);
      remote.dropReply = true;
      await expectLater(engine.synchronize(), throwsStateError);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      hive = await HiveService.openWorkspace(workspace);
      engine = CloudSyncEngine(hive, remote);
      expect(engine.summary.pending, 1);
      await engine.synchronize();
      expect(engine.summary.pending, 0);
      expect(remote.rows.values.single['revision'], 1);
    },
  );
}
