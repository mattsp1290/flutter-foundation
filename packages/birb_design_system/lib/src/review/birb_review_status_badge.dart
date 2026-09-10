import 'package:flutter/material.dart';

import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';
import 'birb_review_style.dart';

/// A review status badge that pairs an icon with human-readable text.
///
/// Status never depends on color alone. The badge is presentation state only:
/// it implies nothing about mergeability or about the viewer's authorization.
/// See `DESIGN.md` section 10.3.
final class BirbReviewStatusBadge extends StatelessWidget {
  const BirbReviewStatusBadge({required this.status, super.key, this.label});

  /// The status to render.
  final BirbReviewStatus status;

  /// Overrides the default English text for [status].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = BirbReviewStyle.statusRoles(theme, status);
    final text = label ?? BirbReviewStyle.statusLabel(status);

    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: roles.background,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BirbSpacing.space2,
              vertical: BirbSpacing.space1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  BirbReviewStyle.statusIcon(status),
                  color: roles.foreground,
                  size: BirbSpacing.space4,
                ),
                const SizedBox(width: BirbSpacing.space1),
                Flexible(
                  child: Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: roles.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
