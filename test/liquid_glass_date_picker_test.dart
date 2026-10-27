import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/shared/widgets/liquid_glass.dart';
import 'package:leon/shared/widgets/liquid_glass_date_picker.dart';

void main() {
  group('LiquidGlassDatePicker Dialog Tests', () {
    testWidgets(
      'renders liquid glass container, month header, weekday labels, and action buttons',
      (WidgetTester tester) async {
        final initialDate = DateTime(2026, 10, 28);
        DateTime? pickedDate;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      pickedDate = await showLiquidGlassDatePicker(
                        context: context,
                        initialDate: initialDate,
                        loggedWorkoutDates: {DateTime(2026, 10, 27)},
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        // Open the dialog
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 1. Verify liquid glass container is present with optical blur
        expect(find.byType(LiquidGlassContainer), findsOneWidget);

        // 2. Verify header texts
        expect(find.text('CALENDAR'), findsOneWidget);
        expect(find.text('October 2026'), findsOneWidget);

        // 3. Verify weekday labels
        expect(find.text('M'), findsWidgets);
        expect(find.text('W'), findsWidgets);

        // 4. Verify selected day 28 is rendered
        expect(find.text('28'), findsOneWidget);

        // 5. Verify action buttons
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('CANCEL'), findsOneWidget);
        expect(find.text('CONFIRM'), findsOneWidget);

        // 6. Verify minimum 11.0 pt typography floor on all text widgets
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final text in textWidgets) {
          if (text.style?.fontSize != null) {
            expect(
              text.style!.fontSize!,
              greaterThanOrEqualTo(11.0),
              reason: 'Text "${text.data}" has font size < 11.0 pt',
            );
          }
        }

        // Tap CONFIRM to close and verify result
        await tester.tap(find.text('CONFIRM'));
        await tester.pumpAndSettle();

        expect(pickedDate, isNotNull);
        expect(pickedDate!.year, 2026);
        expect(pickedDate!.month, 10);
        expect(pickedDate!.day, 28);
      },
    );

    testWidgets(
      'tapping CANCEL closes dialog without selecting a new date',
      (WidgetTester tester) async {
        DateTime? pickedDate;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      pickedDate = await showLiquidGlassDatePicker(
                        context: context,
                        initialDate: DateTime(2026, 10, 28),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();

        expect(pickedDate, isNull);
        expect(find.byType(LiquidGlassContainer), findsNothing);
      },
    );

    testWidgets(
      'month navigation switches displayed month',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => showLiquidGlassDatePicker(
                      context: context,
                      initialDate: DateTime(2026, 10, 28),
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('October 2026'), findsOneWidget);

        // Tap Next Month
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        expect(find.text('November 2026'), findsOneWidget);

        // Tap Prev Month twice
        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
        expect(find.text('October 2026'), findsOneWidget);

        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
        expect(find.text('September 2026'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();
      },
    );
  });
}
