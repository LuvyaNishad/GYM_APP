import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:leon/core/utils/measurement_units.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/health_tracking/models/body_measurement_model.dart';
import 'package:leon/features/history/services/workout_recap_service.dart';
import 'package:leon/features/profile/services/pdf_report_service.dart';
import 'package:leon/features/profile/services/training_report_data.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/backup_service.dart';
import 'package:leon/services/export_file_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/state/app_providers.dart';
import 'package:flutter/services.dart';

WorkoutModel workout(
  String id,
  DateTime date, {
  double weight = 30,
  String? name,
}) => WorkoutModel(
  id: id,
  userId: 'guest',
  name: name ?? 'Élan – Αθήνα – Тренировка',
  date: date,
  durationSeconds: 600,
  notes: 'Private notes',
  exercises: [
    WorkoutExercise(
      exerciseId: 'row',
      exerciseName: 'Dumbbell row',
      muscleGroup: 'Back',
      sets: [
        WorkoutSet(
          weightKg: weight,
          reps: 10,
          weightKgRight: weight + 2,
          repsRight: 8,
          rpe: 8,
        ),
        const WorkoutSet(weightKg: 10, reps: 5, isWarmup: true),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const hive = HiveService();
  late Directory directory;
  late BackupService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('leon_backup_');
    await HiveService.init(storagePath: directory.path);
    service = BackupService(hive);
  });
  tearDown(() async {
    await HiveService.close();
    await directory.delete(recursive: true);
  });

  Future<void> seed() async {
    await hive.put(
      'workouts',
      'w1',
      workout('w1', DateTime(2026, 10, 2)).toJson(),
    );
    await hive.put(
      'user',
      'local',
      const UserModel(
        id: 'guest',
        email: '',
        displayName: 'Élan',
        weightUnit: 'lbs',
        trainingSchedules:
            '[{"splitId":"ppl","startedOn":"2026-10-01","trainingDays":[true,true,true,false],"isPaused":true}]',
      ).toJson(),
    );
    await hive.put(
      'splits',
      'custom',
      const TrainingSplitModel(
        id: 'custom',
        name: 'Custom routine',
        shortName: 'C',
        daysPerWeek: 3,
        description: 'Saved routine',
        isCustom: true,
        workouts: [],
        plannedMuscleSets: {},
      ).toJson(),
    );
    await hive.put(
      'body_measurements',
      'm1',
      BodyMeasurementEntry(
        id: 'm1',
        date: DateTime(2026, 10, 3),
        weightKg: 77,
        waistCm: 80,
      ).toJson(),
    );
    await hive.put(
      'custom_exercises',
      'custom_row',
      const ExerciseLibraryItem(
        id: 'custom_row',
        name: 'Custom row',
        category: 'Back',
        description: 'Authored exercise',
        primaryMuscles: ['Back'],
        isCustom: true,
      ).toJson(),
    );
    await hive.putSettingChecked('exercise_favorites_v1', ['custom_row']);
    await hive.putSettingChecked(
      'daily_habits_v1',
      jsonEncode(
        HabitLog(
          days: {
            '2026-10-02': const DayHabits(sleepHours: 8, sleepLogged: true),
          },
        ).toJson(),
      ),
    );
    await hive.putSettingChecked('step_history_by_date', '{"2026-10-02":6000}');
    await hive.putSettingChecked('step_boot_base', 900000);
  }

  Uint8List encode(Map<String, dynamic> root) =>
      Uint8List.fromList(utf8.encode(jsonEncode(root)));

  test(
    'full backup restores a fresh installation and survives reopening',
    () async {
      await seed();
      final bytes = await service.export();
      final exported = jsonDecode(utf8.decode(bytes)) as Map;
      expect(
        (exported['settings'] as Map).containsKey('step_boot_base'),
        false,
      );
      await HiveService.close();
      final fresh = await Directory.systemTemp.createTemp('leon_fresh_');
      try {
        await HiveService.init(storagePath: fresh.path);
        final preview = await service.preview(bytes);
        expect(preview.changes.join(' '), contains('1 new'));
        await service.restore(preview, RestoreMode.replaceAll);
        await HiveService.close();
        await HiveService.init(storagePath: fresh.path);
        expect(
          hive
              .read('workouts', 'w1', WorkoutModel.fromJson)!
              .exercises
              .first
              .sets
              .first
              .weightKgRight,
          32,
        );
        expect(
          hive.read('user', 'local', UserModel.fromJson)!.trainingSchedules,
          contains('"isPaused":true'),
        );
        expect(hive.contains('splits', 'custom'), true);
        expect(hive.contains('custom_exercises', 'custom_row'), true);
        expect(hive.contains('body_measurements', 'm1'), true);
        expect(hive.getSetting<List>('exercise_favorites_v1'), ['custom_row']);
        expect(
          hive.getSetting<String>('step_history_by_date'),
          contains('6000'),
        );
        expect(hive.getSetting<String>('daily_habits_v1'), contains('8'));
      } finally {
        await HiveService.close();
        await fresh.delete(recursive: true);
        await HiveService.init(storagePath: directory.path);
      }
    },
  );
  test(
    'merge modes use stable identities without duplicate workouts',
    () async {
      await seed();
      final bytes = await service.export();
      await hive.put(
        'workouts',
        'w1',
        workout('w1', DateTime(2026, 10, 2), weight: 60).toJson(),
      );
      await hive.put(
        'workouts',
        'w2',
        workout('w2', DateTime(2026, 10, 4)).toJson(),
      );
      var preview = await service.preview(bytes);
      expect(preview.changes.first, contains('1 conflicts'));
      await service.restore(preview, RestoreMode.keepExisting);
      expect(
        hive
            .read('workouts', 'w1', WorkoutModel.fromJson)!
            .exercises
            .first
            .sets
            .first
            .weightKg,
        60,
      );
      preview = await service.preview(bytes);
      await service.restore(preview, RestoreMode.useBackup);
      expect(hive.readAll('workouts', WorkoutModel.fromJson).length, 2);
      expect(
        hive
            .read('workouts', 'w1', WorkoutModel.fromJson)!
            .exercises
            .first
            .sets
            .first
            .weightKg,
        30,
      );
      preview = await service.preview(bytes);
      await service.restore(preview, RestoreMode.replaceAll);
      expect(hive.contains('workouts', 'w2'), false);
    },
  );
  test('changed data invalidates the concrete restore preview', () async {
    await seed();
    final preview = await service.preview(await service.export());
    await hive.putSettingChecked('weight_unit', 'lbs');
    await expectLater(
      service.restore(preview, RestoreMode.replaceAll),
      throwsStateError,
    );
    expect(hive.getSetting<String>('weight_unit'), 'lbs');
  });
  test('partial failed restore rolls all boxes back', () async {
    await seed();
    final bytes = await service.export();
    await hive.putSettingChecked('weight_unit', 'kg');
    final before = jsonEncode(hive.snapshot());
    final preview = await service.preview(bytes);
    await expectLater(
      service.restore(
        preview,
        RestoreMode.replaceAll,
        beforeBoxWrite: (box) async {
          if (box == 'splits') throw StateError('disk failure');
        },
      ),
      throwsStateError,
    );
    expect(jsonEncode(hive.snapshot()), before);
    expect(hive.getSetting<String>('_restore_journal'), null);
  });
  test(
    'restore tolerates step metadata refresh, preserves device state, rejects changed totals',
    () async {
      await seed();
      Map<String, Object> steps(int count, String updated) => {
        'date': '2026-10-31',
        'days': {'2026-10-31': count},
        'source': 'Phone',
        'updatedAt': updated,
      };
      await hive.putSettingChecked(
        'step_daily_snapshot',
        jsonEncode(steps(500, '2026-10-31T10:00:00Z')),
      );
      var preview = await service.preview(await service.export());
      await hive.putSettingChecked(
        'step_daily_snapshot',
        jsonEncode(steps(500, '2026-10-31T10:01:00Z')),
      );
      await hive.putSettingChecked('device_session', 'current');
      await service.restore(preview, RestoreMode.keepExisting);
      expect(hive.getSetting<String>('device_session'), 'current');
      expect(
        jsonDecode(
          hive.getSetting<String>('step_daily_snapshot')!,
        )['updatedAt'],
        '2026-10-31T10:01:00Z',
      );
      preview = await service.preview(await service.export());
      await hive.putSettingChecked(
        'step_daily_snapshot',
        jsonEncode(steps(501, '2026-10-31T10:02:00Z')),
      );
      await expectLater(
        service.restore(preview, RestoreMode.replaceAll),
        throwsStateError,
      );
    },
  );
  test(
    'restored profile and habits refresh through storage invalidation',
    () async {
      await seed();
      final bytes = await service.export();
      await hive.put(
        'user',
        'local',
        const UserModel(id: 'guest', email: '', displayName: 'Before').toJson(),
      );
      await hive.deleteSettingChecked('daily_habits_v1');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(userProfileProvider)?.displayName, 'Before');
      expect(container.read(habitLogProvider).days, isEmpty);
      final preview = await service.preview(bytes);
      await service.restore(preview, RestoreMode.replaceAll);
      container.invalidate(hiveServiceProvider);
      expect(container.read(userProfileProvider)?.displayName, 'Élan');
      expect(container.read(habitLogProvider).days, contains('2026-10-02'));
    },
  );
  test(
    'malformed portable steps and preferences cannot reach storage',
    () async {
      await seed();
      final bytes = await service.export();
      for (final (key, value) in <(String, Object)>[
        ('step_today_count', -1),
        ('onboarding_complete', 'true'),
        ('weight_unit', 'stone'),
        ('step_hourly_distribution', '[1,2]'),
        ('step_history_by_date', '{"2026-02-30":10}'),
        (
          'step_daily_snapshot',
          '{"date":"2026-10-31","source":"Phone","days":{"2026-10-31":-1}}',
        ),
      ]) {
        final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        root['settings'][key] = value;
        await expectLater(
          service.preview(encode(root)),
          throwsFormatException,
          reason: key,
        );
      }
      expect(hive.getSetting<int>('step_today_count'), null);
    },
  );
  test('bootstrap recovers a process-interrupted restore journal', () async {
    await seed();
    final before = jsonEncode(hive.snapshot());
    await hive.putSettingChecked('_restore_journal', before);
    await hive.clearBox('workouts');
    await HiveService.close();
    await HiveService.init(storagePath: directory.path);
    expect(jsonEncode(hive.snapshot()), before);
    expect(hive.contains('workouts', 'w1'), true);
  });
  test('corrupt current records stop export rather than vanish', () async {
    await Hive.box<String>('workouts').put('bad', '{broken');
    await expectLater(service.export(), throwsFormatException);
  });
  test(
    'malformed values, unknown version and duplicate JSON keys are rejected',
    () async {
      await seed();
      final root =
          jsonDecode(utf8.decode(await service.export()))
              as Map<String, dynamic>;
      root['version'] = 99;
      await expectLater(service.preview(encode(root)), throwsFormatException);
      root['version'] = 2;
      (root['documents']['workouts']['w1']['exercises'][0]['sets'][0]
              as Map)['weight_kg'] =
          -1;
      await expectLater(service.preview(encode(root)), throwsFormatException);
      final valid = utf8.decode(await service.export());
      final duplicate = valid.replaceFirst(
        '"version": 2',
        '"version": 2, "version": 2',
      );
      await expectLater(
        service.preview(Uint8List.fromList(utf8.encode(duplicate))),
        throwsFormatException,
      );
    },
  );
  test(
    'version 1 migrates missing new boxes without dropping old data',
    () async {
      await seed();
      final root =
          jsonDecode(utf8.decode(await service.export()))
              as Map<String, dynamic>;
      root['version'] = 1;
      root['documents'].remove('custom_exercises');
      root['documents'].remove('body_measurements');
      final preview = await service.preview(encode(root));
      expect(preview.documents['custom_exercises'], isEmpty);
      expect((preview.documents['workouts'] as Map).length, 1);
    },
  );
  test('active drafts cannot be replaced by restore', () async {
    await seed();
    final bytes = await service.export();
    await hive.putSettingChecked('active_session_data', {'isActive': true});
    await expectLater(
      service.restore(await service.preview(bytes), RestoreMode.replaceAll),
      throwsStateError,
    );
  });
  test(
    'monthly dataset uses history for PRs, bounds and canonical side volume',
    () {
      final data = TrainingReportData(
        month: DateTime(2026, 10),
        now: DateTime(2026, 10, 31),
        history: [
          workout('old', DateTime(2026, 9, 30), weight: 20),
          workout('new', DateTime(2026, 10, 1)),
          workout('future', DateTime(2026, 11, 1), weight: 200),
        ],
        measurements: [
          BodyMeasurementEntry(
            id: 'm',
            date: DateTime(2026, 10, 2),
            weightKg: 77,
          ),
        ],
      );
      expect(data.sessions.length, 1);
      expect(data.volumeKg, 556);
      expect(data.sets, 1);
      expect(data.prs.length, 1);
      expect(
        data.summary(const MeasurementUnits(weightUnit: 'lbs')),
        contains('lbs'),
      );
    },
  );
  test('CSV contains authored sets and both sides, escapes formula labels', () {
    final csv = utf8.decode(
      TrainingReportData.workoutsCsv([
        workout('w', DateTime(2026, 10, 2), name: '=SUM(1,2)'),
      ]),
    );
    expect(csv, contains("'=SUM(1,2)"));
    expect(csv, contains('"right","32.0","8"'));
    expect(csv, contains('"rpe"'));
    expect(csv, contains('"true"'));
    expect(csv, isNot(contains('BenchPress')));
  });
  test(
    'PDF saves real monthly Unicode data and multi-page long lists',
    () async {
      final data = TrainingReportData(
        month: DateTime(2026, 10),
        history: [
          for (var i = 0; i < 45; i++)
            workout(
              'w$i',
              DateTime(2026, 10, 1 + i % 30),
              weight: 30 + i.toDouble(),
            ),
        ],
        measurements: [
          BodyMeasurementEntry(
            id: 'm',
            date: DateTime(2026, 10, 3),
            weightKg: 77,
            waistCm: 80,
          ),
        ],
      );
      final bytes = await PdfReportService.generateMonthlyReportPdf(data);
      expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      final path = Platform.environment['LEON_PDF_QA'];
      if (path != null) await File(path).writeAsBytes(bytes);
    },
  );
  test(
    'recap is exactly 1080x1920 with privacy options and long lists',
    () async {
      final w = workout('w', DateTime(2026, 10, 2));
      final bytes = await WorkoutRecapService.png(
        w.copyWith(
          exercises: [
            for (var i = 0; i < 20; i++)
              w.exercises.first.copyWith(
                exerciseName:
                    'Very long Unicode exercise title number $i repeated in the recap',
              ),
          ],
        ),
        includeDetails: true,
      );
      final image = await decodeImageFromList(bytes);
      expect(image.width, 1080);
      expect(image.height, 1920);
      image.dispose();
      final path = Platform.environment['LEON_PNG_QA'];
      if (path != null) await File(path).writeAsBytes(bytes);
    },
  );
  test(
    'file gateway transmits exact bytes and preserves picker cancellation',
    () async {
      const channel = MethodChannel('leon/file_test');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'save' ? 'content://saved' : null;
          });
      final files = ExportFileService(channel: channel);
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(
        await files.save('backup.json', 'application/json', bytes),
        'content://saved',
      );
      expect(calls.single.arguments['bytes'], bytes);
      expect(await files.pickBackup(), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}
