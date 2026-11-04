import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/features/authentication/screens/login_screen.dart';
import 'package:leon/features/authentication/screens/signup_screen.dart';

void main() {
  group('Authentication Flow & UI Tests', () {
    testWidgets('LoginScreen renders email/password fields and buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );

      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('CONTINUE AS GUEST'), findsOneWidget);
      expect(find.text("Don't have an account? Create Account"), findsOneWidget);
    });

    testWidgets('LoginScreen validates empty input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );

      // Tap SIGN IN without typing anything
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('SignupScreen renders name, email and password confirmation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const SignupScreen(),
          ),
        ),
      );

      expect(find.text('NEW ATHLETE'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('SignupScreen validates mismatched passwords', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const SignupScreen(),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Display Name'), 'Alex Hunter');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'alex@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password (min 6 characters)'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'mismatch456');

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    test('AuthNotifier state defaults to unauthenticated in test environment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authState = container.read(authProvider);
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.userId, isNull);
      expect(authState.isLoading, isFalse);
    });
  });
}
