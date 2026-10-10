import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';
import 'package:leon/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('LEON Onboarding Screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingCompleteProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OnboardingScreen(),
        ),
      ),
    );

    // Initial page is Splash (Screen 01)
    expect(find.text('L E O N'), findsOneWidget);
    expect(find.text('PREMIUM FITNESS OS'), findsOneWidget);
  });
}
