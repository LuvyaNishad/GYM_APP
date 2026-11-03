import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/shared/widgets/deferred_tab.dart';
import 'package:leon/shared/widgets/immediate_press_feedback.dart';
import 'package:leon/shared/widgets/retained_swipe_tabs.dart';

class _Host extends StatefulWidget {
  const _Host({required this.pages, this.reduced = false, super.key});
  final List<Widget> pages;
  final bool reduced;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;
  final signal = ValueNotifier<int>(0);
  final selections = <int>[];

  void select(int value) => setState(() {
    index = value;
    selections.add(value);
  });

  void tapTab(int value) {
    signal.value++;
    if (value != index) select(value);
  }

  @override
  void dispose() {
    signal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: widget.reduced),
      child: Scaffold(
        body: RetainedSwipeTabs(
          currentIndex: index,
          selectionSignal: signal,
          onSelected: select,
          children: widget.pages,
        ),
      ),
    ),
  );
}

class _AnimatedPage extends StatefulWidget {
  const _AnimatedPage({super.key});

  @override
  State<_AnimatedPage> createState() => _AnimatedPageState();
}

class _AnimatedPageState extends State<_AnimatedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.black,
    child: Center(child: Text('Animated page')),
  );
}

List<Widget> pages({Widget? second}) => [
  const ColoredBox(
    color: Colors.black,
    child: Center(child: Text('First')),
  ),
  second ??
      const ColoredBox(
        color: Colors.black,
        child: Center(child: Text('Second')),
      ),
  const ColoredBox(
    color: Colors.black,
    child: Center(child: Text('Third')),
  ),
];

double translation(WidgetTester tester, int index) => tester
    .widget<Transform>(
      find.byKey(ValueKey('retained-tab-offset-$index'), skipOffstage: false),
    )
    .transform
    .getTranslation()
    .x;

