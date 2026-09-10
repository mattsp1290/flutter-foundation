import 'dart:ui' show CheckedState;

import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_appearance_store.dart';

void main() {
  testWidgets('renders three labeled choices with selected semantics', (
    tester,
  ) async {
    final controller = await _initializedController();
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSelector(tester, controller);

      expect(find.byType(RadioListTile<AppearanceMode>), findsExactly(3));
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byType(Radio<AppearanceMode>).first)
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('uses caller-provided choice labels', (tester) async {
    final controller = await _initializedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppearanceSelector(
            controller: controller,
            systemLabel: 'Automatic',
            lightLabel: 'Day',
            darkLabel: 'Night',
          ),
        ),
      ),
    );

    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);
  });

  testWidgets('supports radio-group keyboard selection', (tester) async {
    final controller = await _initializedController();
    addTearDown(controller.dispose);
    await _pumpSelector(tester, controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.selectedMode, AppearanceMode.light);
    expect(
      find.byKey(const ValueKey<String>('appearance-saving')),
      findsNothing,
    );
  });

  testWidgets('keyboard can choose again while a save is pending', (
    tester,
  ) async {
    final store = TestAppearanceStore(controlWrites: true);
    final controller = await _initializedController(store);
    addTearDown(controller.dispose);
    await _pumpSelector(tester, controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final focusedContext = tester.binding.focusManager.primaryFocus?.context;
    expect(focusedContext, isNotNull);
    expect(
      find.ancestor(
        of: find.byElementPredicate(
          (element) => identical(element, focusedContext),
        ),
        matching: find.byKey(
          const ValueKey<AppearanceMode>(AppearanceMode.system),
        ),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await store.waitForWrite(0);
    await tester.pump();

    expect(controller.selectedMode, AppearanceMode.light);
    expect(store.writes, <AppearanceMode>[AppearanceMode.light]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.selectedMode, AppearanceMode.dark);
    expect(store.writes, <AppearanceMode>[AppearanceMode.light]);

    store.succeedWrite(0);
    await store.waitForWrite(1);
    store.succeedWrite(1);
    await tester.pump();
    expect(store.value, AppearanceMode.dark);
  });

  testWidgets('allows a newer choice while the selected save is pending', (
    tester,
  ) async {
    final store = TestAppearanceStore(controlWrites: true);
    final controller = await _initializedController(store);
    addTearDown(controller.dispose);
    await _pumpSelector(tester, controller);

    await tester.tap(find.text('Light'));
    await store.waitForWrite(0);
    await tester.pump();

    expect(controller.selectedMode, AppearanceMode.light);
    expect(
      find.byKey(const ValueKey<String>('appearance-saving')),
      findsOneWidget,
    );
    expect(_tile(tester, AppearanceMode.light).enabled, isFalse);
    expect(_tile(tester, AppearanceMode.dark).enabled, isTrue);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(controller.selectedMode, AppearanceMode.dark);
    expect(store.writes, <AppearanceMode>[AppearanceMode.light]);

    store.succeedWrite(0);
    await store.waitForWrite(1);
    store.succeedWrite(1);
    await tester.pump();
    expect(store.value, AppearanceMode.dark);
    expect(controller.lastPersistedMode, AppearanceMode.dark);
  });

  testWidgets('shows a failed save and retries with custom text', (
    tester,
  ) async {
    final store = TestAppearanceStore(controlWrites: true);
    final controller = await _initializedController(store);
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    await _pumpSelector(
      tester,
      controller,
      errorTextBuilder: (_, error) => 'Localized: $error',
      retryTextBuilder: (_) => 'Try again',
      savingTextBuilder: (_, mode, label) => 'Persisting $label ($mode)',
    );

    await tester.tap(find.text('Dark'));
    await store.waitForWrite(0);
    await tester.pump();
    expect(find.textContaining('Persisting Dark'), findsOneWidget);
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('appearance-saving')),
      ),
      matchesSemantics(
        label: 'Persisting Dark (AppearanceMode.dark)',
        isLiveRegion: true,
      ),
    );
    store.failWrite(0, StateError('disk full'));
    await tester.pump();

    expect(find.textContaining('Localized:'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('appearance-save-error')),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('appearance-save-error')),
      ),
      matchesSemantics(
        label: 'Localized: Bad state: disk full',
        isLiveRegion: true,
      ),
    );

    await tester.tap(find.text('Try again'));
    await store.waitForWrite(1);
    store.succeedWrite(1);
    await tester.pump();

    expect(find.text('Try again'), findsNothing);
    expect(controller.lastPersistedMode, AppearanceMode.dark);
    semantics.dispose();
  });

  testWidgets('shows initialization and nonfatal read failure states', (
    tester,
  ) async {
    final error = StateError('unavailable');
    final controller = AppearanceController(
      store: TestAppearanceStore(readError: error),
    );
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    await _pumpSelector(
      tester,
      controller,
      initializingTextBuilder: (_) => 'Preparing theme',
    );

    expect(
      find.byKey(const ValueKey<String>('appearance-initializing')),
      findsOneWidget,
    );
    expect(find.text('Preparing theme'), findsOneWidget);
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('appearance-initializing')),
      ),
      matchesSemantics(label: 'Preparing theme', isLiveRegion: true),
    );

    await controller.initialize();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('appearance-initializing')),
      findsNothing,
    );
    expect(find.text('Could not load appearance.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('appearance-read-error')),
      ),
      matchesSemantics(label: 'Could not load appearance.', isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('replaces and never disposes a borrowed controller', (
    tester,
  ) async {
    final firstStore = TestAppearanceStore();
    final secondStore = TestAppearanceStore(value: AppearanceMode.dark);
    final first = await _initializedController(firstStore);
    final second = await _initializedController(secondStore);
    final selectedController = ValueNotifier<AppearanceController>(first);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(selectedController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<AppearanceController>(
            valueListenable: selectedController,
            builder: (_, controller, _) => AppearanceSelector(
              key: const ValueKey<String>('mounted-selector'),
              controller: controller,
            ),
          ),
        ),
      ),
    );
    selectedController.value = second;
    await tester.pump();
    expect(_tile(tester, AppearanceMode.dark).selected, isTrue);

    await first.setMode(AppearanceMode.light);
    await tester.pump();
    expect(firstStore.writes, <AppearanceMode>[AppearanceMode.light]);
    expect(_tile(tester, AppearanceMode.dark).selected, isTrue);

    await second.setMode(AppearanceMode.light);
    await tester.pump();
    expect(secondStore.writes, <AppearanceMode>[AppearanceMode.light]);
    expect(_tile(tester, AppearanceMode.light).selected, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await second.setMode(AppearanceMode.dark);
    expect(secondStore.writes.last, AppearanceMode.dark);
  });

  testWidgets('selection preserves unrelated host state', (tester) async {
    final controller = await _initializedController();
    final textController = TextEditingController();
    addTearDown(controller.dispose);
    addTearDown(textController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              TextField(controller: textController),
              AppearanceSelector(controller: controller),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'preserved');
    await tester.tap(find.text('Light'));
    await tester.pump();

    expect(textController.text, 'preserved');
    expect(controller.selectedMode, AppearanceMode.light);
  });

  testWidgets('stacks without overflow at narrow width and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = await _initializedController();
    addTearDown(controller.dispose);

    await _pumpSelector(tester, controller, textScale: 2);

    expect(tester.takeException(), isNull);
    final tiles = find.byType(RadioListTile<AppearanceMode>);
    expect(
      tester.getTopLeft(tiles.at(0)).dx,
      tester.getTopLeft(tiles.at(1)).dx,
    );
    expect(
      tester.getTopLeft(tiles.at(1)).dx,
      tester.getTopLeft(tiles.at(2)).dx,
    );
  });

  testWidgets('stacks safely when its horizontal constraints are unbounded', (
    tester,
  ) async {
    final controller = await _initializedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnconstrainedBox(
            alignment: Alignment.topLeft,
            constrainedAxis: Axis.vertical,
            child: AppearanceSelector(controller: controller),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final tiles = find.byType(RadioListTile<AppearanceMode>);
    expect(
      tester.getTopLeft(tiles.at(0)).dx,
      tester.getTopLeft(tiles.at(1)).dx,
    );
    expect(tester.getSize(find.byType(AppearanceSelector)).width, 480);
  });
}

Future<AppearanceController> _initializedController([
  TestAppearanceStore? store,
]) async {
  final controller = AppearanceController(
    store: store ?? TestAppearanceStore(),
  );
  await controller.initialize();
  return controller;
}

RadioListTile<AppearanceMode> _tile(WidgetTester tester, AppearanceMode mode) =>
    tester.widget(find.byKey(ValueKey<AppearanceMode>(mode)));

Future<void> _pumpSelector(
  WidgetTester tester,
  AppearanceController controller, {
  AppearanceErrorTextBuilder? errorTextBuilder,
  AppearanceRetryTextBuilder? retryTextBuilder,
  AppearanceInitializingTextBuilder? initializingTextBuilder,
  AppearanceSavingTextBuilder? savingTextBuilder,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: AppearanceSelector(
          controller: controller,
          errorTextBuilder: errorTextBuilder,
          retryTextBuilder: retryTextBuilder,
          initializingTextBuilder: initializingTextBuilder,
          savingTextBuilder: savingTextBuilder,
        ),
      ),
    ),
  ),
);
