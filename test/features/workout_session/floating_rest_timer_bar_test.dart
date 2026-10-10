import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/features/workout_session/widgets/active_session_header.dart';
import 'package:leon/features/workout_session/widgets/floating_rest_timer_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveSessionHeader Widget', () {
    testWidgets('renders split name, stopwatch, and progress metrics', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ActiveSessionHeader(
                onFinishPressed: () {},
                onCancelPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Start session
      final element = tester.element(find.byType(ActiveSessionHeader));
      final container = ProviderScope.containerOf(element);
      container.read(activeSessionProvider.notifier).startSession(
        splitName: 'PUSH DAY // WORKOUT A',
      );
      await tester.pumpAndSettle();

      expect(find.text('PUSH DAY // WORKOUT A'), findsOneWidget);
      expect(find.text('FINISH'), findsOneWidget);
      expect(find.textContaining('SETS'), findsOneWidget);
    });
  });

  group('FloatingRestTimerBar Widget', () {
    testWidgets('renders remaining time and ±10s action chips when active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingRestTimerBar(),
                ],
              ),
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(FloatingRestTimerBar));
      final container = ProviderScope.containerOf(element);

      // Trigger timer
      container.read(restTimerProvider.notifier).startTimer(
        durationSeconds: 90,
        exerciseName: 'Barbell Bench Press',
        setNumber: 1,
      );
      await tester.pump();

      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('+10s'), findsOneWidget);
      expect(find.text('-10s'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      // Tap +10s
      await tester.tap(find.text('+10s'));
      await tester.pump();
      expect(find.text('01:40'), findsOneWidget);

      // Tap -10s
      await tester.tap(find.text('-10s'));
      await tester.pump();
      expect(find.text('01:30'), findsOneWidget);

      // Tap SKIP
      await tester.tap(find.text('SKIP'));
      await tester.pump();
      expect(container.read(restTimerProvider).isRunning, isFalse);
    });
  });
}
