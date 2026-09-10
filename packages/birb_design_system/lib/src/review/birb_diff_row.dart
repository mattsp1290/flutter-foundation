part of 'birb_diff_view.dart';

/// One flattened list item.
@immutable
sealed class _DiffRow {
  const _DiffRow();
}

/// A hunk heading. Only hunks that have one produce a row, so the heading is
/// non-nullable here.
final class _HeadingRow extends _DiffRow {
  const _HeadingRow({required this.hunkId, required this.heading});

  final String hunkId;
  final String heading;
}

final class _LineRow extends _DiffRow {
  const _LineRow(this.line);

  final BirbDiffLine line;
}

/// How one source row arranges its metadata, gutter, and source column.
///
/// The two layouts differ in four values that must stay consistent with each
/// other — the code inset, the row extent, whether metadata is stacked above
/// the source, and which gutter cells are shown. Modelling them together means
/// choosing the layout once, rather than repeating the same condition at each
/// site and hoping the answers agree.
@immutable
sealed class _DiffRowLayout {
  const _DiffRowLayout({required this.sourceHeight, required this.markerWidth});

  /// The height of the row's source line.
  final double sourceHeight;

  /// The width of the change-marker cell.
  final double markerWidth;

  /// Horizontal space reserved before the source column.
  double get codeInset;

  /// The total height of one source row, excluding padding.
  double get contentHeight;

  /// The metadata line above the source, or null when the gutter is inline.
  Widget? metadata(ThemeData theme, String description);

  /// Wraps the gutter for this layout.
  Widget gutter(Widget child);

  /// The cells shown in the gutter, in order.
  List<Widget> gutterCells(
    ThemeData theme,
    BirbDiffLine line, {
    required Widget selectionCue,
    required Widget changeMarker,
  });
}

/// The wide layout: a fixed-width gutter beside the scrolling source column.
final class _InlineRowLayout extends _DiffRowLayout {
  const _InlineRowLayout({
    required super.sourceHeight,
    required super.markerWidth,
    required this.gutterWidth,
    required this.numberWidth,
  });

  final double gutterWidth;
  final double numberWidth;

  @override
  double get codeInset => gutterWidth;

  @override
  double get contentHeight => sourceHeight;

  @override
  Widget? metadata(ThemeData theme, String description) => null;

  @override
  Widget gutter(Widget child) => SizedBox(width: gutterWidth, child: child);

  @override
  List<Widget> gutterCells(
    ThemeData theme,
    BirbDiffLine line, {
    required Widget selectionCue,
    required Widget changeMarker,
  }) {
    final gutterStyle = BirbReviewStyle.gutterTextStyle(theme);
    Widget number(int? value) => SizedBox(
      width: numberWidth,
      child: Text(
        value?.toString() ?? '',
        style: gutterStyle,
        textAlign: TextAlign.right,
        maxLines: 1,
      ),
    );

    return <Widget>[
      selectionCue,
      number(line.oldNumber),
      number(line.newNumber),
      const SizedBox(width: BirbSpacing.space1),
      changeMarker,
      const SizedBox(width: BirbSpacing.space1),
    ];
  }
}

/// The narrow or large-text layout.
///
/// Metadata reflows above the bounded source viewport and wraps; nothing is
/// shrunk, ellipsized, or pushed off screen.
final class _StackedRowLayout extends _DiffRowLayout {
  const _StackedRowLayout({
    required super.sourceHeight,
    required super.markerWidth,
    required this.metadataHeight,
    required this.selectionCueWidth,
  });

  final double metadataHeight;
  final double selectionCueWidth;

  @override
  double get codeInset => selectionCueWidth + markerWidth + BirbSpacing.space1;

  @override
  double get contentHeight => metadataHeight + sourceHeight;

