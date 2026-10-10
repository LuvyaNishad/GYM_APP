import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';
import 'package:leon/features/exercise_library/widgets/exercise_library_card.dart';
import 'package:leon/features/exercise_library/widgets/exercise_filter_bar.dart';
import 'package:leon/features/exercise_library/widgets/exercise_detail_sheet.dart';
import 'package:leon/features/exercise_library/widgets/add_to_routine_dialog.dart';
import 'package:leon/features/exercise_library/screens/exercise_library_screen.dart';
import 'package:leon/features/exercise_library/screens/custom_exercise_creator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleExercise = ExerciseLibraryItem(
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    category: 'Chest',
    description: 'Horizontal compound push',
    primaryMuscles: ['pectoralis major'],
    secondaryMuscles: ['triceps', 'anterior deltoids'],
    equipment: ['barbell', 'bench'],
    primaryEquipment: 'barbell',
    movementPattern: 'horizontal_push',
    exerciseType: 'compound',
    difficulty: 'intermediate',
    tags: ['chest', 'strength'],
    instructions: [
      'Lie on a flat bench with feet planted',
      'Lower the bar under control to mid-chest',
      'Press upward without bouncing',
    ],
    coachingNotes: 'Keep shoulder blades retracted and wrists stacked.',
    defaultRestSeconds: 120,
    alternatives: ['dumbbell-bench-press'],
  );

  const altExercise = ExerciseLibraryItem(
    id: 'dumbbell-bench-press',
    name: 'Dumbbell Bench Press',
    category: 'Chest',
    description: 'Dumbbell variation',
    primaryMuscles: ['pectoralis major'],
    secondaryMuscles: ['triceps'],
    equipment: ['dumbbells', 'flat bench'],
    primaryEquipment: 'dumbbell',
    movementPattern: 'horizontal_push',
    exerciseType: 'compound',
    difficulty: 'beginner to intermediate',
    tags: ['chest'],
    instructions: ['Press dumbbells upward with control.'],
  );

  late ExerciseRepository testRepo;

  setUp(() {
    testRepo = ExerciseRepository();
    testRepo.setCatalog([sampleExercise, altExercise]);
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(testRepo),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('ExerciseLibraryCard Tests', () {
    testWidgets('renders exercise name, tags, and handles quick add', (tester) async {
      bool tapped = false;
      bool quickAddTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseLibraryCard(
              exercise: sampleExercise,
              onTap: () => tapped = true,
              onQuickAdd: () => quickAddTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('COMPOUND'), findsOneWidget);
      expect(find.text('BARBELL'), findsOneWidget);
      expect(find.text('Target: Pectoralis Major'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Barbell Bench Press'));
      expect(tapped, isTrue);

      // Tap quick add + button
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(quickAddTapped, isTrue);
    });
  });

  group('ExerciseFilterBar Tests', () {
    testWidgets('renders master filter button and quick chips', (tester) async {
      await tester.pumpWidget(createTestWidget(const ExerciseFilterBar()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Barbell'), findsOneWidget);
    });
  });

  group('ExerciseDetailSheet Tests', () {
    testWidgets('renders notch, instructions, and handles alternative swap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool addedToWorkout = false;

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ExerciseDetailSheet(
                    initialExercise: sampleExercise,
                    onAddToWorkout: (ex) => addedToWorkout = true,
                  ),
                );
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('PRIMARY MUSCLE'), findsOneWidget);
      expect(find.text('ADD TO WORKOUT'), findsOneWidget);

      // Scroll down to reveal instructions and alternatives
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('HOW TO PERFORM'), findsOneWidget);
      expect(find.text('Dumbbell Bench Press'), findsOneWidget);

      // Switch to alternative
      await tester.tap(find.text('Dumbbell Bench Press'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Now the header shows the alternative
      expect(find.text('Dumbbell Bench Press'), findsWidgets);

      // Tap ADD TO WORKOUT
      await tester.tap(find.text('ADD TO WORKOUT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(addedToWorkout, isTrue);
    });
  });

  group('AddToRoutineDialog Tests', () {
    testWidgets('renders configurator and handles set stepper', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AddToRoutineDialog(exercise: sampleExercise),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ADD TO ROUTINE'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('3 SETS'), findsOneWidget);

      // Tap + on stepper
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('4 SETS'), findsOneWidget);

      // Tap CONFIRM & ADD
      await tester.tap(find.text('CONFIRM & ADD'));
      await tester.pumpAndSettle();
    });
  });

  group('ExerciseLibraryScreen Tests', () {
    testWidgets('renders search field, filter bar, and exercise items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            home: ExerciseLibraryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('EXERCISE LIBRARY'), findsOneWidget);
      expect(find.text('2 EXERCISES FOUND'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Dumbbell Bench Press'), findsOneWidget);

      // Search for specific exercise
      await tester.enterText(find.byType(TextField), 'Dumbbell');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1 EXERCISES FOUND'), findsOneWidget);
      expect(find.text('Dumbbell Bench Press'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
    });
  });

  group('CustomExerciseCreatorScreen Tests', () {
    testWidgets('renders form fields and validates required name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(const CustomExerciseCreatorScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('CREATE CUSTOM EXERCISE'), findsOneWidget);
      expect(find.text('SAVE CUSTOM EXERCISE'), findsOneWidget);

      // Attempt submit without name
      await tester.tap(find.text('SAVE CUSTOM EXERCISE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Please enter an exercise name'), findsOneWidget);
    });
  });
}
