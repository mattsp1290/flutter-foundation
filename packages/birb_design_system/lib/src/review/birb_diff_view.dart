import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';
import 'birb_review_style.dart';

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

/// A bounded unified diff for one changed file revision.
///
/// The host owns every value this widget renders. It supplies finite
/// constraints — a [SizedBox] or an [Expanded] inside a bounded layout — and it
/// owns loading, failure, and retry around the diff. Nothing here performs
/// asynchronous work, parses a patch, highlights syntax, or reconstructs a
/// patch position.
///
/// Rows are flattened once per [snapshot] and rendered with a lazy vertical
/// list, so snapshot preparation costs O(total source text) and widget
/// construction costs O(visible rows). Line numbers and the change sign never
/// require horizontal scrolling; only the source column scrolls sideways, and
/// every row shares one offset.
///
/// [selectedAnchor] is controlled: an anchor from another file or revision is
/// ignored rather than matched to an unrelated line with the same number. A
/// null [onCommentRequested] removes the comment action and leaves a read-only
/// diff whose `Copy source line` action still works.
///
/// See `DESIGN.md` section 9 for the role, geometry, and keyboard contracts.
final class BirbDiffView extends StatefulWidget {
  const BirbDiffView({
    required this.snapshot,
    super.key,
    this.selectedAnchor,
    this.onCommentRequested,
    this.labels = const BirbDiffViewLabels(),
  });

  /// The validated file revision to display.
  final BirbDiffSnapshot snapshot;

  /// The host-selected anchor, or null when nothing is selected.
  final BirbDiffAnchor? selectedAnchor;

  /// Reports the exact anchor the user asked to discuss.
  final ValueChanged<BirbDiffAnchor>? onCommentRequested;

  /// Overridable display text.
  final BirbDiffViewLabels labels;

  @override
  State<BirbDiffView> createState() => _BirbDiffViewState();
}

/// One flattened list item: either a hunk heading or one source line.
@immutable
class _DiffRow {
  const _DiffRow.heading(this.hunk) : line = null;
  const _DiffRow.line(this.line) : hunk = null;

  final BirbDiffHunk? hunk;
  final BirbDiffLine? line;
}

class _BirbDiffViewState extends State<BirbDiffView> {
  static const double _stackBreakpoint = 360;
  static const double _maximumInlineCodeScale = 1.5;
  static const double _rowPadding = BirbSpacing.space1;
  static const double _stripHeight = BirbSpacing.space3;
  static const double _selectionCueWidth = BirbSpacing.space4;

  /// How many of the longest rows are laid out to find the true column width.
  static const int _widthCandidateCount = 8;

  final FocusNode _navigationFocus = FocusNode(
    debugLabel: 'BirbDiffView navigation',
  );
  final FocusNode _sourceSelectionFocus = FocusNode(
    debugLabel: 'BirbDiffView source selection',
    skipTraversal: true,
  );
  final FocusNode _selectionRegionFocus = FocusNode(
    debugLabel: 'BirbDiffView selection region',
    skipTraversal: true,
  );
  final TextEditingController _sourceSelectionController =
      TextEditingController();

  ScrollController _vertical = ScrollController();
  ScrollController _horizontal = ScrollController();

  List<_DiffRow> _rows = const <_DiffRow>[];
  Map<String, int> _rowIndexByLineId = const <String, int>{};
  List<BirbDiffLine> _lines = const <BirbDiffLine>[];
  List<String> _widthCandidates = const <String>[];
  String _widestGutterText = '';
  int _numberDigits = 1;

  List<double> _extents = const <double>[];
  List<double> _offsets = const <double>[];
  double _contentWidth = 0;
  double _codeWidth = 0;
  double _charWidth = 0;
  double _lineHeight = 0;
  double _gutterWidth = 0;

  /// Horizontal space reserved before the source column in the current layout.
  double _codeInset = 0;
  double _numberWidth = 0;
  double _markerWidth = 0;
  double _stackedGutterHeight = 0;
  bool _stacked = false;

  Object? _metricsKey;
  String? _activeLineId;
  String? _sourceSelectionLineId;

  @override
  void initState() {
    super.initState();
    _navigationFocus.addListener(_handleFocusChange);
    _prepareSnapshot();
  }

