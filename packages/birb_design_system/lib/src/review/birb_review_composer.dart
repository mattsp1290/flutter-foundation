import 'package:flutter/material.dart';

import '../tokens/birb_tokens.dart';
import '../widgets/birb_text_form_field.dart';

/// Caller-supplied text for [BirbReviewComposer].
@immutable
final class BirbReviewComposerLabels {
  const BirbReviewComposerLabels({
    this.caption = 'Reply',
    this.hint = 'Write a plain-text reply',
    this.submitAction = 'Send reply',
    this.cancelAction = 'Discard draft',
    this.pendingLabel = 'Sending reply',
    this.blankDraftError = 'Write something before sending.',
  });

  final String caption;
  final String hint;
  final String submitAction;
  final String cancelAction;
  final String pendingLabel;
  final String blankDraftError;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewComposerLabels &&
      other.caption == caption &&
      other.hint == hint &&
      other.submitAction == submitAction &&
      other.cancelAction == cancelAction &&
      other.pendingLabel == pendingLabel &&
      other.blankDraftError == blankDraftError;

  @override
  int get hashCode => Object.hash(
    caption,
    hint,
    submitAction,
    cancelAction,
    pendingLabel,
    blankDraftError,
  );
}

/// Stable lookup keys for [BirbReviewComposer].
abstract final class BirbReviewComposerKeys {
  static const ValueKey<String> root = ValueKey<String>('birb-review-composer');
  static const ValueKey<String> editor = ValueKey<String>(
    'birb-review-composer-editor',
  );
  static const ValueKey<String> submitAction = ValueKey<String>(
    'birb-review-composer-submit',
  );
  static const ValueKey<String> cancelAction = ValueKey<String>(
    'birb-review-composer-cancel',
  );

  /// The submit label, which becomes the live progress region while pending.
  static const ValueKey<String> pendingStatus = ValueKey<String>(
    'birb-review-composer-pending',
  );
}

/// A multiline reply editor whose asynchronous state the host owns.
///
/// The composer borrows [controller] and [focusNode]: it never disposes them
/// and never clears draft text. A host keys them by thread — or by
/// new-discussion anchor including revision — so a late completion for one
/// draft cannot clear or append to another.
///
/// `Enter` inserts a newline; submission happens only through the labeled
/// button, so a reply is never sent by accident. A whitespace-only draft is
/// rejected with a visible correction; a valid draft is emitted untrimmed.
///
/// While [isSubmitting] the text stays visible and read-only — semantically
/// distinct from `enabled: false`, which blocks input and every callback — the
/// actions are disabled, and progress is announced. A failure keeps the text and
/// shows [errorText] in the existing live correction row so the same action can
/// retry.
///
/// An internal activation guard suppresses repeated submit activations within a
/// single frame and disables the action while it holds, so a double activation
/// cannot send one draft twice. It releases on the next frame and never depends
/// on callback identity, so it can neither deadlock nor be reopened by an
/// unrelated rebuild. See `DESIGN.md` section 9.6.
final class BirbReviewComposer extends StatefulWidget {
  const BirbReviewComposer({
    required this.controller,
    required this.onSubmit,
    super.key,
    this.focusNode,
    this.onCancel,
    this.isSubmitting = false,
    this.errorText,
    this.enabled = true,
    this.labels = const BirbReviewComposerLabels(),
  });

  /// The host-owned draft. Never disposed or cleared by this widget.
  final TextEditingController controller;

  /// The host-owned focus node. Never disposed by this widget.
  final FocusNode? focusNode;

  /// Receives the untrimmed draft text. Null disables submission.
  final ValueChanged<String>? onSubmit;

  /// Discards the draft. Null hides the cancel action.
  final VoidCallback? onCancel;

  /// Whether the host is sending a draft.
  final bool isSubmitting;

  /// A visible, retryable failure for the last submission.
  final String? errorText;

  /// Whether the composer accepts input and emits callbacks at all.
  final bool enabled;

  /// Overridable display text.
  final BirbReviewComposerLabels labels;

  @override
  State<BirbReviewComposer> createState() => _BirbReviewComposerState();
}

class _BirbReviewComposerState extends State<BirbReviewComposer> {
  static const int _minimumLines = 3;
  static const int _maximumLines = 8;

  bool _rejectedBlankDraft = false;

  /// Suppresses repeated activations within one frame.
  bool _awaitingHostRebuild = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleDraftChange);
  }

  @override
  void didUpdateWidget(BirbReviewComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleDraftChange);
      widget.controller.addListener(_handleDraftChange);
      _rejectedBlankDraft = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleDraftChange);
    super.dispose();
  }

  /// Clears the blank-draft correction as soon as the draft becomes valid.
  void _handleDraftChange() {
    if (!_rejectedBlankDraft || !mounted) return;
    if (widget.controller.text.trim().isEmpty) return;
    setState(() => _rejectedBlankDraft = false);
  }

  bool get _interactive =>
      widget.enabled &&
      !widget.isSubmitting &&
      !_awaitingHostRebuild &&
      widget.onSubmit != null;

  void _handleSubmit() {
    if (!_interactive) return;
    final text = widget.controller.text;
    if (text.trim().isEmpty) {
      setState(() => _rejectedBlankDraft = true);
      return;
    }
    setState(() => _awaitingHostRebuild = true);
    widget.onSubmit!(text);
    // The guard only has to survive repeated activations within one frame. A
    // prop-delta release would deadlock against a host that reports the same
    // failure twice, and would be defeated by any host passing an inline
    // callback, so release it on the next frame instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _awaitingHostRebuild) {
        setState(() => _awaitingHostRebuild = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _rejectedBlankDraft
        ? widget.labels.blankDraftError
        : widget.errorText;

    return Column(
      key: BirbReviewComposerKeys.root,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BirbTextFormField(
          key: BirbReviewComposerKeys.editor,
          label: widget.labels.caption,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.isSubmitting,
          hintText: widget.labels.hint,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: _minimumLines,
          maxLines: _maximumLines,
          errorText: error,
        ),
        const SizedBox(height: BirbSpacing.space2),
        Wrap(
          spacing: BirbSpacing.space2,
          runSpacing: BirbSpacing.space2,
          children: <Widget>[
            FilledButton.icon(
              key: BirbReviewComposerKeys.submitAction,
              onPressed: _interactive ? _handleSubmit : null,
              icon: widget.isSubmitting
                  ? SizedBox.square(
                      dimension: BirbSpacing.space4,
                      child: CircularProgressIndicator(
                        strokeWidth: BirbBorders.strong,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              // The visible label is the live region, so progress is announced
              // once and stays navigable.
              label: Semantics(
                key: BirbReviewComposerKeys.pendingStatus,
                liveRegion: widget.isSubmitting,
                child: Text(
                  widget.isSubmitting
                      ? widget.labels.pendingLabel
                      : widget.labels.submitAction,
                ),
              ),
            ),
            if (widget.onCancel != null)
              OutlinedButton.icon(
                key: BirbReviewComposerKeys.cancelAction,
                onPressed: widget.enabled && !widget.isSubmitting
                    ? widget.onCancel
                    : null,
                icon: const Icon(Icons.close),
                label: Text(widget.labels.cancelAction),
              ),
          ],
        ),
      ],
    );
  }
}
