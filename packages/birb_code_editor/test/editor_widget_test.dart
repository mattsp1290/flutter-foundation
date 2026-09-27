import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'find replacement uses one transaction and reports malformed regex',
    (tester) async {
      final controller = BirbEditorController(
        documentId: 'find',
        source: 'go\r\nGo\rgo\n',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BirbSourceEditor(controller: controller)),
        ),
      );
      await tester.tap(find.byTooltip('Find and replace'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Find source'),
        'go',
      );
      await tester.pump();
      expect(find.text('1 of 3 matches'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Replace with (literal text)'),
        'package',
      );
      await tester.tap(find.text('Replace all'));
      expect(controller.snapshot.source, 'package\r\npackage\rpackage\n');
      expect(controller.snapshot.generation, 1);
      controller.undo();
      expect(controller.snapshot.source, 'go\r\nGo\rgo\n');
      await tester.pump();
      await tester.tap(find.text('Regex'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Find source'),
        '[',
      );
      await tester.pump();
      expect(find.text('Invalid regular expression'), findsOneWidget);
      controller.setReadOnly(true);
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Replace all'))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'Escape closes find before enabling Tab traversal; Tab exits in both directions',
    (tester) async {
      final controller = BirbEditorController(documentId: 'keys', source: 'go');
      final sourceFocus = FocusNode();
      final before = FocusNode();
      final after = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextButton(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before editor'),
                ),
                Expanded(
                  child: BirbSourceEditor(
                    controller: controller,
                    focusNode: sourceFocus,
                  ),
                ),
                TextButton(
                  focusNode: after,
                  onPressed: () {},
                  child: const Text('After editor'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Find and replace'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Find source'), findsNothing);
      expect(sourceFocus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(
        find.text('Tab moves focus — restore indentation'),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        after.hasFocus,
        isTrue,
        reason:
            'Focused node: ${FocusManager.instance.primaryFocus?.debugLabel}',
      );
      sourceFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(before.hasFocus, isTrue);
      expect(controller.snapshot.source, 'go');
      await tester.pumpWidget(const SizedBox());
      sourceFocus.dispose();
      before.dispose();
      after.dispose();
      controller.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
