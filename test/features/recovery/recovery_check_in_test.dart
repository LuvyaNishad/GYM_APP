import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/dashboard/widgets/recovery_status_widget.dart';
import 'package:leon/features/recovery/screens/recovery_screen.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/shared/widgets/leon_button.dart';
import '../../helpers/memory_hive_service.dart';

class SlowHive extends MemoryHiveService {
  Completer<void>? gate;
  int attempts = 0;
  @override
  Future<void> putSettingChecked(String key, Object? value) async {
    attempts++;
    if (gate != null) await gate!.future;
    await super.putSettingChecked(key, value);
  }
}

void main() {
  final today = DateTime(2026, 11, 3);
  testWidgets('Home recovery information opens the shared explanation sheet', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(MemoryHiveService()),
        localDateProvider.overrideWith((ref) => today),
      ],
    );
    addTearDown(container.dispose);
    final rootNavigator = GlobalKey<NavigatorState>();
    final tabNavigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigator,
          theme: AppTheme.dark,
          home: Navigator(
            key: tabNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: RecoveryStatusWidget()),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Recovery information'));
    await tester.pumpAndSettle();
    expect(find.text('How recovery is estimated'), findsOneWidget);
    expect(find.text('YOUR INPUTS'), findsOneWidget);
    expect(find.text('THE SCORE'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      rootNavigator.currentState!.canPop(),
      isTrue,
      reason: 'Home information covers the app navigation, above the tab',
    );
    expect(tabNavigator.currentState!.canPop(), isFalse);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('How recovery is estimated'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  Future<ProviderContainer> mount(
    WidgetTester tester,
    MemoryHiveService hive, {
    double width = 390,
    double scale = 1,
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hive),
        localDateProvider.overrideWith((ref) => today),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          home: const RecoveryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('recovery-check-in-action'));
    await tester.scrollUntilVisible(
      action,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> revealSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('SAVE CHECK-IN'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Invalid check-in retains fields and writes only explicit corrected zeros',
    (tester) async {
      final hive = MemoryHiveService();
      final container = await mount(
        tester,
        hive,
        width: 320,
        scale: 2,
        keyboard: 300,
      );
      await tester.enterText(find.byType(TextField).at(0), '25');
      await tester.enterText(find.byType(TextField).at(1), '-1');
      await revealSave(tester);
      expect(tester.getCenter(find.text('SAVE CHECK-IN')).dy, lessThan(544));
      await tester.tap(find.text('SAVE CHECK-IN'));
      await tester.pumpAndSettle();
      expect(find.text('Enter sleep between 0 and 24 hours.'), findsOneWidget);
      expect(find.text('Enter water between 0 and 10,000 ml.'), findsOneWidget);
      expect(hive.settings, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '25',
      );
      await tester.enterText(find.byType(TextField).at(0), '0');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await revealSave(tester);
      await tester.tap(find.text('SAVE CHECK-IN'));
      await tester.pumpAndSettle();
      final day = container.read(habitLogProvider).day(today);
      expect(day.sleepLogged, isTrue);
      expect(day.sleepHours, 0);
      expect(day.water, hasLength(1));
      expect(day.waterMl, 0);
      expect(day.soreness, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Pending save gives 16ms press feedback, stable label and geometry, and blocks duplicate and close',
    (tester) async {
      final hive = SlowHive();
      final container = await mount(tester, hive);
      await tester.enterText(find.byType(TextField).at(0), '7.5');
      await tester.enterText(find.byType(TextField).at(1), '250');
      final save = find.widgetWithText(LeonButton, 'SAVE CHECK-IN');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      final before = tester.getRect(save);
      hive.gate = Completer<void>();
      final pointer = await tester.startGesture(tester.getCenter(save));
      await tester.pump(const Duration(milliseconds: 16));
      final button = tester.widget<ElevatedButton>(
        find.descendant(of: save, matching: find.byType(ElevatedButton)),
      );
      expect(button.statesController!.value, contains(WidgetState.pressed));
      expect(hive.attempts, 0);
      await pointer.up();
      await tester.pump();
      expect(tester.widget<LeonButton>(save).isLoading, isTrue);
      expect(find.text('SAVING...'), findsNothing);
      expect(tester.getRect(save), before);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(save, warnIfMissed: false);
      await tester.tap(find.byTooltip('Close'), warnIfMissed: false);
      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(8, 20));
      await tester.pump();
      expect(find.text('Recovery check-in'), findsOneWidget);
      expect(hive.attempts, 1);
      await tester.dragFrom(
        tester.getCenter(find.text('Recovery check-in')),
        const Offset(0, 600),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text('Recovery check-in'),
        findsOneWidget,
        reason: 'A pending write cannot be dismissed by dragging the sheet',
      );
      hive.failSettings = true;
      hive.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        '250',
      );
      hive.failSettings = false;
      await revealSave(tester);
      await tester.tap(find.text('SAVE CHECK-IN'));
      await tester.pumpAndSettle();
      expect(find.text('Recovery check-in'), findsNothing);
      expect(container.read(habitLogProvider).day(today).waterMl, 250);
      expect(container.read(habitLogProvider).day(today).water, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Large text soreness selection preserves zero as a logged value',
    (tester) async {
      final container = await mount(
        tester,
        MemoryHiveService(),
        width: 320,
        scale: 2,
      );
      final dropdown = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('0 · None').last,
        -120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('0 · None').last);
      await tester.pumpAndSettle();
      await revealSave(tester);
      await tester.tap(find.text('SAVE CHECK-IN'));
      await tester.pumpAndSettle();
      expect(container.read(habitLogProvider).day(today).soreness, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
