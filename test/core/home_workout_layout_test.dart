import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/screens/dashboard_screen.dart';
import 'package:leon/features/dashboard/widgets/telemetry_detail_sheets.dart';
import 'package:leon/features/workout_builder/screens/workout_builder_screen.dart';
import 'package:leon/features/workout_builder/screens/routine_library_screen.dart';
import 'package:leon/features/workout_builder/widgets/create_routine_sheet.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/features/workout_session/screens/workout_session_screen.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';
import 'package:leon/features/workout_session/widgets/effort_picker_modal.dart';
import 'package:leon/features/workout_session/widgets/workout_summary_dialog.dart';
import 'package:leon/services/hive_service.dart';
import '../helpers/memory_hive_service.dart';

void main() {
  testWidgets(
    'Home, health sheets, routine editor and session tools fit larger text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        for (final family in ['Outfit', 'JetBrainsMono']) {
          final loader = FontLoader(family);
          for (final weight in ['Regular', 'Medium', 'Bold']) {
            loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
          }
          await loader.load();
        }
      });
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
      );
      addTearDown(container.dispose);
      Future<void> mount(Widget screen, {double keyboard = 0}) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                  padding: const EdgeInsets.only(top: 28, bottom: 24),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      for (final screen in <Widget>[
        const DashboardScreen(),
        const WorkoutBuilderScreen(),
        const RoutineLibraryScreen(),
        const CreateRoutineSheet(),
      ]) {
        await mount(screen);
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} larger text',
        );
        final scroll = find.byType(Scrollable).first;
        await tester.drag(scroll, const Offset(0, -650));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} scrolled',
        );
      }
      for (final show in [
        showStepsDetailSheet,
        showCaloriesDetailSheet,
        showHydrationDetailSheet,
        showSleepDetailSheet,
      ]) {
        await mount(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => show(context, const DailyTelemetry()),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Health sheet larger text',
        );
        await tester.tap(find.byTooltip('Close'));
        await tester.pump(const Duration(milliseconds: 400));
      }
      final session = container.read(activeSessionProvider.notifier);
      session.startSession();
      await mount(const WorkoutSessionScreen(), keyboard: 280);
      expect(tester.takeException(), isNull, reason: 'Session with keyboard');
      container
          .read(restTimerProvider.notifier)
          .startTimer(durationSeconds: 90);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Active rest with keyboard',
      );
      await mount(
        const Scaffold(body: PlateCalculatorModal(initialTotalWeightKg: 83)),
        keyboard: 280,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Plate calculator keyboard',
      );
      await mount(
        Scaffold(
          body: EffortPickerModal(
            initialRir: 2,
            initialRpe: 8,
            onSaved: (_, _) {},
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'Effort picker');
      await mount(
        Scaffold(
          body: WorkoutSummaryDialog(
            session: container.read(activeSessionProvider),
            onConfirmedSave: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'Recap larger text');
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
