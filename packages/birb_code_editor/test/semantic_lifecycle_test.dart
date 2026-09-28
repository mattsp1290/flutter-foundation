import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Finder sourceField() => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == 'Go source',
);

Widget host(BirbEditorController controller) => MaterialApp(
  home: Scaffold(body: BirbSourceEditor(controller: controller)),
);

void main() {
  for (final transition in [
    'replace',
    'identical reload',
    'detach',
    'swap',
    'swap back',
  ]) {
    testWidgets('obsolete semantic actions reject $transition', (tester) async {
      final controller = BirbEditorController(documentId: 'old', source: 'old');
      final other = BirbEditorController(documentId: 'other', source: 'other');
      await tester.pumpWidget(host(controller));
      final stale = tester.widget<Semantics>(sourceField()).properties;
      if (transition == 'replace') {
        controller.replaceDocument(documentId: 'new', source: 'valuable');
      } else if (transition == 'identical reload') {
        controller.replaceDocument(documentId: 'old', source: 'old');
      } else if (transition == 'detach') {
        await tester.pumpWidget(const SizedBox());
      } else {
        await tester.pumpWidget(host(other));
        if (transition == 'swap back') {
          await tester.pumpWidget(host(controller));
        }
      }
      final before = controller.snapshot;
      stale.onSetText!('obsolete text');
      stale.onSetSelection!(const TextSelection.collapsed(offset: 1));
      stale.onCut!();
      stale.onPaste!();
      expect(controller.snapshot, same(before));
      expect(other.snapshot.source, 'other');
      await tester.pumpWidget(host(controller));
      await tester.pump();
      final valid = tester
          .widget<Semantics>(sourceField())
          .properties
          .onSetText!;
      valid('first');
      valid('second'); // Both events can arrive before the next frame.
      expect(controller.snapshot.source, 'second');
      controller.undo();
      expect(controller.snapshot.source, 'first');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      other.dispose();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  }

  testWidgets('semantic selection and navigation use exact source offsets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = BirbEditorController(
      documentId: 'unicode',
      source: 'a😀\r\nword next',
    );
    await tester.pumpWidget(host(controller));
    controller.setSelection(const TextSelection.collapsed(offset: 1));
    await tester.pump();
    Future<void> move(
      SemanticsAction action,
      bool extend,
      TextSelection expected,
    ) async {
      final node = tester.getSemantics(sourceField());
      expect(node.getSemanticsData().hasAction(action), isTrue);
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: action,
          viewId: tester.view.viewId,
          nodeId: node.id,
          arguments: extend,
        ),
      );
      await tester.pump();
      expect(controller.snapshot.selection.baseOffset, expected.baseOffset);
      expect(controller.snapshot.selection.extentOffset, expected.extentOffset);
      expect(
        tester.getSemantics(sourceField()).getSemanticsData().textSelection,
        controller.snapshot.selection,
      );
      expect(controller.snapshot.generation, 0);
    }

    await move(
      SemanticsAction.moveCursorForwardByCharacter,
      false,
      const TextSelection.collapsed(offset: 3),
    );
    await move(
      SemanticsAction.moveCursorForwardByCharacter,
      true,
      const TextSelection(baseOffset: 3, extentOffset: 5),
    );
    controller.setReadOnly(true);
    controller.setSelection(const TextSelection.collapsed(offset: 5));
    await tester.pump();
    await move(
      SemanticsAction.moveCursorForwardByWord,
      true,
      const TextSelection(baseOffset: 5, extentOffset: 9),
    );
    await move(
      SemanticsAction.moveCursorBackwardByWord,
      false,
      const TextSelection.collapsed(offset: 5),
    );
    await move(
      SemanticsAction.moveCursorBackwardByCharacter,
      false,
      const TextSelection.collapsed(offset: 3),
    );
    await move(
      SemanticsAction.moveCursorBackwardByCharacter,
      false,
      const TextSelection.collapsed(offset: 1),
    );
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    controller.dispose();
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}
