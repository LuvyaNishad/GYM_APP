import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/widgets/edit_biometrics_dialog.dart';
import 'package:leon/features/profile/widgets/edit_profile_dialog.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/state/app_providers.dart';

import '../../helpers/memory_hive_service.dart';

void main() {
  testWidgets(
    'Biometrics preserves exact values through unit toggles and saves edited imperial values',
    (tester) async {
      final hive = MemoryHiveService();
      await hive.put(
        'user',
        AppConstants.hiveKeyLocalProfile,
        const UserModel(
          id: 'existing',
          email: '',
          displayName: 'Alex',
          preferredSplit: 'PPL',
          heightCm: 180.123,
          currentWeight: 80.123,
          targetWeight: 75.234,
          weightUnit: 'lbs',
          heightUnit: 'ft',
        ).toJson(),
      );
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          localDateProvider.overrideWith((ref) => DateTime(2026, 11, 6)),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditBiometricsSheet(
                    context,
                    container.read(accountProfileProvider),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      Future<void> save() async {
        final button = find.widgetWithText(ElevatedButton, 'Update Biometrics');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await open();
      for (final label in ['kg', 'lbs', 'kg', 'lbs']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      for (final label in ['cm', 'ft / in']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      await save();
      var saved = container.read(userProfileProvider)!;
      expect(saved.currentWeight, 80.123);
      expect(saved.targetWeight, 75.234);
      expect(saved.heightCm, 180.123);
      await open();
      await tester.enterText(find.byType(TextField).at(1), '200');
      await save();
      saved = container.read(userProfileProvider)!;
      expect(saved.currentWeight, closeTo(200 / 2.2046226218, 1e-9));
      expect(saved.targetWeight, 75.234);
      expect(saved.heightCm, 180.123);
      await open();
      for (final field in find.byType(TextField).evaluate().toList()) {
        await tester.enterText(find.byWidget(field.widget), '');
      }
      await save();
      saved = container.read(userProfileProvider)!;
      expect(saved.currentWeight, isNull);
      expect(saved.targetWeight, isNull);
      expect(saved.heightCm, isNull);
      expect(saved.age, isNull);
      expect(saved.preferredSplit, 'PPL');
      expect(tester.takeException(), isNull);
    },
  );
  for (final biometrics in [false, true]) {
    testWidgets(
      '${biometrics ? 'Biometrics' : 'Profile'} waits for persistence and retains failed edits for retry',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final hive = MemoryHiveService();
        final container = ProviderContainer(
          overrides: [
            hiveServiceProvider.overrideWithValue(hive),
            localDateProvider.overrideWith((ref) => DateTime(2026, 10, 31)),
          ],
        );
        addTearDown(container.dispose);
        // An onboarding split ID must remain selectable without resetting it.
        await hive.put(
          AppConstants.hiveBoxUser,
          AppConstants.hiveKeyLocalProfile,
          const UserModel(
            id: 'existing',
            email: '',
            displayName: '',
            preferredSplit: 'custom_split_id',
            experienceLevel: 'Experienced',
          ).toJson(),
        );
        final original = container.read(accountProfileProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: const EdgeInsets.only(bottom: 300),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      if (biometrics) {
                        showEditBiometricsSheet(context, original);
                      } else {
                        showEditProfileSheet(context, original);
                      }
                    },
                    child: const Text('Open sheet'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open sheet'));
        await tester.pumpAndSettle();
        final entered = biometrics ? '182' : 'Saved lifter';
        await tester.enterText(find.byType(TextField).first, entered);
        await tester.pumpAndSettle();
        final saveLabel = biometrics ? 'Update Biometrics' : 'Save Changes';
        final saveButton = find.widgetWithText(ElevatedButton, saveLabel);
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        expect(tester.getCenter(saveButton).dy, lessThan(544));
        hive.documentGate = Completer<void>();
        await tester.tap(find.widgetWithText(ElevatedButton, saveLabel));
        await tester.pump();
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, saveLabel),
              )
              .onPressed,
          isNull,
        );
        expect(container.read(accountProfileProvider), original);
        await tester.dragFrom(const Offset(195, 100), const Offset(0, 650));
        await tester.pump(const Duration(seconds: 1));
        await tester.binding.handlePopRoute();
        await tester.tapAt(const Offset(5, 5));
        await tester.pump();
        expect(find.widgetWithText(ElevatedButton, saveLabel), findsOneWidget);
        hive.failDocuments = true;
        hive.documentGate!.complete();
        await tester.pumpAndSettle();
        expect(find.textContaining('Could not save'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == entered,
          ),
          findsOneWidget,
        );
        expect(container.read(accountProfileProvider), original);
        hive.failDocuments = false;
        hive.documentGate = null;
        await tester.tap(find.widgetWithText(ElevatedButton, saveLabel));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        final saved = container.read(accountProfileProvider);
        expect(saved.preferredSplit, 'custom_split_id');
        expect(saved.experienceLevel, 'Experienced');
        if (biometrics) {
          expect(saved.heightCm, 182);
        } else {
          expect(saved.displayName, entered);
          expect(container.read(userProfileProvider)!.displayName, entered);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