  @override
  Widget? metadata(ThemeData theme, String description) => SizedBox(
    height: metadataHeight,
    child: ExcludeSemantics(
      child: SelectionContainer.disabled(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BirbSpacing.space2),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(
              description,
              style: BirbReviewStyle.rowMetadataTextStyle(theme),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget gutter(Widget child) => child;

  @override
  List<Widget> gutterCells(
    ThemeData theme,
    BirbDiffLine line, {
    required Widget selectionCue,
    required Widget changeMarker,
  }) => <Widget>[
    selectionCue,
    changeMarker,
    const SizedBox(width: BirbSpacing.space1),
  ];
}

/// The row-rendering half of [BirbDiffView].
///
/// These are methods of [_BirbDiffViewState] living in their own file;
/// an extension in the same library keeps the private state reachable
/// without widening any visibility.
extension _DiffRowBuilding on _BirbDiffViewState {
  /// The active line's description, including the no-final-newline marker.
  String _activeLineDescription(BirbDiffLine line) => line.hasNoFinalNewline
      ? '${widget.labels.activeLine(line)} · '
            '${widget.labels.noFinalNewlineText}'
      : widget.labels.activeLine(line);

  Widget _buildRow(ThemeData theme, int index) => switch (_rows[index]) {
    _HeadingRow(:final hunkId, :final heading) => _heading(
      theme,
      hunkId: hunkId,
      heading: heading,
    ),
    _LineRow(:final line) => _lineRow(theme, line),
  };

  Widget _heading(
    ThemeData theme, {
    required String hunkId,
    required String heading,
  }) {
    return SelectionContainer.disabled(
      key: BirbDiffViewKeys.heading(hunkId),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BirbReviewStyle.hunkHeadingBackground(theme),
          border: BirbReviewStyle.hunkHeadingBorder(theme),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BirbSpacing.space2,
            vertical: _BirbDiffViewState._rowPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              heading,
              style: BirbReviewStyle.hunkHeadingTextStyle(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineRow(ThemeData theme, BirbDiffLine line) {
    final selected = _isSelected(line);
    final active = line.id == _activeLineId;
    final metadata = _layout.metadata(theme, _activeLineDescription(line));

    return GestureDetector(
      key: BirbDiffViewKeys.line(line.id),
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      onTap: () => _setActive(line.id, takeFocus: true),
      child: Semantics(
        container: true,
        selected: selected,
        onTap: () => _setActive(line.id, takeFocus: true),
        label: _activeLineDescription(line),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? BirbReviewStyle.selectedRowBackground(theme)
                : BirbReviewStyle.codeBackground(theme),
            border: active
                ? Border.fromBorderSide(
                    BirbReviewStyle.activeRowSide(
                      theme,
                      focused: _navigationFocus.hasFocus,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: _BirbDiffViewState._rowPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Present only in the stacked layout, where metadata reflows
                // above the bounded source viewport and wraps.
                ?metadata,
                SizedBox(
                  height: _layout.sourceHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // The row label already announces the kind and both line
                      // numbers, so the gutter would only repeat them.
                      _layout.gutter(
                        ExcludeSemantics(
                          child: SelectionContainer.disabled(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _layout.gutterCells(
                                theme,
                                line,
                                selectionCue: _selectionCue(
                                  theme,
                                  selected: selected,
                                ),
                                changeMarker: _changeMarker(theme, line),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _source(theme, line)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionCue(ThemeData theme, {required bool selected}) => SizedBox(
    width: _BirbDiffViewState._selectionCueWidth,
    child: selected
        ? Icon(
            BirbReviewStyle.selectedRowIcon,
            size: _BirbDiffViewState._selectionCueWidth,
            color: theme.colorScheme.onSurface,
          )
        : null,
  );

  Widget _changeMarker(ThemeData theme, BirbDiffLine line) {
    final marker = BirbReviewStyle.lineMarker(theme, line.kind);
    return ColoredBox(
      color: marker.background,
      child: SizedBox(
        width: _layout.markerWidth,
        child: Text(
          BirbReviewStyle.lineSign(line.kind),
          style: BirbReviewStyle.codeTextStyle(theme)
              .copyWith(color: marker.foreground),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _source(ThemeData theme, BirbDiffLine line) {
    final codeStyle = BirbReviewStyle.codeTextStyle(theme);
    final displayed = BirbSourceText.expandTabs(line.text);
    final Widget content = _sourceSelectionLineId == line.id
        ? _SourceSelectionField(
            controller: _sourceSelectionController,
            focusNode: _sourceSelectionFocus,
            style: codeStyle,
            label: widget.labels.sourceSelectionLabel,
            onUnmounted: _handleSourceSelectionUnmounted,
          )
        : Text(
            displayed,
            style: codeStyle,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
          );

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: _codeWidth,
        maxWidth: _codeWidth,
        child: AnimatedBuilder(
          animation: _horizontal,
          builder: (context, child) => Transform.translate(
            offset: Offset(-_horizontalOffset, 0),
            child: child,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// The active line's read-only native editor.
///
/// A read-only [TextField] gives the caret placement, `Shift+Arrow` selection,
/// and platform copy shortcut that F2 promises. It is excluded from traversal
/// so no source row becomes a tab stop, and it reports its own disposal so
/// focus can return to the navigation region when pointer scrolling unmounts
/// it.
class _SourceSelectionField extends StatefulWidget {
  const _SourceSelectionField({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.label,
    required this.onUnmounted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final String label;
  final VoidCallback onUnmounted;

  @override
  State<_SourceSelectionField> createState() => _SourceSelectionFieldState();
}

class _SourceSelectionFieldState extends State<_SourceSelectionField> {
  @override
  void dispose() {
    widget.onUnmounted();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: TextField(
        key: BirbDiffViewKeys.sourceSelectionField,
        controller: widget.controller,
        focusNode: widget.focusNode,
        readOnly: true,
        maxLines: 1,
        style: widget.style,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
