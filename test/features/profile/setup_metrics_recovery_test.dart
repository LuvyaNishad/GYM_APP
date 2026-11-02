import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/utils/measurement_units.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/health_tracking/models/body_measurement_model.dart';
import 'package:leon/features/health_tracking/providers/body_measurements_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';
import 'package:leon/features/onboarding/screens/onboarding_screen.dart';
import 'package:leon/features/profile/models/account_profile_model.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/recovery/providers/recovery_provider.dart';
import 'package:leon/features/recovery/screens/recovery_screen.dart';
import 'package:leon/features/workout_builder/data/split_presets.dart';
import 'package:leon/features/workout_builder/models/programme_configuration.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/models/training_schedule.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_session/providers/plate_preferences_provider.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/widgets/exercise_set_table.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/profile_storage.dart';
import 'package:leon/services/workout_service.dart';
import 'package:leon/state/app_providers.dart';

import '../../helpers/memory_hive_service.dart';

final today = DateTime(2026, 10, 31);
const user = UserModel(
  id: 'lifter',
  email: 'real@example.com',
  displayName: 'Alex',
  preferredSplit: 'split_ppl',
);
ProviderContainer containerFor(MemoryHiveService hive) => ProviderContainer(
  overrides: [
    hiveServiceProvider.overrideWithValue(hive),
    localDateProvider.overrideWith((ref) => today),
  ],
);
WorkoutModel workout(
  String id,
  DateTime date, {
  double weight = 20,
  String name = 'Push Day A',
}) => WorkoutModel(
  id: id,
  userId: user.id,
  name: name,
  date: date,
  exercises: [
    WorkoutExercise(
      exerciseId: 'press',
      exerciseName: 'Press',
      muscleGroup: 'Chest',
      sets: [WorkoutSet(weightKg: weight, reps: 10)],
    ),
  ],
);
Future<void> seedUser(MemoryHiveService hive, [UserModel value = user]) =>
    hive.put(
      AppConstants.hiveBoxUser,
      AppConstants.hiveKeyLocalProfile,
      value.toJson(),
    );

class _InputSession extends ActiveSessionNotifier {
  _InputSession(this.unilateral);
  final bool unilateral;
  @override
  ActiveSessionState build() {
    super.build();
    return ActiveSessionState(
      startTime: today,
      exercises: [
        ActiveExerciseState(
          exerciseId: 'press',
          name: 'Press',
          muscleGroup: 'Chest',
          isUnilateral: unilateral,
          sets: [
            ActiveSetState(
              setNumber: 1,
              weightKg: 20,
              reps: 10,
              weightKgRight: unilateral ? 30 : null,
              repsRight: unilateral ? 8 : null,
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  test(
    'Actual Hive restart retains setup, preferences, schedules and recovery check-in',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'leon-profile-recovery-',
      );
      await HiveService.init(storagePath: directory.path);
      addTearDown(() async {
        await HiveService.close();
        expect(
          directory.absolute.path.startsWith(
            Directory.systemTemp.absolute.path,
          ),
          isTrue,
        );
        await directory.delete(recursive: true);
      });
      const hive = HiveService();
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          localDateProvider.overrideWith((ref) => today),
        ],
      );
      final setup = container.read(onboardingProvider.notifier);
      setup.setAge(32);
      setup.setHeight(180);
      setup.setWeight(80);
      setup.setTargetWeight(85);
      setup.setTrainingDays(3);
      await setup.complete();
      await container
          .read(platePreferencesProvider.notifier)
          .save(const PlatePreferences(barKg: 15, plates: [10, 5]));
      await container
          .read(splitsProvider.notifier)
          .pauseTraining(resumeOn: today.add(const Duration(days: 4)));
      await container
          .read(habitLogProvider.notifier)
          .saveRecoveryCheckIn(
            date: today,
            hours: 8,
            waterToAdd: 2000,
            soreness: 3,
          );
      final saved = container.read(userProfileProvider)!;
      await HiveService.close();
      await expectLater(
        container
            .read(accountProfileProvider.notifier)
            .updatePreferences(defaultRestSeconds: 180),
        throwsA(isA<HiveError>()),
      );
      expect(container.read(userProfileProvider), saved);
      container.dispose();
      await HiveService.init(storagePath: directory.path);
      final reopened = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          localDateProvider.overrideWith((ref) => today),
        ],
      );
      addTearDown(reopened.dispose);
      expect(reopened.read(userProfileProvider), saved);
      expect(reopened.read(onboardingCompleteProvider), isTrue);
      expect(reopened.read(splitsProvider).activeSplit.daysPerWeek, 3);
      expect(
        trainingResumeDate(reopened.read(splitsProvider).schedules, today),
        today.add(const Duration(days: 4)),
      );
      expect(reopened.read(platePreferencesProvider).plates, [10, 5]);
      expect(reopened.read(recoverySummaryProvider).habits.soreness, 3);
      expect(reopened.read(recoverySummaryProvider).score, isNotNull);
    },
  );

