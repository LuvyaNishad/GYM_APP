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
  late FakeHiveService hive;
  late ProviderContainer container;
  setUp(() {
    hive = FakeHiveService();
    container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(hive)],
    );
  });
  tearDown(() => container.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(540, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCreateRoutineSheet(context),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Day accordion supports direct renaming without saving the draft',
    (tester) async {
      await open(tester);
      expect(find.text('Workout 1'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'Leg Day');
      await tester.pump();
      expect(find.text('Leg Day'), findsWidgets);
      expect(container.read(splitsProvider).customSplits, isEmpty);
      await tester.tap(find.byTooltip('Cancel editing'));
      await tester.pumpAndSettle();
      expect(container.read(splitsProvider).customSplits, isEmpty);
    },
  );

  testWidgets('Recovery day toggle remains part of the draft', (tester) async {
    await open(tester);
    await tester.tap(find.text('Workout 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, true);
    expect(container.read(splitsProvider).customSplits, isEmpty);
  });

  testWidgets('Saving a two-day empty routine does not activate it', (
    tester,
  ) async {
    await open(tester);
    final initial = container.read(splitsProvider).activeSplitId;
    await tester.tap(find.text('SAVE ROUTINE'));
    await tester.pumpAndSettle();
    final saved = container.read(splitsProvider).customSplits.single;
    expect(saved.workouts.length, 2);
    expect(saved.workouts.every((day) => day.exercises.isEmpty), true);
    expect(container.read(splitsProvider).activeSplitId, initial);
  });

  testWidgets('Make active is a separate explicit action after saving', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('SAVE ROUTINE'));
    await tester.pumpAndSettle();
    final saved = container.read(splitsProvider).customSplits.single;
    await tester.tap(find.text('Make active'));
    await tester.pumpAndSettle();
    expect(container.read(splitsProvider).activeSplitId, saved.id);
  });
}
