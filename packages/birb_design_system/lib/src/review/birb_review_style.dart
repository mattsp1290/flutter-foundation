import 'package:flutter/material.dart';

import '../color/birb_semantic_colors.dart';
import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';

/// One filled pair of existing semantic roles.
typedef BirbReviewRoles = ({Color background, Color foreground});

/// Semantic role resolution for the review components.
///
/// Every value comes from the ambient [ColorScheme] or [BirbSemanticColors].
/// Nothing here constructs a color, transforms one, or reads the private
/// palette, and no field is added to [BirbSemanticColors]. `DESIGN.md`
/// section 9 is the authority for each mapping; this class exists so hosts and
/// contrast tests can enumerate the same pairs the widgets paint.
///
/// Source-text transformations live in [BirbSourceText]: this class resolves
/// presentation, it does not process content.
abstract final class BirbReviewStyle {
  /// Platform monospace families for source code, best match first.
  ///
  /// No font asset is bundled and no remote font is fetched, so an unavailable
  /// family degrades to the next entry.
  static const List<String> codeFontFamilyFallback = <String>[
    'ui-monospace',
    'SFMono-Regular',
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'Courier New',
    'monospace',
  ];

  /// The scoped monospace source-code style.
  ///
  /// Keeps `bodyMedium` size, height, and weight so OS text scaling still
  /// applies. Code text is never shrunk to fit.
  static TextStyle codeTextStyle(ThemeData theme) {
    final body = theme.textTheme.bodyMedium ?? const TextStyle();
    return body.copyWith(
      color: theme.colorScheme.onSurface,
      fontFamily: codeFontFamilyFallback.first,
      fontFamilyFallback: codeFontFamilyFallback.sublist(1),
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  /// The style for a diff row's numeric line-number cells.
  ///
  /// The numbers are part of the scoped monospace exception so they stay
  /// column-aligned with the source beside them.
  static TextStyle gutterTextStyle(ThemeData theme) =>
      codeTextStyle(theme).copyWith(color: theme.colorScheme.onSurfaceVariant);

  /// The style for a row's prose metadata, such as its line description.
  ///
  /// This is ordinary platform typography: the monospace exception covers
  /// source code and the numeric cells, never prose. See `DESIGN.md` 9.1.
  static TextStyle rowMetadataTextStyle(ThemeData theme) =>
      (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );

  /// The style for a hunk heading.
  static TextStyle hunkHeadingTextStyle(ThemeData theme) =>
      codeTextStyle(theme).copyWith(color: theme.colorScheme.onSurfaceVariant);

  /// The fill behind a hunk heading.
  static Color hunkHeadingBackground(ThemeData theme) =>
      theme.colorScheme.surfaceContainerLow;

  /// The fill behind ordinary source rows.
  static Color codeBackground(ThemeData theme) => theme.colorScheme.surface;

  /// The fill behind the host-selected source row.
  static Color selectedRowBackground(ThemeData theme) =>
      theme.colorScheme.surfaceContainerHigh;

  /// The color-independent selection indicator.
  static const IconData selectedRowIcon = Icons.arrow_right;

  /// The boundary drawn around the keyboard-active source row.
  ///
  /// While the diff navigation region owns focus this is the visible focus
  /// indication, so it uses the semantic focus role at [BirbBorders.strong].
  static BorderSide activeRowSide(ThemeData theme, {required bool focused}) {
    final semantics = theme.extension<BirbSemanticColors>()!;
    return focused
        ? BorderSide(color: semantics.focus, width: BirbBorders.strong)
        : BorderSide(color: theme.colorScheme.outline, width: BirbBorders.thin);
  }

  /// Roles for a compact change marker.
  ///
  /// Context lines have no filled marker; they use the ordinary code roles.
  static BirbReviewRoles lineMarker(ThemeData theme, BirbDiffLineKind kind) {
    final colors = theme.colorScheme;
    final semantics = theme.extension<BirbSemanticColors>()!;
    return switch (kind) {
      BirbDiffLineKind.context => (
        background: colors.surface,
        foreground: colors.onSurfaceVariant,
      ),
      BirbDiffLineKind.addition => (
        background: semantics.success,
        foreground: semantics.onSuccess,
      ),
      BirbDiffLineKind.deletion => (
        background: colors.error,
        foreground: colors.onError,
      ),
    };
  }

  /// The literal sign glyph for [kind].
  static String lineSign(BirbDiffLineKind kind) => switch (kind) {
    BirbDiffLineKind.context => ' ',
    BirbDiffLineKind.addition => '+',
    BirbDiffLineKind.deletion => '−',
  };

  /// The accessible kind word for [kind].
  static String lineKindLabel(BirbDiffLineKind kind) => switch (kind) {
    BirbDiffLineKind.context => 'Unchanged',
    BirbDiffLineKind.addition => 'Added',
    BirbDiffLineKind.deletion => 'Removed',
  };

  /// Roles for a review status badge.
  static BirbReviewRoles statusRoles(ThemeData theme, BirbReviewStatus status) {
    final colors = theme.colorScheme;
    final semantics = theme.extension<BirbSemanticColors>()!;
    return switch (status) {
      BirbReviewStatus.pending => (
        background: semantics.warning,
        foreground: semantics.onWarning,
      ),
      BirbReviewStatus.approved => (
        background: semantics.success,
        foreground: semantics.onSuccess,
      ),
      BirbReviewStatus.changesRequested => (
        background: colors.error,
        foreground: colors.onError,
      ),
      BirbReviewStatus.commented => (
        background: semantics.info,
        foreground: semantics.onInfo,
      ),
    };
  }

  /// The paired icon for a review status badge.
  static IconData statusIcon(BirbReviewStatus status) => switch (status) {
    BirbReviewStatus.pending => Icons.schedule,
    BirbReviewStatus.approved => Icons.check,
    BirbReviewStatus.changesRequested => Icons.close,
    BirbReviewStatus.commented => Icons.chat_bubble_outline,
  };

  /// The default human-readable text for a review status badge.
  static String statusLabel(BirbReviewStatus status) => switch (status) {
    BirbReviewStatus.pending => 'Review pending',
    BirbReviewStatus.approved => 'Approved',
    BirbReviewStatus.changesRequested => 'Changes requested',
    BirbReviewStatus.commented => 'Commented',
  };

  /// The default human-readable text for a file change kind.
  static String fileChangeLabel(BirbReviewFileChange change) =>
      switch (change) {
        BirbReviewFileChange.added => 'Added',
        BirbReviewFileChange.modified => 'Modified',
        BirbReviewFileChange.deleted => 'Deleted',
        BirbReviewFileChange.renamed => 'Renamed',
      };

  /// The 1 px top boundary above a hunk heading. See `DESIGN.md` section 9.2.
  static Border hunkHeadingBorder(ThemeData theme) =>
      Border(top: objectSide(theme));

  /// The boundary around one meaningful grouped object.
  static BorderSide objectSide(ThemeData theme) =>
      BorderSide(color: theme.colorScheme.outline, width: BirbBorders.thin);
}
