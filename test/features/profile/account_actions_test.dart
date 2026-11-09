import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/screens/profile_screen.dart';
import 'package:leon/features/workout_session/services/native_rest_service.dart';
import 'package:leon/features/workout_session/services/notification_service.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/services/backup_service.dart';
import 'package:leon/services/export_file_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/sync_service.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';
import 'package:leon/state/app_providers.dart';
import '../../services/cloud_sync_engine_test.dart' show WorkspaceMemory, owner;
import 'account_layout_test.dart' show openSection, reveal;

class _Storage extends WorkspaceMemory {
  @override
  Future<Map<String, dynamic>> flushedSnapshot() async => snapshot();
}

class _Files extends ExportFileService {
  final saved = <(String, String, Uint8List)>[];
  final shared = <(String, String, Uint8List)>[];
  Uint8List? backup;
  Completer<String?>? gate;
  @override
  Future<String?> save(String name, String mime, Uint8List bytes) async {
    saved.add((name, mime, bytes));
    return gate?.future;
  }

  @override
  Future<bool> share(String name, String mime, Uint8List bytes) async {
    shared.add((name, mime, bytes));
    return false;
  }

  @override
  Future<Uint8List?> pickBackup() async => backup;
}

class _Auth extends AuthNotifier {
  int signOuts = 0;
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    userId: owner,
    email: 'alex@example.com',
  );
  @override
  Future<void> signOut() async {
    signOuts++;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _Sync extends SyncService {
  int calls = 0;
  bool offline = false;
  @override
  SyncState build() => const SyncState(status: SyncStatus.synced);
  @override
  Future<void> syncAll() async {
    calls++;
    state = SyncState(status: offline ? SyncStatus.offline : SyncStatus.synced);
  }
}

class _Notifications extends WorkoutNotificationService {
  _Notifications() : super(initialize: () async => false);
  int requests = 0;
  @override
  Future<bool> requestPermissions() async {
    requests++;
    return false;
  }
}

class _Rest extends NativeRestService {
  int requests = 0;
  @override
  Future<void> requestExactAlarms() async {
    requests++;
  }
}

class _Fixture {
  final hive = _Storage();
  final files = _Files();
  final notifications = _Notifications();
  final rest = _Rest();
  final capture = GlobalKey();
  late ProviderContainer container;
  late GoRouter router;
  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool fonts = false,
  }) async {
    if (fonts) {
      for (final family in ['Outfit', 'JetBrainsMono']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'))).load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await hive.put(
      'user',
      AppConstants.hiveKeyLocalProfile,
      const UserModel(
        id: owner,
        email: '',
        displayName: 'Alex',
        preferredSplit: 'PPL',
        trainingSchedules: '[]',
        trainingDaysPerWeek: 4,
        onboardingComplete: true,
        currentWeight: 80,
        targetWeight: 75,
        heightCm: 180,
        experienceLevel: 'Experienced',
      ).toJson(),
    );
    container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hive),
        localDateProvider.overrideWith((ref) => DateTime(2026, 11, 6)),
        authProvider.overrideWith(_Auth.new),
        syncServiceProvider.overrideWith(_Sync.new),
        exportFileServiceProvider.overrideWithValue(files),
        workoutNotificationServiceProvider.overrideWithValue(notifications),
        nativeRestServiceProvider.overrideWithValue(rest),
      ],
    );
    addTearDown(container.dispose);
    router = GoRouter(
      initialLocation: '/profile',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              AppShell.navigation(navigationShell: shell),
          branches: [
            for (var i = 0; i < 4; i++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/tab$i',
                    builder: (_, state) => const SizedBox(),
                  ),
                ],
              ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        for (final path in [
          AppConstants.routeHealthTracking,
          AppConstants.routeRecovery,
          AppConstants.routeLogin,
          AppConstants.routeOnboarding,
        ])
          GoRoute(
            path: path,
            builder: (_, state) => Scaffold(
              appBar: AppBar(title: Text('Opened $path')),
              body: const SizedBox(),
            ),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark.copyWith(platform: TargetPlatform.android),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 24, bottom: 16),
              ),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final picture = await boundary.toImage();
      final bytes = await picture.toByteData(format: ImageByteFormat.png);
      await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }
}