  test(
    'Legacy Account merges only missing fields; explicit canonical unsets survive restart',
    () async {
      final hive = MemoryHiveService();
      await hive.put(
        AppConstants.hiveBoxUser,
        AppConstants.hiveKeyLocalProfile,
        {'id': 'real-id', 'email': 'real@example.com', 'display_name': 'Alex'},
      );
      await hive.put(AppConstants.hiveBoxUser, 'account_profile_data', {
        'height_cm': 180,
        'age': 32,
        'default_rest_seconds': 120,
        'email': 'athlete@leon.fit',
      });
      final migrated = readLocalProfile(hive)!;
      expect(migrated.heightCm, 180);
      expect(migrated.age, 32);
      expect(migrated.email, 'real@example.com');
      expect(migrated.currentWeight, isNull);
      expect(migrated.startingWeightKg, isNull);
      await seedUser(hive, migrated.copyWith(age: null, heightCm: null));
      final reopened = containerFor(hive);
      addTearDown(reopened.dispose);
      expect(reopened.read(accountProfileProvider).age, isNull);
      expect(reopened.read(accountProfileProvider).heightCm, isNull);
    },
  );

  test(
    'Setup replay persists choices and preserves identity, history, past schedule and pause return',
    () async {
      final hive = MemoryHiveService();
      final past = TrainingSchedule.fromSplit(
        kPresetSplits.first,
        today.subtract(const Duration(days: 10)),
      );
      final paused = TrainingSchedule.fromSplit(
        kPresetSplits.first,
        today.subtract(const Duration(days: 2)),
        isPaused: true,
        historyStartedOn: past.startedOn,
      );
      final returnDay = today.add(const Duration(days: 7));
      final scheduledReturn = TrainingSchedule.fromSplit(
        kPresetSplits.first,
        returnDay,
        historyStartedOn: past.startedOn,
      );
      await seedUser(
        hive,
        user.copyWith(
          createdAt: DateTime(2020),
          avatarUrl: 'avatar',
          onboardingComplete: true,
          trainingSchedules: TrainingSchedule.encode([
            past,
            paused,
            scheduledReturn,
          ]),
        ),
      );
      await WorkoutService(
        hive,
      ).saveWorkout(workout('saved', today.subtract(const Duration(days: 3))));
      final container = containerFor(hive);
      final setup = container.read(onboardingProvider.notifier);
      await setup.reset();
      expect(container.read(onboardingCompleteProvider), isTrue);
      setup.setAge(32);
      setup.setHeight(182);
      setup.setWeight(80);
      setup.setTargetWeight(85);
      setup.setWeightUnit(false);
      setup.setHeightUnit(false);
      setup.setTrainingDays(3);
      setup.setPreferredSplit('Full Body');
      setup.setExperienceLevel('ADVANCED');
      setup.toggleInjury('Knee');
      await setup.complete();
      final updated = container.read(userProfileProvider)!;
      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.avatarUrl, 'avatar');
      expect(updated.createdAt, DateTime(2020));
      expect(updated.age, 32);
      expect(updated.heightCm, 182);
      expect(updated.currentWeight, 80);
      expect(updated.targetWeight, 85);
      expect(updated.startingWeightKg, 80);
      expect(updated.goalDirection, 'gain');
      expect(updated.experienceLevel, 'ADVANCED');
      expect(updated.trainingDaysPerWeek, 3);
      expect(updated.injuries, ['Knee']);
      expect(updated.heightUnit, 'ft');
      final schedules = container.read(splitsProvider).schedules;
      expect(schedules.first.toJson(), past.toJson());
      expect(trainingScheduleForDate(schedules, today)!.isPaused, isTrue);
      expect(trainingResumeDate(schedules, today), returnDay);
      expect(container.read(historyWorkoutsProvider).single.id, 'saved');
      container.dispose();
      final restarted = containerFor(hive);
      addTearDown(restarted.dispose);
      expect(restarted.read(userProfileProvider), updated);
      expect(restarted.read(splitsProvider).activeSplitId, 'split_full_body');
      expect(restarted.read(splitsProvider).activeSplit.daysPerWeek, 3);
      expect(restarted.read(onboardingCompleteProvider), isTrue);
    },
  );

  test(
    'Skipped setup leaves biometrics unset and failed save is retryable',
    () async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final setup = container.read(onboardingProvider.notifier);
      hive.failDocuments = true;
      await expectLater(setup.complete(), throwsStateError);
      expect(container.read(onboardingCompleteProvider), isFalse);
      expect(container.read(userProfileProvider), isNull);
      hive.failDocuments = false;
      await setup.complete();
      final saved = container.read(accountProfileProvider);
      expect(saved.email, '');
      expect(saved.age, isNull);
      expect(saved.currentWeightKg, isNull);
      expect(saved.goalProgress, isNull);
    },
  );

  test('Frequency and gear alter presets; custom routines remain authored', () {
    final configured = configureProgramme(
      kPresetSplits.first,
      user.copyWith(trainingDaysPerWeek: 3, equipment: ['Dumbbells']),
    );
    expect(configured.daysPerWeek, 3);
    expect(configured.workouts.any((w) => w.isRestDay), isFalse);
    expect(
      configured.workouts
          .expand((w) => w.exercises)
          .every(
            (e) =>
                e.equipment == 'dumbbell' &&
                !e.exerciseName.toLowerCase().contains('incline'),
          ),
      isTrue,
    );
    final schedule = TrainingSchedule.fromSplit(configured, today);
    expect(
      List.generate(
        7,
        (i) => schedule.isTrainingDay(today.add(Duration(days: i))),
      ).where((b) => b).length,
      3,
    );
    final fullGym = configureProgramme(
      kPresetSplits.first,
      user.copyWith(trainingDaysPerWeek: 4, equipment: ['Full Gym']),
    );
    expect(
      fullGym.workouts.first.exercises.length,
      kPresetSplits.first.workouts.first.exercises.length,
    );
    final custom = configured.copyWith(isCustom: true);
    expect(
      configureProgramme(custom, user.copyWith(trainingDaysPerWeek: 5)),
      same(custom),
    );
  });

  test(
    'Account activates the actual split, preserves pause, and reports failed switches',
    () async {
      final hive = MemoryHiveService();
      await seedUser(hive);
      final container = containerFor(hive);
      addTearDown(container.dispose);
      await container.read(splitsProvider.notifier).pauseTraining();
      await container
          .read(accountProfileProvider.notifier)
          .updatePreferences(preferredSplit: 'Upper/Lower');
      expect(container.read(splitsProvider).activeSplitId, 'split_upper_lower');
      expect(
        trainingScheduleForDate(
          container.read(splitsProvider).schedules,
          today,
        )!.isPaused,
        isTrue,
      );
      hive.failDocuments = true;
      await expectLater(
        container
            .read(splitsProvider.notifier)
            .switchActiveSplit('split_arnold'),
        throwsStateError,
      );
      expect(container.read(splitsProvider).activeSplitId, 'split_upper_lower');
    },
  );

  test(
    'Rest overrides and plate preferences persist with canonical weight units',
    () async {
      const inherited = PlannedExercise(
        exerciseId: 'e',
        exerciseName: 'Press',
        muscleGroup: 'Chest',
      );
      expect(
        inherited
            .toActiveExerciseState(defaultRestSeconds: 180)
            .restDurationSeconds,
        180,
      );
      final explicit = inherited.copyWith(restSeconds: 90);
      expect(
        PlannedExercise.fromJson(
          explicit.toJson(),
        ).toActiveExerciseState(defaultRestSeconds: 180).restDurationSeconds,
        90,
      );
      final hive = MemoryHiveService();
      await seedUser(hive);
      final container = containerFor(hive);
      await container
          .read(accountProfileProvider.notifier)
          .updatePreferences(defaultRestSeconds: 180, barbellTareKg: 15);
      await container
          .read(platePreferencesProvider.notifier)
          .save(const PlatePreferences(barKg: 10, plates: [5, 2.5]));
      container.dispose();
      final restarted = containerFor(hive);
      addTearDown(restarted.dispose);
      expect(restarted.read(accountProfileProvider).barbellTareKg, 10);
      expect(restarted.read(platePreferencesProvider).plates, [5, 2.5]);
      expect(restarted.read(accountProfileProvider).defaultRestSeconds, 180);
      const imperial = MeasurementUnits(weightUnit: 'lbs', heightUnit: 'ft');
      expect(imperial.weightToKg(imperial.weightFromKg(80)), closeTo(80, 1e-9));
      expect(
        imperial.heightToCm(imperial.heightFromCm(182)),
        closeTo(182, 1e-9),
      );
      expect(imperial.height(182), '6 ft 0 in');
    },
  );

  test('Concurrent profile and plate writes preserve both changes', () async {
    final hive = MemoryHiveService();
    await seedUser(hive);
    final container = containerFor(hive);
    addTearDown(container.dispose);
    hive.documentGate = Completer<void>();
    final plates = container
        .read(platePreferencesProvider.notifier)
        .save(const PlatePreferences(barKg: 10, plates: [5]));
    final rest = container
        .read(accountProfileProvider.notifier)
        .updatePreferences(defaultRestSeconds: 180);
    await Future<void>.delayed(Duration.zero);
    hive.documentGate!.complete();
    await Future.wait([plates, rest]);
    expect(container.read(userProfileProvider)!.barbellTareKg, 10);
    expect(container.read(userProfileProvider)!.defaultRestSeconds, 180);
    expect(container.read(userProfileProvider)!.availablePlates, [5]);
    expect(container.read(accountProfileProvider).barbellTareKg, 10);
  });

  test(
    'Account statistics refresh after actual saves, edits and deletions; future logs excluded',
    () async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      expect(container.read(accountProfileProvider).totalWorkouts, 0);
      final service = container.read(workoutServiceProvider);
      await service.saveWorkout(workout('a', today));
      await service.saveWorkout(
        workout('future', today.add(const Duration(days: 1))),
      );
      container.read(historyWorkoutsProvider.notifier).refresh();
      expect(container.read(accountProfileProvider).totalWorkouts, 1);
      expect(container.read(accountProfileProvider).totalVolumeKg, 200);
      await container
          .read(historyWorkoutsProvider.notifier)
          .updateWorkout(workout('a', today, weight: 30));
      expect(container.read(accountProfileProvider).totalVolumeKg, 300);
      await container.read(historyWorkoutsProvider.notifier).deleteWorkout('a');
      expect(container.read(accountProfileProvider).totalWorkouts, 0);
      expect(container.read(accountProfileProvider).totalVolumeKg, 0);
    },
  );

  test(
    'Measurement comparison uses an actual month, handles missing fields and future midnight',
    () async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final measurements = container.read(bodyMeasurementsProvider.notifier);
      await measurements.addMeasurement(
        BodyMeasurementEntry(
          id: 'old',
          date: today.subtract(const Duration(days: 100)),
          weightKg: 100,
        ),
      );
      await measurements.addMeasurement(
        BodyMeasurementEntry(
          id: 'recent',
          date: today,
          weightKg: 80,
          waistCm: 85,
          thighsCm: 50,
        ),
      );
      expect(
        container.read(recompositionSummaryProvider).weightDelta30d,
        isNull,
      );
      await measurements.addMeasurement(
        BodyMeasurementEntry(
          id: 'month',
          date: today.subtract(const Duration(days: 30)),
          weightKg: 84,
          thighsCm: 52,
        ),
      );
      await measurements.addMeasurement(
        BodyMeasurementEntry(
          id: 'future',
          date: today.add(const Duration(days: 1)),
          weightKg: 999,
        ),
      );
      final summary = container.read(recompositionSummaryProvider);
      expect(summary.latestWeight, 80);
      expect(summary.weightDelta30d, -4);
      expect(summary.thighDelta30d, -2);
      expect(summary.waistDelta30d, isNull);
      expect(summary.comparisonDays, 30);
      expect(container.read(accountProfileProvider).currentWeightKg, 80);
      await container
          .read(accountProfileProvider.notifier)
          .updateBiometrics(currentWeightKg: 82);
      expect(container.read(accountProfileProvider).currentWeightKg, 82);
    },
  );

  test(
    'Goal progress starts from actual supplied weight; calories require supplied age and sex',
    () {
      final empty = AccountProfile(memberSince: today);
      expect(empty.bmi, isNull);
      expect(empty.goalProgress, isNull);
      expect(empty.maintenanceCaloriesEstimate, isNull);
      final gain = empty.copyWith(
        startingWeightKg: 70.0,
        currentWeightKg: 75.0,
        targetWeightKg: 80.0,
        goalDirection: 'gain',
      );
      expect(gain.goalProgress, .5);
      expect(gain.isCutting, isFalse);
      final loss = gain.copyWith(
        startingWeightKg: 90.0,
        currentWeightKg: 85.0,
        targetWeightKg: 80.0,
        goalDirection: 'lose',
        heightCm: 165.0,
        age: 32,
        sex: 'male',
      );
      expect(loss.goalProgress, .5);
      expect(loss.bmiCategory, 'Obesity range');
      expect(loss.bmrEstimate, 1726);
      expect(loss.calorieAssumptions, contains('1.55'));
      expect(loss.copyWith(age: null).bmrEstimate, isNull);
    },
  );

  test(
    'Recovery stays unavailable for missing inputs; real zero values, failures and restart are distinct',
    () async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      expect(container.read(recoverySummaryProvider).score, isNull);
      expect(container.read(recoverySummaryProvider).recentSessions, 0);
      final habits = container.read(habitLogProvider.notifier);
      await habits.saveRecoveryCheckIn(
        date: today,
        hours: 0,
        waterToAdd: 0,
        soreness: null,
      );
      expect(container.read(recoverySummaryProvider).missingInputs, [
        'Soreness',
      ]);
      hive.failSettings = true;
      await expectLater(
        habits.saveRecoveryCheckIn(
          date: today,
          hours: 8,
          waterToAdd: 2500,
          soreness: 2,
        ),
        throwsStateError,
      );
      expect(container.read(recoverySummaryProvider).score, isNull);
      expect(container.read(habitLogProvider).day(today).waterMl, 0);
      hive.failSettings = false;
      await habits.saveRecoveryCheckIn(
        date: today,
        hours: 8,
        waterToAdd: 2500,
        soreness: 2,
      );
      await WorkoutService(
        hive,
      ).saveWorkout(workout('last', today.subtract(const Duration(days: 1))));
      container.read(historyWorkoutsProvider.notifier).refresh();
      final summary = container.read(recoverySummaryProvider);
      expect(summary.score, isNotNull);
      expect(summary.recentSessions, 1);
      expect(summary.recentVolumeKg, 200);
      expect(summary.baselineVolumeKg, isNull);
      container.dispose();
      final restarted = containerFor(hive);
      addTearDown(restarted.dispose);
      expect(
        restarted.read(recoverySummaryProvider).score!.value,
        summary.score!.value,
      );
      expect(restarted.read(recoverySummaryProvider).habits.sleepHours, 8);
    },
  );

  testWidgets(
    'Recovery overview adapts real missing and complete inputs to large text and explains the score on demand',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final family in ['Outfit', 'JetBrainsMono']) {
          final loader = FontLoader(family);
          for (final weight in ['Regular', 'Medium', 'Bold']) {
            loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
          }
          await loader.load();
        }
      });
      for (final mode in ['empty', 'partial', 'complete']) {
        final hive = MemoryHiveService();
        final container = containerFor(hive);
        if (mode != 'empty') {
          await container
              .read(habitLogProvider.notifier)
              .saveRecoveryCheckIn(
                date: today,
                hours: 8,
                waterToAdd: 2500,
                soreness: mode == 'complete' ? 0 : null,
              );
          await WorkoutService(hive).saveWorkout(
            workout('last', today.subtract(const Duration(days: 1))),
          );
          container.read(historyWorkoutsProvider.notifier).refresh();
        }
        for (final size in [const Size(390, 844), const Size(720, 1024)]) {
          tester.view.physicalSize = size;
          for (final scale in [1.0, 1.5, 2.0]) {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: AppTheme.dark,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      highContrast: scale == 2,
                    ),
                    child: child!,
                  ),
                  home: const RecoveryScreen(),
                ),
              ),
            );
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: '$mode at $size, $scale text',
            );
            final action = find.byKey(
              const ValueKey('recovery-check-in-action'),
            );
            await tester.ensureVisible(action);
            await tester.pump();
            expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
            expect(find.text('More input needed'), findsNothing);
            expect(find.text('THE SCORE'), findsNothing);
            for (final title in ['Sleep', 'Hydration', 'Soreness']) {
              final value = find.byKey(ValueKey('recovery-input-value-$title'));
              await tester.ensureVisible(value);
              await tester.pump();
              expect(
                tester
                    .getRect(find.text(title))
                    .overlaps(tester.getRect(value)),
                isFalse,
                reason: '$title stays separate from its value at $scale',
              );
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$mode input rows at $scale',
            );
            await tester.tap(find.byTooltip('How recovery is estimated'));
            await tester.pumpAndSettle();
            expect(find.text('THE SCORE'), findsOneWidget);
            expect(find.text('YOUR INPUTS'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: 'Explanation at $scale',
            );
            await tester.tap(find.byTooltip('Close'));
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      }
    },
  );

  testWidgets(
    'Recovery input retains failed save and fits phone keyboard at large text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      await container
          .read(habitLogProvider.notifier)
          .saveRecoveryCheckIn(date: today, soreness: 2);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: const EdgeInsets.only(bottom: 300),
                textScaler: TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const RecoveryScreen(),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('recovery-check-in-action')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '8');
      await tester.enterText(find.byType(TextField).at(1), '1000');
      final save = find.text('SAVE CHECK-IN');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getCenter(save).dy, lessThan(544));
      hive.failSettings = true;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '8',
      );
      hive.failSettings = false;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(container.read(recoverySummaryProvider).score, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Imperial plate target applies canonical kg and explicit bar override',
    (tester) async {
      final hive = MemoryHiveService();
      await seedUser(hive, user.copyWith(weightUnit: 'lbs', barbellTareKg: 15));
      final container = containerFor(hive);
      addTearDown(container.dispose);
      double? selected;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: PlateCalculatorModal(
                initialTotalWeightKg: 60,
                initialBarWeightKg: 20,
                onWeightSelected: (kg) => selected = kg,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Target total weight (lbs)'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '132.277357308');
      await tester.pump();
      final apply = find.textContaining('APPLY');
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pump();
      expect(selected, closeTo(60, .01));
    },
  );

  for (final unilateral in [false, true]) {
    testWidgets(
      'Imperial ${unilateral ? 'two-sided' : 'bilateral'} set input stores kg',
      (tester) async {
        final hive = MemoryHiveService();
        await seedUser(hive, user.copyWith(weightUnit: 'lbs'));
        final container = ProviderContainer(
          overrides: [
            hiveServiceProvider.overrideWithValue(hive),
            activeSessionProvider.overrideWith(() => _InputSession(unilateral)),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) => ExerciseSetTable(
                      exercise: ref
                          .watch(activeSessionProvider)
                          .exercises
                          .single,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('LBS'), findsOneWidget);
        await tester.enterText(find.byType(TextField).at(0), '88.184904872');
        if (unilateral) {
          await tester.enterText(find.byType(TextField).at(2), '176.369809744');
        }
        await tester.pump(const Duration(milliseconds: 400));
        final set = container
            .read(activeSessionProvider)
            .exercises
            .single
            .sets
            .single;
        expect(set.weightKg, closeTo(40, 1e-6));
        if (unilateral) expect(set.weightKgRight, closeTo(80, 1e-6));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final page in [2, 3, 4, 5, 6]) {
    testWidgets('Setup page $page fits large phone text with keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      container.read(onboardingProvider.notifier).setPage(page);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: const EdgeInsets.only(bottom: 300),
                textScaler: TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final action = find.text(
        page == 6
            ? 'SAVE SETUP'
            : page == 5
            ? 'FINALIZE SETUP'
            : 'CONTINUE',
      );
      if (page == 6) {
        await tester.scrollUntilVisible(
          action,
          250,
          scrollable: find.byType(Scrollable).last,
        );
      }
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.getCenter(action).dy, lessThan(544));
      expect(tester.takeException(), isNull);
    });
  }
}
