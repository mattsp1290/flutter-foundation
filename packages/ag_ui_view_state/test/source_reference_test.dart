import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:test/test.dart';

void main() {
  final message = MessageView(
    id: 'assistant',
    role: ViewMessageRole.assistant,
    text: 'answer',
  );
  SourceReferenceView reference({String passage = 'one\ntwo\n'}) =>
      SourceReferenceView(
        id: 'opaque',
        parentMessageId: 'assistant',
        label: 'Source',
        passage: passage,
        startLine: 5,
        highlightStartLine: 6,
        highlightEndLine: 7,
      );

  test('derives inclusive range retaining a final empty line', () {
    expect(reference().endLine, 7);
  });

  test('rejects orphan parents and invalid ranges', () {
    expect(
      () => AgentViewState(sourceReferences: [reference()]),
      throwsArgumentError,
    );
    expect(
      () => SourceReferenceView(
        id: 'id',
        parentMessageId: 'assistant',
        label: 'label',
        passage: 'x',
        startLine: 1,
        highlightStartLine: 2,
        highlightEndLine: 2,
      ),
      throwsArgumentError,
    );
  });

  test(
    'controller preserves, clears, and ignores stale replacements',
    () async {
      final controller = AgentViewController();
      final generation = controller.beginRequest();
      controller.replaceState(
        AgentViewState(messages: [message]),
        generation: generation,
      );
      controller.replaceSourceReferences([reference()], generation: generation);
      expect(controller.state.sourceReferences, hasLength(1));
      controller.beginRequest();
      expect(controller.state.sourceReferences, hasLength(1));
      controller.replaceSourceReferences(const [], generation: generation);
      expect(controller.state.sourceReferences, hasLength(1));
      controller.replaceConversation();
      expect(controller.state.sourceReferences, isEmpty);
      await controller.dispose();
    },
  );
}
