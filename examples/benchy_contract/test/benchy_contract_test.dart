import 'package:benchy_contract/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the host abort separate from chat controls', (
    tester,
  ) async {
    await tester.pumpWidget(const BenchyContractApp());

    expect(find.text('Synthetic host-authority fixture'), findsOneWidget);
    expect(find.text('Simulated hardware abort'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    // The selectable fixture caption also uses EditableText. Only the chat
    // composer should accept input; readonly selection is not a chat control.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EditableText && !widget.readOnly,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.readOnly,
      ),
      findsOneWidget,
    );
  });
}
