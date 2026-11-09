import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  bool reducedMotion = true,
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
            disableAnimations: reducedMotion,
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  if (reducedMotion) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('email morph eases smoothly and reuses the artwork paint layer', (
    tester,
  ) async {
    await mount(tester, const LoginScreen(), reducedMotion: false);
    final art = find.byType(WeightPlateArt);
    final artState = tester.state(art);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: art, matching: find.byType(RepaintBoundary)),
    );
    double height() =>
        tester.getSize(find.byKey(const ValueKey('login-art-space'))).height;
    double scale() => tester
        .widget<Transform>(find.byKey(const ValueKey('login-art-scale')))
        .transform
        .storage[0];
    expect(height(), 290);
    expect(boundary.size, const Size(400, 310));
    await tester.tap(find.text('Continue with email'));
    await tester.pump();
    final picture = (boundary.debugLayer!.firstChild as PictureLayer).picture;
    var previousHeight = height();
    var previousScale = scale();
    final samples = <double>[];
    for (var frame = 0; frame < 38; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final currentHeight = height();
      expect(currentHeight, lessThanOrEqualTo(previousHeight));
      expect(scale(), lessThanOrEqualTo(previousScale));
      if (frame == 0) expect(scale(), lessThan(previousScale));
      samples.add(previousHeight - currentHeight);
      expect(boundary.size, const Size(400, 310));
      expect(tester.state(art), same(artState));
      expect(
        (boundary.debugLayer!.firstChild as PictureLayer).picture,
        same(picture),
        reason: 'Scaling must reuse the existing plate drawing.',
      );
      previousHeight = currentHeight;
      previousScale = scale();
    }
    expect(height(), 105);
    expect(samples.first, lessThan(samples[18]));
    expect(samples.last, lessThan(samples[18]));
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Make every rep count.'), findsNothing);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reversing mid-morph keeps size continuous and form input intact',
    (tester) async {
      await mount(tester, const LoginScreen(), reducedMotion: false);
      double height() =>
          tester.getSize(find.byKey(const ValueKey('login-art-space'))).height;
      await tester.tap(find.text('Continue with email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      final beforeReverse = height();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(height(), closeTo(beforeReverse, .001));
      await tester.pump(const Duration(milliseconds: 80));
      expect(height(), greaterThan(beforeReverse));
      final beforeReentry = height();
      await tester.tap(find.text('Continue with email'));
      await tester.pump();
      expect(height(), closeTo(beforeReentry, .001));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'alex@example.com',
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Continue with email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
