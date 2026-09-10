import 'package:flutter/material.dart';

import '../color/birb_semantic_colors.dart';
import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';
import 'birb_review_style.dart';

/// Reports the resolved state a viewer asked for on one thread.
typedef BirbThreadResolutionRequest = void Function(
  String threadId, {
  required bool resolved,
});

/// Builds the human-readable location text for an anchored thread.
typedef BirbThreadAnchorLabel = String Function(BirbDiffAnchor anchor);

String _defaultAnchorLabel(BirbDiffAnchor anchor) =>
    'On ${anchor.side == BirbDiffSide.before ? 'old' : 'new'} '
    'line ${anchor.lineNumber}';

/// Caller-supplied text for [BirbReviewThreadView].
@immutable
final class BirbReviewThreadLabels {
  const BirbReviewThreadLabels({
    this.generalDiscussion = 'General discussion',
    this.resolvedLabel = 'Resolved',
    this.unresolvedLabel = 'Unresolved',
    this.outdatedLabel = 'Outdated location',
    this.resolveAction = 'Resolve thread',
    this.reopenAction = 'Reopen thread',
    this.pendingLabel = 'Updating thread state',
    this.emptyText = 'No comments yet',
    this.anchorLabel = _defaultAnchorLabel,
  });

  final String generalDiscussion;
  final String resolvedLabel;
  final String unresolvedLabel;
  final String outdatedLabel;
  final String resolveAction;
  final String reopenAction;
  final String pendingLabel;
  final String emptyText;
  final BirbThreadAnchorLabel anchorLabel;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewThreadLabels &&
      other.generalDiscussion == generalDiscussion &&
      other.resolvedLabel == resolvedLabel &&
      other.unresolvedLabel == unresolvedLabel &&
      other.outdatedLabel == outdatedLabel &&
      other.resolveAction == resolveAction &&
      other.reopenAction == reopenAction &&
      other.pendingLabel == pendingLabel &&
      other.emptyText == emptyText &&
      other.anchorLabel == anchorLabel;

  @override
  int get hashCode => Object.hash(
    generalDiscussion,
    resolvedLabel,
    unresolvedLabel,
    outdatedLabel,
    resolveAction,
    reopenAction,
    pendingLabel,
    emptyText,
    anchorLabel,
  );
}

/// One host-controlled review conversation.
///
/// The host owns [thread]. Resolve and reopen only report the requested state
/// through [onResolutionRequested]; this widget never updates the supplied
/// model optimistically. While [isUpdating] the action is disabled and exposes
/// a progress label, and [errorText] stays visible in a scoped live region with
/// retry through the same action.
///
/// Comment bodies are plain text: they wrap, stay selectable, and never execute
/// a link or Markdown. Every comment remains visible when a thread is resolved.
/// An [BirbReviewThread.outdated] thread keeps its recorded location and gets no
/// jump-to-current-line action.
///
/// A host composes a reply editor below this widget; the thread owns neither the
/// draft nor any network operation. See `DESIGN.md` section 10.6.
final class BirbReviewThreadView extends StatelessWidget {
  const BirbReviewThreadView({
    required this.thread,
    super.key,
    this.onResolutionRequested,
    this.isUpdating = false,
    this.errorText,
    this.labels = const BirbReviewThreadLabels(),
  });

  /// The conversation to render.
  final BirbReviewThread thread;

  /// Reports the resolved state the viewer asked for. Null hides the action.
  final BirbThreadResolutionRequest? onResolutionRequested;

  /// Whether the host is applying a resolve or reopen request.
  final bool isUpdating;

  /// A visible, retryable failure for the last resolve or reopen request.
  final String? errorText;

  /// Overridable display text.
  final BirbReviewThreadLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = theme.extension<BirbSemanticColors>()!;
    final anchor = thread.anchor;
    final location = anchor == null
        ? labels.generalDiscussion
        : labels.anchorLabel(anchor);
    final error = errorText;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(BirbReviewStyle.objectSide(theme)),
        borderRadius: BirbRadii.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BirbSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: BirbSpacing.space2,
              runSpacing: BirbSpacing.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(location, style: theme.textTheme.titleSmall),
                _StateLabel(
                  text: thread.resolved
                      ? labels.resolvedLabel
                      : labels.unresolvedLabel,
                  icon: thread.resolved
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
                if (thread.outdated)
                  _StateLabel(text: labels.outdatedLabel, icon: Icons.history),
              ],
            ),
            const SizedBox(height: BirbSpacing.space2),
            if (thread.comments.isEmpty)
              Text(labels.emptyText, style: theme.textTheme.bodyMedium)
            else
              for (final comment in thread.comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: BirbSpacing.space3),
                  child: _Comment(comment: comment),
                ),
            if (onResolutionRequested != null) ...<Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: BirbReviewThreadKeys.resolutionAction,
                  onPressed: isUpdating
                      ? null
                      : () => onResolutionRequested!(
                          thread.id,
                          resolved: !thread.resolved,
                        ),
                  icon: isUpdating
                      ? SizedBox.square(
                          dimension: BirbSpacing.space4,
                          child: CircularProgressIndicator(
                            strokeWidth: BirbBorders.strong,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : Icon(thread.resolved ? Icons.replay : Icons.check),
                  // The visible label is the live region, so progress is
                  // announced once and stays navigable, instead of duplicating
                  // it in a zero-area shadow node.
                  label: Semantics(
                    key: BirbReviewThreadKeys.pendingStatus,
                    liveRegion: isUpdating,
                    child: Text(
                      isUpdating
                          ? labels.pendingLabel
                          : thread.resolved
                          ? labels.reopenAction
                          : labels.resolveAction,
                    ),
                  ),
                ),
              ),
            ],
            if (error != null) ...<Widget>[
              const SizedBox(height: BirbSpacing.space1),
              Semantics(
                key: BirbReviewThreadKeys.errorStatus,
                container: true,
                liveRegion: true,
                label: 'Error: $error',
                child: ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: semantics.errorIndicator,
                        size: BirbSpacing.space4,
                      ),
                      const SizedBox(width: BirbSpacing.space1),
                      Expanded(
                        child: Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: semantics.errorIndicator,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stable lookup keys for [BirbReviewThreadView].
abstract final class BirbReviewThreadKeys {
  static const ValueKey<String> resolutionAction = ValueKey<String>(
    'birb-review-thread-resolution',
  );

  /// The action label, which becomes the live progress region while pending.
  static const ValueKey<String> pendingStatus = ValueKey<String>(
    'birb-review-thread-pending',
  );
  static const ValueKey<String> errorStatus = ValueKey<String>(
    'birb-review-thread-error',
  );

  /// The rendered body of the comment identified by [commentId].
  static ValueKey<String> commentBody(String commentId) =>
      ValueKey<String>('birb-review-comment-$commentId');
}

class _StateLabel extends StatelessWidget {
  const _StateLabel({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: BirbSpacing.space4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: BirbSpacing.space1),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.comment});

  final BirbReviewComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${comment.author} · ${comment.timestamp}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: BirbSpacing.space1),
        SelectableText(
          comment.body,
          key: BirbReviewThreadKeys.commentBody(comment.id),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
