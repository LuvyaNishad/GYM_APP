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
