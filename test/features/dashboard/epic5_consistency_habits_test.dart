import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/dashboard/providers/dashboard_provider.dart';
import 'package:leon/features/dashboard/widgets/weekly_consistency_card.dart';
import 'package:leon/features/health_tracking/models/body_measurement_model.dart';
import 'package:leon/features/health_tracking/providers/body_measurements_provider.dart';
import 'package:leon/features/health_tracking/screens/health_tracking_screen.dart';
import 'package:leon/shared/widgets/sync_status_indicator.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';

void main() {
  group('Epic 5: Weekly Consistency Provider Tests', () {
    test(
      'weeklyConsistencyProvider calculates compliance and supportive message',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final consistency = container.read(weeklyConsistencyProvider);
        expect(
          consistency.plannedThisWeek,
          container.read(splitsProvider).activeSplit.daysPerWeek,
        );
        expect(consistency.days.length, 7);
        expect(consistency.fourWeekHistory.length, 4);
        expect(consistency.complianceRate, inInclusiveRange(0.0, 1.0));
        expect(consistency.supportiveMessage, isNotEmpty);
        expect(consistency.supportiveMessage.contains('streak'), isFalse);
      },
    );
  });

  group('Epic 5: Body Measurements & Recomposition Tests', () {
    test(
      'bodyMeasurementsProvider manages entries and computes 30-day deltas',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initial = container.read(bodyMeasurementsProvider);
        expect(initial.length, 0);

        final summary = container.read(recompositionSummaryProvider);
        expect(summary.latestWeight, 0.0);
        expect(summary.weightDelta30d, 0.0);

        // Add new measurement
        final newEntry = BodyMeasurementEntry(
          id: 'm_new_test',
          date: DateTime.now(),
          weightKg: 78.5,
          bodyFatPercent: 15.8,
          waistCm: 81.5,
          chestCm: 103.5,
          armsCm: 38.0,
          thighsCm: 58.6,
        );

        await container
            .read(bodyMeasurementsProvider.notifier)
            .addMeasurement(newEntry);

        final afterAdd = container.read(bodyMeasurementsProvider);
        expect(afterAdd.length, 1);
        expect(afterAdd.first.id, 'm_new_test');

        final updatedSummary = container.read(recompositionSummaryProvider);
        expect(updatedSummary.latestWeight, 78.5);

        // Delete measurement
        await container
            .read(bodyMeasurementsProvider.notifier)
            .deleteMeasurement('m_new_test');
        final afterDelete = container.read(bodyMeasurementsProvider);
        expect(afterDelete.length, 0);
      },
    );
  });

  group('Epic 5: Widget Interactive Tests', () {
    testWidgets(
      'WeeklyConsistencyCard renders 7-day indicators, compliance badge, and trend',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: WeeklyConsistencyCard()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('THIS WEEK'), findsOneWidget);
        expect(find.textContaining('training days'), findsOneWidget);
        expect(find.byIcon(Icons.circle_outlined), findsNWidgets(7));
      },
    );

    testWidgets(
      'SyncStatusIndicator displays dot and opens data safety dialog on tap',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: SyncStatusIndicator(showLabel: true)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SAVED'), findsOneWidget);

        await tester.tap(find.byType(SyncStatusIndicator));
        await tester.pumpAndSettle();

        expect(find.text('OFFLINE-FIRST DATA SAFETY'), findsOneWidget);
        expect(
          find.textContaining('saved locally first via Hive storage'),
          findsOneWidget,
        );

        await tester.tap(find.text('UNDERSTOOD'));
        await tester.pumpAndSettle();
        expect(find.text('OFFLINE-FIRST DATA SAFETY'), findsNothing);
      },
    );

    testWidgets(
      'HealthTrackingScreen toggles between DAILY METRICS and RECOMPOSITION',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HealthTrackingScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('DAILY METRICS'), findsOneWidget);
        expect(find.text('RECOMPOSITION'), findsOneWidget);

        // Initially in DAILY METRICS tab
        expect(find.text('STEPS'), findsOneWidget);

        // Switch to RECOMPOSITION tab
        await tester.tap(find.text('RECOMPOSITION'));
        await tester.pumpAndSettle();

        expect(find.text('BODY COMPOSITION CHECK-IN'), findsOneWidget);
        expect(find.text('WAIST'), findsOneWidget);
        expect(find.text('ARMS (FLEXED)'), findsOneWidget);
        expect(find.text('LOG'), findsOneWidget);

        // Tap LOG to open sheet
        await tester.tap(find.text('LOG'));
        await tester.pumpAndSettle();

        expect(find.text('RECORD MEASUREMENTS'), findsOneWidget);
        expect(find.text('SAVE MEASUREMENTS'), findsOneWidget);
      },
    );
  });
}
