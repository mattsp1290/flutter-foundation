import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    '320 pixel editor at 200 percent text keeps source and controls reachable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = BirbEditorController(
        documentId: 'small',
        source: 'package main\r\nfunc main() { println("hello") }\n',
      );
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 480),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: BirbSourceEditor(controller: controller, focusNode: focus),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final surface = find.byKey(const ValueKey('editor-focus-border'));
      expect(tester.getSize(surface).height, greaterThan(48));
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      final border =
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
      expect((border.border! as Border).top.width, 2);
      await tester.tap(find.byTooltip('Find and replace'));
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Find source'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Find source'),
        'main',
      );
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Close find'));
      await tester.tap(find.byTooltip('Close find'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.snapshot.generation, 0);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
