import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';
import 'package:leon/shared/widgets/retained_swipe_tabs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShell Navigation & Layout Tests', () {
    testWidgets('AppShell retains five branches and floating navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AppShell(location: '/dashboard')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final indexedStackFinder = find.byType(RetainedSwipeTabs);
      expect(indexedStackFinder, findsOneWidget);

      final indexedStack = tester.widget<RetainedSwipeTabs>(indexedStackFinder);
      expect(indexedStack.currentIndex, 0);
      expect(indexedStack.children.length, 5);

      // GlassNavPill is present
      expect(find.byType(GlassNavPill), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Tapping a nav tab selects the branch on the next frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AppShell(location: '/')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initial tab is 0
      var indexedStack = tester.widget<RetainedSwipeTabs>(
        find.byType(RetainedSwipeTabs),
      );
      expect(indexedStack.currentIndex, 0);

      // Tap on 'Exercises' tab in the nav pill
      final exercisesTab = find.text('Exercises');
      expect(exercisesTab, findsOneWidget);

      await tester.tap(exercisesTab);
      await tester.pump();

      indexedStack = tester.widget<RetainedSwipeTabs>(
        find.byType(RetainedSwipeTabs),
      );
      expect(indexedStack.currentIndex, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'Tapping Workouts and Account tabs updates active index cleanly',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: AppShell(location: '/')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Tap Workouts
        await tester.tap(find.text('Workouts'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        var indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 1);

        // Tap Account
        await tester.tap(find.text('Account'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 4);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'Horizontal swipe gestures navigate forward and backward between tabs',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: AppShell(location: '/')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        var indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 0);

        // Fling left (right-to-left) to advance from Home (0) to Workouts (1)
        await tester.fling(
          find.byType(RetainedSwipeTabs),
          const Offset(-400, 0),
          1000.0,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 1);
        // Fling left again to advance from Workouts (1) to Exercises (2)
        await tester.fling(
          find.byType(RetainedSwipeTabs),
          const Offset(-400, 0),
          1000.0,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 2);

        // Fling right (left-to-right) to go back from Exercises (2) to Workouts (1)
        await tester.fling(
          find.byType(RetainedSwipeTabs),
          const Offset(400, 0),
          1000.0,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        indexedStack = tester.widget<RetainedSwipeTabs>(
          find.byType(RetainedSwipeTabs),
        );
        expect(indexedStack.currentIndex, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'AppShell.bottomPadding computes total clearance with safe area',
      (tester) async {
        double? computedPadding;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(bottom: 34.0),
              ),
              child: Builder(
                builder: (context) {
                  computedPadding = AppShell.bottomPadding(
                    context,
                    extra: 24.0,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        // reservedBottomSpace (102.0) + bottomInset (34.0) + extra (24.0) = 160.0
        expect(computedPadding, equals(160.0));
      },
    );
  });

  testWidgets('navigation semantics expose one tap action per labelled tab', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var selections = 0;
      var selected = -1;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlassNavPill(
                activeIndex: 0,
                onTabSelected: (index) {
                  selections++;
                  selected = index;
                },
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < kNavPillTabs.length; i++) {
        final node = tester.getSemantics(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == kNavPillTabs[i].label,
          ),
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.semantics.performAction(
          find.semantics.byLabel(kNavPillTabs[i].label),
          SemanticsAction.tap,
        );
        expect(selected, i);
        expect(selections, i + 1);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('large-text navigation wraps at 320 without shrinking labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    double? expectedHeight;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  expectedHeight = GlassNavPill.heightFor(context);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GlassNavPill(activeIndex: 0, onTabSelected: (_) {}),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(GlassNavPill)).height, expectedHeight);
    final pill = tester.getRect(find.byType(GlassNavPill));
    for (final tab in kNavPillTabs) {
      final text = tester.widget<Text>(find.text(tab.label));
      expect(text.style!.fontSize, 11);
      final rect = tester.getRect(find.text(tab.label));
      expect(pill.contains(rect.topLeft), isTrue);
      expect(pill.contains(rect.bottomRight - const Offset(.1, .1)), isTrue);
    }
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('keyboard focus activates nav once for Enter and Space', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GlassNavPill(activeIndex: 0, onTabSelected: selected.add),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, [0]);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(selected, [0, 1]);
  });
}
