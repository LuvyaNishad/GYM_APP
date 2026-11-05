import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/features/authentication/screens/login_screen.dart';
import 'package:leon/features/authentication/screens/signup_screen.dart';
import 'package:leon/features/authentication/widgets/weight_plate_art.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

Future<void> mount(
  WidgetTester tester,
  Widget screen, {
  double width = 390,
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(MemoryHiveService()),
        localDateProvider.overrideWithValue(DateTime(2026, 11, 5)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('account choice opens a focused email form and validates input', (
    tester,
  ) async {
    await mount(tester, const LoginScreen());
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tapVisible(tester, 'Continue with email');
    expect(find.text('Welcome back.'), findsOneWidget);
    await tapVisible(tester, 'Log in');
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('email input survives back to account choice and reentry', (
    tester,
  ) async {
    await mount(tester, const LoginScreen());
    await tapVisible(tester, 'Continue with email');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'alex@example.com',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    await tapVisible(tester, 'Continue with email');
    expect(find.text('alex@example.com'), findsOneWidget);
  });

  testWidgets(
    'registration keeps confirmation and mismatched-password feedback',
    (tester) async {
      await mount(tester, const SignupScreen());
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Alex',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'alex@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'mismatch456',
      );
      await tapVisible(tester, 'Create account');
      expect(find.text('Passwords do not match.'), findsOneWidget);
    },
  );

  for (final signup in [false, true]) {
    testWidgets(
      '${signup ? 'Registration' : 'Login'} fits 320px, 200% text and keyboard with reachable actions',
      (tester) async {
        await mount(
          tester,
          signup ? const SignupScreen() : const LoginScreen(),
          width: 320,
          scale: 2,
          keyboard: 300,
        );
        if (!signup) await tapVisible(tester, 'Continue with email');
        expect(find.byType(WeightPlateArt), findsNothing);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email address'),
          'alex@example.com',
        );
        await tapVisible(tester, signup ? 'Create account' : 'Log in');
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.text(signup ? 'Create account' : 'Log in'),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.text(signup ? 'Create account' : 'Log in')).dy,
          lessThan(544),
        );
        await tester.ensureVisible(find.text('Continue as guest'));
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.text('Continue as guest')).dy,
          lessThan(544),
        );
      },
    );
  }

  testWidgets(
    'artwork stops for reduced motion, hidden subtree and background',
    (tester) async {
      Future<void> art({bool reduced = false, bool enabled = true}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: TickerMode(
                enabled: enabled,
                child: const SizedBox(
                  width: 400,
                  height: 310,
                  child: WeightPlateArt(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await art();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await art(reduced: true);
      expect(tester.binding.transientCallbackCount, 0);
      await art(enabled: false);
      expect(tester.binding.transientCallbackCount, 0);
      await art();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('auth starts unauthenticated without a configured session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
  });
}
