import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:birb_ag_ui_widgets/birb_ag_ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delegates source callbacks without owning host resources', (
    tester,
  ) async {
    final text = TextEditingController();
    final focus = FocusNode();
    SourceReferenceView? opened;
    final reference = SourceReferenceView(
      id: 'opaque',
      parentMessageId: 'a',
      label: 'Source',
      passage: 'text',
      startLine: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirbAgentConversation(
            state: AgentViewState(
              messages: const [
                MessageView(
                  id: 'a',
                  role: ViewMessageRole.assistant,
                  text: 'reply',
                ),
              ],
              sourceReferences: [reference],
            ),
            controller: text,
            focusNode: focus,
            onSourceOpen: (value) => opened = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Source'));
    expect(opened, same(reference));
    expect(text.hasListeners, isFalse);
    text.dispose();
    focus.dispose();
  });
}
