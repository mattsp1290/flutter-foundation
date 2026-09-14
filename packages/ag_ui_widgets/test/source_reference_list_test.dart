import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:ag_ui_widgets/ag_ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders bounded source text and delegates only its opaque value',
    (tester) async {
      SourceReferenceView? opened;
      final reference = SourceReferenceView(
        id: 'opaque-source',
        parentMessageId: 'assistant-1',
        label: 'Example source',
        passage: 'first line\nsecond line',
        startLine: 8,
        revisionLabel: 'r1',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SourceReferenceList(
              references: [reference],
              onOpen: (value) => opened = value,
            ),
          ),
        ),
      );
      expect(find.textContaining('8: first line'), findsOneWidget);
      await tester.tap(find.text('Example source'));
      expect(opened, same(reference));
    },
  );
}
