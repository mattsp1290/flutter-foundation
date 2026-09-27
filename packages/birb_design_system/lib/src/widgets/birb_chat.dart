import 'package:flutter/material.dart';

import 'birb_text_form_field.dart';

/// Plain-text chat presentation. The host owns message identity and streaming.
class BirbChatMessage extends StatelessWidget {
  const BirbChatMessage({
    super.key,
    required this.author,
    required this.text,
    this.streaming = false,
    this.status,
    this.actions = const [],
  });
  final String author;
  final String text;
  final bool streaming;
  final String? status;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: author,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(author, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(text),
          if (streaming || status != null)
            Semantics(liveRegion: true, child: Text(status ?? 'Responding…')),
          if (actions.isNotEmpty) Wrap(spacing: 8, children: actions),
        ],
      ),
    ),
  );
}

/// Borrows editing state; submitting blocks duplicate sends, not newer typing.
/// The host clears drafts only after a confirmed response for that exact text.
class BirbChatComposer extends StatefulWidget {
  const BirbChatComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.submitting = false,
    this.readOnly = false,
    this.label = 'Message',
    this.sendLabel = 'Send message',
    this.errorText,
    this.onRetry,
    this.beforeSubmit,
    this.editorIdentifier,
  });
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmit;
  final bool submitting, readOnly;
  final String label, sendLabel;
  final String? errorText, editorIdentifier;
  final VoidCallback? onRetry;
  final Widget? beforeSubmit;
  @override
  State<BirbChatComposer> createState() => _BirbChatComposerState();
}

class _BirbChatComposerState extends State<BirbChatComposer> {
  bool _activated = false;
  String? _validation;
  void _send() {
    if (_activated ||
        widget.submitting ||
        widget.readOnly ||
        widget.onSubmit == null) {
      return;
    }
    final text = widget.controller.text;
    if (text.trim().isEmpty) {
      setState(() => _validation = 'Write a message before sending.');
      return;
    }
    setState(() {
      _activated = true;
      _validation = null;
    });
    try {
      widget.onSubmit!(text);
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activated = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        container: true,
        explicitChildNodes: true,
        identifier: widget.editorIdentifier,
        child: BirbTextFormField(
          label: widget.label,
          controller: widget.controller,
          focusNode: widget.focusNode,
          minLines: 2,
          maxLines: 6,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.multiline,
          errorText: widget.errorText ?? _validation,
        ),
      ),
      if (widget.beforeSubmit != null) widget.beforeSubmit!,
      if (widget.errorText != null && widget.onRetry != null)
        TextButton(
          onPressed: widget.submitting || widget.readOnly
              ? null
              : widget.onRetry,
          child: const Text('Retry message'),
        ),
      FilledButton(
        onPressed:
            widget.submitting ||
                widget.readOnly ||
                _activated ||
                widget.onSubmit == null
            ? null
            : _send,
        child: Text(widget.submitting ? 'Sending…' : widget.sendLabel),
      ),
    ],
  );
}
