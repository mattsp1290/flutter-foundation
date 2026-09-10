import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foundation_catalog/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void useViewport(WidgetTester tester, Size size) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  ThemeData themeOf(WidgetTester tester) => Theme.of(
    tester.element(find.byKey(BirbReviewHarnessKeys.simulationNotice)),
  );

  testWidgets('opens on the code review preview with the Birb light theme', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(const CatalogApp());
    await tester.pumpAndSettle();

    expect(find.byType(BirbReviewHarness), findsOneWidget);
    expect(find.byType(BirbThemeHarness), findsNothing);
    expect(
      find.text('Simulated review — nothing is sent anywhere.'),
      findsOneWidget,
    );

    final theme = themeOf(tester);
    expect(theme.colorScheme, BirbTheme.light.colorScheme);
    expect(theme.extension<BirbSemanticColors>(), BirbSemanticColors.light);
  });

  testWidgets('switches between the two previews', (tester) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(const CatalogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CatalogKeys.themePreviewTab));
    await tester.pumpAndSettle();
    expect(find.byType(BirbThemeHarness), findsOneWidget);
    expect(find.byType(BirbReviewHarness), findsNothing);
    expect(find.text('Design system preview'), findsOneWidget);

    await tester.tap(find.byKey(CatalogKeys.reviewPreviewTab));
    await tester.pumpAndSettle();
    expect(find.byType(BirbReviewHarness), findsOneWidget);
    expect(find.byType(BirbThemeHarness), findsNothing);
  });

  testWidgets('switches brightness with no theme transition', (tester) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(const CatalogApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeAnimationDuration, BirbDurations.instant);
    expect(app.theme, BirbTheme.light);
    expect(app.darkTheme, BirbTheme.dark);

    await tester.tap(find.byKey(CatalogKeys.darkModeChip));
    await tester.pump();
    expect(themeOf(tester).colorScheme, BirbTheme.dark.colorScheme);
    expect(
      themeOf(tester).extension<BirbSemanticColors>(),
      BirbSemanticColors.dark,
    );

    await tester.tap(find.byKey(CatalogKeys.lightModeChip));
    await tester.pump();
    expect(themeOf(tester).colorScheme, BirbTheme.light.colorScheme);
  });

  testWidgets('the review workflow runs through the public package API', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(const CatalogApp());
    await tester.pumpAndSettle();

    // Choose a commentable line and open a new discussion.
    await tester.ensureVisible(
      find.byKey(BirbDiffViewKeys.line('modified-added-11')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BirbDiffViewKeys.line('modified-added-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BirbDiffViewKeys.commentAction));
    await tester.pumpAndSettle();
    expect(find.text('New discussion — On new line 11'), findsOneWidget);

    // Reply through the composer and see the comment appear.
    final composer = find.byKey(BirbReviewHarnessKeys.newDiscussionComposer);
    await tester.enterText(
      find.descendant(of: composer, matching: find.byType(TextField)),
      'Catalog reply',
    );
    await tester.pump();
    final submit = find.descendant(
      of: composer,
      matching: find.byKey(BirbReviewComposerKeys.submitAction),
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Catalog reply'), findsWidgets);
    expect(find.text('You · just now'), findsOneWidget);
  });

  testWidgets('renders at 320 logical pixels and 200 percent text without '
      'overflow', (tester) async {
    useViewport(tester, const Size(320, 900));
    // MaterialApp rebuilds MediaQuery from the view, so the scale has to come
    // from the platform dispatcher rather than an ambient MediaQuery.
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const CatalogApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(CatalogKeys.reviewPreviewTab), findsOneWidget);
    expect(find.byKey(BirbReviewHarnessKeys.diff), findsOneWidget);
  });
}
