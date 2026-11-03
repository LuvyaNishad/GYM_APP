import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/authentication/screens/login_screen.dart';
import 'package:leon/features/authentication/screens/signup_screen.dart';
import 'package:leon/features/dashboard/widgets/retractable_calendar_header.dart';
import 'package:leon/shared/widgets/daily_activity_chart.dart';
import 'package:leon/shared/widgets/glass_card.dart';
import 'package:leon/shared/widgets/leon_button.dart';

Future<void> mount(
  WidgetTester tester,
  Widget screen, {
  double width = 320,
  double scale = 1,
  double keyboard = 0,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pump();
}

void expectWithinViewport(
  WidgetTester tester,
  Finder control, {
  double keyboard = 0,
}) {
  final rect = tester.getRect(control);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(844 - keyboard));
}

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runAsync(() async {
      for (final family in ['Outfit', 'JetBrainsMono']) {
        final loader = FontLoader(family);
        loader.addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
        loader.addFont(rootBundle.load('assets/fonts/$family-Bold.ttf'));
        await loader.load();
      }
    });
  });

  testWidgets(
    'Login footer actions fit and remain reachable with enlarged text',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        await mount(tester, const LoginScreen(), scale: scale);
        for (final label in ['CONTINUE AS GUEST', 'GET STARTED']) {
          final control = find.text(label);
          await tester.ensureVisible(control);
          await tester.pump();
          expectWithinViewport(tester, control);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('Auth controls remain reachable above the keyboard at 2x text', (
    tester,
  ) async {
    for (final screen in [const LoginScreen(), const SignupScreen()]) {
      await mount(tester, screen, scale: 2, keyboard: 300);
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.last);
      await tester.pump();
      await tester.enterText(fields.last, 'unchanged-input-2.5');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(fields.last).controller!.text,
        'unchanged-input-2.5',
      );
      final action = find.byType(LeonButton);
      await tester.ensureVisible(action);
      await tester.pump();
      expectWithinViewport(tester, action, keyboard: 300);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Auth forms keep a centered content measure on wide layouts', (
    tester,
  ) async {
    for (final width in [768.0, 1280.0]) {
      for (final screen in [const LoginScreen(), const SignupScreen()]) {
        await mount(tester, screen, width: width);
        final rect = tester.getRect(find.byType(GlassCard));
        expect(rect.width, lessThanOrEqualTo(640));
        expect(rect.center.dx, closeTo(width / 2, .1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets(
    'Large button labels wrap and pending state keeps its label and box',
    (tester) async {
      var calls = 0;
      const label = 'Customize setup (2 min)';
      Future<void> show(bool pending) => mount(
        tester,
        Scaffold(
          body: Center(
            child: LeonButton(
              label: label,
              icon: Icons.tune_rounded,
              width: 232,
              isLoading: pending,
              onPressed: () => calls++,
            ),
          ),
        ),
        scale: 2,
      );
      await show(false);
      final idle = tester.getSize(find.byType(LeonButton));
      expect(idle.height, greaterThan(52));
      final text = tester.widget<Text>(find.text(label.toUpperCase()));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(tester.takeException(), isNull);
      await show(true);
      expect(tester.getSize(find.byType(LeonButton)), idle);
      expect(find.text(label.toUpperCase()), findsOneWidget);
      await tester.tap(find.byType(LeonButton));
      await tester.pump();
      expect(calls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Chosen long name wraps without removing calendar actions', (
    tester,
  ) async {
    const name = 'Alexandra Morgan Rodriguez';
    await mount(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: RetractableCalendarHeader(
            userName: name,
            selectedDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      ),
      scale: 2,
    );
    final greeting = tester.widget<Text>(find.text('Hi, $name'));
    expect(greeting.maxLines, isNull);
    expect(greeting.overflow, isNull);
    expect(find.byTooltip('Choose date'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    final chooseDate = tester.getSize(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Choose date',
      ),
    );
    final today = tester.getSize(
      find
          .ancestor(of: find.text('TODAY'), matching: find.byType(InkWell))
          .first,
    );
    for (final size in [chooseDate, today]) {
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.getSize(find.text('Hi, $name')).width,
      greaterThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Pending button without an icon keeps intrinsic size and label position',
    (tester) async {
      Future<void> show(bool pending) => mount(
        tester,
        Scaffold(
          body: Center(
            child: LeonButton(
              label: 'Save setup',
              isLoading: pending,
              onPressed: () {},
            ),
          ),
        ),
        scale: 2,
      );
      await show(false);
      final idleSize = tester.getSize(find.byType(LeonButton));
      final idleLabel = tester.getRect(find.text('SAVE SETUP'));
      await show(true);
      expect(tester.getSize(find.byType(LeonButton)), idleSize);
      expect(tester.getRect(find.text('SAVE SETUP')), idleLabel);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Selected chart follows the theme when its primary changes', (
    tester,
  ) async {
    const key = ValueKey('theme-chart');
    Future<void> show(Color accent) => mount(
      tester,
      Scaffold(
        body: DailyActivityChart(
          values: const [1, 2, 3],
          selected: 1,
          onSelected: (_) {},
          paintKey: key,
        ),
      ),
      theme: AppTheme.dark.copyWith(
        colorScheme: AppTheme.dark.colorScheme.copyWith(primary: accent),
      ),
    );
    await show(AppColors.primary);
    final chartElement = tester.element(find.byType(DailyActivityChart));
    final initialPainter =
        tester.widget<CustomPaint>(find.byKey(key)).painter!
            as ActivityBarPainter;
    expect(initialPainter.accent, AppColors.primary);
    await show(AppColors.amber);
    // MaterialApp interpolates theme changes outside the fixture's inner
    // reduced-motion MediaQuery. Finish that transition before asserting the
    // target theme, while retaining the existing chart and reveal controller.
    await tester.pump(kThemeAnimationDuration);
    await tester.pump();
    final painter =
        tester.widget<CustomPaint>(find.byKey(key)).painter!
            as ActivityBarPainter;
    expect(tester.element(find.byType(DailyActivityChart)), same(chartElement));
    expect(painter.reveal, same(initialPainter.reveal));
    expect(painter.accent, AppColors.amber);
    expect(painter.shouldRepaint(initialPainter), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Outlined button changes its material on first pointer frame and cancels',
    (tester) async {
      var calls = 0;
      await mount(
        tester,
        Scaffold(
          body: Center(
            child: LeonButton(
              label: 'Continue as guest',
              icon: Icons.person_outline,
              width: 260,
              isOutlined: true,
              onPressed: () => calls++,
            ),
          ),
        ),
      );
      final material = find
          .descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(Material),
          )
          .first;
      final restColor = tester.widget<Material>(material).color;
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(LeonButton)),
      );
      await tester.pump();
      expect(tester.widget<Material>(material).color, isNot(restColor));
      expect(calls, 0);
      await finger.cancel();
      await tester.pump();
      expect(tester.widget<Material>(material).color, restColor);
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
