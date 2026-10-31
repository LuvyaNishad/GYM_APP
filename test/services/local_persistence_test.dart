import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/features/health_tracking/models/body_measurement_model.dart';
import 'package:leon/features/health_tracking/providers/body_measurements_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/workout_service.dart';
import 'package:leon/state/app_providers.dart';
import '../helpers/memory_hive_service.dart';

const custom = ExerciseLibraryItem(
  id: 'custom_test',
  name: 'Custom row',
  category: 'Back',
  description: 'A custom exercise',
  primaryMuscles: ['latissimus dorsi'],
  equipment: ['dumbbell'],
  primaryEquipment: 'dumbbell',
  movementPattern: 'horizontal_pull',
  exerciseType: 'compound',
  difficulty: 'intermediate',
  tags: ['custom'],
  instructions: ['Row with control'],
  isCustom: true,
);
final measurement = BodyMeasurementEntry(
  id: 'legacy_measurement',
  date: DateTime(2026, 10, 1),
  weightKg: 77,
  bodyFatPercent: 18,
  waistCm: 80,
  chestCm: 100,
  armsCm: 35,
  thighsCm: 55,
  notes: 'Original',
);

WorkoutModel workout(
  String id,
  int day,
  double weight, {
  double? right,
  bool warmup = false,
}) => WorkoutModel(
  id: id,
  userId: 'guest',
  name: 'Pull',
  date: DateTime(2026, 10, day),
  notes: 'Keep this note',
  trainingPlan: const {'splitId': 'custom_split'},
  exercises: [
    WorkoutExercise(
      exerciseId: custom.id,
      exerciseName: custom.name,
      muscleGroup: 'Back',
      supersetGroupId: 'pair',
      rpe: 8,
      isWarmup: warmup,
      sets: [
        WorkoutSet(
          weightKg: weight,
          reps: 10,
          weightKgRight: right,
          repsRight: right == null ? null : 8,
          rpe: 7.5,
          isPr: true,
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'real Hive opens legacy measurements and preserves all records across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'leon_persistence_',
      );
      final parent = Directory.systemTemp.absolute.path;
      addTearDown(() async {
        await Hive.close();
        expect(directory.absolute.parent.path, parent);
        expect(
          directory.path.split(Platform.pathSeparator).last,
          startsWith('leon_persistence_'),
        );
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      final legacy = await Hive.openBox<String>('body_measurements');
      await legacy.put(measurement.id, jsonEncode(measurement.toJson()));
      await Hive.close();

      await HiveService.init(storagePath: directory.path);
      const hive = HiveService();
      var container = ProviderContainer();
      expect(
        container.read(bodyMeasurementsProvider).single.toJson(),
        measurement.toJson(),
      );
      final repository = ExerciseRepository(hive: hive)..setCatalog([]);
      await repository.addCustomExercise(custom);
      await repository.updateCustomExercise(
        custom.copyWith(name: 'Renamed row'),
      );
      const plan = PlannedExercise(
        exerciseId: 'custom_test',
        exerciseName: 'Custom row',
        muscleGroup: 'Back',
        restSeconds: 123,
      );
      await hive.put(AppConstants.hiveBoxSplits, 'plan', plan.toJson());
      final service = WorkoutService(hive);
      await service.saveWorkout(workout('first', 1, 40, right: 35));
      await service.saveWorkout(workout('second', 2, 50, right: 40));
      await container
          .read(accountProfileProvider.notifier)
          .updateProfile(
            displayName: 'Test lifter',
            experienceLevel: 'Advanced',
          );
      container.dispose();
      await Hive.close();

      await HiveService.init(storagePath: directory.path);
      container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(bodyMeasurementsProvider).single.toJson(),
        measurement.toJson(),
      );
      expect(container.read(accountProfileProvider).displayName, 'Test lifter');
      expect(container.read(userProfileProvider)!.displayName, 'Test lifter');
      final reopened = ExerciseRepository(hive: hive)..setCatalog([]);
      expect(reopened.getById(custom.id)!.name, 'Renamed row');
      final logsBefore = service.readWorkouts();
      expect(logsBefore.first.exercises.single.sets.single.isPr, isTrue);
      await reopened.deleteCustomExercise(custom.id);
      expect(service.readWorkouts(), logsBefore);
      final storedProfile = container.read(accountProfileProvider);
      final storedMeasurements = container.read(bodyMeasurementsProvider);
      final storedHistory = container.read(historyWorkoutsProvider);
      await Hive.close();
      await expectLater(
        container
            .read(accountProfileProvider.notifier)
            .updateIdentity(displayName: 'Unavailable'),
        throwsA(isA<HiveError>()),
      );
      await expectLater(
        container
            .read(bodyMeasurementsProvider.notifier)
            .deleteMeasurement(measurement.id),
        throwsA(isA<HiveError>()),
      );
      await expectLater(
        container
            .read(historyWorkoutsProvider.notifier)
            .updateWorkout(storedHistory.first.copyWith(name: 'Unavailable')),
        throwsA(isA<HiveError>()),
      );
      await expectLater(
        reopened.addCustomExercise(custom),
        throwsA(isA<HiveError>()),
      );
      expect(container.read(accountProfileProvider), storedProfile);
      expect(container.read(bodyMeasurementsProvider), storedMeasurements);
      expect(container.read(historyWorkoutsProvider), storedHistory);
      await HiveService.init(storagePath: directory.path);
      await container
          .read(accountProfileProvider.notifier)
          .updateIdentity(displayName: 'Retry saved');
      expect(container.read(accountProfileProvider).displayName, 'Retry saved');
      expect(
        hive
            .read(AppConstants.hiveBoxSplits, 'plan', PlannedExercise.fromJson)!
            .toJson(),
        plan.toJson(),
      );
      expect(plan.toActiveExerciseState().name, 'Custom row');
      await Hive.close();
      await HiveService.init(storagePath: directory.path);
      expect(ExerciseRepository(hive: hive).getById(custom.id), isNull);
      expect(service.readWorkouts(), logsBefore);
    },
  );

  test(
    'failed measurement writes/deletes retain old state and can be retried',
    () async {
      final hive = MemoryHiveService();
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bodyMeasurementsProvider.notifier);
      hive.failDocuments = true;
      await expectLater(notifier.addMeasurement(measurement), throwsStateError);
      expect(container.read(bodyMeasurementsProvider), isEmpty);
      hive.failDocuments = false;
      await notifier.addMeasurement(measurement);
      hive.failDelete = true;
      await expectLater(
        notifier.deleteMeasurement(measurement.id),
        throwsStateError,
      );
      expect(
        container.read(bodyMeasurementsProvider).single.id,
        measurement.id,
      );
      hive.failDelete = false;
      await notifier.deleteMeasurement(measurement.id);
      expect(container.read(bodyMeasurementsProvider), isEmpty);
    },
  );

  test(
    'custom CRUD failures do not mutate the catalog or saved records',
    () async {
      final hive = MemoryHiveService();
      final repo = ExerciseRepository(hive: hive)..setCatalog([]);
      hive.failDocuments = true;
      await expectLater(repo.addCustomExercise(custom), throwsStateError);
      expect(repo.allExercises, isEmpty);
      hive.failDocuments = false;
      await repo.addCustomExercise(custom);
      hive.failDocuments = true;
      await expectLater(
        repo.updateCustomExercise(custom.copyWith(name: 'Failed name')),
        throwsStateError,
      );
      expect(repo.getById(custom.id)!.name, custom.name);
      hive.failDocuments = false;
      hive.failDelete = true;
      await expectLater(repo.deleteCustomExercise(custom.id), throwsStateError);
      expect(repo.getById(custom.id), isNotNull);
      hive.failDelete = false;
      await repo.deleteCustomExercise(custom.id);
      expect(ExerciseRepository(hive: hive).allExercises, isEmpty);
    },
  );

  test(
    'profile batch failure publishes neither document; queued edits retain both changes',
    () async {
      final hive = MemoryHiveService();
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      final original = container.read(accountProfileProvider);
      final notifier = container.read(accountProfileProvider.notifier);
      hive.failDocuments = true;
      await expectLater(
        notifier.updateProfile(displayName: 'Failed'),
        throwsStateError,
      );
      expect(
        container.read(accountProfileProvider).displayName,
        original.displayName,
      );
      expect(container.read(userProfileProvider), isNull);
      expect(hive.documents[AppConstants.hiveBoxUser], isNull);
      hive.failDocuments = false;
      hive.documentGate = Completer<void>();
      final name = notifier.updateIdentity(displayName: 'Saved name');
      final weight = notifier.updateBiometrics(currentWeightKg: 82);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(accountProfileProvider).displayName,
        original.displayName,
      );
      hive.documentGate!.complete();
      await Future.wait([name, weight]);
      expect(container.read(accountProfileProvider).displayName, 'Saved name');
      expect(container.read(accountProfileProvider).currentWeightKg, 82);
      expect(container.read(userProfileProvider)!.displayName, 'Saved name');
      expect(container.read(userProfileProvider)!.currentWeight, 82);
    },
  );

  test(
    'history mutation failures retain stored bytes and derived history',
    () async {
      final hive = MemoryHiveService();
      final service = WorkoutService(hive);
      await service.saveWorkout(workout('first', 1, 40));
      await service.saveWorkout(workout('second', 2, 50));
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      final original = container.read(historyWorkoutsProvider);
      final bytes = Map.of(hive.documents[AppConstants.hiveBoxWorkouts]!);
      final notifier = container.read(historyWorkoutsProvider.notifier);
      hive.failDocuments = true;
      await expectLater(
        notifier.updateWorkout(original.first.copyWith(name: 'Failed edit')),
        throwsStateError,
      );
      expect(container.read(historyWorkoutsProvider), original);
      expect(hive.documents[AppConstants.hiveBoxWorkouts], bytes);
      hive.failDelete = true;
      await expectLater(notifier.deleteWorkout('first'), throwsStateError);
      expect(container.read(historyWorkoutsProvider), original);
      hive.failDocuments = false;
      hive.failDelete = false;
      await notifier.deleteWorkout('first');
      expect(
        container
            .read(historyWorkoutsProvider)
            .single
            .exercises
            .single
            .sets
            .single
            .isPr,
        isFalse,
      );
      expect(service.readWorkouts(), container.read(historyWorkoutsProvider));
    },
  );
}
