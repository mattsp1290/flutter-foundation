import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:birb_code_editor/src/diagnostic_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixtureProvider implements BirbEditorProvider {
  final completions = <Completer<List<BirbEditorCompletion>>>[];
  @override
  Future<List<BirbEditorCompletion>> complete(BirbEditorRequest request) {
    final completer = Completer<List<BirbEditorCompletion>>();
    completions.add(completer);
    return completer.future;
  }

  @override
  Future<BirbEditorHover?> hover(BirbEditorRequest request) async =>
      const BirbEditorHover(text: 'Plain hover information');
  @override
  Future<List<BirbEditorDiagnostic>> diagnose(
    BirbEditorRequest request,
  ) async => const [
    BirbEditorDiagnostic(
      range: TextRange(start: 0, end: 3),
      severity: BirbEditorDiagnosticSeverity.warning,
      message: 'Example diagnostic',
    ),
  ];
}

Future<void> _controlKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    BirbEditorController controller,
    FocusNode focus,
    _FixtureProvider provider,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirbSourceEditor(
            controller: controller,
            focusNode: focus,
            provider: provider,
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
  }

  BirbEditorCompletion item(String text) => BirbEditorCompletion(
    label: text,
    edit: BirbEditorEdit(range: const TextRange(start: 0, end: 3), text: text),
  );

  testWidgets(
    'completion keyboard navigation accepts one atomic edit and ignores stale responses',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'doc',
        source: 'bad\r\nsource',
      );
      final focus = FocusNode();
      final provider = _FixtureProvider();
      await mount(tester, controller, focus, provider);
      await _controlKey(tester, LogicalKeyboardKey.space);
      expect(provider.completions, hasLength(1));
      provider.completions.single.complete([item('first'), item('second')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Completions'), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.snapshot.selection.extentOffset, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(controller.snapshot.source, 'second\r\nsource');
      expect(controller.snapshot.generation, 1);
      controller.undo();
      expect(controller.snapshot.source, 'bad\r\nsource');
      await tester.pump();
      await _controlKey(tester, LogicalKeyboardKey.space);
      controller.replaceDocument(documentId: 'next', source: 'loaded');
      provider.completions.last.complete([item('stale')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('stale'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'hover and diagnostics use visible geometry; diagnostics navigate exact ranges',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'doc',
        source: 'bad\r\nsource',
      );
      final focus = FocusNode();
      final provider = _FixtureProvider();
      await mount(tester, controller, focus, provider);
      await _controlKey(tester, LogicalKeyboardKey.keyK);
      await tester.pump();
      await tester.pump();
      expect(find.text('Plain hover information'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(find.text('Plain hover information'), findsNothing);
      await tester.tap(find.byTooltip('Editor commands'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Refresh diagnostics'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Refresh diagnostics'));
      await tester.pumpAndSettle();
      expect(
        find.text('Warning on line 1: Example diagnostic'),
        findsOneWidget,
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('editor-diagnostic-markers')),
                  )
                  .painter!
              as EditorDiagnosticMarkers;
      expect(painter.diagnostics, hasLength(1));
      final rect = painter.geometry
          .range(painter.diagnostics.single.range)
          .single;
      expect(rect.width, greaterThan(0));
      expect(rect.left, greaterThanOrEqualTo(painter.geometry.gutter.dx));
      await tester.tap(find.text('Warning on line 1: Example diagnostic'));
      expect(
        controller.snapshot.selection,
        const TextSelection(baseOffset: 0, extentOffset: 3),
      );
      controller.replaceDocument(documentId: 'doc', source: 'new');
      await tester.pump();
      await tester.pump();
      expect(find.text('Warning on line 1: Example diagnostic'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets('pointer hover remains available after geometry changes', (
    tester,
  ) async {
    final controller = BirbEditorController(
      documentId: 'pointer',
      source: 'bad\nsource',
    );
    final focus = FocusNode();
    await mount(tester, controller, focus, _FixtureProvider());
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('editor-focus-border'));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('editor-diagnostic-markers')),
                )
                .painter!
            as EditorDiagnosticMarkers;
    final point =
        tester.getTopLeft(surface) + painter.geometry.caret(1)!.center;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(point);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();
    expect(find.text('Plain hover information'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.tap(find.byTooltip('Enable wrap'));
    await tester.pumpAndSettle();
    await mouse.moveTo(point + const Offset(1, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();
    expect(find.text('Plain hover information'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    controller.dispose();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets(
    'selection toolbar is keyboard available and readonly disables mutations',
    (tester) async {
      final controller = BirbEditorController(documentId: 'doc', source: 'bad');
      final focus = FocusNode();
      await mount(tester, controller, focus, _FixtureProvider());
      controller.setReadOnly(true);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      await tester.pump();
      expect(find.text('Selection'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cut'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Paste'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Copy'))
            .onPressed,
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Selection'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
