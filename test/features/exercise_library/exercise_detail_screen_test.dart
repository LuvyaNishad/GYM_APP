import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/screens/exercise_detail_screen.dart';
import 'package:leon/services/hive_service.dart';

class FakeHiveService extends HiveService {
  final Map<String, dynamic> settings = {};
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) async {
    documents.putIfAbsent(boxName, () => {})[key] = json;
  }

  @override
  Future<void> putSetting(String key, Object? value) async {
    settings[key] = value;
  }

  @override
  T? getSetting<T>(String key, {T? fallback}) {
    return (settings[key] as T?) ?? fallback;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testExercise = ExerciseLibraryItem(
    id: 'incline-dumbbell-press',
    name: 'Incline Dumbbell Press',
    category: 'Chest',
    description: 'Upper chest hypertrophy builder using adjustable incline bench.',
    primaryMuscles: ['upper pectoralis', 'anterior deltoid'],
    secondaryMuscles: ['triceps brachii'],
    equipment: ['dumbbells', 'incline bench'],
    primaryEquipment: 'dumbbell',
    movementPattern: 'horizontal push',
    exerciseType: 'hypertrophy',
    difficulty: 'intermediate',
    instructions: [
      'Set bench to 30-degree incline.',
      'Retract scapula and press dumbbells smoothly.',
      'Lower under control with 3-second negative.',
    ],
    coachingNotes: 'Keep elbows tucked at 45 degrees to avoid shoulder strain.',
  );

  group('ExerciseDetailScreen Task 3.1 Tests', () {
    testWidgets('Renders all guide sections, anatomy tags, cues, and 1RM calculator',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeHive = FakeHiveService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(fakeHive),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: ExerciseDetailScreen(exercise: testExercise),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & category
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);

      // Target Anatomy
      expect(find.text('ANATOMICAL TARGETS'), findsOneWidget);
      expect(find.textContaining('UPPER PECTORALIS'), findsOneWidget);

      // Execution guide
      expect(find.text('FORM EXECUTION CHECKLIST'), findsOneWidget);
      expect(find.text('Set bench to 30-degree incline.'), findsOneWidget);

      // Coaching cues
      expect(find.text('COACHING TIP ● KEY CUE'), findsOneWidget);
      expect(find.textContaining('Keep elbows tucked at 45 degrees'), findsOneWidget);

      // 1RM Calculator
      expect(find.text('ESTIMATED 1RM CALCULATOR'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Reps Completed'), findsOneWidget);

      // Action buttons
      expect(find.text('ADD TO ROUTINE'), findsOneWidget);
      expect(find.text('START WORKOUT'), findsOneWidget);

      // Verify HIG min font size >= 11.0 on all Text widgets
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final tw in textWidgets) {
        if (tw.style?.fontSize != null) {
          expect(
            tw.style!.fontSize!,
            greaterThanOrEqualTo(10.99),
            reason: 'Text "${tw.data ?? tw.textSpan?.toPlainText()}" violates HIG min 11pt floor',
          );
        }
      }
    });

    testWidgets('1RM Calculator updates estimated max dynamically on rep/weight change',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeHive = FakeHiveService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(fakeHive),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: ExerciseDetailScreen(exercise: testExercise),
          ),
        ),
      );
      await tester.pump();

      // Enter weight: 100 kg, reps: 10
      // Epley: 100 * (1 + 10/30) = 133.3 kg
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), '100');
      await tester.enterText(textFields.at(1), '10');
      await tester.pump();

      expect(find.textContaining('133.3'), findsOneWidget);
    });
  });
}
