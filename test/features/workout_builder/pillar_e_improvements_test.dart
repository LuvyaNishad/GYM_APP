import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_builder/widgets/create_routine_sheet.dart';
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
  List<T> readAll<T>(
    String boxName,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final box = documents[boxName];
    if (box == null) return [];
    return box.values.map((v) => fromJson(v as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> delete(String boxName, String key) async {
    documents[boxName]?.remove(key);
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

  late FakeHiveService fakeHive;

  setUp(() {
    fakeHive = FakeHiveService();
  });

  Widget buildTestWidget({
    required Widget child,
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Pillar E Improvements - Routine Editor & Builder Tests', () {
    testWidgets('E1: CreateRoutineSheet renders edit icons and renames day via dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestWidget(
          child: const CreateRoutineSheet(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial default day names exist
      expect(find.text('Workout Day 1'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      // Tap on Workout Day 1 to open rename dialog
      await tester.tap(find.text('Workout Day 1'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('EDIT WORKOUT DAY'), findsOneWidget);
      expect(find.text('DAY NAME'), findsOneWidget);
      expect(find.text('SUBTITLE / FOCUS'), findsOneWidget);
      expect(find.text('Mark as Rest Day'), findsOneWidget);

      // Verify suggestion chips are present
      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Pull Day'), findsOneWidget);
      expect(find.text('Leg Day'), findsOneWidget);

      // Tap 'Leg Day' suggestion chip
      await tester.tap(find.text('Leg Day'));
      await tester.pumpAndSettle();

      // Tap SAVE in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'SAVE'));
      await tester.pumpAndSettle();

      // Verify day name is updated to 'Leg Day'
      expect(find.text('Leg Day'), findsOneWidget);
      expect(find.text('Workout Day 1'), findsNothing);
    });

    testWidgets('E1: Allows toggling a day to Rest Day via rename dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestWidget(
          child: const CreateRoutineSheet(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Day 2
      await tester.tap(find.text('Workout Day 2'));
      await tester.pumpAndSettle();

      // Toggle rest day switch inside dialog
      final restSwitch = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Switch),
      );
      expect(restSwitch, findsOneWidget);
      await tester.tap(restSwitch);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.widgetWithText(FilledButton, 'SAVE'));
      await tester.pumpAndSettle();

      // Verify Day 2 now displays 'Rest Day'
      expect(find.text('Rest Day'), findsWidgets);
    });

    testWidgets('E2: Displays SET AS ACTIVE ROUTINE toggle and switches active split when true',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestWidget(
          child: const CreateRoutineSheet(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Verify toggle presence
      expect(find.text('SET AS ACTIVE ROUTINE'), findsOneWidget);
      expect(find.text('Apply immediately to Home dashboard'), findsOneWidget);

      final initialActive = container.read(splitsProvider).activeSplitId;

      // Tap SAVE ROUTINE with active toggle ON
      await tester.tap(find.widgetWithText(FilledButton, 'SAVE ROUTINE'));
      await tester.pumpAndSettle();

      final updatedActive = container.read(splitsProvider).activeSplitId;
      expect(updatedActive, isNot(equals(initialActive)));
      expect(updatedActive.startsWith('custom_split_'), isTrue);
    });

    testWidgets('E2: Does NOT switch active split when SET AS ACTIVE ROUTINE toggle is disabled',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestWidget(
          child: const CreateRoutineSheet(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      final initialActive = container.read(splitsProvider).activeSplitId;

      // Find the active routine switch in the bottom container
      final activeSwitch = find.descendant(
        of: find.byType(CreateRoutineSheet),
        matching: find.byType(Switch),
      );
      expect(activeSwitch, findsOneWidget);

      // Toggle off
      await tester.tap(activeSwitch);
      await tester.pumpAndSettle();

      // Tap SAVE ROUTINE
      await tester.tap(find.widgetWithText(FilledButton, 'SAVE ROUTINE'));
      await tester.pumpAndSettle();

      final afterSaveActive = container.read(splitsProvider).activeSplitId;
      // Active split should remain unchanged
      expect(afterSaveActive, equals(initialActive));
      // But custom split was saved
      expect(container.read(splitsProvider).customSplits.isNotEmpty, isTrue);
    });
  });
}