  @override
  void didUpdateWidget(BirbDiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged =
        widget.snapshot.file.id != oldWidget.snapshot.file.id ||
        widget.snapshot.revisionId != oldWidget.snapshot.revisionId;
    if (identityChanged) {
      _resetScrollControllers();
      _prepareSnapshot();
      return;
    }
    if (widget.snapshot != oldWidget.snapshot) {
      _prepareSnapshot();
      return;
    }
    if (widget.labels != oldWidget.labels) {
      final previous = _widestGutterText;
      _computeWidestGutterText();
      if (previous != _widestGutterText) _metricsKey = null;
    }
    if (widget.selectedAnchor != oldWidget.selectedAnchor) {
      _adoptSelectedAnchor();
    }
  }

  @override
  void dispose() {
    _navigationFocus
      ..removeListener(_handleFocusChange)
      ..dispose();
    _sourceSelectionFocus.dispose();
    _selectionRegionFocus.dispose();
    _sourceSelectionController.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _resetScrollControllers() {
    final vertical = _vertical;
    final horizontal = _horizontal;
    _vertical = ScrollController();
    _horizontal = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vertical.dispose();
      horizontal.dispose();
    });
  }

  /// Flattens and measures the snapshot once, not on every lazy row build.
  void _prepareSnapshot() {
    final rows = <_DiffRow>[];
    final indexByLineId = <String, int>{};
    final lines = <BirbDiffLine>[];
    // A rune count only approximates display width, so keep several of the
    // longest rows as candidates and measure them all. Otherwise one wide-glyph
    // line among narrow ones would under-measure the column and be clipped with
    // no scroll extent left to reach it.
    final candidates = <String>[];
    var digits = 1;
    for (final hunk in widget.snapshot.hunks) {
      if (hunk.heading != null) {
        rows.add(_DiffRow.heading(hunk));
      }
      for (final line in hunk.lines) {
        indexByLineId[line.id] = rows.length;
        rows.add(_DiffRow.line(line));
        lines.add(line);
        final oldDigits = line.oldNumber?.toString().length ?? 1;
        final newDigits = line.newNumber?.toString().length ?? 1;
        if (oldDigits > digits) digits = oldDigits;
        if (newDigits > digits) digits = newDigits;
        _considerWidthCandidate(
          candidates,
          BirbReviewStyle.expandTabs(line.text),
        );
      }
    }
    _rows = List<_DiffRow>.unmodifiable(rows);
    _rowIndexByLineId = Map<String, int>.unmodifiable(indexByLineId);
    _lines = List<BirbDiffLine>.unmodifiable(lines);
    _widthCandidates = List<String>.unmodifiable(candidates);
    _numberDigits = digits;
    _extents = const <double>[];
    _offsets = const <double>[];
    _computeWidestGutterText();
    _metricsKey = null;
    _sourceSelectionLineId = null;
    _activeLineId = lines.isEmpty ? null : lines.first.id;
    _adoptSelectedAnchor();
    // A tall hunk heading must not hide the active line on first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealActive();
    });
  }

  /// Keeps [_widthCandidateCount] rows that could plausibly be the widest.
  ///
  /// Candidates stay ordered longest-first by rune count; every one of them is
  /// laid out later, so a wide-glyph row that loses on rune count can still win
  /// on pixels.
  static void _considerWidthCandidate(List<String> candidates, String text) {
    if (text.isEmpty) return;
    final length = text.runes.length;
    if (candidates.length >= _widthCandidateCount &&
        length <= candidates.last.runes.length) {
      return;
    }
    var index = 0;
    while (index < candidates.length &&
        candidates[index].runes.length >= length) {
      if (candidates[index] == text) return;
      index += 1;
    }
    candidates.insert(index, text);
    if (candidates.length > _widthCandidateCount) candidates.removeLast();
  }

  /// Finds the longest accessible line description once, not per row build.
  ///
  /// A stacked row renders that description as wrapping metadata, so one
  /// measurement of the longest string bounds every row's height.
  void _computeWidestGutterText() {
    var widest = '';
    for (final line in _lines) {
      final description = _activeLineDescription(line);
      if (description.runes.length > widest.runes.length) {
        widest = description;
      }
    }
    _widestGutterText = widest;
  }

  /// Adopts a valid host selection as the keyboard-active line.
  ///
  /// An anchor from another file or revision, or one naming a line this
  /// snapshot does not contain, is ignored.
  void _adoptSelectedAnchor() {
    final anchor = widget.selectedAnchor;
    if (anchor == null) return;
    if (anchor.fileId != widget.snapshot.file.id) return;
    if (anchor.revisionId != widget.snapshot.revisionId) return;
    if (!_rowIndexByLineId.containsKey(anchor.lineId)) return;
    _activeLineId = anchor.lineId;
  }

  bool _isSelected(BirbDiffLine line) {
    final anchor = widget.selectedAnchor;
    return anchor != null &&
        anchor.fileId == widget.snapshot.file.id &&
        anchor.revisionId == widget.snapshot.revisionId &&
        anchor.lineId == line.id;
  }

  BirbDiffLine? get _activeLine {
    final id = _activeLineId;
    if (id == null) return null;
    final index = _rowIndexByLineId[id];
    if (index == null) return null;
    return _rows[index].line;
  }

  /// Recomputes cached extents when width, text scale, or font metrics change.
  void _ensureMetrics(BuildContext context, double width) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final codeStyle = BirbReviewStyle.codeTextStyle(theme);
    final gutterStyle = BirbReviewStyle.gutterTextStyle(theme);
    final headingStyle = BirbReviewStyle.hunkHeadingTextStyle(theme);
    // A record compares by value, so an unlucky hash can never reuse stale
    // geometry the way a hashed key could.
    final key = (
      width,
      scaler,
      codeStyle,
      gutterStyle,
      headingStyle,
      _rows.length,
      widget.snapshot.revisionId,
    );
    if (_metricsKey == key) return;
    _metricsKey = key;

    final sample = _measure('0' * 10, codeStyle, scaler);
    _charWidth = sample.width / 10;
    _lineHeight = sample.height;

    _numberWidth = _charWidth * _numberDigits + BirbSpacing.space1;
    _markerWidth = _charWidth * 2;
    final inlineGutterWidth =
        _selectionCueWidth +
        _numberWidth * 2 +
        _markerWidth +
        BirbSpacing.space2;

    // Stack metadata above the source when the row is narrow, the code scale
    // is large, or an inline gutter would leave no usable source column.
    final baseFontSize = codeStyle.fontSize ?? 14;
    final scaledFontSize = scaler.scale(baseFontSize);
    _stacked =
        width < _stackBreakpoint ||
        scaledFontSize > baseFontSize * _maximumInlineCodeScale ||
        width - inlineGutterWidth < _charWidth * 12;
    _gutterWidth = _stacked ? 0 : inlineGutterWidth;
    // A stacked row still reserves the selection cue and the change marker
    // beside the source cell, so the code viewport is narrower than the row.
    _codeInset = _stacked
        ? _selectionCueWidth + _markerWidth + BirbSpacing.space1
        : _gutterWidth;

    _stackedGutterHeight = _stacked && _widestGutterText.isNotEmpty
        ? _measure(
            _widestGutterText,
            gutterStyle,
            scaler,
            maxWidth: (width - BirbSpacing.space2 * 2).clamp(
              1.0,
              double.infinity,
            ),
          ).height
        : 0;

    final codeViewport = (width - _codeInset).clamp(0.0, double.infinity);
    var measured = 0.0;
    for (final candidate in _widthCandidates) {
      final candidateWidth = _measure(candidate, codeStyle, scaler).width;
      if (candidateWidth > measured) measured = candidateWidth;
    }
    _codeWidth = measured > codeViewport ? measured : codeViewport;
    _contentWidth = _codeInset + _codeWidth;

    final rowExtent =
        (_stacked ? _stackedGutterHeight + _lineHeight : _lineHeight) +
        _rowPadding * 2;
    final extents = <double>[];
    final offsets = <double>[];
    var running = 0.0;
    for (final row in _rows) {
      final extent = row.hunk == null
          ? rowExtent
          : _measure(
                  row.hunk!.heading!,
                  headingStyle,
                  scaler,
                  maxWidth: (width - BirbSpacing.space2 * 2).clamp(
                    1.0,
                    double.infinity,
                  ),
                ).height +
                _rowPadding * 2;
      offsets.add(running);
      extents.add(extent);
      running += extent;
    }
    _extents = List<double>.unmodifiable(extents);
    _offsets = List<double>.unmodifiable(offsets);
  }

  TextPainter _measure(
    String text,
    TextStyle style,
    TextScaler scaler, {
    double maxWidth = double.infinity,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: maxWidth.isFinite ? null : 1,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  double get _horizontalOffset =>
      _horizontal.hasClients ? _horizontal.offset : 0;

  bool get _canScrollSource =>
      _charWidth > 0 &&
      _horizontal.hasClients &&
      _horizontal.position.maxScrollExtent > 0;

  void _scrollSource(double delta) {
    if (!_horizontal.hasClients) return;
    final position = _horizontal.position;
    _horizontal.jumpTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void _moveActive(int delta) {
    if (_lines.isEmpty) return;
    final current = _lines.indexWhere((line) => line.id == _activeLineId);
    final next = (current < 0 ? 0 : current + delta).clamp(
      0,
      _lines.length - 1,
    );
    _setActive(_lines[next].id);
  }

  void _setActive(String lineId, {bool takeFocus = false}) {
    setState(() {
      _activeLineId = lineId;
      if (_sourceSelectionLineId != null && _sourceSelectionLineId != lineId) {
        _sourceSelectionLineId = null;
      }
    });
    // Without this a pointer or assistive-technology activation would leave
    // primary focus outside the region, so the next arrow key would be spent
    // on directional traversal instead of moving the active line.
    if (takeFocus && _sourceSelectionLineId == null) {
      _navigationFocus.requestFocus();
    }
    _revealActive();
  }

  void _revealActive() {
    final id = _activeLineId;
    if (id == null || !_vertical.hasClients) return;
    final index = _rowIndexByLineId[id];
    if (index == null || index >= _offsets.length) return;
    final position = _vertical.position;
    final top = _offsets[index];
    final bottom = top + _extents[index];
    final viewport = position.viewportDimension;
    double? target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + viewport) {
      target = bottom - viewport;
    }
    if (target == null) return;
    _vertical.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void _enterSourceSelection() {
    final line = _activeLine;
    if (line == null) return;
    _revealActive();
    _sourceSelectionController.value = TextEditingValue(
      text: BirbReviewStyle.expandTabs(line.text),
      selection: const TextSelection.collapsed(offset: 0),
    );
    setState(() => _sourceSelectionLineId = line.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _sourceSelectionLineId == line.id) {
        _sourceSelectionFocus.requestFocus();
      }
    });
  }

  void _exitSourceSelection() {
    if (_sourceSelectionLineId == null) return;
    setState(() => _sourceSelectionLineId = null);
    _navigationFocus.requestFocus();
  }

  /// Restores focus when pointer scrolling unmounts the focused source row.
  void _handleSourceSelectionUnmounted() {
    if (!mounted || _sourceSelectionLineId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sourceSelectionLineId == null) return;
      setState(() => _sourceSelectionLineId = null);
      _navigationFocus.requestFocus();
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_sourceSelectionLineId == null) return KeyEventResult.ignored;
      _exitSourceSelection();
      return KeyEventResult.handled;
    }
    // Editor and native selection keystrokes belong to the descendant that
    // owns focus.
    if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (_lines.isEmpty) return KeyEventResult.ignored;
        _moveActive(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_lines.isEmpty) return KeyEventResult.ignored;
        _moveActive(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        if (_lines.isEmpty) return KeyEventResult.ignored;
        _setActive(_lines.first.id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        if (_lines.isEmpty) return KeyEventResult.ignored;
        _setActive(_lines.last.id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (!_canScrollSource) return KeyEventResult.ignored;
        _scrollSource(_charWidth * 8);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (!_canScrollSource) return KeyEventResult.ignored;
        _scrollSource(-_charWidth * 8);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.f2:
        if (_activeLine == null) return KeyEventResult.ignored;
        _enterSourceSelection();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _copyActiveLine() {
    final line = _activeLine;
    if (line == null) return;
    Clipboard.setData(ClipboardData(text: line.text));
  }

  void _requestComment() {
    final line = _activeLine;
    final callback = widget.onCommentRequested;
    if (line == null || callback == null) return;
    callback(widget.snapshot.anchorFor(line));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = _unavailableMessage();

    return Material(
      key: BirbDiffViewKeys.root,
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(BirbReviewStyle.objectSide(theme)),
          borderRadius: BirbRadii.none,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            assert(
              constraints.hasBoundedHeight,
              'BirbDiffView needs a finite height. Wrap it in a SizedBox or '
              'an Expanded inside a bounded layout.',
            );
            assert(
              constraints.hasBoundedWidth,
              'BirbDiffView needs a finite width. Wrap it in a SizedBox or '
              'a bounded layout.',
            );
            // Chrome takes its natural height but never enough to squeeze the
            // source list out of the layout, so nothing overflows at 320
            // logical pixels or 200 percent text.
            final available = constraints.maxHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: available * 0.2),
                  child: SingleChildScrollView(child: _header(theme)),
                ),
                if (unavailable != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(BirbSpacing.space3),
                      child: Text(
                        unavailable,
                        key: BirbDiffViewKeys.unavailableMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...<Widget>[
                  Expanded(child: _sourceRegion(theme)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: available * 0.35),
                    child: SingleChildScrollView(child: _chrome(theme)),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String? _unavailableMessage() {
    final file = widget.snapshot.file;
    return switch (file.content) {
      BirbReviewContentAvailability.binary => widget.labels.binaryText,
      BirbReviewContentAvailability.unavailable =>
        widget.labels.unavailableText,
      BirbReviewContentAvailability.text =>
        widget.snapshot.isEmpty ? widget.labels.emptyText : null,
    };
  }

  Widget _header(ThemeData theme) {
    final file = widget.snapshot.file;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(BirbSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(file.path, style: theme.textTheme.titleSmall),
          if (file.previousPath != null)
            Text(
              '${widget.labels.renamedFrom} ${file.previousPath}',
              style: theme.textTheme.bodySmall,
            ),
          Text(
            '${BirbReviewStyle.fileChangeLabel(file.change)} · '
            '+${file.additions} ${widget.labels.additions} · '
            '−${file.deletions} ${widget.labels.deletions}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _sourceRegion(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureMetrics(context, constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Focus(
                key: BirbDiffViewKeys.navigationRegion,
                focusNode: _navigationFocus,
                onKeyEvent: _handleKey,
                child: Semantics(
                  container: true,
                  label: widget.labels.navigationLabel,
                  hint: widget.labels.keyboardHelp,
                  child: SelectionArea(
                    focusNode: _selectionRegionFocus,
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onHorizontalDragUpdate: (details) =>
                          _scrollSource(-details.delta.dx),
                      child: ListView.builder(
                        controller: _vertical,
                        itemCount: _rows.length,
                        itemBuilder: (context, index) => SizedBox(
                          height: _extents[index],
                          child: _buildRow(theme, index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _horizontalStrip(theme, constraints.maxWidth),
          ],
        );
      },
    );
  }

  /// The shared horizontal offset control for the source column.
  ///
  /// The thumb stays thin but its hit area is a full interaction target, the
  /// scroll actions stay in semantics, and a horizontal drag anywhere over the
  /// source rows moves the same offset.
  Widget _horizontalStrip(ThemeData theme, double width) {
    final scrollable = _contentWidth > width;
    return Semantics(
      key: BirbDiffViewKeys.horizontalScroll,
      container: true,
      label: widget.labels.horizontalScrollLabel,
      child: SizedBox(
        height: BirbSizes.minimumInteractiveDimension,
        child: Align(
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: scrollable,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              physics: scrollable ? null : const NeverScrollableScrollPhysics(),
              child: SizedBox(width: _contentWidth, height: _stripHeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chrome(ThemeData theme) {
    final line = _activeLine;
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(BirbSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              line == null
                  ? widget.labels.noActiveLineText
                  : _activeLineDescription(line),
              key: BirbDiffViewKeys.activeLineDescription,
              style: theme.textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: BirbSpacing.space1),
          Wrap(
            spacing: BirbSpacing.space2,
            runSpacing: BirbSpacing.space2,
            children: <Widget>[
              if (widget.onCommentRequested != null)
                OutlinedButton.icon(
                  key: BirbDiffViewKeys.commentAction,
                  onPressed: line == null ? null : _requestComment,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(
                    line == null
                        ? widget.labels.noActiveLineText
                        : widget.labels.commentAction(line),
                  ),
                ),
              OutlinedButton.icon(
                key: BirbDiffViewKeys.copyAction,
                onPressed: line == null ? null : _copyActiveLine,
                icon: const Icon(Icons.copy_outlined),
                label: Text(widget.labels.copyActionLabel),
              ),
              OutlinedButton.icon(
                key: BirbDiffViewKeys.selectSourceAction,
                onPressed: line == null ? null : _enterSourceSelection,
                icon: const Icon(Icons.text_fields_outlined),
                label: Text(widget.labels.selectSourceActionLabel),
              ),
            ],
          ),
          const SizedBox(height: BirbSpacing.space1),
          Text(widget.labels.keyboardHelp, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// The active line's description, including the no-final-newline marker.
  String _activeLineDescription(BirbDiffLine line) => line.hasNoFinalNewline
      ? '${widget.labels.activeLine(line)} · '
            '${widget.labels.noFinalNewlineText}'
      : widget.labels.activeLine(line);

  Widget _buildRow(ThemeData theme, int index) {
    final row = _rows[index];
    final hunk = row.hunk;
    if (hunk != null) return _heading(theme, hunk);
    return _lineRow(theme, row.line!);
  }

  Widget _heading(ThemeData theme, BirbDiffHunk hunk) {
    return SelectionContainer.disabled(
      key: BirbDiffViewKeys.heading(hunk.id),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BirbReviewStyle.hunkHeadingBackground(theme),
          border: BirbReviewStyle.hunkHeadingBorder(theme),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BirbSpacing.space2,
            vertical: _rowPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              hunk.heading!,
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
            padding: const EdgeInsets.symmetric(vertical: _rowPadding),
            child: _stacked
                ? _stackedRow(theme, line, selected: selected)
                : _inlineRow(theme, line, selected: selected),
          ),
        ),
      ),
    );
  }

  /// The wide layout: a fixed gutter beside the scrolling source column.
  Widget _inlineRow(
    ThemeData theme,
    BirbDiffLine line, {
    required bool selected,
  }) {
    final gutterStyle = BirbReviewStyle.gutterTextStyle(theme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _gutterWidth,
          // The row label already announces the kind and both line numbers, so
          // the gutter would only repeat them.
          child: ExcludeSemantics(
            child: SelectionContainer.disabled(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _selectionCue(theme, selected: selected),
                  SizedBox(
                    width: _numberWidth,
                    child: Text(
                      line.oldNumber?.toString() ?? '',
                      style: gutterStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(
                    width: _numberWidth,
                    child: Text(
                      line.newNumber?.toString() ?? '',
                      style: gutterStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: BirbSpacing.space1),
                  _changeMarker(theme, line),
                  const SizedBox(width: BirbSpacing.space1),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _source(theme, line)),
      ],
    );
  }

  /// The narrow or large-text layout.
  ///
  /// Metadata reflows above the bounded source viewport and wraps; nothing is
  /// shrunk, ellipsized, or pushed off screen.
  Widget _stackedRow(
    ThemeData theme,
    BirbDiffLine line, {
    required bool selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _stackedGutterHeight,
          child: ExcludeSemantics(
            child: SelectionContainer.disabled(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BirbSpacing.space2,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    _activeLineDescription(line),
                    style: BirbReviewStyle.gutterTextStyle(theme),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: _lineHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: SelectionContainer.disabled(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _selectionCue(theme, selected: selected),
                      _changeMarker(theme, line),
                      const SizedBox(width: BirbSpacing.space1),
                    ],
                  ),
                ),
              ),
              Expanded(child: _source(theme, line)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectionCue(ThemeData theme, {required bool selected}) => SizedBox(
    width: _selectionCueWidth,
    child: selected
        ? Icon(
            BirbReviewStyle.selectedRowIcon,
            size: _selectionCueWidth,
            color: theme.colorScheme.onSurface,
          )
        : null,
  );

  Widget _changeMarker(ThemeData theme, BirbDiffLine line) {
    final marker = BirbReviewStyle.lineMarker(theme, line.kind);
    return ColoredBox(
      color: marker.background,
      child: SizedBox(
        width: _markerWidth,
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
    final displayed = BirbReviewStyle.expandTabs(line.text);
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
