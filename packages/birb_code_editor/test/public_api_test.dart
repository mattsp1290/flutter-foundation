import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _input(
  WidgetTester tester,
  String text, {
  TextRange composing = TextRange.empty,
}) async {
  final editing = tester.testTextInput.editingState!;
  final client =
      (tester.testTextInput.log
                  .lastWhere((call) => call.method == 'TextInput.setClient')
                  .arguments
              as List)
          .first;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('TextInputClient.updateEditingStateWithDeltas', [
        client,
        {
          'deltas': [
            {
              'oldText': editing['text'],
              'deltaText': text,
              'deltaStart': 0,
              'deltaEnd': (editing['text'] as String).length,
              'selectionBase': text.length,
              'selectionExtent': text.length,
              'selectionAffinity': 'TextAffinity.downstream',
              'selectionIsDirectional': false,
              'composingBase': composing.start,
              'composingExtent': composing.end,
            },
          ],
        },
      ]),
    ),
    (_) {},
  );
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    BirbEditorController controller,
    FocusNode focus,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: 400,
          child: BirbSourceEditor(controller: controller, focusNode: focus),
        ),
      ),
    ),
  );

  testWidgets(
    'typing after an atomic command has a separate exact undo boundary',
    (tester) async {
      const tail = '\r\nend\rlast\n';
      final controller = BirbEditorController(
        documentId: 'history',
        source: 'ab$tail',
      );
      final focus = FocusNode();
      await mount(tester, controller, focus);
      focus.requestFocus();
      await tester.pump();
      await _input(tester, 'abc');
      controller.applyEdits(
        expectedDocumentId: 'history',
        expectedGeneration: controller.snapshot.generation,
        edits: const [
          BirbEditorEdit(range: TextRange(start: 1, end: 2), text: 'B'),
        ],
      );
      final completed = controller.snapshot;
      await tester.pump();
      await _input(tester, 'aBcx');
      controller.undo();
      expect(controller.snapshot.source, 'aBc$tail');
      expect(controller.snapshot.selection, completed.selection);
      controller.undo();
      expect(controller.snapshot.source, 'abc$tail');
      expect(controller.snapshot.selection.extentOffset, 3);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'keyboard Enter preserves logical positions when mixed separators join',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'mixed',
        source: 'x\ra\n\nb',
      );
      final focus = FocusNode();
      await mount(tester, controller, focus);
      controller.setSelection(const TextSelection.collapsed(offset: 4));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(controller.snapshot.source, 'x\ra\n\r\nb');
      expect(
        controller.snapshot.selection,
        const TextSelection.collapsed(offset: 6),
      );
      expect(
        controller.setSelection(const TextSelection.collapsed(offset: 7)),
        BirbEditorEditResult.applied,
      );
      await _input(tester, 'bc');
      expect(controller.snapshot.source, 'x\ra\n\r\nbc');
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'public view publishes composing input synchronously and rejects transactions during composition',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'doc',
        source: 'hello',
      );
      final focus = FocusNode();
      await mount(tester, controller, focus);
      focus.requestFocus();
      await tester.pump();
      final observed = <BirbEditorSnapshot>[];
      controller.addTextListener(observed.add);
      await _input(
        tester,
        'hello中',
        composing: const TextRange(start: 5, end: 6),
      );
      expect(controller.snapshot.source, 'hello中');
      expect(observed.single.source, 'hello中');
      expect(controller.snapshot.composing, const TextRange(start: 5, end: 6));
      expect(
        controller.applyEdits(
          expectedDocumentId: 'doc',
          expectedGeneration: 1,
          edits: const [
            BirbEditorEdit(range: TextRange(start: 0, end: 0), text: 'bad'),
          ],
        ),
        BirbEditorEditResult.composing,
      );
      await _input(tester, 'hello中文');
      expect(observed.map((value) => value.generation), [1, 2]);
      expect(controller.snapshot.composing, TextRange.empty);
      await tester.pumpWidget(const SizedBox());
      focus.addListener(() {});
      focus.dispose();
      controller.undo();
      expect(controller.snapshot.source, 'hello');
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'readonly transition rejects input before rebuild and reload retires the old engine',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'doc',
        source: 'hello',
      );
      final focus = FocusNode();
      await mount(tester, controller, focus);
      focus.requestFocus();
      await tester.pump();
      controller.setReadOnly(true);
      await _input(tester, 'forbidden');
      expect(controller.snapshot.source, 'hello');
      controller.setReadOnly(false);
      controller.replaceDocument(documentId: 'next', source: 'loaded');
      await _input(tester, 'obsolete');
      expect(controller.snapshot.source, 'loaded');
      await tester.pump();
      await tester.pump();
      focus.requestFocus();
      await tester.pump();
      await _input(tester, 'current');
      expect(controller.snapshot.source, 'current');
      expect(controller.snapshot.documentId, 'next');
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets('view remount and controller swap preserve independent history', (
    tester,
  ) async {
    final first = BirbEditorController(documentId: 'first', source: 'one');
    final second = BirbEditorController(documentId: 'second', source: 'two');
    final focus = FocusNode();
    await mount(tester, first, focus);
    focus.requestFocus();
    await tester.pump();
    await _input(tester, 'edited');
    await mount(tester, second, focus);
    expect(first.snapshot.source, 'edited');
    expect(second.snapshot.source, 'two');
    await tester.pumpWidget(const SizedBox());
    await mount(tester, first, focus);
    expect(first.snapshot.selection.extentOffset, 6);
    first.undo();
    expect(first.snapshot.source, 'one');
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('scroll and source survive detach and sequential remount', (
    tester,
  ) async {
    final source = List.generate(200, (i) => 'var line$i = $i').join('\r\n');
    final controller = BirbEditorController(
      documentId: 'scroll',
      source: source,
    );
    final focus = FocusNode();
    double scrollOffset() => tester
        .stateList<ScrollableState>(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.label == 'Go source',
            ),
            matching: find.byType(Scrollable),
          ),
        )
        .where((state) => state.axisDirection == AxisDirection.down)
        .single
        .position
        .pixels;
    await mount(tester, controller, focus);
    await tester.dragFrom(const Offset(320, 240), const Offset(0, -600));
    await tester.pumpAndSettle();
    final offset = scrollOffset();
    expect(offset, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    await mount(tester, controller, focus);
    await tester.pump();
    expect(scrollOffset(), closeTo(offset, 1));
    expect(controller.snapshot.source, source);
    expect(controller.snapshot.generation, 0);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    controller.dispose();
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets(
    'two mounted editors remain independent and release their borrowed focus nodes',
    (tester) async {
      final first = BirbEditorController(documentId: 'first', source: 'one');
      final second = BirbEditorController(documentId: 'second', source: 'two');
      final focus = FocusNode();
      final otherFocus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: BirbSourceEditor(controller: first, focusNode: focus),
                ),
                Expanded(
                  child: BirbSourceEditor(
                    controller: second,
                    focusNode: otherFocus,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await _input(tester, 'first change');
      otherFocus.requestFocus();
      await tester.pump();
      await _input(tester, 'second change');
      first.undo();
      expect(first.snapshot.source, 'one');
      expect(second.snapshot.source, 'second change');
      expect(() => first.dispose(), throwsStateError);
      await tester.pumpWidget(const SizedBox());
      focus.addListener(() {});
      otherFocus.addListener(() {});
      focus.dispose();
      otherFocus.dispose();
      first.dispose();
      second.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets('simultaneous attachment is rejected explicitly', (tester) async {
    final controller = BirbEditorController(documentId: 'doc');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: BirbSourceEditor(controller: controller)),
              Expanded(child: BirbSourceEditor(controller: controller)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isA<StateError>());
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
