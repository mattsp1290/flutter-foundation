import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture inventory is closed and unique', () {
    expect(BirbThemeHarnessInventory.byFamily.keys, BirbHarnessFamily.values);
    expect(
      BirbThemeHarnessInventory.byFamily.map(
        (family, fixtures) => MapEntry(family, fixtures.length),
      ),
      const <BirbHarnessFamily, int>{
        BirbHarnessFamily.typography: 15,
        BirbHarnessFamily.surfaces: 10,
        BirbHarnessFamily.interactiveControls: 21,
        BirbHarnessFamily.overlays: 4,
        BirbHarnessFamily.statuses: 7,
        BirbHarnessFamily.navigation: 2,
        BirbHarnessFamily.inputs: 3,
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

        expect(find.byKey(BirbThemeHarnessKeys.root), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('${themeCase.name} opens every transient overlay', (
      tester,
    ) async {
      await _pumpHarness(tester, themeCase.theme, const Size(1000, 3000));

      await _tapFixture(tester, BirbHarnessFamily.overlays, 'dialogTrigger');
      expect(find.byKey(BirbThemeHarnessKeys.dialog), findsOneWidget);
      await tester.tap(find.byKey(BirbThemeHarnessKeys.dialogDismiss));
      await tester.pumpAndSettle();

      await _tapFixture(tester, BirbHarnessFamily.overlays, 'menuTrigger');
      expect(find.byKey(BirbThemeHarnessKeys.menuItem), findsOneWidget);
      await tester.tap(find.byKey(BirbThemeHarnessKeys.menuItem));
      await tester.pumpAndSettle();

      await _tapFixture(tester, BirbHarnessFamily.overlays, 'snackbarTrigger');
      expect(find.byKey(BirbThemeHarnessKeys.snackbar), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byKey(BirbThemeHarnessKeys.root)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      final tooltip = find.byKey(
        BirbThemeHarnessKeys.fixture((
          family: BirbHarnessFamily.overlays,
          name: 'tooltip',
        )),
      );
      await tester.ensureVisible(tooltip);
      await tester.longPress(tooltip);
      await tester.pumpAndSettle();
      expect(find.text('Theme tooltip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

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
