part of 'birb_diff_view.dart';

/// Builds the accessible label for a line action.
typedef BirbDiffLineLabelBuilder = String Function(BirbDiffLine line);

String _defaultCommentActionLabel(BirbDiffLine line) =>
    'Comment on ${BirbReviewStyle.lineKindLabel(line.kind).toLowerCase()} '
    'line ${line.anchoredNumber}';

String _defaultActiveLineLabel(BirbDiffLine line) {
  final positions = <String>[
    if (line.oldNumber != null) 'old line ${line.oldNumber}',
    if (line.newNumber != null) 'new line ${line.newNumber}',
  ].join(', ');
  return '${BirbReviewStyle.lineKindLabel(line.kind)} $positions';
}

/// Caller-supplied text for [BirbDiffView].
///
/// Defaults are English. Hosts localize by supplying their own values, and
/// hosts localize accessible line descriptions through the two builders.
///
/// This class compares by value, and that comparison is load-bearing:
/// [BirbDiffView] re-measures every line's description when its labels change,
/// so an identity-only comparison would make a host that builds labels inside
/// `build()` pay that O(lines) cost on every frame.
@immutable
final class BirbDiffViewLabels {
  const BirbDiffViewLabels({
    this.emptyText = 'No textual changes',
    this.binaryText = 'Binary file. No text diff is shown.',
    this.unavailableText = 'Source content is unavailable for this revision.',
    this.navigationLabel = 'Diff source navigation',
    this.keyboardHelp =
        'Keyboard: Up and Down move the active line. Home and End jump to the '
        'first and last line. Left and Right scroll the source. F2 selects the '
        'active line source text, Escape returns here. Tab moves to the line '
        'actions and then out of the diff.',
    this.horizontalScrollLabel = 'Scroll source text horizontally',
    this.copyActionLabel = 'Copy source line',
    this.selectSourceActionLabel = 'Select source text (F2)',
    this.noActiveLineText = 'No active line',
    this.sourceSelectionLabel = 'Active line source text',
    this.noFinalNewlineText = 'No newline at end of file',
    this.renamedFrom = 'Renamed from',
    this.additions = 'additions',
    this.deletions = 'deletions',
    this.commentAction = _defaultCommentActionLabel,
    this.activeLine = _defaultActiveLineLabel,
  });

  final String emptyText;
  final String binaryText;
  final String unavailableText;
  final String navigationLabel;
  final String keyboardHelp;
  final String horizontalScrollLabel;
  final String copyActionLabel;
  final String selectSourceActionLabel;
  final String noActiveLineText;
  final String sourceSelectionLabel;
  final String noFinalNewlineText;
  final String renamedFrom;
  final String additions;
  final String deletions;
  final BirbDiffLineLabelBuilder commentAction;
  final BirbDiffLineLabelBuilder activeLine;

  @override
  bool operator ==(Object other) =>
      other is BirbDiffViewLabels &&
      other.emptyText == emptyText &&
      other.binaryText == binaryText &&
      other.unavailableText == unavailableText &&
      other.navigationLabel == navigationLabel &&
      other.keyboardHelp == keyboardHelp &&
      other.horizontalScrollLabel == horizontalScrollLabel &&
      other.copyActionLabel == copyActionLabel &&
      other.selectSourceActionLabel == selectSourceActionLabel &&
      other.noActiveLineText == noActiveLineText &&
      other.sourceSelectionLabel == sourceSelectionLabel &&
      other.noFinalNewlineText == noFinalNewlineText &&
      other.renamedFrom == renamedFrom &&
      other.additions == additions &&
      other.deletions == deletions &&
      other.commentAction == commentAction &&
      other.activeLine == activeLine;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    emptyText,
    binaryText,
    unavailableText,
    navigationLabel,
    keyboardHelp,
    horizontalScrollLabel,
    copyActionLabel,
    selectSourceActionLabel,
    noActiveLineText,
    sourceSelectionLabel,
    noFinalNewlineText,
    renamedFrom,
    additions,
    deletions,
    commentAction,
    activeLine,
  ]);
}

/// Stable lookup keys for [BirbDiffView] regions, rows, and actions.
///
/// Catalogs and tests address the diff through these keys.
abstract final class BirbDiffViewKeys {
  static const ValueKey<String> root = ValueKey<String>('birb-diff-view');
  static const ValueKey<String> navigationRegion = ValueKey<String>(
    'birb-diff-navigation',
  );
  static const ValueKey<String> horizontalScroll = ValueKey<String>(
    'birb-diff-horizontal-scroll',
  );
  static const ValueKey<String> activeLineDescription = ValueKey<String>(
    'birb-diff-active-line',
  );
  static const ValueKey<String> commentAction = ValueKey<String>(
    'birb-diff-comment-action',
  );
  static const ValueKey<String> copyAction = ValueKey<String>(
    'birb-diff-copy-action',
  );
  static const ValueKey<String> selectSourceAction = ValueKey<String>(
    'birb-diff-select-source-action',
  );
  static const ValueKey<String> sourceSelectionField = ValueKey<String>(
    'birb-diff-source-selection-field',
  );
  static const ValueKey<String> unavailableMessage = ValueKey<String>(
    'birb-diff-unavailable-message',
  );

  /// The row rendering the line identified by [lineId].
  static ValueKey<String> line(String lineId) =>
      ValueKey<String>('birb-diff-line-$lineId');

  /// The heading row of the hunk identified by [hunkId].
  static ValueKey<String> heading(String hunkId) =>
      ValueKey<String>('birb-diff-heading-$hunkId');

  /// Whether [key] identifies a rendered source row.
  static bool isLineKey(Object? key) =>
      key is ValueKey<String> && key.value.startsWith('birb-diff-line-');
}
