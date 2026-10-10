import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockExercises = [
    const ExerciseLibraryItem(
      id: 'barbell-bench-press',
      name: 'Barbell Bench Press',
      category: 'Chest',
      description: 'Horizontal compound push',
      primaryMuscles: ['pectoralis major'],
      secondaryMuscles: ['triceps', 'anterior deltoids'],
      equipment: ['barbell', 'flat bench'],
      primaryEquipment: 'barbell',
      movementPattern: 'horizontal_push',
      exerciseType: 'compound',
      difficulty: 'intermediate',
      tags: ['chest', 'strength'],
      instructions: ['Lie on bench', 'Lower bar', 'Press up'],
      defaultRestSeconds: 120,
      alternatives: ['dumbbell-bench-press'],
    ),
    const ExerciseLibraryItem(
      id: 'dumbbell-bench-press',
      name: 'Dumbbell Bench Press',
      category: 'Chest',
      description: 'Dumbbell push',
      primaryMuscles: ['pectoralis major'],
      secondaryMuscles: ['triceps'],
      equipment: ['dumbbells', 'flat bench'],
      primaryEquipment: 'dumbbell',
      movementPattern: 'horizontal_push',
      exerciseType: 'compound',
      difficulty: 'beginner to intermediate',
      tags: ['chest'],
      instructions: ['Hold dumbbells', 'Press up'],
      defaultRestSeconds: 90,
    ),
    const ExerciseLibraryItem(
      id: 'lat-pulldown',
      name: 'Lat Pulldown',
      category: 'Back',
      description: 'Vertical pull',
      primaryMuscles: ['latissimus dorsi'],
      secondaryMuscles: ['biceps'],
      equipment: ['cable machine'],
      primaryEquipment: 'cable',
      movementPattern: 'vertical_pull',
      exerciseType: 'compound',
      difficulty: 'beginner',
      tags: ['back'],
      instructions: ['Grip bar', 'Pull down'],
      defaultRestSeconds: 90,
    ),
    const ExerciseLibraryItem(
      id: 'bicep-curl',
      name: 'Barbell Bicep Curl',
      category: 'Arms',
      description: 'Bicep isolation',
      primaryMuscles: ['biceps brachii'],
      secondaryMuscles: ['forearms'],
      equipment: ['barbell'],
      primaryEquipment: 'barbell',
      movementPattern: 'curl',
      exerciseType: 'isolation',
      difficulty: 'beginner',
      tags: ['arms'],
      instructions: ['Curl bar up', 'Lower under control'],
      defaultRestSeconds: 60,
    ),
  ];

  group('ExerciseRepository Tests', () {
    late ExerciseRepository repo;

    setUp(() {
      repo = ExerciseRepository();
      repo.setCatalog(mockExercises);
    });

    test('retrieves exercise by ID', () {
      final ex = repo.getById('barbell-bench-press');
      expect(ex, isNotNull);
      expect(ex!.name, 'Barbell Bench Press');
    });

    test('filters by Category', () {
      final chestItems = repo.filter(category: 'Chest');
      expect(chestItems.length, 2);
      expect(chestItems.every((e) => e.category == 'Chest'), isTrue);
    });

    test('filters by Equipment', () {
      final barbellItems = repo.filter(equipment: 'barbell');
      expect(barbellItems.length, 2);
    });

    test('filters by Exercise Type', () {
      final isolations = repo.filter(exerciseType: 'isolation');
      expect(isolations.length, 1);
      expect(isolations.first.name, 'Barbell Bicep Curl');
    });

    test('searches by keyword across name and muscles', () {
      final results = repo.filter(searchQuery: 'pectoralis');
      expect(results.length, 2);

      final latResults = repo.filter(searchQuery: 'pulldown');
      expect(latResults.length, 1);
      expect(latResults.first.id, 'lat-pulldown');
    });

    test('fetches smart alternatives', () {
      final alts = repo.getAlternatives('barbell-bench-press');
      expect(alts.isNotEmpty, isTrue);
      expect(alts.first.id, 'dumbbell-bench-press');
    });
  });

  group('ExerciseLibraryNotifier Tests', () {
    late ExerciseRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = ExerciseRepository();
      repo.setCatalog(mockExercises);
      container = ProviderContainer(
        overrides: [
          exerciseRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state contains all exercises', () {
      final state = container.read(exerciseLibraryProvider);
      expect(state.allExercises.length, 4);
      expect(state.filteredExercises.length, 4);
    });

    test('toggle category filter filters and toggles off', () {
      final notifier = container.read(exerciseLibraryProvider.notifier);

      notifier.setCategory('Chest');
      var state = container.read(exerciseLibraryProvider);
      expect(state.filteredExercises.length, 2);
      expect(state.filter.selectedCategory, 'Chest');

      // Tapping again toggles back to All
      notifier.setCategory('Chest');
      state = container.read(exerciseLibraryProvider);
      expect(state.filteredExercises.length, 4);
      expect(state.filter.selectedCategory, 'All');
    });

    test('adds custom exercise and updates state', () {
      final notifier = container.read(exerciseLibraryProvider.notifier);
      const custom = ExerciseLibraryItem(
        id: 'custom-hack-squat',
        name: 'Arsenal Hack Squat',
        category: 'Legs',
        description: 'Heavy plate loaded hack squat',
        primaryMuscles: ['quadriceps'],
        equipment: ['machine'],
        primaryEquipment: 'machine',
        isCustom: true,
      );

      notifier.addCustomExercise(custom);
      final state = container.read(exerciseLibraryProvider);
      expect(state.allExercises.length, 5);
      expect(state.filteredExercises.any((e) => e.id == 'custom-hack-squat'), isTrue);
    });
  });
}
