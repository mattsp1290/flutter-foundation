import 'package:birb_appearance/birb_appearance.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foundation_catalog/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final preview in <CatalogThemePreview>[
    CatalogThemePreview.light,
    CatalogThemePreview.dark,
  ]) {
    testWidgets('${preview.name} renders every catalog section and fixture', (
      tester,
    ) async {
      final store = _CatalogStore();
      await _pumpCatalog(tester, store, preview: preview);

      expect(
        Theme.of(tester.element(find.byKey(CatalogKeys.root))).brightness,
        preview == CatalogThemePreview.light
            ? Brightness.light
            : Brightness.dark,
      );
      for (final fixture in BirbThemeHarnessInventory.all) {
        expect(
          find.byKey(BirbThemeHarnessKeys.fixture(fixture)),
          findsOneWidget,
          reason: '${fixture.family.name}/${fixture.name}',
        );
      }

      await _selectSection(tester, CatalogSection.appearance);
      expect(
        find.byKey(CatalogKeys.section(CatalogSection.appearance)),
        findsOneWidget,
      );
      expect(find.byKey(CatalogKeys.forcedPreview), findsOneWidget);

      await _selectSection(tester, CatalogSection.accessibility);
      expect(
        find.byKey(CatalogKeys.section(CatalogSection.accessibility)),
        findsOneWidget,
      );
      expect(find.text('Keyboard focus sample'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('activates the catalog overlay fixtures', (tester) async {
    await _pumpCatalog(
      tester,
      _CatalogStore(),
      preview: CatalogThemePreview.light,
      size: const Size(1000, 900),
    );

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
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard traversal reaches a stable catalog control', (
    tester,
  ) async {
    await _pumpCatalog(tester, _CatalogStore());
    final target = find.byKey(CatalogKeys.narrowToggle);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var tabs = 0; tabs < 12 && !_focusIsInside(target); tabs += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }

    expect(_focusIsInside(target), isTrue);
  });

  testWidgets('appearance selection keeps the selected catalog section', (
    tester,
  ) async {
    final store = _CatalogStore();
    await _pumpCatalog(tester, store);
    await _selectSection(tester, CatalogSection.appearance);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(store.writes, <AppearanceMode>[AppearanceMode.dark]);
    expect(
      Theme.of(tester.element(find.byKey(CatalogKeys.root))).brightness,
      Brightness.dark,
    );
    expect(
      find.byKey(CatalogKeys.section(CatalogSection.appearance)),
      findsOneWidget,
    );

    await tester.pumpWidget(CatalogApp(appearanceStore: store));
    await tester.pumpAndSettle();
    expect(
      find.byKey(CatalogKeys.section(CatalogSection.appearance)),
      findsOneWidget,
    );
    expect(find.byKey(CatalogKeys.appearanceSelector), findsOneWidget);
  });

  testWidgets('preview controls apply 320 width and 200 percent text', (
    tester,
  ) async {
    await _pumpCatalog(tester, _CatalogStore(), size: const Size(1000, 900));
    await _selectSection(tester, CatalogSection.accessibility);

    await tester.tap(find.byKey(CatalogKeys.narrowToggle));
    await tester.tap(find.byKey(CatalogKeys.largeTextToggle));
    await tester.pump();

    expect(tester.getSize(find.byKey(CatalogKeys.contentViewport)).width, 320);
    final section = find.byKey(
      CatalogKeys.section(CatalogSection.accessibility),
    );
    expect(MediaQuery.textScalerOf(tester.element(section)).scale(10), 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves the ambient text scale until preview overrides it', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpCatalog(tester, _CatalogStore());

    final section = find.byKey(CatalogKeys.section(CatalogSection.components));
    expect(MediaQuery.textScalerOf(tester.element(section)).scale(10), 15);

    await tester.tap(find.byKey(CatalogKeys.largeTextToggle));
    await tester.pump();
    expect(MediaQuery.textScalerOf(tester.element(section)).scale(10), 20);
  });

  testWidgets('forced preview does not rewrite the persisted preference', (
    tester,
  ) async {
    final store = _CatalogStore(value: AppearanceMode.dark);
    await _pumpCatalog(tester, store, preview: CatalogThemePreview.light);
    await _selectSection(tester, CatalogSection.appearance);

    expect(find.byKey(CatalogKeys.forcedPreview), findsOneWidget);
    expect(find.byKey(CatalogKeys.appearanceSelector), findsNothing);
    expect(store.writes, isEmpty);
    expect(store.value, AppearanceMode.dark);
    expect(
      Theme.of(tester.element(find.byKey(CatalogKeys.root))).brightness,
      Brightness.light,
    );
  });
}

Future<void> _pumpCatalog(
  WidgetTester tester,
  AppearanceStore store, {
  CatalogThemePreview preview = CatalogThemePreview.persisted,
  Size size = const Size(800, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(CatalogApp(appearanceStore: store, preview: preview));
  await tester.pumpAndSettle();
}

Future<void> _selectSection(WidgetTester tester, CatalogSection section) async {
  await tester.tap(find.byKey(CatalogKeys.destination(section)));
  await tester.pumpAndSettle();
}

Future<void> _tapFixture(
  WidgetTester tester,
  BirbHarnessFamily family,
  String name,
) async {
  final fixture = find.byKey(
    BirbThemeHarnessKeys.fixture((family: family, name: name)),
  );
  await tester.ensureVisible(fixture);
  await tester.tap(fixture);
  await tester.pumpAndSettle();
}

bool _focusIsInside(Finder finder) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return find
      .ancestor(
        of: find.byElementPredicate((element) => element == context),
        matching: finder,
      )
      .evaluate()
      .isNotEmpty;
}

final class _CatalogStore implements AppearanceStore {
  _CatalogStore({this.value = AppearanceMode.system});

  AppearanceMode value;
  final List<AppearanceMode> writes = <AppearanceMode>[];

  @override
  Future<AppearanceReadResult> read() async => (mode: value, isPersisted: true);

  @override
  Future<void> write(AppearanceMode mode) async {
    writes.add(mode);
    value = mode;
  }
}
