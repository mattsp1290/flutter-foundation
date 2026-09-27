import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'source exposes an editable semantic field and guards readonly actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BirbEditorController(
        documentId: 'semantic',
        source: 'package main\r\n',
      );
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirbSourceEditor(controller: controller, focusNode: focus),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      final source = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Go source',
      );
      var data = tester.getSemantics(source).getSemanticsData();
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.value, 'package main\r\n');
      final properties = tester.widget<Semantics>(source).properties;
      properties.onSetText!('package changed\r\n');
      expect(controller.snapshot.source, 'package changed\r\n');
      controller.undo();
      expect(controller.snapshot.source, 'package main\r\n');
      controller.setReadOnly(true);
      // Even a semantic callback captured before the readonly frame is guarded.
      properties.onSetText!('stale mutation');
      expect(controller.snapshot.source, 'package main\r\n');
      await tester.pump();
      await tester.pump();
      data = tester.getSemantics(source).getSemanticsData();
      expect(data.flagsCollection.isReadOnly, isTrue);
      expect(tester.widget<Semantics>(source).properties.onSetText, isNull);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      focus.dispose();
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

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
