import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/providers/auth_link_provider.dart';
import 'package:leon/features/authentication/screens/auth_email_screen.dart';
import 'package:leon/features/authentication/screens/login_screen.dart';
import 'package:leon/features/authentication/screens/password_reset_screen.dart';
import 'package:leon/services/auth_link_service.dart';
import 'package:leon/services/auth_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../helpers/memory_hive_service.dart';
import 'auth_session_test.dart' show FakeAuth;

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'forgot and resend forms preserve the login email without requiring a password',
    (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(MemoryHiveService()),
            authServiceProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Continue with email');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'lifter@example.invalid',
      );
      await tapText(tester, 'Forgot password?');
      expect(find.text('lifter@example.invalid'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      await tapText(tester, 'Send reset link');
      expect(auth.calls, 1);
      expect(find.textContaining('If this email'), findsOneWidget);
      await tapText(tester, 'Back to sign in');
      expect(find.text('lifter@example.invalid'), findsOneWidget);
      await tapText(tester, 'Resend confirmation email');
      expect(find.text('lifter@example.invalid'), findsOneWidget);
      expect(find.text('Confirm your email'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
    },
  );

  for (final confirmation in [false, true]) {
    testWidgets(
      '${confirmation ? 'Confirmation' : 'Reset email'} fits 320px/200% text/keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hiveServiceProvider.overrideWithValue(MemoryHiveService()),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 300),
                ),
                child: child!,
              ),
              home: AuthEmailScreen(confirmation: confirmation),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = confirmation
            ? 'Send confirmation email'
            : 'Send reset link';
        await tapText(tester, label);
        expect(find.text('Enter a valid email address.'), findsOneWidget);
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.getCenter(find.text(label)).dy, lessThan(544));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'cold recovery takes priority over restored Home and keeps keyboard actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final links = AuthLinkService(
        readRecoveryOwner: () => null,
        writeRecoveryOwner: (_) async {},
      );
      links.handleAuthState(
        sb.AuthState(
          sb.AuthChangeEvent.passwordRecovery,
          sb.Session(
            accessToken: 'synthetic',
            tokenType: 'bearer',
            user: FakeAuth().user,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [authLinkServiceProvider.overrideWithValue(links)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 844),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: const AuthLinkGate(
              child: MaterialApp(home: Scaffold(body: Text('Restored Home'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Restored Home'), findsNothing);
      expect(find.text('Set a new password.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'new-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'different',
      );
      await tapText(tester, 'Update password');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.ensureVisible(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await links.dispose();
    },
  );
}
