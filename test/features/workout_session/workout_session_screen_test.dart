import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/screens/workout_session_screen.dart';
import 'package:leon/features/workout_session/widgets/active_session_header.dart';
import 'package:leon/features/workout_session/widgets/exercise_sequence_card.dart';
import 'package:leon/features/workout_session/widgets/floating_rest_timer_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutSessionScreen Widget', () {
    testWidgets('renders active header, sequence list cards, and floating rest bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutSessionScreen(),
          ),
        ),
      );

      // Execute post frame callback to start session
      await tester.pump();
      // Render state with started session
      await tester.pump();

      // Verify Header
      expect(find.byType(ActiveSessionHeader), findsOneWidget);
      expect(find.textContaining('PUSH DAY'), findsOneWidget);

      // Verify Sequence Cards
      expect(find.byType(ExerciseSequenceCard), findsWidgets);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);

      // Verify Floating Rest Bar
      expect(find.byType(FloatingRestTimerBar), findsOneWidget);

      // Tap on second exercise card to toggle accordion expansion
      await tester.tap(find.text('Incline Dumbbell Press'));
      await tester.pump();

      // Top action button + ADD EXERCISE should be present
      expect(find.text('+ ADD EXERCISE'), findsOneWidget);
    });
  });
}
