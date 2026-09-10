import 'dart:ui' show Tristate;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';
import 'review_test_fixtures.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} items show path, kind, and counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        themedHost(
          SingleChildScrollView(
            child: BirbChangedFileList(files: allFiles, onFileSelected: (_) {}),
          ),
          brightness: brightness,
        ),
      );

      expect(find.text(textFile.path), findsOneWidget);
      expect(
        find.text('Modified · +3 additions, −2 deletions'),
        findsOneWidget,
      );
      expect(find.text('Added · +12 additions, −0 deletions'), findsOneWidget);
      expect(
        find.text('Deleted · +0 additions, −40 deletions'),
        findsOneWidget,
      );
      expect(
        find.text('Renamed from ${renamedFile.previousPath}'),
        findsOneWidget,
      );
      expect(find.text('Binary file'), findsOneWidget);
      expect(find.text('Content unavailable'), findsOneWidget);
    });
  }

  testWidgets('selection uses a non-color cue and selected semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbChangedFileList(
            files: allFiles,
            selectedFileId: renamedFile.id,
            onFileSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.text('Renamed · +1 additions, −1 deletions · Selected'),
      findsOneWidget,
    );
    final selectedText = tester.widget<Text>(find.text(renamedFile.path));
    expect(selectedText.style?.fontWeight, FontWeight.w700);

    final selectedData = tester
        .getSemantics(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(renamedFile.path)},')),
        )
        .getSemanticsData();
    expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);

    final unselectedData = tester
        .getSemantics(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(textFile.path)},')),
        )
        .getSemanticsData();
    expect(unselectedData.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('an external selection change updates the rendering', (
    tester,
  ) async {
    Widget build(String? selected) => themedHost(
      SingleChildScrollView(
        child: BirbChangedFileList(
          files: <BirbReviewFile>[textFile, addedFile],
          selectedFileId: selected,
          onFileSelected: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(build(textFile.id));
    expect(
      tester.widget<Text>(find.text(textFile.path)).style?.fontWeight,
      FontWeight.w700,
    );

    await tester.pumpWidget(build(addedFile.id));
    expect(
      tester.widget<Text>(find.text(textFile.path)).style?.fontWeight,
      isNot(FontWeight.w700),
    );
    expect(
      tester.widget<Text>(find.text(addedFile.path)).style?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('keyboard traversal activates items with Enter and Space', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbChangedFileList(
            files: <BirbReviewFile>[textFile, addedFile],
            onFileSelected: chosen.add,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      focusIsInside(
        find.ancestor(
          of: find.text(textFile.path),
          matching: find.byType(OutlinedButton),
        ),
      ),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, <String>[textFile.id]);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(chosen, <String>[textFile.id, addedFile.id]);
  });

  testWidgets('disabled navigation emits no callback and disables items', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbChangedFileList(files: <BirbReviewFile>[textFile]),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty list renders overridable empty text', (tester) async {
    await tester.pumpWidget(
      themedHost(const BirbChangedFileList(files: <BirbReviewFile>[])),
    );
    expect(find.text('No changed files'), findsOneWidget);

    await tester.pumpWidget(
      themedHost(
        const BirbChangedFileList(
          files: <BirbReviewFile>[],
          labels: BirbChangedFileListLabels(empty: 'Keine Dateien'),
        ),
      ),
    );
    expect(find.text('Keine Dateien'), findsOneWidget);
    expect(find.text('No changed files'), findsNothing);
  });

  testWidgets('long paths wrap at 320 logical pixels and 200 percent text', (
    tester,
  ) async {
    useViewport(tester, const Size(320, 600));
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbChangedFileList(
            files: <BirbReviewFile>[unavailableFile],
            onFileSelected: (_) {},
          ),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    final pathFinder = find.text(unavailableFile.path);
    expect(pathFinder, findsOneWidget);
    final rendered = tester.renderObject<RenderParagraph>(pathFinder);
    expect(rendered.size.height, greaterThan(rendered.textSize.height / 2));
    expect(rendered.didExceedMaxLines, isFalse);
    expect(tester.getSize(find.byType(OutlinedButton)).width, lessThan(321));
  });

  testWidgets('every item keeps the 48 logical pixel minimum target', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbChangedFileList(files: allFiles, onFileSelected: (_) {}),
        ),
      ),
    );

    for (final element in find.byType(OutlinedButton).evaluate()) {
      final size = tester.getSize(find.byElementPredicate((e) => e == element));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
