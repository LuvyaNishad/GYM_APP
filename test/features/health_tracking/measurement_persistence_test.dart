import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/health_tracking/providers/body_measurements_provider.dart';
import 'package:leon/features/health_tracking/widgets/log_measurement_sheet.dart';
import 'package:leon/services/hive_service.dart';

import '../../helpers/memory_hive_service.dart';

void main() {
  testWidgets(
    'invalid optional measurements stay visible; failed saves wait and retain all input for retry',
    (tester) async {
      final hive = MemoryHiveService();
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => LogMeasurementSheet.show(context),
                  child: const Text('Open measurements'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open measurements'));
      await tester.pumpAndSettle();
      Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(input('WEIGHT'), '80.5');
      await tester.enterText(input('BODY FAT'), '101');
      await tester.tap(find.text('SAVE MEASUREMENTS'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a valid body fat'), findsOneWidget);
      expect(container.read(bodyMeasurementsProvider), isEmpty);
      expect(hive.documentWrites, 0);
      await tester.enterText(input('BODY FAT'), '18.5');
      hive.documentGate = Completer<void>();
      await tester.tap(find.text('SAVE MEASUREMENTS'));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'SAVE MEASUREMENTS'),
            )
            .onPressed,
        isNull,
      );
      expect(container.read(bodyMeasurementsProvider), isEmpty);
      await tester.dragFrom(
        tester.getCenter(find.text('RECORD MEASUREMENTS')),
        const Offset(0, 650),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(find.byType(LogMeasurementSheet), findsOneWidget);
      hive.failDocuments = true;
      hive.documentGate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save measurements.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(input('WEIGHT')).controller!.text,
        '80.5',
      );
      expect(
        tester.widget<TextField>(input('BODY FAT')).controller!.text,
        '18.5',
      );
      hive.failDocuments = false;
      hive.documentGate = null;
      await tester.tap(find.text('SAVE MEASUREMENTS'));
      await tester.pumpAndSettle();
      expect(find.text('RECORD MEASUREMENTS'), findsNothing);
      final saved = container.read(bodyMeasurementsProvider).single;
      expect(saved.weightKg, 80.5);
      expect(saved.bodyFatPercent, 18.5);
      expect(saved.waistCm, isNull);
      expect(hive.documentWrites, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
