import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pending send leaves later drafting enabled and never clears text',
    (tester) async {
      final controller = TextEditingController(text: 'first');
      addTearDown(controller.dispose);
      final sent = <String>[];
      Widget app(bool pending) => MaterialApp(
        theme: BirbTheme.light,
        home: Scaffold(
          body: BirbChatComposer(
            controller: controller,
            submitting: pending,
            onSubmit: sent.add,
          ),
        ),
      );
      await tester.pumpWidget(app(false));
      await tester.tap(find.text('Send message'));
      await tester.pump();
      expect(sent, ['first']);
      await tester.pumpWidget(app(true));
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      await tester.enterText(find.byType(TextField), 'next draft');
      await tester.tap(find.text('Sending…'));
      await tester.pumpWidget(app(false));
      expect(controller.text, 'next draft');
      expect(sent, ['first']);
    },
  );
  testWidgets('blank drafts rejected and message updates stay selectable', (
    tester,
  ) async {
    final controller = TextEditingController(text: '  ');
    addTearDown(controller.dispose);
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: BirbTheme.dark,
        home: Scaffold(
          body: Column(
            children: [
              const BirbChatMessage(
                author: 'Coach',
                text: '<literal> reply',
                streaming: true,
              ),
              BirbChatComposer(
                controller: controller,
                onSubmit: (_) => count++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Send message'));
    await tester.pump();
    expect(count, 0);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Responding…'), findsOneWidget);
    expect(find.text('Write a message before sending.'), findsOneWidget);
  });
}
