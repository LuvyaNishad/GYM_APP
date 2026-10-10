import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/widgets/effort_picker_modal.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Plate Calculator Logic', () {
    test('calculates correct plates per side for 100 kg on standard 20 kg bar (Olympic 25kg set)', () {
      final breakdown = calculatePlatesPerSide(totalWeightKg: 100.0, barWeightKg: 20.0);
      // 40 kg per side -> 1x25kg + 1x15kg
      expect(breakdown[25.0], 1);
      expect(breakdown[15.0], 1);
    });

    test('calculates correct plates per side for 100 kg with 20 kg max plates', () {
      final breakdown = calculatePlatesPerSide(
        totalWeightKg: 100.0,
        barWeightKg: 20.0,
        availablePlates: [20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
      );
      // 40 kg per side -> 2x20kg
      expect(breakdown[20.0], 2);
      expect(breakdown[10.0] ?? 0, 0);
    });

    test('calculates correct plates per side for 82.5 kg', () {
      final breakdown = calculatePlatesPerSide(totalWeightKg: 82.5, barWeightKg: 20.0);
      // 31.25 kg per side -> 1x25kg + 1x5kg + 1x1.25kg
      expect(breakdown[25.0], 1);
      expect(breakdown[5.0], 1);
      expect(breakdown[1.25], 1);
    });

    test('handles target weight equal to or below bar weight', () {
      final breakdown = calculatePlatesPerSide(totalWeightKg: 20.0, barWeightKg: 20.0);
      expect(breakdown.isEmpty, isTrue);
    });
  });

  group('EffortPickerModal Widget', () {
    testWidgets('renders RIR and RPE options and updates upon tap', (tester) async {
      double selectedRir = 2.0;
      double selectedRpe = 8.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffortPickerModal(
              initialRir: 2.0,
              initialRpe: 8.0,
              onSaved: (rir, rpe) {
                selectedRir = rir;
                selectedRpe = rpe;
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('EFFORT SELECTOR'), findsOneWidget);
      expect(find.textContaining('1 RIR'), findsOneWidget);

      // Tap 1 RIR chip
      await tester.tap(find.textContaining('1 RIR'));
      await tester.pump();

      // Tap Confirm
      await tester.tap(find.text('CONFIRM'));
      await tester.pump();

      expect(selectedRir, 1.0);
      expect(selectedRpe, 9.0);
    });
  });

  group('PlateCalculatorModal Widget', () {
    testWidgets('renders barbell diagram and plate calculation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlateCalculatorModal(
              initialTotalWeightKg: 100.0,
            ),
          ),
        ),
      );

      expect(find.textContaining('PLATE CALCULATOR'), findsOneWidget);
      expect(find.textContaining('100.0 KG'), findsOneWidget);
      expect(find.textContaining('40.0 KG PER SIDE'), findsOneWidget);
    });
  });
}
