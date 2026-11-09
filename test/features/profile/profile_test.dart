import 'package:leon/features/profile/services/training_report_data.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/profile/models/account_profile_model.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/services/pdf_report_service.dart';
import 'package:leon/features/profile/screens/profile_screen.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/core/providers/local_date_provider.dart';

void main() {
  group('AccountProfile Model & Biometrics Computation Tests', () {
    test('Calculates BMI, BMR, TDEE, and Goal Delta accurately', () {
      final profile = AccountProfile(
        displayName: 'Leon Kennedy',
        email: 'leon@fitness.os',
        memberSince: DateTime(2026, 1, 1),
        heightCm: 180.0,
        age: 26,
        sex: 'male',
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
    test('Updates biometrics and updates state', () async {
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(accountProfileProvider.notifier);
      expect(container.read(accountProfileProvider).currentWeightKg, isNull);

      await notifier.updateBiometrics(
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

    test('Toggles preferences correctly', () async {
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(accountProfileProvider.notifier);
      await notifier.toggleAudioCues(false);
      expect(container.read(accountProfileProvider).audioCuesEnabled, isFalse);

      await notifier.toggleCycleTracking(true);
      expect(
        container.read(accountProfileProvider).cycleTrackingEnabled,
        isTrue,
      );
    });
  });

  group('PDF Athletic Report Generation Tests', () {
    test('Generates valid non-empty PDF document bytes', () async {
      final report = TrainingReportData(
        month: DateTime(2026, 1),
        history: [],
        measurements: [],
      );
      final bytes = await PdfReportService.generateMonthlyReportPdf(report);
      expect(bytes, isNotEmpty);
      // PDF documents start with '%PDF-'
      final header = utf8.decode(bytes.sublist(0, 5), allowMalformed: true);
      expect(header, equals('%PDF-'));
    });
  });

  group('ProfileScreen Widget Tests', () {
    for (final layout in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets(
        'Identity follows sign-in changes with a blank saved email at ${layout.$1}px/${layout.$2}x',
        (tester) async {
          tester.view.physicalSize = Size(layout.$1, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = ProviderContainer(
            overrides: [
              hiveServiceProvider.overrideWithValue(MemoryHiveService()),
              authProvider.overrideWith(_IdentityAuth.new),
              localDateProvider.overrideWith((ref) => DateTime(2026, 11, 6)),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(layout.$2)),
                  child: child!,
                ),
                home: const ProfileScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final auth = container.read(authProvider.notifier) as _IdentityAuth;
          expect(find.text('Local profile'), findsOneWidget);
          expect(container.read(accountProfileProvider).email, isEmpty);
          auth.set(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'signed-in-account',
              email: 'alexandra.morgan.rodriguez@example.com',
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('alexandra.morgan.rodriguez@example.com'),
            findsOneWidget,
          );
          expect(find.text('Local profile'), findsNothing);
          expect(tester.takeException(), isNull);
          auth.set(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'account-without-email',
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Cloud account'), findsOneWidget);
          auth.set(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'anonymous-account',
              isAnonymous: true,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Guest profile'), findsOneWidget);
          auth.set(const AuthState(status: AuthStatus.unauthenticated));
          await tester.pumpAndSettle();
          expect(find.text('Local profile'), findsOneWidget);
          expect(
            find.text('alexandra.morgan.rodriguez@example.com'),
            findsNothing,
          );
          auth.set(const AuthState());
          await tester.pumpAndSettle();
          expect(find.text('Checking account…'), findsOneWidget);
          expect(container.read(accountProfileProvider).email, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Renders Account screen components and actions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(MemoryHiveService()),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Account Header & Identity
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Personal profile & settings'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('leon@fitness.os'), findsNothing);

      // Verify Physical Biometrics & Goal delta
      expect(find.text('BIOMETRICS & GOALS'), findsOneWidget);
      expect(find.text('HEIGHT'), findsNothing);
      await tester.tap(find.text('BIOMETRICS & GOALS'));
      await tester.pumpAndSettle();
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('CURRENT'), findsOneWidget);
      expect(find.text('GOAL'), findsOneWidget);

      // Verify Training Preferences
      await tester.scrollUntilVisible(
        find.text('TRAINING PREFERENCES'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('TRAINING PREFERENCES'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Default rest timer'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Default rest timer'), findsOneWidget);

      // Verify Export actions
      expect(find.text('REPORTS & DATA EXPORT'), findsNothing);
      expect(find.text('Export Monthly PDF Report'), findsNothing);
    });
  });
}

class _IdentityAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  void set(AuthState next) => state = next;
}
