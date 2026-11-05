import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';
import 'package:leon/features/onboarding/screens/onboarding_screen.dart';
import 'package:leon/services/hive_service.dart';

class _FakeHiveService extends HiveService {
  @override
  T? getSetting<T>(String key, {T? fallback}) => fallback;
}

void main() {
  testWidgets('AEON Onboarding Screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(_FakeHiveService()),
          onboardingCompleteProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Initial page is Splash (Screen 01)
    expect(find.text('A E O N'), findsOneWidget);
    expect(find.text('PREMIUM FITNESS OS'), findsOneWidget);
  });
}
