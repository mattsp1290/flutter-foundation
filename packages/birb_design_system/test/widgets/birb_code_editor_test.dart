import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final preset in BirbCodeTheme.values) {
    for (final theme in [BirbTheme.light, BirbTheme.dark]) {
      test('${preset.name} readable token palette in ${theme.brightness}', () {
        final c = preset.resolve(theme);
        for (final foreground in [
          c.foreground,
          c.comment,
          c.gutter,
          c.keyword,
          c.string,
          c.number,
        ]) {
          final a = foreground.computeLuminance(),
              b = c.background.computeLuminance();
          final ratio =
              (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
      });
    }
  }
  testWidgets('gutter follows native wrapping at caret-width boundaries', (
    tester,
  ) async {
    final controller = BirbCodeController(text: '${'x' * 24}\nsecond\n');
    addTearDown(controller.dispose);
    for (final width in [319.0, 320.0, 321.0, 340.0, 350.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirbTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 240,
              child: BirbCodeEditor(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump();
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final gutterFinder = find
          .descendant(
            of: find.byType(BirbCodeEditor),
            matching: find.byType(CustomPaint),
          )
          .evaluate()
          .where((e) => (e.widget as CustomPaint).painter != null)
          .first;
      final gutter = gutterFinder.renderObject! as RenderCustomPaint;
      final pattern = paints;
      for (final start in [0, 25, 32]) {
        final top = gutter
            .globalToLocal(
              editable.localToGlobal(
                editable
                    .getLocalRectForCaret(TextPosition(offset: start))
                    .topLeft,
              ),
            )
            .dy;
        pattern.paragraph(
          offset: predicate<Offset>((offset) => (offset.dy - top).abs() < .01),
        );
      }
      expect(
        (Canvas canvas) => gutter.painter!.paint(canvas, gutter.size),
        pattern,
      );
    }
  });
  testWidgets(
    'native editing preserves source, composition and borrowed state',
    (tester) async {
      final controller = BirbCodeController(
        text: 'package solution\n// λ\t\nvar s = `hello`\n',
      );
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: BirbTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: BirbCodeEditor(
                controller: controller,
                focusNode: focus,
                label: 'Go source code',
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        withComposing: false,
      );
      expect(span.toPlainText(), controller.text);
      expect(
        span.children!.whereType<TextSpan>().any(
          (s) => s.text == 'package' && s.style?.fontWeight == FontWeight.bold,
        ),
        isTrue,
      );
      await tester.enterText(
        find.byType(TextField),
        'package solution\nvar s = "未完成',
      );
      expect(controller.text, 'package solution\nvar s = "未完成');
      controller.value = controller.value.copyWith(
        composing: TextRange(start: 0, end: 7),
      );
      expect(
        controller
            .buildTextSpan(context: context, withComposing: true)
            .toPlainText(),
        controller.text,
      );
      await tester.pumpWidget(const SizedBox());
      controller.text = 'still owned';
      expect(controller.text, 'still owned');
    },
  );
  testWidgets(
    'narrow large text, long lines, readonly and theme switch retain value',
    (tester) async {
      final source =
          'package solution\n${'// long source ' * 40}\n\tvar x = 123\n';
      final controller = BirbCodeController(text: source);
      addTearDown(controller.dispose);
      for (final preset in BirbCodeTheme.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: BirbTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 300,
                  child: BirbCodeEditor(
                    controller: controller,
                    theme: preset,
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<TextField>(find.byType(TextField)).readOnly,
          isTrue,
        );
        expect(controller.text, source);
        await tester.drag(find.byType(TextField), const Offset(0, -200));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('empty and trailing-line editor renders and does not rewrite', (
    tester,
  ) async {
    final controller = BirbCodeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirbTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 250,
            child: BirbCodeEditor(controller: controller),
          ),
        ),
      ),
    );
    for (final source in ['', '\n', '\n\n', 'a\n']) {
      controller.text = source;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.text, source);
    }
  });
}
