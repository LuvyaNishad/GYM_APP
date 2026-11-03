import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/widgets/workout_summary_dialog.dart';
import 'package:leon/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutSummaryDialog Widget', () {
    testWidgets(
      'large-text recap scrolls to Save and Resume; failed save can retry without duplicate submission',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var writes = 0;
        var gate = Completer<void>();
        final session = ActiveSessionState(
          workoutId: 'recap',
          splitName: 'My long upper body workout with unilateral exercises',
          startTime: DateTime(2026, 11, 4),
          isActive: true,
          exercises: [
            const ActiveExerciseState(
              exerciseId: 'press',
              name: 'Single-arm incline dumbbell chest press',
              muscleGroup: 'Chest',
              sets: [
                ActiveSetState(
                  setNumber: 1,
                  weightKg: 12.5,
                  reps: 10,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: false,
                      builder: (_) => WorkoutSummaryDialog(
                        session: session,
                        onConfirmedSave: () {
                          writes++;
                          return gate.future;
                        },
                      ),
                    ),
                    child: const Text('Open recap'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open recap'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('RESUME WORKOUT'));
        await tester.pumpAndSettle();
        expect(find.text('RESUME WORKOUT').hitTestable(), findsOneWidget);
        final save = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'SAVE WORKOUT'),
            )
            .onPressed!;
        save();
        save();
        await tester.pump();
        expect(writes, 1);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(WorkoutSummaryDialog), findsOneWidget);
        gate.completeError(StateError('disk unavailable'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Your workout is still here.'),
          findsOneWidget,
        );
        gate = Completer<void>();
        await tester.ensureVisible(find.text('SAVE WORKOUT'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAVE WORKOUT'));
        await tester.pump();
        expect(writes, 2);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutSummaryDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'renders duration, volume, sets, and triggers onConfirmedSave',
      (tester) async {
        bool saved = false;

        final session = ActiveSessionState(
          workoutId: 'test_wkt',
          splitName: 'PUSH DAY // WORKOUT A',
          startTime: DateTime.now(),
          elapsedSeconds: 2540, // 42m 20s
          isActive: true,
          exercises: [
            const ActiveExerciseState(
              exerciseId: 'ex1',
              name: 'Barbell Bench Press',
              muscleGroup: 'Chest',
              sets: [
                ActiveSetState(
                  setNumber: 1,
                  weightKg: 80,
                  reps: 8,
                  isCompleted: true,
                ),
                ActiveSetState(
                  setNumber: 2,
                  weightKg: 80,
                  reps: 8,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: WorkoutSummaryDialog(
                  session: session,
                  onConfirmedSave: () {
                    saved = true;
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('WORKOUT RECAP'), findsOneWidget);
        expect(find.textContaining('PUSH DAY // WORKOUT A'), findsOneWidget);
        expect(find.textContaining('1280 kg'), findsOneWidget);
        expect(find.textContaining('2/2 sets'), findsOneWidget);

        // Tap Save
        await tester.tap(find.text('SAVE WORKOUT'));
        await tester.pump();

        expect(saved, isTrue);
      },
    );
  });
}
