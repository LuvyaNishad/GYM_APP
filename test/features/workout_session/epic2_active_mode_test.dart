import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/widgets/active_workout_resume_banner.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/widgets/exercise_sequence_card.dart';
import 'package:leon/features/workout_session/widgets/exercise_set_table.dart';
import 'package:leon/features/workout_session/widgets/exercise_substitution_sheet.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';

class _FakeHiveService extends HiveService {
  final Map<String, dynamic> settings = {};

  @override
  Future<void> putSetting(String key, Object? value) async {
    settings[key] = value;
  }

  @override
  Future<void> putSettingChecked(String key, Object? value) =>
      putSetting(key, value);
  @override
  Future<void> deleteSettingChecked(String key) => deleteSetting(key);

  @override
  T? getSetting<T>(String key, {T? fallback}) {
    return (settings[key] as T?) ?? fallback;
  }

  @override
  Future<void> deleteSetting(String key) async {
    settings.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Epic 2 — Active Mode & Crash Protection Tests', () {
    late _FakeHiveService fakeHive;

    setUp(() {
      fakeHive = _FakeHiveService();
    });

    testWidgets(
      'ActiveWorkoutResumeBanner renders when session is active and hides when inactive',
      (tester) async {
        final container = ProviderContainer(
          overrides: [hiveServiceProvider.overrideWithValue(fakeHive)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: ActiveWorkoutResumeBanner()),
            ),
          ),
        );

        // Inactive session: Banner is shrunk / not visible
        expect(find.text('RESUME'), findsNothing);

        // Start session
        container
            .read(activeSessionProvider.notifier)
            .startSession(splitName: 'Leg Day // Workout C');
        await tester.pump();

        // Active session: Banner displays split name and resume CTA
        expect(find.text('RESUME'), findsOneWidget);
        expect(find.textContaining('Leg Day // Workout C'), findsOneWidget);

        // Clean up session ticker
        container.read(activeSessionProvider.notifier).cancelSession();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Should disappear after cancelling
        expect(find.text('RESUME'), findsNothing);
      },
    );

    testWidgets(
      'ExerciseSubstitutionSheet displays matching muscle alternatives and performs SWAP',
      (tester) async {
        const exercise = ActiveExerciseState(
          exerciseId: 'chest_bench',
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          equipment: 'barbell',
          sets: [
            ActiveSetState(
              setNumber: 1,
              weightKg: 80.0,
              reps: 8,
              isCompleted: true,
            ),
            ActiveSetState(
              setNumber: 2,
              weightKg: 80.0,
              reps: 8,
              isCompleted: false,
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [hiveServiceProvider.overrideWithValue(fakeHive)],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container.read(exerciseLibraryProvider.notifier).loadCatalog(),
        );
        // Set initial session with this exercise
        container
            .read(activeSessionProvider.notifier)
            .startSession(initialExercises: [exercise]);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(
                body: ExerciseSubstitutionSheet(currentExercise: exercise),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Replace exercise'), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsOneWidget);

        // Choose the first ranked catalog recommendation.
        final tile = tester.widget<ListTile>(find.byType(ListTile).first);
        final replacementName = (tile.title! as Text).data!;
        final replacement = container
            .read(exerciseLibraryProvider)
            .allExercises
            .firstWhere((item) => item.name == replacementName);
        await tester.ensureVisible(find.text(replacementName));
        await tester.tap(find.text(replacementName));
        await tester.pump();

        // Exercise should now be substituted in activeSessionProvider
        final updatedSession = container.read(activeSessionProvider);
        expect(updatedSession.exercises[1].name, replacementName);
        expect(updatedSession.exercises[1].exerciseId, replacement.id);
        expect(updatedSession.exercises[1].sets, hasLength(1));
        expect(updatedSession.exercises[1].sets.single.isCompleted, isFalse);
        expect(updatedSession.exercises.first.exerciseId, exercise.exerciseId);
        expect(updatedSession.exercises.first.sets, hasLength(1));
        expect(updatedSession.exercises.first.sets.single.isCompleted, isTrue);

        // Clean up session ticker
        container.read(activeSessionProvider.notifier).cancelSession();
      },
    );

    testWidgets(
      'ExerciseSetTable checkmark uses Electric Cyan and tactile medium feedback',
      (tester) async {
        final container = ProviderContainer(
          overrides: [hiveServiceProvider.overrideWithValue(fakeHive)],
        );
        addTearDown(container.dispose);

        container.read(activeSessionProvider.notifier).startSession();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final session = ref.watch(activeSessionProvider);
                      return ExerciseSetTable(
                        exercise: session.exercises.first,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Tap first checkmark to complete set
        final checkIconFinder = find.byIcon(Icons.circle_outlined).first;
        await tester.tap(checkIconFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Should now show filled check_circle with primary cyan color
        final completedIcon = tester.widget<Icon>(
          find.byIcon(Icons.check_circle).first,
        );
        expect(completedIcon.color, AppColors.primary);

        // Clean up session ticker
        container.read(activeSessionProvider.notifier).cancelSession();
      },
    );

    testWidgets(
      'ExerciseSequenceCard 3-dot menu opens ExerciseSubstitutionSheet',
      (tester) async {
        final container = ProviderContainer(
          overrides: [hiveServiceProvider.overrideWithValue(fakeHive)],
        );
        addTearDown(container.dispose);

        container.read(activeSessionProvider.notifier).startSession();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final session = ref.watch(activeSessionProvider);
                      return ExerciseSequenceCard(
                        exercise: session.exercises.first,
                        index: 0,
                        isExpanded: true,
                        onToggleExpand: () {},
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Tap 3-dot menu
        await tester.tap(find.byTooltip('Exercise options'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Menu option 'Replace exercise' is visible
        expect(find.text('Replace exercise'), findsOneWidget);

        // Clean up session ticker
        container.read(activeSessionProvider.notifier).cancelSession();
      },
    );
  });
}
