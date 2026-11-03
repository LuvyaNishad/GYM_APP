import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/screens/profile_screen.dart';
import 'package:leon/services/hive_service.dart';

import '../../helpers/memory_hive_service.dart';

Future<ProviderContainer> mountAccount(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  MemoryHiveService? storage,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      hiveServiceProvider.overrideWithValue(storage ?? MemoryHiveService()),
      localDateProvider.overrideWith((ref) => DateTime(2026, 11, 3)),
    ],
  );
  addTearDown(container.dispose);
  final notifier = container.read(accountProfileProvider.notifier);
  await notifier.updateProfile(
    displayName: 'Alexandra Morgan Rodriguez',
    email: 'alexandra.morgan.rodriguez@example.com',
  );
  await notifier.updateBiometrics(
    heightCm: 180,
    currentWeightKg: 80,
    targetWeightKg: 75,
    age: 30,
    sex: 'female',
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> reveal(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 60,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final layout in [(320.0, 2.0), (390.0, 1.0), (800.0, 1.3)]) {
    testWidgets(
      'Account remains usable at ${layout.$1}px and ${layout.$2}x text',
      (tester) async {
        final container = await mountAccount(
          tester,
          width: layout.$1,
          scale: layout.$2,
        );
        final before = container.read(accountProfileProvider);
        expect(tester.takeException(), isNull);
        await reveal(tester, 'Training details');
        await tester.tap(find.text('Training details'));
        await tester.pumpAndSettle();
        await reveal(tester, 'Injury notes');
        expect(tester.takeException(), isNull);
        await reveal(tester, 'Weight unit');
        await tester.tap(find.text('Weight unit'));
        await tester.pumpAndSettle();
        expect(find.text('Kilograms (kg)'), findsOneWidget);
        expect(find.text('Pounds (lbs)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Dismiss the choice without changing a preference.
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        await reveal(tester, 'Reset preferences');
        await tester.tap(find.text('Reset preferences'));
        await tester.pumpAndSettle();
        expect(find.text('Reset preferences?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await reveal(tester, 'Redo setup');
        await tester.tap(find.text('Redo setup'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(container.read(accountProfileProvider), same(before));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Account choice menus persist units and alerts, and retain failed preferences',
    (tester) async {
      final storage = MemoryHiveService();
      final container = await mountAccount(tester, storage: storage);
      await reveal(tester, 'Default rest timer');
      await tester.tap(find.text('Default rest timer'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<int>, '120 seconds'),
      );
      await tester.pumpAndSettle();
      expect(container.read(accountProfileProvider).defaultRestSeconds, 120);

      storage.failDocuments = true;
      await tester.tap(find.text('Barbell weight'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<double>, '15.0 kg'),
      );
      await tester.pumpAndSettle();
      expect(container.read(accountProfileProvider).barbellTareKg, 20);
      expect(find.textContaining('Could not save'), findsOneWidget);
      storage.failDocuments = false;
      await tester.pump(const Duration(seconds: 6));

      for (final choice in [
        ('Weight unit', 'Pounds (lbs)'),
        ('Height unit', 'Feet & inches (ft / in)'),
        ('Workout alerts', 'Silent'),
      ]) {
        await reveal(tester, choice.$1);
        await tester.tap(find.text(choice.$1));
        await tester.pumpAndSettle();
        await tester.tap(
          find.ancestor(
            of: find.text(choice.$2),
            matching: find.byWidgetPredicate(
              (widget) => widget is CheckedPopupMenuItem,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }
      final saved = container.read(accountProfileProvider);
      expect(saved.weightUnit, 'lbs');
      expect(saved.heightUnit, 'ft');
      expect(saved.currentWeightKg, 80);
      expect(saved.heightCm, 180);
      expect(saved.audioCuesEnabled, isFalse);
      expect(saved.hapticFeedbackEnabled, isFalse);
      final reopened = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(storage),
          localDateProvider.overrideWith((ref) => DateTime(2026, 11, 3)),
        ],
      );
      addTearDown(reopened.dispose);
      final restored = reopened.read(accountProfileProvider);
      expect(restored.weightUnit, 'lbs');
      expect(restored.heightUnit, 'ft');
      expect(restored.defaultRestSeconds, 120);
      expect(restored.audioCuesEnabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
