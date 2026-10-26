import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/widgets/calories_bento_card.dart';
import 'package:leon/features/dashboard/widgets/sleep_bento_card.dart';
import 'package:leon/features/dashboard/widgets/steps_bento_card.dart';
import 'package:leon/features/dashboard/widgets/water_bento_card.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';

class _TestTelemetryNotifier extends DailyTelemetryNotifier {
  _TestTelemetryNotifier(this._initial);
  final DailyTelemetry _initial;

  @override
  DailyTelemetry build() => _initial;

  void setSteps(int steps) {
    state = state.copyWith(steps: steps);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chunk 2: Granular Riverpod Rebuilds & Bento Cards', () {
    testWidgets('Bento cards render accurately when telemetry parameter is omitted (Riverpod .select)',
        (tester) async {
      const initialTelemetry = DailyTelemetry(
        steps: 7420,
        calories: 650,
        waterMl: 2500,
        sleepHours: 7.5,
      );

      final notifier = _TestTelemetryNotifier(initialTelemetry);
      final container = ProviderContainer(
        overrides: [
          dailyTelemetryProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: Column(
                children: [
                  StepsBentoCard(),
                  CaloriesBentoCard(),
                  WaterBentoCard(),
                  SleepBentoCard(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check values rendered from Riverpod
      expect(find.text('7,420'), findsOneWidget);
      expect(find.text('650'), findsOneWidget);
      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);

      // Mutate only steps in the provider
      notifier.setSteps(8888);
      await tester.pump();

      // Steps card updated, other values remained steady
      expect(find.text('8,888'), findsOneWidget);
      expect(find.text('650'), findsOneWidget);
      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
    });

    testWidgets('Bento cards honor explicit telemetry prop override when provided',
        (tester) async {
      const explicitTelemetry = DailyTelemetry(
        steps: 1234,
        calories: 999,
        waterMl: 1200,
        sleepHours: 6.2,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  StepsBentoCard(telemetry: explicitTelemetry),
                  CaloriesBentoCard(telemetry: explicitTelemetry),
                  WaterBentoCard(telemetry: explicitTelemetry),
                  SleepBentoCard(telemetry: explicitTelemetry),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('1,200'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);
    });
  });

  group('Chunk 2: Exercise Search Debounce Tests', () {
    testWidgets('debounceSearchQuery updates state after 150ms debounce window',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(exerciseLibraryProvider.notifier);

      // Trigger debounced search query
      notifier.debounceSearchQuery('bench');

      // Before timer fires, searchQuery is not yet committed
      expect(container.read(exerciseLibraryProvider).filter.searchQuery, isEmpty);

      // Advance clock past 150ms
      await tester.pump(const Duration(milliseconds: 160));

      // Query is now applied
      expect(container.read(exerciseLibraryProvider).filter.searchQuery, equals('bench'));
      expect(container.read(exerciseLibraryProvider).filter.hasActiveFilters, isTrue);

      // Rapidly change queries within debounce window
      notifier.debounceSearchQuery('squ');
      await tester.pump(const Duration(milliseconds: 50));
      notifier.debounceSearchQuery('squat');
      await tester.pump(const Duration(milliseconds: 50));

      // Not updated yet
      expect(container.read(exerciseLibraryProvider).filter.searchQuery, equals('bench'));

      // Advance full 150ms after the last call
      await tester.pump(const Duration(milliseconds: 160));
      expect(container.read(exerciseLibraryProvider).filter.searchQuery, equals('squat'));
    });
  });
}