Future<TestGesture> heldDrag(WidgetTester tester, Offset delta) async {
  final finger = await tester.startGesture(const Offset(300, 300));
  await finger.moveBy(const Offset(-25, 0));
  await tester.pump();
  await finger.moveBy(delta);
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

void main() {
  testWidgets(
    'drag follows pointer, reverses, and cancellation retains route',
    (tester) async {
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(_Host(key: key, pages: pages()));
      final finger = await heldDrag(tester, const Offset(-150, 0));
      final before = translation(tester, 0);
      expect(before, lessThan(0));
      expect(key.currentState!.index, 0);
      await finger.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(translation(tester, 0), greaterThan(before));
      await finger.cancel();
      await tester.pumpAndSettle();
      expect(key.currentState!.index, 0);
      expect(translation(tester, 0), 0);
      expect(key.currentState!.selections, isEmpty);
    },
  );

  testWidgets(
    'release commits immediately and a same-tab tap interrupts settle',
    (tester) async {
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(_Host(key: key, pages: pages()));
      final finger = await heldDrag(tester, const Offset(-300, 0));
      await finger.up();
      await tester.pump();
      expect(key.currentState!.index, 1);
      expect(translation(tester, 1), greaterThan(0));
      key.currentState!.tapTab(1);
      await tester.pump();
      expect(key.currentState!.index, 1);
      expect(translation(tester, 1), 0);
      await tester.pumpAndSettle();
      expect(key.currentState!.selections, [1]);
    },
  );

  testWidgets(
    'new drag during committed settle rebases and cancels to committed route',
    (tester) async {
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(_Host(key: key, pages: pages()));
      final finger = await heldDrag(tester, const Offset(-300, 0));
      await finger.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(key.currentState!.index, 1);
      final before = translation(tester, 1);
      final second = await tester.startGesture(const Offset(300, 300));
      expect(translation(tester, 1), closeTo(before, 1));
      await second.moveBy(const Offset(-25, 0));
      await tester.pump();
      expect(translation(tester, 1), closeTo(before - 25, 1));
      await second.moveBy(const Offset(-20, 0));
      await tester.pump();
      expect(translation(tester, 1), closeTo(before - 45, 1));
      await second.cancel();
      await tester.pumpAndSettle();
      expect(key.currentState!.index, 1);
      expect(translation(tester, 1), 0);
      expect(key.currentState!.selections, [1]);
    },
  );

  testWidgets(
    'tap interruption prevents the original pointer leaving a stuck offset',
    (tester) async {
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(_Host(key: key, pages: pages()));
      final finger = await heldDrag(tester, const Offset(-150, 0));
      key.currentState!.tapTab(2);
      await tester.pump();
      expect(translation(tester, 2), 0);
      await finger.moveBy(const Offset(-50, 0));
      await tester.pump();
      await finger.up();
      await tester.pumpAndSettle();
      expect(key.currentState!.index, 2);
      expect(translation(tester, 2), 0);
      expect(key.currentState!.selections, [2]);
    },
  );

  testWidgets(
    'nested horizontal control can win during settle without reverting route',
    (tester) async {
      var childDrags = 0;
      final secondPage = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (_) => childDrags++,
        child: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Chart')),
        ),
      );
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(
        _Host(
          key: key,
          pages: pages(second: secondPage),
        ),
      );
      final finger = await heldDrag(tester, const Offset(-300, 0));
      await finger.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final nested = await tester.startGesture(const Offset(500, 300));
      await nested.moveBy(const Offset(-25, 0));
      await nested.moveBy(const Offset(-80, 0));
      await nested.up();
      await tester.pumpAndSettle();
      expect(childDrags, greaterThan(0));
      expect(key.currentState!.index, 1);
      expect(key.currentState!.selections, [1]);
    },
  );

  testWidgets('vertical and nested horizontal scrolling do not select a tab', (
    tester,
  ) async {
    final scroll = ScrollController();
    final horizontal = ScrollController();
    addTearDown(scroll.dispose);
    addTearDown(horizontal.dispose);
    final key = GlobalKey<_HostState>();
    await tester.pumpWidget(
      _Host(
        key: key,
        pages: [
          ListView(
            controller: scroll,
            children: [
              SizedBox(
                height: 160,
                child: ListView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    SizedBox(width: 2000, child: Text('Horizontal list')),
                  ],
                ),
              ),
              const SizedBox(height: 2000),
            ],
          ),
          const Text('Second'),
        ],
      ),
    );
    await tester.dragFrom(const Offset(300, 80), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(horizontal.offset, greaterThan(0));
    expect(key.currentState!.index, 0);
    await tester.dragFrom(const Offset(300, 350), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(key.currentState!.selections, isEmpty);
  });

  testWidgets(
    'offscreen warmup waits through active tickers and loads after they stop',
    (tester) async {
      var builds = 0;
      final busy = GlobalKey<_AnimatedPageState>();
      await tester.pumpWidget(
        _Host(
          pages: [
            _AnimatedPage(key: busy),
            DeferredTab(
              index: 1,
              child: Builder(
                builder: (_) {
                  builds++;
                  return const Text('Warmed page');
                },
              ),
            ),
          ],
        ),
      );
      // This crosses the staggered timer while a repeating ticker is active.
      // It must let the pending frame advance instead of retrying at time zero.
      await tester.pump(const Duration(seconds: 2));
      expect(builds, 0);
      busy.currentState!.animation.stop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(builds, 1);
      expect(find.text('Warmed page', skipOffstage: false), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'visible neighbor warms without rebuilding screen on each pixel',
    (tester) async {
      final builds = [0, 0, 0];
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(
        _Host(
          key: key,
          pages: [
            for (var i = 0; i < 3; i++)
              DeferredTab(
                index: i,
                child: Builder(
                  builder: (context) {
                    builds[i]++;
                    return Text('Page $i');
                  },
                ),
              ),
          ],
        ),
      );
      expect(builds, [1, 0, 0]);
      final finger = await tester.startGesture(const Offset(300, 300));
      await finger.moveBy(const Offset(-25, 0));
      await finger.moveBy(const Offset(-50, 0));
      await tester.pump();
      expect(builds[1], 1);
      expect(builds[2], 0);
      final warmed = List<int>.of(builds);
      await finger.moveBy(const Offset(-10, 0));
      await tester.pump();
      await finger.moveBy(const Offset(-10, 0));
      await tester.pump();
      expect(builds, warmed);
      await finger.cancel();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'text input and scroll survive branch changes; reduced motion settles immediately',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final key = GlobalKey<_HostState>();
      await tester.pumpWidget(
        _Host(
          key: key,
          reduced: true,
          pages: [
            ListView(
              controller: scroll,
              children: [
                TextField(controller: controller),
                const SizedBox(height: 2000),
              ],
            ),
            const Text('Second'),
          ],
        ),
      );
      await tester.enterText(find.byType(TextField), 'Retained input');
      scroll.jumpTo(200);
      await tester.pump();
      key.currentState!.tapTab(1);
      await tester.pump();
      key.currentState!.tapTab(0);
      await tester.pump();
      expect(controller.text, 'Retained input');
      expect(scroll.offset, 200);
      final finger = await heldDrag(tester, const Offset(-300, 0));
      await finger.up();
      await tester.pump();
      expect(key.currentState!.index, 1);
      expect(translation(tester, 1), 0);
    },
  );

  testWidgets(
    'raw pressed state precedes native tap and clears on cancellation',
    (tester) async {
      late WidgetStatesController states;
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImmediatePressFeedback(
              builder: (context, controller) {
                states = controller;
                return ElevatedButton(
                  statesController: controller,
                  onPressed: () => taps++,
                  child: const Text('Action'),
                );
              },
            ),
          ),
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(ElevatedButton)),
      );
      expect(states.value, contains(WidgetState.pressed));
      expect(taps, 0);
      await finger.cancel();
      await tester.pump();
      expect(states.value, isNot(contains(WidgetState.pressed)));
      expect(taps, 0);
      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 1);
      expect(states.value, isNot(contains(WidgetState.pressed)));
    },
  );

  testWidgets('resize interruption ignores updates from the old pointer', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    final key = GlobalKey<_HostState>();
    await tester.pumpWidget(_Host(key: key, pages: pages()));
    final finger = await heldDrag(tester, const Offset(-150, 0));
    tester.view.physicalSize = const Size(600, 600);
    await tester.pump();
    expect(translation(tester, 0), 0);
    await finger.moveBy(const Offset(-50, 0));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();
    expect(key.currentState!.index, 0);
    expect(translation(tester, 0), 0);
  });
}
