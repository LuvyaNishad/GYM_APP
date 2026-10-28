import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/features/workout_session/screens/workout_session_screen.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/shared/widgets/app_shell.dart';

import '../helpers/memory_hive_service.dart';

void main() {
  Future<void> configureView(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  Future<void> mountShell(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    await configureView(tester, size: size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(body: AppShell(location: '/dashboard')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<ProviderContainer> mountSession(
    WidgetTester tester,
    Widget child, {
    required Size size,
    double textScale = 1,
    double keyboard = 0,
    bool startSession = true,
  }) async {
    await configureView(tester, size: size);
    final container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
    );
    addTearDown(container.dispose);
    if (startSession) {
      container.read(activeSessionProvider.notifier).startSession();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: widget!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return container;
  }

  testWidgets('compact large-text navigation fits and keeps 44dp targets', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await mountShell(tester, size: const Size(360, 800), textScale: 1.5);

    expect(tester.takeException(), isNull);
    for (final label in [
      'Home',
      'Workouts',
      'Exercises',
      'History',
      'Account',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    for (final label in [
      'Home',
      'Workouts',
      'Exercises',
      'History',
      'Account',
    ]) {
      final target = find.bySemanticsLabel(label);
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$label width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$label height');
    }

    for (final label in ['Workouts', 'Exercises', 'History', 'Account']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull, reason: '$label at 1.5x text');
    }
  });

  testWidgets('wide AppShell centers content within a 720dp maximum', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await mountShell(tester, size: const Size(800, 1280));

    final main = find.byKey(const ValueKey('app-shell-main-content'));
    final nav = find.byKey(const ValueKey('app-shell-nav-content'));
    expect(tester.getSize(main).width, AppShell.mainContentMaxWidth);
    expect(tester.getSize(nav).width, AppShell.mainContentMaxWidth);
    expect(tester.getTopLeft(main).dx, 40);
    expect(tester.getTopLeft(nav).dx, 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active session fits compact keyboard and 1.5x text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final container = await mountSession(
      tester,
      const WorkoutSessionScreen(),
      size: const Size(360, 800),
      textScale: 1.5,
      keyboard: 280,
    );
    expect(tester.takeException(), isNull);

    container.read(restTimerProvider.notifier).startTimer(durationSeconds: 90);
    await tester.pump();
    expect(tester.takeException(), isNull);
    container.read(restTimerProvider.notifier).skip();
    await container.read(activeSessionProvider.notifier).discardSession();
  });

  testWidgets('plate calculator fits compact keyboard and 1.5x text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await mountSession(
      tester,
      const Scaffold(body: PlateCalculatorModal(initialTotalWeightKg: 83)),
      size: const Size(360, 800),
      textScale: 1.5,
      keyboard: 280,
      startSession: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active session fits 800x360 landscape', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final container = await mountSession(
      tester,
      const WorkoutSessionScreen(),
      size: const Size(800, 360),
    );
    expect(tester.takeException(), isNull);
    await container.read(activeSessionProvider.notifier).discardSession();
  });
}
