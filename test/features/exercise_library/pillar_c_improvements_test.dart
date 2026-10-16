import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/features/exercise_library/screens/custom_exercise_creator_screen.dart';
import 'package:leon/features/exercise_library/widgets/exercise_filter_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pillar C Improvements - Exercise Library & Custom Movements Tests', () {
    test('ExerciseRepository.filter with onlyCustom filters custom exercises', () {
      final repo = ExerciseRepository();
      
      const customEx = ExerciseLibraryItem(
        id: 'custom-test-1',
        name: 'Custom Bulgarian Split Squat',
        category: 'Legs',
        description: 'Test custom movement',
        isCustom: true,
      );
      repo.addCustomExercise(customEx);

      final allResults = repo.filter();
      expect(allResults.any((e) => e.id == 'custom-test-1'), isTrue);

      final customOnlyResults = repo.filter(onlyCustom: true);
      expect(customOnlyResults.isNotEmpty, isTrue);
      expect(customOnlyResults.every((e) => e.isCustom), isTrue);
      expect(customOnlyResults.any((e) => e.id == 'custom-test-1'), isTrue);
    });

    test('ExerciseFilterState tracks onlyCustom in activeFiltersCount and hasActiveFilters', () {
      const stateEmpty = ExerciseFilterState();
      expect(stateEmpty.onlyCustom, isFalse);
      expect(stateEmpty.activeFiltersCount, equals(0));
      expect(stateEmpty.hasActiveFilters, isFalse);

      final stateCustom = stateEmpty.copyWith(onlyCustom: true);
      expect(stateCustom.onlyCustom, isTrue);
      expect(stateCustom.activeFiltersCount, equals(1));
      expect(stateCustom.hasActiveFilters, isTrue);
    });

    test('ExerciseLibraryNotifier toggleOnlyCustom and setOnlyCustom update state and filter catalog', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(exerciseLibraryProvider.notifier);
      await notifier.loadCatalog();

      const customEx = ExerciseLibraryItem(
        id: 'custom-incline-press',
        name: 'Custom Incline Smith Press',
        category: 'Chest',
        description: 'Custom bench angle',
        isCustom: true,
      );
      notifier.addCustomExercise(customEx);

      // Verify custom is present in all
      expect(container.read(exerciseLibraryProvider).allExercises.any((e) => e.id == 'custom-incline-press'), isTrue);

      // Filter by custom only
      notifier.setOnlyCustom(true);
      var state = container.read(exerciseLibraryProvider);
      expect(state.filter.onlyCustom, isTrue);
      expect(state.filteredExercises.every((e) => e.isCustom), isTrue);
      expect(state.filteredExercises.any((e) => e.id == 'custom-incline-press'), isTrue);

      // Toggle off
      notifier.toggleOnlyCustom();
      state = container.read(exerciseLibraryProvider);
      expect(state.filter.onlyCustom, isFalse);
      expect(state.filteredExercises.length, equals(state.allExercises.length));
    });

    testWidgets('ExerciseFilterBar displays Custom chip and toggles onlyCustom on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Custom chip is present
      final customChip = find.text('Custom');
      expect(customChip, findsOneWidget);

      // Tap Custom chip
      await tester.tap(customChip);
      await tester.pumpAndSettle();

      // Verify onlyCustom is now true
      expect(container.read(exerciseLibraryProvider).filter.onlyCustom, isTrue);
    });

    testWidgets('CustomExerciseCreatorScreen creates custom exercise and auto-filters library', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CustomExerciseCreatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in exercise name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'V-Bar Lat Pulldown Special');
      await tester.pumpAndSettle();

      // Tap SAVE CUSTOM EXERCISE button
      final saveButton = find.text('SAVE CUSTOM EXERCISE');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify the exercise was added and library was auto-filtered to custom
      final libState = container.read(exerciseLibraryProvider);
      expect(libState.filter.onlyCustom, isTrue);
      expect(libState.allExercises.any((e) => e.name == 'V-Bar Lat Pulldown Special'), isTrue);
      expect(libState.filteredExercises.any((e) => e.name == 'V-Bar Lat Pulldown Special'), isTrue);
    });
  });
}
