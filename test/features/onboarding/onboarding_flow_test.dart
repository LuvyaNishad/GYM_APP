import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';
import 'package:leon/features/onboarding/screens/onboarding_screen.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/shared/widgets/leon_button.dart';

class FakeHiveService extends HiveService {
  final Map<String, dynamic> settings = {};
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) async {
    documents.putIfAbsent(boxName, () => {})[key] = json;
  }

  @override
  Future<void> putSetting(String key, Object? value) async {
    settings[key] = value;
  }

  @override
  T? getSetting<T>(String key, {T? fallback}) {
    return (settings[key] as T?) ?? fallback;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingState 7-Screen Architecture Tests', () {
    test('Verifies totalPages, stepProgress, and stepLabel mapping across 4 survey steps', () {
      const state0 = OnboardingState(currentPage: 0);
      expect(OnboardingState.totalPages, equals(7));
      expect(state0.stepProgress, equals(0.0));
      expect(state0.stepLabel, equals(''));

      const state1 = OnboardingState(currentPage: 1);
      expect(state1.stepProgress, equals(0.0));
      expect(state1.stepLabel, equals(''));

      const state2 = OnboardingState(currentPage: 2);
      expect(state2.stepProgress, closeTo(1 / 4, 0.01));
      expect(state2.stepLabel, equals('01 / 04'));

      const state3 = OnboardingState(currentPage: 3);
      expect(state3.stepProgress, closeTo(2 / 4, 0.01));
      expect(state3.stepLabel, equals('02 / 04'));

      const state4 = OnboardingState(currentPage: 4);
      expect(state4.stepProgress, closeTo(3 / 4, 0.01));
      expect(state4.stepLabel, equals('03 / 04'));

      const state5 = OnboardingState(currentPage: 5);
      expect(state5.stepProgress, equals(1.0));
      expect(state5.stepLabel, equals('04 / 04'));

      const state6 = OnboardingState(currentPage: 6);
      expect(state6.stepProgress, equals(1.0));
      expect(state6.stepLabel, equals(''));
      expect(state6.isLastPage, isTrue);
    });
  });

  group('OnboardingScreen Widget Flow Tests', () {
    testWidgets(
      'Walks through expanded 4-step survey (7-screen total) and verifies all HIG elements',
      timeout: const Timeout(Duration(seconds: 45)),
      (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeHive = FakeHiveService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(fakeHive),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Screen 0: Splash
      expect(find.text('L E O N'), findsOneWidget);
      expect(find.text('PREMIUM FITNESS OS'), findsOneWidget);
      expect(find.text('TAP ANYWHERE TO ENTER'), findsOneWidget);

      // Tap to go to Welcome
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 1: Welcome
      expect(find.text('WELCOME TO LEON'), findsOneWidget);
      expect(find.text('CUSTOMIZE SETUP (2 MIN)'), findsOneWidget);
      expect(
          find.text('CONTINUE AS GUEST'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);

      // Verify both buttons use LeonButton with matching heights (52.0)
      final buttons = tester.widgetList<LeonButton>(find.byType(LeonButton)).toList();
      expect(buttons.length, greaterThanOrEqualTo(2));
      expect(buttons[0].height, equals(52.0));
      expect(buttons[1].height, equals(52.0));
      expect(buttons[1].isOutlined, isTrue);

      // Tap "CUSTOMIZE SETUP (2 MIN)" to go to Step 1 (01 / 04)
      await tester.tap(find.text('CUSTOMIZE SETUP (2 MIN)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 2: Step 01 / 04 (Goal & Experience)
      expect(find.text('01 / 04'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('GOAL & EXPERIENCE'), findsOneWidget);
      expect(find.text('PRIMARY TRAINING GOAL'), findsOneWidget);
      expect(find.text('EXPERIENCE TIER'), findsOneWidget);
      expect(find.text('BUILD MUSCLE'), findsOneWidget);
      expect(find.text('STRENGTH'), findsOneWidget);
      expect(find.text('LOSE FAT'), findsOneWidget);
      expect(find.text('ATHLETIC'), findsOneWidget);
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.text('INTERMEDIATE'), findsOneWidget);
      expect(find.text('ADVANCED'), findsOneWidget);

      // Verify selecting STRENGTH works smoothly
      await tester.tap(find.text('STRENGTH'));
      await tester.pump();

      // Tap "CONTINUE" to go to Step 2 (02 / 04)
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 3: Step 02 / 04 (Biometrics)
      expect(find.text('02 / 04'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('BODY BIOMETRICS'), findsOneWidget);
      expect(find.text('METRIC (KG / CM)'), findsOneWidget);
      expect(find.text('IMPERIAL (LBS / IN)'), findsOneWidget);
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('CURRENT WEIGHT'), findsOneWidget);
      expect(find.text('TARGET GOAL WEIGHT'), findsOneWidget);

      // Tap "CONTINUE" to go to Step 3 (03 / 04)
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 4: Step 03 / 04 (Split & Schedule)
      expect(find.text('03 / 04'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('SPLIT & SCHEDULE'), findsOneWidget);
      expect(find.text('DAYS PER WEEK'), findsOneWidget);
      expect(find.text('TRAINING SPLIT'), findsOneWidget);
      expect(find.text('PUSH / PULL / LEGS'), findsOneWidget);

      // Tap "CONTINUE" to go to Step 4 (04 / 04)
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 5: Step 04 / 04 (Injuries & Equipment)
      expect(find.text('04 / 04'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('INJURIES & EQUIPMENT'), findsOneWidget);
      expect(find.text('AREAS TO PROTECT (INJURIES / RESTRICTIONS)'), findsOneWidget);
      expect(find.text('ALL CLEAR / NONE'), findsOneWidget);
      expect(find.text('AVAILABLE EQUIPMENT'), findsOneWidget);
      expect(find.text('Full Gym'), findsOneWidget);

      // Tap "FINALIZE SETUP" to go to Ready screen
      await tester.tap(find.text('FINALIZE SETUP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen 6: Ready
      expect(find.text('WORKOUT PLAN READY'), findsOneWidget);
      expect(find.text('START WORKOUT'), findsOneWidget);
      expect(find.textContaining('DAYS / WK'), findsOneWidget);
    });

    testWidgets('Guest Bypass button on Welcome Screen has identical geometry and styling',
        timeout: const Timeout(Duration(seconds: 45)),
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeHive = FakeHiveService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(fakeHive),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Tap splash to reach welcome
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify guest button
      final guestButton = find.text('CONTINUE AS GUEST');
      expect(guestButton, findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      // Verify buttons have matched 52px height
      final leonButtons = tester.widgetList<LeonButton>(find.byType(LeonButton)).toList();
      expect(leonButtons.length, 2);
      expect(leonButtons[0].height, equals(leonButtons[1].height));
      expect(leonButtons[0].height, equals(52.0));
      expect(leonButtons[1].isOutlined, isTrue);
    });

    testWidgets('Skip button on survey steps immediately finalizes onboarding',
        timeout: const Timeout(Duration(seconds: 45)),
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeHive = FakeHiveService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(fakeHive),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Enter Welcome
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Go to Step 1
      await tester.tap(find.text('CUSTOMIZE SETUP (2 MIN)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap SKIP
      expect(find.text('SKIP'), findsOneWidget);
      await tester.tap(find.text('SKIP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should complete onboarding in fake Hive and state
      expect(fakeHive.getSetting<bool>(AppConstants.settingOnboardingComplete), isTrue);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(OnboardingScreen)))
            .read(onboardingCompleteProvider),
        isTrue,
      );
    });
  });
}
