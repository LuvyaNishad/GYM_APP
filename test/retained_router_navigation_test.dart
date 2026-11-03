import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';
import 'package:leon/shared/widgets/retained_swipe_tabs.dart';
import 'package:leon/state/app_providers.dart';

class _EditablePage extends StatefulWidget {
  const _EditablePage(this.path);
  final String path;
  @override
  State<_EditablePage> createState() => _EditablePageState();
}

class _EditablePageState extends State<_EditablePage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      key: ValueKey('scroll-${widget.path}'),
      controller: scroll,
      children: [
        TextField(key: ValueKey('input-${widget.path}'), controller: input),
        const SizedBox(height: 2000),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'GoRouter retains branch input, scroll and nested route across taps and swipes',
    (tester) async {
      final router = GoRouter(
        routes: [
          StatefulShellRoute(
            builder: (context, state, shell) =>
                AppShell.navigation(navigationShell: shell),
            navigatorContainerBuilder: (context, shell, children) => Consumer(
              builder: (context, ref, child) => RetainedSwipeTabs(
                currentIndex: shell.currentIndex,
                selectionSignal: TabSelectionIntent.maybeOf(context),
                children: children,
                onSelected: (index) {
                  ref.read(bottomNavIndexProvider.notifier).select(index);
                  shell.goBranch(index);
                },
              ),
            ),
            branches: [
              for (final tab in kNavPillTabs)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: tab.route,
                      builder: (context, state) => _EditablePage(tab.route),
                      routes: [
                        if (tab.route == '/profile')
                          GoRoute(
                            path: 'details',
                            builder: (context, state) =>
                                const Scaffold(body: Text('Profile details')),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();
      await tester.tap(find.text('Account').last);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('input-/profile')),
        'Retained profile input',
      );
      tester
          .widget<ListView>(find.byKey(const ValueKey('scroll-/profile')))
          .controller!
          .jumpTo(200);
      await tester.pump();
      await tester.tap(find.text('Home').last);
      await tester.pump();
      await tester.tap(find.text('Account').last);
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(
        tester
            .widget<RetainedSwipeTabs>(find.byType(RetainedSwipeTabs))
            .currentIndex,
        4,
      );
      final restoredScroll = tester
          .widget<ListView>(find.byKey(const ValueKey('scroll-/profile')))
          .controller!;
      expect(restoredScroll.offset, 200);
      restoredScroll.jumpTo(0);
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('input-/profile')),
      );
      expect(field.controller!.text, 'Retained profile input');
      router.go('/profile/details');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pump();
      await tester.tap(find.text('Account').last);
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/profile/details',
      );
      expect(find.text('Profile details'), findsOneWidget);
      final finger = await tester.startGesture(const Offset(300, 300));
      await finger.moveBy(const Offset(25, 0));
      await finger.moveBy(const Offset(300, 0));
      await tester.pump(const Duration(milliseconds: 200));
      await finger.up();
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/analytics');
      await tester.tap(find.text('History').last);
      await tester.pump();
      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('retained-tab-offset-3')),
      );
      expect(transform.transform.getTranslation().x, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
}
