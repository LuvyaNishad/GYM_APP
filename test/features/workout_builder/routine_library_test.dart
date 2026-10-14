import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_builder/screens/routine_library_screen.dart';
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

  group('RoutineLibrary & SplitsNotifier Task 3.2 Tests', () {
    test('SplitsNotifier supports save, duplicate, delete, and persistence', () async {
      final fakeHive = FakeHiveService();
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(splitsProvider.notifier);
      final initial = container.read(splitsProvider);

      expect(initial.presetSplits.isNotEmpty, isTrue);
      expect(initial.customSplits.isEmpty, isTrue);

      // Duplicate a preset split
      final duplicated = await notifier.duplicateSplit(initial.presetSplits.first.id);
      expect(duplicated.isCustom, isTrue);
      expect(duplicated.name, contains('(Custom)'));

      final afterDuplicate = container.read(splitsProvider);
      expect(afterDuplicate.customSplits.length, equals(1));
      expect(afterDuplicate.customSplits.first.id, equals(duplicated.id));
      expect(fakeHive.documents[AppConstants.hiveBoxSplits]?[duplicated.id], isNotNull);

      // Switch active split
      notifier.switchActiveSplit(duplicated.id);
      expect(container.read(splitsProvider).activeSplitId, equals(duplicated.id));
      expect(fakeHive.settings[AppConstants.settingActiveSplitId], equals(duplicated.id));

      // Delete custom split
      await notifier.deleteCustomSplit(duplicated.id);
      final afterDelete = container.read(splitsProvider);
      expect(afterDelete.customSplits.isEmpty, isTrue);
      expect(fakeHive.documents[AppConstants.hiveBoxSplits]?[duplicated.id], isNull);
    });

    testWidgets('RoutineLibraryScreen renders tabs, action buttons, and HIG compliant text',
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
            home: const RoutineLibraryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Tabs
      expect(find.text('ROUTINE LIBRARY'), findsOneWidget);
      expect(find.textContaining('PRESET SPLITS'), findsOneWidget);
      expect(find.textContaining('MY ROUTINES'), findsOneWidget);

      // FAB
      expect(find.text('NEW ROUTINE'), findsOneWidget);

      // Preset Splits actions
      expect(find.text('DUPLICATE'), findsWidgets);

      // Verify HIG font size >= 11.0 pt
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final tw in textWidgets) {
        if (tw.style?.fontSize != null) {
          expect(
            tw.style!.fontSize!,
            greaterThanOrEqualTo(10.99),
            reason: 'Text "${tw.data ?? tw.textSpan?.toPlainText()}" violates HIG 11pt floor',
          );
        }
      }
    });

    testWidgets('Tapping NEW ROUTINE opens create routine sheet with inputs and days picker',
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
            home: const RoutineLibraryScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap FAB
      await tester.tap(find.text('NEW ROUTINE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('CREATE CUSTOM ROUTINE'), findsOneWidget);
      expect(find.text('ROUTINE NAME'), findsOneWidget);
      expect(find.text('TRAINING DAYS PER WEEK'), findsOneWidget);
      expect(find.text('SAVE ROUTINE'), findsOneWidget);

      // Save custom routine
      await tester.tap(find.text('SAVE ROUTINE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should be saved in fake Hive
      expect(fakeHive.documents[AppConstants.hiveBoxSplits], isNotEmpty);
    });
  });
}
