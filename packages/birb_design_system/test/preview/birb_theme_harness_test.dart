import 'dart:ui' show CheckedState, SemanticsAction, Tristate;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';

void main() {
  test('fixture inventory is closed and unique', () {
    expect(
      BirbThemeHarnessInventory.byFamily,
      const <BirbHarnessFamily, List<String>>{
        BirbHarnessFamily.typography: <String>[
          'displayLarge',
          'displayMedium',
          'displaySmall',
          'headlineLarge',
          'headlineMedium',
          'headlineSmall',
          'titleLarge',
          'titleMedium',
          'titleSmall',
          'bodyLarge',
          'bodyMedium',
          'bodySmall',
          'labelLarge',
          'labelMedium',
          'labelSmall',
        ],
        BirbHarnessFamily.surfaces: <String>[
          'appBar',
          'surface',
          'surfaceDim',
          'surfaceBright',
          'surfaceContainerLowest',
          'surfaceContainerLow',
          'surfaceContainer',
          'surfaceContainerHigh',
          'surfaceContainerHighest',
          'card',
          'divider',
        ],
        BirbHarnessFamily.interactiveControls: <String>[
          'filledButton',
          'elevatedButton',
          'outlinedButton',
          'textButton',
          'menuButton',
          'iconButton',
          'disabledButton',
          'checkboxSelected',
          'checkboxUnselected',
          'checkboxError',
          'checkboxDisabled',
          'radioSelected',
          'radioUnselected',
          'radioDisabled',
          'switchSelected',
          'switchUnselected',
          'switchDisabled',
          'sliderEnabled',
          'sliderDisabled',
          'chipSelected',
          'chipUnselected',
          'chipDisabled',
        ],
        BirbHarnessFamily.overlays: <String>[
          'dialogTrigger',
          'menuTrigger',
          'snackbarTrigger',
          'tooltip',
        ],
        BirbHarnessFamily.statuses: <String>[
          'success',
          'warning',
          'info',
          'error',
          'selected',
          'loading',
          'disabled',
        ],
        BirbHarnessFamily.navigation: <String>[
          'navigationBar',
          'navigationRail',
        ],
        BirbHarnessFamily.inputs: <String>['enabled', 'error', 'disabled'],
      },
    );
    final fixtures = BirbThemeHarnessInventory.all.toList();
    expect(fixtures.toSet(), hasLength(fixtures.length));
  });

  for (final themeCase in <({String name, ThemeData theme})>[
    (name: 'light', theme: BirbTheme.light),
    (name: 'dark', theme: BirbTheme.dark),
  ]) {
    testWidgets('${themeCase.name} renders every fixture', (tester) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));

      for (final fixture in BirbThemeHarnessInventory.all) {
        expect(
          find.byKey(BirbThemeHarnessKeys.fixture(fixture)),
          findsOneWidget,
          reason: '${fixture.family.name}/${fixture.name}',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${themeCase.name} renders at 320 pixels and 200 percent text',
      (tester) async {
        await _pumpHarness(
          tester,
          themeCase.theme,
          const Size(320, 5000),
          textScaler: const TextScaler.linear(2),
        );

        for (final fixture in BirbThemeHarnessInventory.all) {
          final finder = _fixture(fixture.family, fixture.name);
          await tester.ensureVisible(finder);
          await tester.pump();
          expect(finder, findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('${themeCase.name} opens and dismisses the dialog', (
      tester,
    ) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));
      await _tapFixture(tester, BirbHarnessFamily.overlays, 'dialogTrigger');
      expect(find.byKey(BirbThemeHarnessKeys.dialog), findsOneWidget);
      await tester.tap(find.byKey(BirbThemeHarnessKeys.dialogDismiss));
      await tester.pumpAndSettle();
      expect(find.byKey(BirbThemeHarnessKeys.dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${themeCase.name} opens and dismisses the themed menu', (
      tester,
    ) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));
      await _tapFixture(tester, BirbHarnessFamily.overlays, 'menuTrigger');
      expect(find.byType(MenuAnchor), findsOneWidget);
      expect(find.byKey(BirbThemeHarnessKeys.menuItem), findsOneWidget);
      final menuMaterial = tester.widget<Material>(
        find.ancestor(
          of: find.byKey(BirbThemeHarnessKeys.menuItem),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Material &&
                widget.color ==
                    themeCase.theme.colorScheme.surfaceContainerHigh,
          ),
        ),
      );
      expect(menuMaterial.elevation, 0);
      await tester.tap(find.byKey(BirbThemeHarnessKeys.menuItem));
      await tester.pumpAndSettle();
      expect(find.byKey(BirbThemeHarnessKeys.menuItem), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${themeCase.name} presents and hides the snackbar', (
      tester,
    ) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));
      await _tapFixture(tester, BirbHarnessFamily.overlays, 'snackbarTrigger');
      expect(find.byKey(BirbThemeHarnessKeys.snackbar), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byKey(BirbThemeHarnessKeys.root)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byKey(BirbThemeHarnessKeys.snackbar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${themeCase.name} presents the tooltip', (tester) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));
      final tooltip = _fixture(BirbHarnessFamily.overlays, 'tooltip');
      await tester.ensureVisible(tooltip);
      await tester.longPress(tooltip);
      await tester.pumpAndSettle();
      expect(find.text('Theme tooltip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('enabled controls change their advertised state', (tester) async {
    await _pumpHarness(tester, BirbTheme.light, const Size(1000, 3000));

    final checkboxFixture = _fixture(
      BirbHarnessFamily.interactiveControls,
      'checkboxUnselected',
    );
    await tester.ensureVisible(checkboxFixture);
    await tester.tap(
      find.descendant(of: checkboxFixture, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(
              of: checkboxFixture,
              matching: find.byType(Checkbox),
            ),
          )
          .value,
      isTrue,
    );

    final switchFixture = _fixture(
      BirbHarnessFamily.interactiveControls,
      'switchUnselected',
    );
    await tester.tap(
      find.descendant(of: switchFixture, matching: find.byType(Switch)),
    );
    await tester.pump();
    expect(
      tester
          .widget<Switch>(
            find.descendant(of: switchFixture, matching: find.byType(Switch)),
          )
          .value,
      isTrue,
    );

    final chip = _fixture(
      BirbHarnessFamily.interactiveControls,
      'chipUnselected',
    );
    await tester.tap(chip);
    await tester.pump();
    expect(
      tester
          .widget<FilterChip>(
            find.descendant(of: chip, matching: find.byType(FilterChip)),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('controls and statuses expose accurate semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpHarness(tester, BirbTheme.light, const Size(1000, 3000));

    final checkbox = _fixture(
      BirbHarnessFamily.interactiveControls,
      'checkboxUnselected',
    );
    final checkboxData = tester.getSemantics(checkbox).getSemanticsData();
    expect(checkboxData.label, 'Unselected checkbox');
    expect(checkboxData.flagsCollection.isChecked, CheckedState.isFalse);
    expect(checkboxData.hasAction(SemanticsAction.tap), isTrue);

    final sliderData = tester
        .getSemantics(
          _fixture(BirbHarnessFamily.interactiveControls, 'sliderEnabled'),
        )
        .getSemanticsData();
    expect(sliderData.label, 'Enabled slider');
    expect(sliderData.hasAction(SemanticsAction.increase), isTrue);

    final success = tester
        .getSemantics(_fixture(BirbHarnessFamily.statuses, 'success'))
        .getSemanticsData();
    expect(success.flagsCollection.isSelected, Tristate.none);
    expect(success.flagsCollection.isEnabled, Tristate.none);

    final selected = tester
        .getSemantics(_fixture(BirbHarnessFamily.statuses, 'selected'))
        .getSemanticsData();
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    final loading = tester
        .getSemantics(_fixture(BirbHarnessFamily.statuses, 'loading'))
        .getSemanticsData();
    expect(loading.value, 'Loading');
    expect(
      find.descendant(
        of: _fixture(BirbHarnessFamily.statuses, 'loading'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('tooltip trigger is keyboard focusable and 48 pixels', (
    tester,
  ) async {
    await _pumpHarness(tester, BirbTheme.light, const Size(1000, 3000));
    final tooltip = _fixture(BirbHarnessFamily.overlays, 'tooltip');
    final button = find.descendant(
      of: tooltip,
      matching: find.byType(IconButton),
    );
    await tester.ensureVisible(button);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var tabs = 0; tabs < 40 && !focusIsInside(button); tabs += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(focusIsInside(button), isTrue);
    expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(button)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
  });

  testWidgets('interactive fixtures meet the labeling guideline', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpHarness(tester, BirbTheme.light, const Size(1000, 3000));

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

Finder _fixture(BirbHarnessFamily family, String name) =>
    find.byKey(BirbThemeHarnessKeys.fixture((family: family, name: name)));

Future<void> _pumpHarness(
  WidgetTester tester,
  ThemeData theme,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      themeAnimationDuration: BirbDurations.instant,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const BirbThemeHarness(),
    ),
  );
  await tester.pump();
}

Future<void> _tapFixture(
  WidgetTester tester,
  BirbHarnessFamily family,
  String name,
) async {
  final finder = find.byKey(
    BirbThemeHarnessKeys.fixture((family: family, name: name)),
  );
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
