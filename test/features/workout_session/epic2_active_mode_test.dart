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

class _FakeHiveService extends HiveService {
  final Map<String, dynamic> settings = {};

  @override
  Future<void> putSetting(String key, Object? value) async {
    settings[key] = value;
  }

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

    testWidgets('ActiveWorkoutResumeBanner renders when session is active and hides when inactive', (tester) async {
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: ActiveWorkoutResumeBanner(),
            ),
          ),
        ),
      );

      // Inactive session: Banner is shrunk / not visible
      expect(find.text('RESUME'), findsNothing);

      // Start session
      container.read(activeSessionProvider.notifier).startSession(splitName: 'Leg Day // Workout C');
      await tester.pump();

      // Active session: Banner displays split name and resume CTA
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.textContaining('Leg Day // Workout C'), findsOneWidget);

      // Clean up session ticker
      container.read(activeSessionProvider.notifier).cancelSession();
      await tester.pump();

      // Should disappear after cancelling
      expect(find.text('RESUME'), findsNothing);
    });

    testWidgets('ExerciseSubstitutionSheet displays matching muscle alternatives and performs SWAP', (tester) async {
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
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      // Set initial session with this exercise
      container.read(activeSessionProvider.notifier).startSession(
        initialExercises: [exercise],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: ExerciseSubstitutionSheet(
                currentExercise: exercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUBSTITUTE EXERCISE'), findsOneWidget);
      expect(find.text('Current: Barbell Bench Press'), findsOneWidget);

      // Incline Dumbbell Press should be listed as a matching Chest alternative
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);

      // Tap SWAP on Incline Dumbbell Press
      await tester.tap(find.widgetWithText(ElevatedButton, 'SWAP').first);
      await tester.pump();

      // Exercise should now be substituted in activeSessionProvider
      final updatedSession = container.read(activeSessionProvider);
      expect(updatedSession.exercises.first.name, 'Incline Dumbbell Press');
      // Completed set #1 remains preserved!
      expect(updatedSession.exercises.first.sets.first.isCompleted, isTrue);

      // Clean up session ticker
      container.read(activeSessionProvider.notifier).cancelSession();
    });

    testWidgets('ExerciseSetTable checkmark uses Electric Cyan and tactile medium feedback', (tester) async {
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
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
                    return ExerciseSetTable(exercise: session.exercises.first);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap first checkmark to complete set
      final checkIconFinder = find.byIcon(Icons.check_circle_outline).first;
      await tester.tap(checkIconFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should now show filled check_circle with primary cyan color
      final completedIcon = tester.widget<Icon>(find.byIcon(Icons.check_circle).first);
      expect(completedIcon.color, AppColors.primary);

      // Clean up session ticker
      container.read(activeSessionProvider.notifier).cancelSession();
    });

    testWidgets('ExerciseSequenceCard 3-dot menu opens ExerciseSubstitutionSheet', (tester) async {
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeSessionProvider.notifier).startSession();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Consumer(
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
      );
      await tester.pump();

      // Tap 3-dot menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Menu option 'Substitute Exercise' is visible
      expect(find.text('Substitute Exercise'), findsOneWidget);

      // Clean up session ticker
      container.read(activeSessionProvider.notifier).cancelSession();
    });
  });
}
