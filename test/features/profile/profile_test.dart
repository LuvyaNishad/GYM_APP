import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/profile/models/account_profile_model.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/services/pdf_report_service.dart';
import 'package:leon/features/profile/screens/profile_screen.dart';

void main() {
  group('AccountProfile Model & Biometrics Computation Tests', () {
    test('Calculates BMI, BMR, TDEE, and Goal Delta accurately', () {
      final profile = AccountProfile(
        displayName: 'Leon Kennedy',
        email: 'leon@fitness.os',
        memberSince: DateTime(2026, 1, 1),
        heightCm: 180.0,
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
        weightUnit: 'kg',
        heightUnit: 'cm',
        experienceLevel: 'Advanced',
        preferredSplit: 'Push / Pull / Legs',
      );

      // BMI = 80 / (1.80 * 1.80) = 24.69
      expect(profile.bmi, closeTo(24.69, 0.1));
      expect(profile.bmiCategory, equals('Normal Weight'));

      // Goal delta: (80 - 75).abs() = 5.0 kg
      expect(profile.weightDeltaKg, equals(5.0));
      expect(profile.isCutting, isTrue);

      // BMR estimate: 10*80 + 6.25*180 - 5*26 + 5 = 800 + 1125 - 130 + 5 = 1800
      expect(profile.bmrEstimate, equals(1800));

      // Maintenance calories: 1800 * 1.55 = 2790
      expect(profile.maintenanceCaloriesEstimate, equals(2790));
    });

    test('Serialization to/from JSON preserves all fields', () {
      final original = AccountProfile(
        displayName: 'Ada Wong',
        email: 'ada@fitness.os',
        memberSince: DateTime(2026, 2, 1),
        heightCm: 170.0,
        currentWeightKg: 60.0,
        targetWeightKg: 58.0,
        cycleTrackingEnabled: true,
        barbellTareKg: 15.0,
      );

      final jsonMap = original.toJson();
      final decoded = AccountProfile.fromJson(jsonMap);

      expect(decoded.displayName, equals('Ada Wong'));
      expect(decoded.email, equals('ada@fitness.os'));
      expect(decoded.heightCm, equals(170.0));
      expect(decoded.currentWeightKg, equals(60.0));
      expect(decoded.cycleTrackingEnabled, isTrue);
      expect(decoded.barbellTareKg, equals(15.0));
    });
  });

  group('AccountProfileNotifier State Tests', () {
    test('Updates biometrics and updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountProfileProvider.notifier);
      expect(container.read(accountProfileProvider).currentWeightKg, equals(78.5));

      notifier.updateBiometrics(
        heightCm: 185.0,
        currentWeightKg: 85.0,
        targetWeightKg: 80.0,
        weightUnit: 'kg',
      );

      final updated = container.read(accountProfileProvider);
      expect(updated.heightCm, equals(185.0));
      expect(updated.currentWeightKg, equals(85.0));
      expect(updated.targetWeightKg, equals(80.0));
    });

    test('Toggles preferences correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountProfileProvider.notifier);
      notifier.toggleAudioCues(false);
      expect(container.read(accountProfileProvider).audioCuesEnabled, isFalse);

      notifier.toggleCycleTracking(true);
      expect(container.read(accountProfileProvider).cycleTrackingEnabled, isTrue);
    });
  });

  group('PDF Athletic Report Generation Tests', () {
    test('Generates valid non-empty PDF document bytes', () async {
      final profile = AccountProfile(
        displayName: 'Leon Kennedy',
        email: 'leon@fitness.os',
        memberSince: DateTime(2026, 1, 1),
        heightCm: 180.0,
        currentWeightKg: 82.5,
        targetWeightKg: 80.0,
      );

      final bytes = await PdfReportService.generateMonthlyReportPdf(profile);
      expect(bytes, isNotEmpty);
      // PDF documents start with '%PDF-'
      final header = utf8.decode(bytes.sublist(0, 5), allowMalformed: true);
      expect(header, equals('%PDF-'));
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders Account screen components and actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Account Header & Identity
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Personal Profile & Settings'), findsOneWidget);
      expect(find.text('Leon'), findsOneWidget);
      expect(find.text('leon@fitness.os'), findsOneWidget);

      // Verify Physical Biometrics & Goal delta
      expect(find.text('BIOMETRICS & GOALS'), findsOneWidget);
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('CURRENT'), findsOneWidget);
      expect(find.text('GOAL'), findsOneWidget);

      // Verify Training Preferences
      expect(find.text('TRAINING PREFERENCES'), findsOneWidget);
      expect(find.text('Default Rest Timer'), findsOneWidget);

      // Verify Export actions
      expect(find.text('REPORTS & DATA EXPORT'), findsOneWidget);
      expect(find.text('Export Monthly PDF Report'), findsOneWidget);
    });
  });
}