Future<void> _choose(WidgetTester tester, String title, String label) async {
  await reveal(tester, title);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is CheckedPopupMenuItem),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeMessage(WidgetTester tester) async {
  if (find.byTooltip('Close message').evaluate().isNotEmpty) {
    await tester.tap(find.byTooltip('Close message'));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final layout in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      'Account errors stay above the real pill and profile sheet at $layout',
      (tester) async {
        final fixture = _Fixture();
        await fixture.mount(
          tester,
          width: layout.$1,
          scale: layout.$2,
          fonts: true,
        );
        fixture.hive.failDocuments = true;
        await openSection(tester, 'APP SETTINGS');
        await _choose(tester, 'Weight unit', 'Pounds (lbs)');
        final error = find.text('Could not save changes. Please try again.');
        expect(error.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(error).bottom,
          lessThan(tester.getRect(find.byType(GlassNavPill)).top),
        );
        expect(fixture.container.read(accountProfileProvider).weightUnit, 'kg');
        await fixture.screenshot(tester, 'account_error_${layout.$1.toInt()}');
        await _closeMessage(tester);
        fixture.hive.failDocuments = false;
        await _choose(tester, 'Weight unit', 'Pounds (lbs)');
        expect(
          fixture.container.read(accountProfileProvider).weightUnit,
          'lbs',
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Edit profile'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save Changes'));
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        final formError = find.text(
          'Check your name and contact email before saving.',
        );
        expect(formError.hitTestable(), findsOneWidget);
        expect(tester.getRect(formError).bottom, lessThan(544));
        expect(find.byType(GlassNavPill).hitTestable(), findsNothing);
        expect(
          fixture.container.read(userProfileProvider)!.displayName,
          'Alex',
        );
        await tester.ensureVisible(find.text('Save Changes'));
        await tester.pumpAndSettle();
        await fixture.screenshot(
          tester,
          'account_form_error_${layout.$1.toInt()}',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Every Account choice persists and pending choices keep saved values',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      await openSection(tester, 'TRAINING PREFERENCES');
      for (final seconds in [60, 90, 180, 120]) {
        await _choose(tester, 'Default rest timer', '$seconds seconds');
        expect(
          fixture.container.read(accountProfileProvider).defaultRestSeconds,
          seconds,
        );
      }
      for (final kg in [15.0, 20.0]) {
        await _choose(tester, 'Barbell weight', '${kg.toStringAsFixed(1)} kg');
        expect(
          fixture.container.read(accountProfileProvider).barbellTareKg,
          kg,
        );
      }
      for (final goal in ['STRENGTH', 'LOSE FAT', 'ATHLETIC', 'BUILD MUSCLE']) {
        await reveal(tester, 'Primary goal');
        await tester.tap(find.text('Primary goal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(goal));
        await tester.pumpAndSettle();
        expect(fixture.container.read(userProfileProvider)!.primaryGoal, goal);
      }
      await openSection(tester, 'APP SETTINGS');
      final gate = Completer<void>();
      fixture.hive.documentGate = gate;
      await reveal(tester, 'Weight unit');
      await tester.tap(find.text('Weight unit'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<String>, 'Pounds (lbs)'),
      );
      for (
        var i = 0;
        i < 10 && find.byTooltip('Saving Weight unit').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(fixture.container.read(accountProfileProvider).weightUnit, 'kg');
      expect(find.byTooltip('Saving Weight unit'), findsOneWidget);
      await tester.tap(find.text('Weight unit'));
      await tester.pump();
      expect(
        find.byType(CheckedPopupMenuItem<String>).hitTestable(),
        findsNothing,
      );
      gate.complete();
      fixture.hive.documentGate = null;
      await tester.pumpAndSettle();
      expect(fixture.container.read(accountProfileProvider).weightUnit, 'lbs');
      for (final choice in [
        ('Weight unit', 'Kilograms (kg)'),
        ('Weight unit', 'Pounds (lbs)'),
        ('Height unit', 'Feet & inches (ft / in)'),
        ('Height unit', 'Centimeters (cm)'),
        ('Workout alerts', 'Silent'),
        ('Workout alerts', 'Vibrate only'),
        ('Workout alerts', 'Sound + vibrate'),
      ]) {
        await _choose(tester, choice.$1, choice.$2);
      }
      final saved = fixture.container.read(userProfileProvider)!;
      expect(saved.weightUnit, 'lbs');
      expect(saved.heightUnit, 'cm');
      expect(saved.currentWeight, 80);
      expect(saved.targetWeight, 75);
      expect(saved.startingWeightKg, isNull);
      expect(saved.goalDirection, isNull);
      expect(saved.preferredSplit, 'PPL');
      expect(saved.trainingSchedules, '[]');
      expect(saved.audioCuesEnabled, isTrue);
      expect(saved.hapticFeedbackEnabled, isTrue);
      final restarted = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fixture.hive),
          localDateProvider.overrideWithValue(DateTime(2026, 11, 6)),
        ],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(accountProfileProvider).weightUnit, 'lbs');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Account routes, permissions, sync and confirmations invoke their intended actions',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      await openSection(tester, 'HEALTH & RECOVERY');
      for (final route in [
        ('Health & measurements', AppConstants.routeHealthTracking),
        ('Recovery check-in', AppConstants.routeRecovery),
      ]) {
        await reveal(tester, route.$1);
        await tester.tap(find.text(route.$1));
        await tester.pumpAndSettle();
        expect(find.text('Opened ${route.$2}'), findsOneWidget);
        fixture.router.pop();
        await tester.pumpAndSettle();
      }
      await reveal(tester, 'Pause training');
      await tester.tap(find.text('Pause training'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassNavPill).hitTestable(), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await openSection(tester, 'APP SETTINGS');
      await reveal(tester, 'Workout notifications');
      await tester.tap(find.text('Workout notifications'));
      await tester.pumpAndSettle();
      expect(fixture.notifications.requests, 1);
      expect(
        find.textContaining('Notifications are unavailable').hitTestable(),
        findsWidgets,
      );
      await _closeMessage(tester);
      await reveal(tester, 'Precise rest alarms');
      await tester.tap(find.text('Precise rest alarms'));
      await tester.pumpAndSettle();
      expect(fixture.rest.requests, 1);
      expect(
        find.textContaining('Precise alarms use').hitTestable(),
        findsWidgets,
      );
      await _closeMessage(tester);
      await openSection(tester, 'CLOUD & SYNC');
      await reveal(tester, 'Sync now');
      await tester.tap(find.text('Sync now'));
      await tester.pumpAndSettle();
      expect(
        (fixture.container.read(syncServiceProvider.notifier) as _Sync).calls,
        1,
      );
      expect(
        find.text('Cloud sync is up to date.').hitTestable(),
        findsOneWidget,
      );
      await _closeMessage(tester);
      final sync =
          fixture.container.read(syncServiceProvider.notifier) as _Sync;
      sync.offline = true;
      await tester.tap(find.text('Sync now'));
      await tester.pumpAndSettle();
      expect(sync.calls, 2);
      expect(
        find.textContaining('offline. Saved changes').hitTestable(),
        findsOneWidget,
      );
      await _closeMessage(tester);
      await reveal(tester, 'Sign out');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (fixture.container.read(authProvider.notifier) as _Auth).signOuts,
        0,
      );
      await openSection(tester, 'SETUP & PREFERENCES');
      await reveal(tester, 'Reset preferences');
      await tester.tap(find.text('Reset preferences'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset preferences'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Reset preferences'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Preferences restored to defaults.').hitTestable(),
        findsOneWidget,
      );
      await _closeMessage(tester);
      await reveal(tester, 'Redo setup');
      await tester.tap(find.text('Redo setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        fixture.container.read(userProfileProvider)!.trainingSchedules,
        '[]',
      );
      await tester.tap(find.text('Redo setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Redo setup'));
      await tester.pumpAndSettle();
      expect(
        find.text('Opened ${AppConstants.routeOnboarding}'),
        findsOneWidget,
      );
      fixture.router.go('/profile');
      await tester.pumpAndSettle();
      await openSection(tester, 'CLOUD & SYNC');
      await reveal(tester, 'Sign out');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(
        (fixture.container.read(authProvider.notifier) as _Auth).signOuts,
        1,
      );
      await reveal(tester, 'Sign in to Cloud');
      await tester.tap(find.text('Sign in to Cloud'));
      await tester.pumpAndSettle();
      expect(find.text('Opened ${AppConstants.routeLogin}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Backup and report buttons pass actual bytes, retain cancellation and protect replacement at 320/2x',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 320, scale: 2);
      await openSection(tester, 'DATA & REPORTS');
      await reveal(tester, 'Backup & export');
      await tester.tap(find.text('Backup & export'));
      await tester.pumpAndSettle();
      for (final label in [
        'Save backup JSON',
        'Share backup JSON',
        'Save logged sets CSV',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await _closeMessage(tester);
      }
      expect(fixture.files.saved.map((e) => e.$2), [
        'application/json',
        'text/csv',
      ]);
      expect(fixture.files.shared.single.$2, 'application/json');
      expect(fixture.files.saved.every((e) => e.$3.isNotEmpty), isTrue);
      fixture.files.backup = await BackupService(fixture.hive).export();
      await tester.ensureVisible(find.text('Choose backup to restore'));
      await tester.tap(find.text('Choose backup to restore'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<RestoreMode>),
      );
      await tester.tap(find.byType(DropdownButtonFormField<RestoreMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace all backed-up data').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Replace data with this backup'));
      await tester.tap(find.text('Replace data with this backup'));
      await tester.pumpAndSettle();
      expect(find.text('Replace saved data?'), findsOneWidget);
      await fixture.screenshot(tester, 'account_restore_confirm_320');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Close'));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await reveal(tester, 'Monthly training report');
      await tester.tap(find.text('Monthly training report'));
      await tester.pumpAndSettle();
      for (final label in ['Save PDF', 'Share PDF']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await _closeMessage(tester);
      }
      expect(fixture.files.saved.last.$2, 'application/pdf');
      expect(fixture.files.saved.last.$3.take(5), '%PDF-'.codeUnits);
      expect(fixture.files.shared.last.$2, 'application/pdf');
      await tester.ensureVisible(find.byTooltip('Close'));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(fixture.container.read(userProfileProvider)!.displayName, 'Alex');
      expect(tester.takeException(), isNull);
    },
  );
}
