import 'dart:ui' show SemanticsAction, Tristate;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';
import 'review_test_fixtures.dart';

void main() {
  Finder lineRows() => find.byWidgetPredicate(
    (widget) => BirbDiffViewKeys.isLineKey(widget.key),
  );

  Future<void> pumpDiff(
    WidgetTester tester, {
    required BirbDiffSnapshot snapshot,
    BirbDiffAnchor? selectedAnchor,
    ValueChanged<BirbDiffAnchor>? onCommentRequested,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Key? key,
  }) async {
    await tester.pumpWidget(
      themedHost(
        BirbDiffView(
          key: key,
          snapshot: snapshot,
          selectedAnchor: selectedAnchor,
          onCommentRequested: onCommentRequested,
        ),
        brightness: brightness,
        textScale: textScale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('rendering', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name} shows signs, numbers, and headings', (
        tester,
      ) async {
        final snapshot = modifiedSnapshot();
        await pumpDiff(
          tester,
          snapshot: snapshot,
          brightness: brightness,
          onCommentRequested: (_) {},
        );

        expect(find.text(snapshot.file.path), findsOneWidget);
        expect(find.text('Modified · +3 additions · −2 deletions'), findsOne);
        expect(find.byKey(BirbDiffViewKeys.heading('hunk-1')), findsOneWidget);
        expect(
          find.text('@@ -10,4 +10,5 @@ Widget build(BuildContext context)'),
          findsOneWidget,
        );

        // Line numbers appear on both sides for context, one side otherwise.
        expect(find.text('10'), findsNWidgets(2));
        expect(find.text('11'), findsNWidgets(2));
        expect(find.text('+'), findsNWidgets(3));
        expect(find.text('−'), findsOneWidget);

        // Tabs expand to four display columns and Unicode survives.
        expect(
          find.text('    return const BirbDiffView(snapshot: snapshot);'),
          findsOneWidget,
        );
        expect(
          find.text(
            '    // Unicode kept verbatim: naïve — 🐦 — <b>literal</b>',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('the deletion marker uses error roles and the addition '
        'marker uses success roles', (tester) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      final theme = BirbTheme.light;

      ColoredBox markerOf(String text) => tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text(text).first,
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        markerOf('−').color,
        BirbReviewStyle.lineMarker(theme, BirbDiffLineKind.deletion).background,
      );
      expect(
        markerOf('+').color,
        BirbReviewStyle.lineMarker(theme, BirbDiffLineKind.addition).background,
      );
    });

    testWidgets('renamed and deleted files render their metadata', (
      tester,
    ) async {
      await pumpDiff(tester, snapshot: deletedSnapshot());
      expect(find.text(deletedFile.path), findsOneWidget);
      expect(find.text('class OldDiff {}'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
      expect(find.text('+'), findsNothing);
    });

    testWidgets('empty, binary, and unavailable content render distinct '
        'overridable messages instead of an empty diff', (tester) async {
      await pumpDiff(tester, snapshot: emptyTextSnapshot());
      expect(find.text('No textual changes'), findsOneWidget);
      expect(lineRows(), findsNothing);

      await pumpDiff(tester, snapshot: binarySnapshot());
      expect(find.text('Binary file. No text diff is shown.'), findsOneWidget);
      expect(lineRows(), findsNothing);

      await pumpDiff(tester, snapshot: unavailableSnapshot());
      expect(
        find.text('Source content is unavailable for this revision.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        themedHost(
          BirbDiffView(
            snapshot: binarySnapshot(),
            labels: const BirbDiffViewLabels(binaryText: 'Binärdatei'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Binärdatei'), findsOneWidget);
    });

    testWidgets('an HTML-like string appears literally', (tester) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      expect(find.textContaining('<b>literal</b>'), findsWidgets);
    });
  });

  group('selection', () {
    testWidgets('a selected anchor adds a non-color cue and semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final snapshot = modifiedSnapshot();
      final line = snapshot.lines.firstWhere((l) => l.id == 'line-added-11');
      await pumpDiff(
        tester,
        snapshot: snapshot,
        selectedAnchor: snapshot.anchorFor(line),
      );

      expect(find.byIcon(BirbReviewStyle.selectedRowIcon), findsOneWidget);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(BirbDiffViewKeys.line(line.id)),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (box.decoration as BoxDecoration).color,
        BirbReviewStyle.selectedRowBackground(BirbTheme.light),
      );

      final rowSemantics = tester
          .getSemantics(
            find
                .descendant(
                  of: find.byKey(BirbDiffViewKeys.line(line.id)),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .getSemanticsData();
      expect(rowSemantics.label, startsWith('Added new line 11'));
      expect(rowSemantics.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('an anchor from another revision or file is ignored', (
      tester,
    ) async {
      final snapshot = modifiedSnapshot();
      await pumpDiff(
        tester,
        snapshot: snapshot,
        selectedAnchor: BirbDiffAnchor(
          fileId: snapshot.file.id,
          revisionId: 'rev-outdated',
          lineId: 'line-added-11',
          side: BirbDiffSide.after,
          lineNumber: 11,
        ),
      );
      expect(find.byIcon(BirbReviewStyle.selectedRowIcon), findsNothing);

      await pumpDiff(
        tester,
        snapshot: snapshot,
        selectedAnchor: BirbDiffAnchor(
          fileId: 'another-file',
          revisionId: snapshot.revisionId,
          lineId: 'line-added-11',
          side: BirbDiffSide.after,
          lineNumber: 11,
        ),
      );
      expect(find.byIcon(BirbReviewStyle.selectedRowIcon), findsNothing);
    });
  });

  group('assistive technology', () {
    testWidgets('a row is activatable and moves the active line', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDiff(
        tester,
        snapshot: modifiedSnapshot(),
        onCommentRequested: (_) {},
      );

      final row = find.semantics.byPredicate(
        (node) => node.label.startsWith('Added new line 11'),
      );
      expect(
        row.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      tester.semantics.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Comment on added line 11'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a row label states the kind and numbers once', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDiff(tester, snapshot: modifiedSnapshot());

      final label = tester
          .getSemantics(
            find
                .descendant(
                  of: find.byKey(BirbDiffViewKeys.line('line-context-10')),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .getSemanticsData()
          .label;
      expect(label, startsWith('Unchanged old line 10, new line 10'));
      // The gutter must not repeat the numbers or read the sign glyph aloud.
      expect('10'.allMatches(label).length, 2);
      expect(label, isNot(contains('+')));
      handle.dispose();
    });

    testWidgets('the no-final-newline marker is rendered, not just modelled', (
      tester,
    ) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      await tester.tap(find.byKey(BirbDiffViewKeys.line('line-context-13')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Unchanged old line 12, new line 13 · No newline at end of file',
        ),
        findsWidgets,
      );
    });

    testWidgets('the active line description is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      final data = tester
          .getSemantics(find.byKey(BirbDiffViewKeys.activeLineDescription))
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('anchors', () {
    testWidgets('the comment action emits the exact anchor for every kind', (
      tester,
    ) async {
      final snapshot = modifiedSnapshot();
      final emitted = <BirbDiffAnchor>[];
      await pumpDiff(
        tester,
        snapshot: snapshot,
        onCommentRequested: emitted.add,
      );

      for (final id in <String>[
        'line-context-10',
        'line-deleted-11',
        'line-added-11',
      ]) {
        await tester.tap(find.byKey(BirbDiffViewKeys.line(id)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(BirbDiffViewKeys.commentAction));
        await tester.pumpAndSettle();
      }

      expect(emitted, hasLength(3));
      expect(
        emitted[0],
        BirbDiffAnchor(
          fileId: snapshot.file.id,
          revisionId: snapshot.revisionId,
          lineId: 'line-context-10',
          side: BirbDiffSide.after,
          lineNumber: 10,
        ),
      );
      expect(
        emitted[1],
        BirbDiffAnchor(
          fileId: snapshot.file.id,
          revisionId: snapshot.revisionId,
          lineId: 'line-deleted-11',
          side: BirbDiffSide.before,
          lineNumber: 11,
        ),
      );
      expect(
        emitted[2],
        BirbDiffAnchor(
          fileId: snapshot.file.id,
          revisionId: snapshot.revisionId,
          lineId: 'line-added-11',
          side: BirbDiffSide.after,
          lineNumber: 11,
        ),
      );
    });

    testWidgets('the action label names the change kind and line number', (
      tester,
    ) async {
      await pumpDiff(
        tester,
        snapshot: modifiedSnapshot(),
        onCommentRequested: (_) {},
      );
      await tester.tap(find.byKey(BirbDiffViewKeys.line('line-deleted-11')));
      await tester.pumpAndSettle();
      expect(find.text('Comment on removed line 11'), findsOneWidget);
      expect(find.text('Removed old line 11'), findsWidgets);
    });

    testWidgets('an omitted callback removes the comment action but keeps '
        'copy', (tester) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      expect(find.byKey(BirbDiffViewKeys.commentAction), findsNothing);
      expect(find.byKey(BirbDiffViewKeys.copyAction), findsOneWidget);
    });
  });

  group('identity replacement', () {
    testWidgets('replacing the revision resets the active line and emits no '
        'stale anchor', (tester) async {
      final emitted = <BirbDiffAnchor>[];
      Widget build(String revision) => themedHost(
        BirbDiffView(
          key: const ValueKey<String>('diff'),
          snapshot: modifiedSnapshot(revisionId: revision),
          onCommentRequested: emitted.add,
        ),
      );

      await tester.pumpWidget(build('rev-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BirbDiffViewKeys.line('line-added-12')));
      await tester.pumpAndSettle();
      expect(find.text('Comment on added line 12'), findsOneWidget);

      await tester.pumpWidget(build('rev-2'));
      await tester.pumpAndSettle();
      expect(find.text('Comment on added line 12'), findsNothing);
      expect(find.text('Comment on unchanged line 10'), findsOneWidget);

      await tester.tap(find.byKey(BirbDiffViewKeys.commentAction));
      await tester.pumpAndSettle();
      expect(emitted, hasLength(1));
      expect(emitted.single.revisionId, 'rev-2');
      expect(emitted.single.lineId, 'line-context-10');
    });

    testWidgets('replacing the file resets owned scroll positions', (
      tester,
    ) async {
      Widget build(BirbDiffSnapshot snapshot) => themedHost(
        BirbDiffView(
          key: const ValueKey<String>('diff'),
          snapshot: snapshot,
          onCommentRequested: (_) {},
        ),
      );

      await tester.pumpWidget(build(largeSnapshot(lineCount: 400)));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(BirbDiffViewKeys.navigationRegion),
        const Offset(0, -600),
        2000,
      );
      await tester.pumpAndSettle();
      final scrolled = tester.widget<Scrollable>(
        find
            .descendant(
              of: find.byKey(BirbDiffViewKeys.navigationRegion),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrolled.controller!.offset, greaterThan(0));

      await tester.pumpWidget(build(modifiedSnapshot()));
      await tester.pumpAndSettle();
      final reset = tester.widget<Scrollable>(
        find
            .descendant(
              of: find.byKey(BirbDiffViewKeys.navigationRegion),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(reset.controller!.offset, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('keyboard', () {
    testWidgets('Tab reaches the navigation region, then the actions, then '
        'leaves', (tester) async {
      await tester.pumpWidget(
        themedHost(
          Column(
            children: <Widget>[
              Expanded(
                child: BirbDiffView(
                  snapshot: modifiedSnapshot(),
                  onCommentRequested: (_) {},
                ),
              ),
              TextButton(
                key: const ValueKey<String>('outside'),
                onPressed: () {},
                child: const Text('Outside the diff'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focusIsInside(find.byKey(BirbDiffViewKeys.commentAction)), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focusIsInside(find.byKey(BirbDiffViewKeys.copyAction)), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusIsInside(find.byKey(BirbDiffViewKeys.selectSourceAction)),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusIsInside(find.byKey(const ValueKey<String>('outside'))),
        isTrue,
      );
      expect(focusIsInside(find.byKey(BirbDiffViewKeys.root)), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('arrows, Home, and End move the active line', (tester) async {
      await pumpDiff(
        tester,
        snapshot: modifiedSnapshot(),
        onCommentRequested: (_) {},
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.text('Unchanged old line 10, new line 10'), findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Comment on removed line 11'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(find.text('Comment on unchanged line 10'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Comment on added line 10000'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(find.text('Comment on unchanged line 10'), findsOneWidget);
    });

    testWidgets('the active row shows the focus boundary while the region '
        'owns focus', (tester) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      final theme = BirbTheme.light;

      BorderSide? sideOf(String lineId) {
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(BirbDiffViewKeys.line(lineId)),
            matching: find.byType(DecoratedBox),
          ),
        );
        return (box.decoration as BoxDecoration).border?.top;
      }

      expect(
        sideOf('line-context-10'),
        BirbReviewStyle.activeRowSide(theme, focused: false),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        sideOf('line-context-10'),
        BirbReviewStyle.activeRowSide(theme, focused: true),
      );
    });

    testWidgets('a tap focuses the navigation region so arrows keep working', (
      tester,
    ) async {
      await pumpDiff(
        tester,
        snapshot: modifiedSnapshot(),
        onCommentRequested: (_) {},
      );

      await tester.tap(find.byKey(BirbDiffViewKeys.line('line-deleted-11')));
      await tester.pumpAndSettle();
      expect(
        focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Comment on added line 11'), findsOneWidget);
    });

    testWidgets('Left and Right scroll the source column', (tester) async {
      await pumpDiff(tester, snapshot: largeSnapshot(lineCount: 40));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final strip = tester.widget<Scrollable>(
        find.descendant(
          of: find.byKey(BirbDiffViewKeys.horizontalScroll),
          matching: find.byType(Scrollable),
        ),
      );
      expect(strip.controller!.offset, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(strip.controller!.offset, greaterThan(0));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(strip.controller!.offset, 0);
    });
  });

  group('copy and native selection', () {
    testWidgets('Copy source line copies the original text in both '
        'commenting modes', (tester) async {
      for (final commenting in <bool>[true, false]) {
        final clipboard = captureClipboard(tester);
        await pumpDiff(
          tester,
          key: ValueKey<bool>(commenting),
          snapshot: modifiedSnapshot(),
          onCommentRequested: commenting ? (_) {} : null,
        );
        await tester.tap(find.byKey(BirbDiffViewKeys.line('line-added-11')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(BirbDiffViewKeys.copyAction));
        await tester.pumpAndSettle();

        expect(clipboard, <String>[
          '\treturn const BirbDiffView(snapshot: snapshot);',
        ], reason: 'commenting: $commenting');
      }
    });

    testWidgets('Copy source line preserves Unicode and excludes decoration', (
      tester,
    ) async {
      final clipboard = captureClipboard(tester);
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      await tester.tap(find.byKey(BirbDiffViewKeys.line('line-added-12')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BirbDiffViewKeys.copyAction));
      await tester.pumpAndSettle();

      expect(clipboard.single, startsWith('\t'));
      expect(clipboard.single, contains('🐦'));
      expect(clipboard.single, isNot(contains('+')));
      expect(clipboard.single, isNot(contains('12')));
      expect(clipboard.single, isNot(contains('\n')));
    });

    testWidgets('keyboard-only F2 selection copies the displayed text and '
        'Escape restores navigation focus', (tester) async {
      for (final commenting in <bool>[true, false]) {
        final clipboard = captureClipboard(tester);
        await pumpDiff(
          tester,
          key: ValueKey<bool>(commenting),
          snapshot: modifiedSnapshot(),
          onCommentRequested: commenting ? (_) {} : null,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        // Reach the tab-containing added line with the keyboard only.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          find.byKey(BirbDiffViewKeys.activeLineDescription),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        final field = find.byKey(BirbDiffViewKeys.sourceSelectionField);
        expect(field, findsOneWidget);
        expect(focusIsInside(field), isTrue);
        final controller = tester.widget<TextField>(field).controller!;
        expect(controller.selection, const TextSelection.collapsed(offset: 0));
        expect(
          controller.text,
          '    return const BirbDiffView(snapshot: snapshot);',
        );

        // Native Shift+Arrow selection over the expanded tab.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        for (var index = 0; index < 4; index += 1) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
        expect(controller.selection.textInside(controller.text), '    ');

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();
        expect(clipboard, <String>['    '], reason: 'commenting: $commenting');

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(BirbDiffViewKeys.sourceSelectionField), findsNothing);
        expect(
          focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
          isTrue,
        );
        expect(find.text('Added new line 11'), findsWidgets);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          focusIsInside(
            find.byKey(
              commenting
                  ? BirbDiffViewKeys.commentAction
                  : BirbDiffViewKeys.copyAction,
            ),
          ),
          isTrue,
        );
      }
    });

    testWidgets('the source column is one selection region that excludes the '
        'gutter', (tester) async {
      await pumpDiff(tester, snapshot: modifiedSnapshot());
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(BirbDiffViewKeys.line('line-added-11')),
          matching: find.byType(SelectionContainer),
        ),
        findsWidgets,
      );
    });
  });

  group('responsive layout', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name} at 320 logical pixels and 200 percent '
          'text nothing overflows and controls stay reachable', (tester) async {
        useViewport(tester, const Size(320, 600));
        final emitted = <BirbDiffAnchor>[];
        await pumpDiff(
          tester,
          snapshot: modifiedSnapshot(),
          onCommentRequested: emitted.add,
          brightness: brightness,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byKey(BirbDiffViewKeys.root)).width, 320);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        final action = find.byKey(BirbDiffViewKeys.commentAction);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(emitted.single.lineId, 'line-deleted-11');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('code text is never shrunk to fit', (tester) async {
      useViewport(tester, const Size(320, 600));
      await pumpDiff(tester, snapshot: modifiedSnapshot(), textScale: 2);
      final paragraph = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.text('Widget build(BuildContext context) {').first,
              matching: find.byType(RichText),
            )
            .first,
      );
      final expected = BirbReviewStyle.codeTextStyle(BirbTheme.light).fontSize!;
      expect(paragraph.text.style!.fontSize, expected);
      expect(paragraph.textScaler.scale(expected), expected * 2);
    });
  });

  group('bounded construction', () {
    testWidgets('a 10,000 line snapshot builds few rows and End reaches the '
        'last line with its exact anchor', (tester) async {
      final emitted = <BirbDiffAnchor>[];
      final snapshot = largeSnapshot();
      await pumpDiff(
        tester,
        snapshot: snapshot,
        onCommentRequested: emitted.add,
      );

      expect(lineRows().evaluate().length, lessThan(200));
      expect(lineRows().evaluate(), isNotEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      expect(lineRows().evaluate().length, lessThan(200));
      expect(
        find.byKey(BirbDiffViewKeys.line('large-line-10000')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(BirbDiffViewKeys.commentAction));
      await tester.pumpAndSettle();
      expect(
        emitted.single,
        BirbDiffAnchor(
          fileId: 'file-large',
          revisionId: 'rev-large',
          lineId: 'large-line-10000',
          side: BirbDiffSide.after,
          lineNumber: 10000,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(find.byKey(BirbDiffViewKeys.line('large-line-1')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byKey(BirbDiffViewKeys.line('large-line-2')), findsOneWidget);
    });

    testWidgets('a 2,000 character line stays horizontally scrollable', (
      tester,
    ) async {
      await pumpDiff(tester, snapshot: largeSnapshot(lineCount: 20));
      final strip = tester.widget<Scrollable>(
        find.descendant(
          of: find.byKey(BirbDiffViewKeys.horizontalScroll),
          matching: find.byType(Scrollable),
        ),
      );
      expect(strip.controller!.position.maxScrollExtent, greaterThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the source can scroll to the end of the widest line in '
        'both layouts', (tester) async {
      for (final layout in <({Size size, double scale})>[
        (size: const Size(800, 600), scale: 1),
        (size: const Size(320, 600), scale: 2),
      ]) {
        tester.view
          ..physicalSize = layout.size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpDiff(
          tester,
          key: ValueKey<String>('layout-${layout.size.width}'),
          snapshot: largeSnapshot(lineCount: 20),
          textScale: layout.scale,
        );

        // The visible width of one row's clipped source viewport.
        final viewport = tester
            .getSize(
              find
                  .descendant(
                    of: find.byKey(BirbDiffViewKeys.line('large-line-1')),
                    matching: find.byType(ClipRect),
                  )
                  .first,
            )
            .width;
        final strip = tester.widget<Scrollable>(
          find.descendant(
            of: find.byKey(BirbDiffViewKeys.horizontalScroll),
            matching: find.byType(Scrollable),
          ),
        );

        // Recomputed independently: the whole widest line must be reachable.
        final painter = TextPainter(
          text: TextSpan(
            text: 'x' * 2000,
            style: BirbReviewStyle.codeTextStyle(BirbTheme.light),
          ),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(layout.scale),
        )..layout();

        expect(
          strip.controller!.position.maxScrollExtent + viewport,
          greaterThanOrEqualTo(painter.width - 0.5),
          reason: 'layout ${layout.size} at ${layout.scale}x',
        );
      }
    });

    testWidgets('focus returns to the navigation region when pointer '
        'scrolling unmounts the focused row', (tester) async {
      await pumpDiff(tester, snapshot: largeSnapshot(lineCount: 400));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(
        focusIsInside(find.byKey(BirbDiffViewKeys.sourceSelectionField)),
        isTrue,
      );

      await tester.fling(
        find.byKey(BirbDiffViewKeys.navigationRegion),
        const Offset(0, -2000),
        4000,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(BirbDiffViewKeys.sourceSelectionField), findsNothing);
      expect(
        focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
        isTrue,
      );
      expect(find.text('Unchanged old line 1, new line 1'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
