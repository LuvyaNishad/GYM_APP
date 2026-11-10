import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/router/app_router.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/features/authentication/screens/login_screen.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';
import 'package:leon/features/onboarding/screens/onboarding_screen.dart';
import 'package:leon/services/backup_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/state/app_providers.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import '../../helpers/memory_hive_service.dart';

ProviderContainer containerFor(MemoryHiveService hive) => ProviderContainer(
  overrides: [
    hiveServiceProvider.overrideWithValue(hive),
    localDateProvider.overrideWithValue(DateTime(2026, 11, 5)),
  ],
);

class _DelayedSetupHive extends MemoryHiveService {
  Completer<void>? progressGate;

  @override
  Future<void> putSettingChecked(String key, Object? value) async {
    if (key == AppConstants.settingSetupDraft) {
      await progressGate?.future;
    }
    await super.putSettingChecked(key, value);
  }
}

void main() {
  testWidgets(
    'returning users can sign in before setup and back out without changing the draft',
    (tester) async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Already have an account? Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(router.canPop(), isTrue);
      expect(container.read(onboardingProvider).currentPage, 0);
      expect(container.read(onboardingCompleteProvider), isFalse);
      expect(hive.documents[AppConstants.hiveBoxUser], isNull);
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppConstants.routeOnboarding,
      );
      expect(container.read(onboardingCompleteProvider), isFalse);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
  test(
    'slow setup navigation cannot restore an older page or choices',
    () async {
      final hive = _DelayedSetupHive()..progressGate = Completer<void>();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final setup = container.read(onboardingProvider.notifier);
      final pending = setup.saveProgress(1);
      expect(container.read(onboardingProvider).currentPage, 1);
      setup.setPrimaryGoal('STRENGTH');
      setup.setPage(2);
      hive.progressGate!.complete();
      await pending;
      expect(container.read(onboardingProvider).currentPage, 2);
      expect(container.read(onboardingProvider).primaryGoal, 'STRENGTH');
    },
  );

  testWidgets(
    'redo opens the questions and advances before disk writes without a resume',
    (tester) async {
      final hive = _DelayedSetupHive();
      hive.settings[AppConstants.settingOnboardingComplete] = true;
      final container = containerFor(hive);
      final router = AppRouter.build(
        initialLocation: AppConstants.routeProfile,
      );
      container.read(appBootstrappedProvider.notifier).markReady();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await container.read(onboardingProvider.notifier).reset();
      router.go(AppConstants.routeOnboarding);
      await tester.pumpAndSettle();
      expect(container.read(onboardingProvider).currentPage, 1);
      expect(find.text('What moves you?'), findsOneWidget);
      expect(find.text('TAP ANYWHERE TO ENTER'), findsNothing);
      hive.progressGate = Completer<void>();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(onboardingProvider).currentPage, 2);
      expect(find.text('02 / 04'), findsOneWidget);
      hive.progressGate!.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingProvider).currentPage, 3);
      expect(find.text('03 / 04'), findsOneWidget);
      expect(find.text('YOUR PLAN'), findsNothing);
      expect(container.read(onboardingCompleteProvider), isTrue);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }
      expect(
        router.routeInformationProvider.value.uri.path,
        AppConstants.routeProfile,
      );
      expect(find.text('TAP ANYWHERE TO ENTER'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    },
  );

  test(
    'failed progress preserves edits and cannot undo newer navigation',
    () async {
      final hive = _DelayedSetupHive()..progressGate = Completer<void>();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final setup = container.read(onboardingProvider.notifier);
      final pending = setup.saveProgress(1);
      setup.setPrimaryGoal('STRENGTH');
      hive.failSettings = true;
      final failure = expectLater(pending, throwsStateError);
      hive.progressGate!.complete();
      await failure;
      expect(container.read(onboardingProvider).currentPage, 0);
      expect(container.read(onboardingProvider).primaryGoal, 'STRENGTH');
      hive.failSettings = false;
      hive.progressGate = Completer<void>();
      final older = setup.saveProgress(1);
      setup.setPage(2);
      hive.failSettings = true;
      final olderFailure = expectLater(older, throwsStateError);
      hive.progressGate!.complete();
      await olderFailure;
      expect(container.read(onboardingProvider).currentPage, 2);
    },
  );

  testWidgets('rapid opening taps cannot activate an incoming Continue', (
    tester,
  ) async {
    final container = containerFor(MemoryHiveService());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OnboardingScreen(),
        ),
      ),
    );
    final openingSpace =
        tester.getTopLeft(find.byType(Scaffold)) + const Offset(30, 35);
    await tester.tapAt(openingSpace);
    await tester.pump();
    for (var tap = 0; tap < 5; tap++) {
      await tester.tapAt(tester.getCenter(find.text('Continue')));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).currentPage, 1);
    expect(find.text('What moves you?'), findsOneWidget);
    expect(find.text('TAP ANYWHERE TO ENTER'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  test('six-page flow has four numbered questions and a plan preview', () {
    expect(OnboardingState.totalPages, 6);
    for (var page = 1; page <= 4; page++) {
      final state = OnboardingState(currentPage: page);
      expect(state.stepLabel, '0$page / 04');
      expect(state.stepProgress, page / 4);
    }
    expect(const OnboardingState(currentPage: 5).isLastPage, isTrue);
  });

  test(
    'setup draft resumes exact inputs and page without completing setup',
    () async {
      final hive = MemoryHiveService();
      final first = containerFor(hive);
      final setup = first.read(onboardingProvider.notifier);
      setup.setWeight(83.456);
      setup.setHeight(174.25);
      setup.setWeightUnit(false);
      setup.setPrimaryGoal('STRENGTH');
      setup.setTrainingDays(4);
      setup.setPreferredSplit('Upper/Lower');
      await setup.saveProgress(3);
      first.dispose();
      final resumed = containerFor(hive);
      addTearDown(resumed.dispose);
      final state = resumed.read(onboardingProvider);
      expect(state.currentPage, 3);
      expect(state.weight, 83.456);
      expect(state.height, 174.25);
      expect(state.isWeightKg, isFalse);
      expect(state.primaryGoal, 'STRENGTH');
      expect(state.preferredSplit, 'split_upper_lower');
      expect(resumed.read(onboardingCompleteProvider), isFalse);
      expect(
        BackupService.settingsKeys,
        isNot(contains(AppConstants.settingSetupDraft)),
      );
      expect(
        BackupService.settingsKeys,
        isNot(contains(AppConstants.settingAccountChoicePending)),
      );
    },
  );

  test(
    'saved setup resumes account choice; offline guest choice then resumes Home',
    () async {
      final hive = MemoryHiveService();
      final first = containerFor(hive);
      await first.read(onboardingProvider.notifier).complete();
      first.dispose();
      final resumed = containerFor(hive);
      expect(resumed.read(onboardingCompleteProvider), isTrue);
      expect(
        resumed.read(routerProvider).routeInformationProvider.value.uri.path,
        AppConstants.routeLogin,
      );
      await resumed.read(authProvider.notifier).signInAsGuest();
      resumed.dispose();
      final home = containerFor(hive);
      addTearDown(home.dispose);
      expect(
        home.read(routerProvider).routeInformationProvider.value.uri.path,
        AppConstants.routeDashboard,
      );
      expect(home.read(authProvider).status, AuthStatus.unauthenticated);
    },
  );

  test(
    'existing completed installs keep Home and a stable router during replay',
    () async {
      final hive = MemoryHiveService();
      hive.settings[AppConstants.settingOnboardingComplete] = true;
      await hive.put(
        AppConstants.hiveBoxUser,
        AppConstants.hiveKeyLocalProfile,
        const UserModel(
          id: 'existing',
          email: '',
          displayName: 'Existing lifter',
          onboardingComplete: false,
          preferredSplit: 'split_ppl',
          trainingDaysPerWeek: 5,
        ).toJson(),
      );
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppConstants.routeDashboard,
      );
      await container.read(onboardingProvider.notifier).complete();
      expect(container.read(routerProvider), same(router));
      expect(container.read(accountChoicePendingProvider), isFalse);
    },
  );

  test(
    'failed draft/profile/guest writes retain retry state and cannot skip account choice',
    () async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      addTearDown(container.dispose);
      final setup = container.read(onboardingProvider.notifier);
      setup.setTrainingDays(4);
      hive.failSettings = true;
      await expectLater(setup.saveProgress(3), throwsStateError);
      expect(container.read(onboardingProvider).currentPage, 0);
      expect(container.read(onboardingProvider).trainingDaysPerWeek, 4);
      hive.failSettings = false;
      await setup.saveProgress(3);
      hive.failDocuments = true;
      await expectLater(setup.complete(), throwsStateError);
      expect(container.read(onboardingCompleteProvider), isFalse);
      hive.failDocuments = false;
      await setup.complete();
      hive.failSettings = true;
      await expectLater(
        container.read(authProvider.notifier).signInAsGuest(),
        throwsStateError,
      );
      expect(container.read(accountChoicePendingProvider), isTrue);
      hive.failSettings = false;
      await container.read(authProvider.notifier).signInAsGuest();
      expect(container.read(accountChoicePendingProvider), isFalse);
    },
  );

  testWidgets(
    'opening goes straight to setup, then preview, account choice and guest Home',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppConstants.routeLogin,
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: AppConstants.routeDashboard,
            builder: (_, _) => const Scaffold(body: Text('Home reached')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      await tester.pumpAndSettle();
      expect(find.text('What moves you?'), findsOneWidget);
      expect(find.text('Continue as guest'), findsNothing);
      await tester.tap(find.text('Get stronger'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your starting point.'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Make room for you.'), findsOneWidget);
      await tester.tap(find.text('4 days'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your space. Your pace.'), findsOneWidget);
      await tester.tap(find.text('See my plan'));
      await tester.pumpAndSettle();
      expect(find.text('4 training days per week'), findsOneWidget);
      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your plan is ready.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      expect(find.text('Home reached'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    },
  );

  testWidgets(
    'redo setup starts with questions and retains a later custom default',
    (tester) async {
      final hive = MemoryHiveService();
      final container = containerFor(hive);
      // Initialize setup before the user creates their own routine.
      container.read(onboardingProvider);
      {
        await container
            .read(userProfileProvider.notifier)
            .load(
              const UserModel(
                id: 'linked-user',
                email: 'test@example.com',
                displayName: 'Luvya',
                onboardingComplete: true,
                preferredSplit: 'split_ppl',
                trainingDaysPerWeek: 5,
              ),
            );
        final routine = TrainingSplitModel(
          id: 'custom_luvya',
          name: 'Luvya routine',
          shortName: 'Luvya',
          plannedMuscleSets: const {},
          daysPerWeek: 5,
          description: '',
          isCustom: true,
          workouts: const [],
        );
        await container.read(splitsProvider.notifier).saveCustomSplit(routine);
        await container
            .read(splitsProvider.notifier)
            .switchActiveSplit(routine.id);
        await container.read(onboardingProvider.notifier).reset();
      }
      expect(container.read(onboardingProvider).preferredSplit, 'custom_luvya');
      expect(container.read(onboardingProvider).isCompleted, isFalse);
      expect(container.read(onboardingCompleteProvider), isTrue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const OnboardingScreen(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(20, 100));
      await tester.pumpAndSettle();
      expect(find.text('What moves you?'), findsOneWidget);
      container.read(onboardingProvider.notifier).setPage(3);
      await tester.pumpAndSettle();
      expect(find.text('Bro Split'), findsOneWidget);
      expect(find.text('Luvya routine'), findsOneWidget);
      bool customRoutineIsSelected() => tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('Luvya routine'),
              matching: find.byType(Semantics),
            ),
          )
          .any((semantics) => semantics.properties.selected == true);
      expect(customRoutineIsSelected(), isTrue);
      await tester.ensureVisible(find.text('Bro Split'));
      await tester.tap(find.text('Bro Split'));
      await tester.pumpAndSettle();
      expect(
        container.read(onboardingProvider).preferredSplit,
        'split_bro_split',
      );
      expect(customRoutineIsSelected(), isFalse);
      await tester.ensureVisible(find.text('Luvya routine'));
      await tester.tap(find.text('Luvya routine'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingProvider).preferredSplit, 'custom_luvya');
      expect(customRoutineIsSelected(), isTrue);
      expect(container.read(userProfileProvider)!.id, 'linked-user');
      expect(
        container.read(userProfileProvider)!.preferredSplit,
        'custom_luvya',
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );

  testWidgets('Skip shows a review before saving or choosing an account', (
    tester,
  ) async {
    final container = containerFor(MemoryHiveService());
    container.read(onboardingProvider.notifier).setPage(1);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Save & continue'), findsOneWidget);
    expect(container.read(onboardingCompleteProvider), isFalse);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets(
    'all setup pages keep Continue reachable at 320px, 200% text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = containerFor(MemoryHiveService());
      for (final page in [1, 2, 3, 4, 5]) {
        container.read(onboardingProvider.notifier).setPage(page);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const OnboardingScreen(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 300),
                ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = page == 5
            ? 'Save & continue'
            : page == 4
            ? 'See my plan'
            : 'Continue';
        expect(tester.getCenter(find.text(label)).dy, lessThan(544));
        expect(tester.takeException(), isNull, reason: 'Setup page $page');
        await tester.pumpWidget(const SizedBox());
      }
      container.dispose();
    },
  );
}
