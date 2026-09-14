import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:ag_ui_widgets/ag_ui_widgets.dart';
import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';

final class BirbAgentConversationLabels {
  const BirbAgentConversationLabels({
    this.send = 'Send message',
    this.stop = 'Stop run',
    this.failurePrefix = 'Run issue',
  });
  final String send;
  final String stop;
  final String failurePrefix;
  @override
  bool operator ==(Object other) =>
      other is BirbAgentConversationLabels &&
      other.send == send &&
      other.stop == stop &&
      other.failurePrefix == failurePrefix;
  @override
  int get hashCode => Object.hash(send, stop, failurePrefix);
}

final class BirbAgentConversation extends StatelessWidget {
  const BirbAgentConversation({
    required this.state,
    required this.controller,
    required this.focusNode,
    this.onSend,
    this.onStop,
    this.onSourceOpen,
    this.header,
    this.approval,
    this.persistentHostAction,
    this.footer,
    this.labels = const BirbAgentConversationLabels(),
    super.key,
  });
  final AgentViewState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function(String)? onSend;
  final Future<void> Function()? onStop;
  final ValueChanged<SourceReferenceView>? onSourceOpen;
  final Widget? header;
  final Widget? approval;
  final Widget? persistentHostAction;
  final Widget? footer;
  final BirbAgentConversationLabels labels;

  @override
  Widget build(BuildContext context) {
    final busy =
        state.runPhase == RunPhase.submitting ||
        state.runPhase == RunPhase.running ||
        state.runPhase == RunPhase.interrupting;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: BirbBorders.strong,
        ),
        borderRadius: BirbRadii.pixel,
      ),
      child: Column(
        children: [
          if (header != null) header!,
          if (persistentHostAction != null) persistentHostAction!,
          Expanded(
            child: TranscriptView(
              messages: state.messages,
              omittedOlderMessages: state.omittedOlderMessages,
              isStale: state.isStale,
              sourceReferences: state.sourceReferences,
              onSourceOpen: onSourceOpen,
            ),
          ),
          ToolActivityList(tools: state.tools, runPhase: state.runPhase),
          if (approval != null) approval!,
          if (state.failure case final failure?)
            Semantics(
              liveRegion: true,
              child: Text('${labels.failurePrefix}: ${failure.safeMessage}'),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AgentInput(
              controller: controller,
              focusNode: focusNode,
              enabled: onSend != null,
              busy: busy,
              onSubmit: onSend ?? (_) async {},
              onInterrupt: onStop,
              submitLabel: labels.send,
              interruptLabel: labels.stop,
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
