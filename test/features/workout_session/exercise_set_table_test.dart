import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/widgets/exercise_set_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseSetTable Widget', () {
    testWidgets(
      'renders set rows, ghost previous data, and handles set checkmark',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final session = ref.watch(activeSessionProvider);
                      if (session.exercises.isEmpty) {
                        return const SizedBox();
                      }
                      return ExerciseSetTable(
                        exercise: session.exercises.first,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final consumerElement = tester.element(find.byType(Consumer));
        final container = ProviderScope.containerOf(consumerElement);

        // Start session
        container.read(activeSessionProvider.notifier).startSession();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify headers
        expect(find.text('SET'), findsOneWidget);
        expect(find.text('KG'), findsOneWidget);
        expect(find.text('REPS'), findsOneWidget);
        expect(find.text('LOG'), findsOneWidget);

        // Verify subtle previous baseline presence
        expect(find.text('prev: —'), findsWidgets);

        // Verify checkmark button exists
        final checkButtons = find.byIcon(Icons.circle_outlined);
        expect(checkButtons, findsWidgets);

        // Tap first set checkmark
        await tester.tap(checkButtons.first);
        await tester.pump();

        // First set should now have solid check icon
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(
          container
              .read(activeSessionProvider)
              .exercises
              .first
              .sets
              .first
              .isCompleted,
          isTrue,
        );

        // Tap Add Set
        await tester.tap(find.text('ADD SET'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          container.read(activeSessionProvider).exercises.first.sets.length,
          5,
        );

        // Cancel session ticker so no timers remain pending
        container.read(activeSessionProvider.notifier).cancelSession();
        await tester.pump();
      },
    );
  });
}
