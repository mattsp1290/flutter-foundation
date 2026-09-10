import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';
import 'birb_review_style.dart';
import 'birb_source_text.dart';

part 'birb_diff_view_labels.dart';
part 'birb_diff_row.dart';

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

class _BirbDiffViewState extends State<BirbDiffView> {
  static const double _stackBreakpoint = 360;
  static const double _maximumInlineCodeScale = 1.5;
  static const double _rowPadding = BirbSpacing.space1;
  static const double _selectionCueWidth = BirbSpacing.space4;

  /// The largest share of the diff's height the header may take.
  static const double _maximumHeaderShare = 0.2;

  /// The largest share the action area and keyboard help may take.
  ///
  /// These two must sum to well under 1: the remainder is the source list, and
  /// a diff whose rows are squeezed out is useless.
  static const double _maximumChromeShare = 0.35;

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

  /// Controllers replaced on an identity change, awaiting a safe disposal.
  final List<ScrollController> _retiredControllers = <ScrollController>[];

  List<_DiffRow> _rows = const <_DiffRow>[];
  Map<String, int> _rowIndexByLineId = const <String, int>{};
  List<BirbDiffLine> _lines = const <BirbDiffLine>[];
  Map<String, int> _lineIndexByLineId = const <String, int>{};
  List<String> _widthCandidates = const <String>[];
  String _widestGutterText = '';
  int _numberDigits = 1;

  List<double> _extents = const <double>[];
  List<double> _offsets = const <double>[];
  double _contentWidth = 0;
  double _codeWidth = 0;
  double _charWidth = 0;
  double _lineHeight = 0;
  late _DiffRowLayout _layout = const _InlineRowLayout(
    sourceHeight: 0,
    markerWidth: 0,
    gutterWidth: 0,
    numberWidth: 0,
  );

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
      _prepareSnapshot(preserveActive: true);
      return;
    }
    if (widget.labels != oldWidget.labels) {
      final previous = _widestGutterText;
      _computeWidestGutterText();
      if (previous != _widestGutterText) _metricsKey = null;
    }
    if (widget.selectedAnchor != oldWidget.selectedAnchor) {
      final previous = _activeLineId;
      _adoptSelectedAnchor();
      if (_activeLineId != previous) {
        // didUpdateWidget runs before layout, so reveal once this frame's
        // extents and viewport exist.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _revealActive();
        });
      }
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
    _drainRetired();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _resetScrollControllers() {
    _retiredControllers.addAll(<ScrollController>[_vertical, _horizontal]);
    _vertical = ScrollController();
    _horizontal = ScrollController();
    // Disposal waits for the frame that detaches them, but dispose() drains
    // the same list so a tear-down with no next frame cannot leak them.
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainRetired());
  }

  void _drainRetired() {
    for (final controller in _retiredControllers) {
      controller.dispose();
    }
    _retiredControllers.clear();
  }

  /// Flattens and measures the snapshot once, not on every lazy row build.
  ///
  /// [preserveActive] keeps the reader's position when only the snapshot's
  /// content changed; a file or revision replacement always restarts.
  void _prepareSnapshot({bool preserveActive = false}) {
    final previousActive = _activeLineId;
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
      final heading = hunk.heading;
      if (heading != null) {
        rows.add(_HeadingRow(hunkId: hunk.id, heading: heading));
      }
      for (final line in hunk.lines) {
        indexByLineId[line.id] = rows.length;
        rows.add(_LineRow(line));
        lines.add(line);
        final oldDigits = line.oldNumber?.toString().length ?? 1;
        final newDigits = line.newNumber?.toString().length ?? 1;
        if (oldDigits > digits) digits = oldDigits;
        if (newDigits > digits) digits = newDigits;
        _considerWidthCandidate(
          candidates,
          BirbSourceText.expandTabs(line.text),
        );
      }
    }
    _rows = List<_DiffRow>.unmodifiable(rows);
    _rowIndexByLineId = Map<String, int>.unmodifiable(indexByLineId);
    _lines = List<BirbDiffLine>.unmodifiable(lines);
    _lineIndexByLineId = Map<String, int>.unmodifiable(<String, int>{
      for (var index = 0; index < lines.length; index += 1)
        lines[index].id: index,
    });
    _widthCandidates = List<String>.unmodifiable(candidates);
    _numberDigits = digits;
    _extents = const <double>[];
    _offsets = const <double>[];
    _computeWidestGutterText();
    _metricsKey = null;
    _sourceSelectionLineId = null;
    _activeLineId = preserveActive && indexByLineId.containsKey(previousActive)
        ? previousActive
        : (lines.isEmpty ? null : lines.first.id);
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
    if (anchor == null || !widget.snapshot.contains(anchor)) return;
    _activeLineId = anchor.lineId;
  }

  bool _isSelected(BirbDiffLine line) {
    final anchor = widget.selectedAnchor;
    return anchor != null &&
        anchor.lineId == line.id &&
        widget.snapshot.contains(anchor);
  }

  BirbDiffLine? get _activeLine {
    final id = _activeLineId;
    if (id == null) return null;
    final index = _rowIndexByLineId[id];
    if (index == null) return null;
    final row = _rows[index];
    return row is _LineRow ? row.line : null;
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

    final numberWidth = _charWidth * _numberDigits + BirbSpacing.space1;
    final markerWidth = _charWidth * 2;
    final inlineGutterWidth =
        _selectionCueWidth + numberWidth * 2 + markerWidth + BirbSpacing.space2;

    // Stack metadata above the source when the row is narrow, the code scale
    // is large, or an inline gutter would leave no usable source column.
    final baseFontSize = codeStyle.fontSize ?? 14;
    final scaledFontSize = scaler.scale(baseFontSize);
    final stacked =
        width < _stackBreakpoint ||
        scaledFontSize > baseFontSize * _maximumInlineCodeScale ||
        width - inlineGutterWidth < _charWidth * 12;

    // Choosing the layout once keeps the inset, the row extent, the metadata
    // line and the gutter cells consistent with each other by construction.
    _layout = stacked
        ? _StackedRowLayout(
            sourceHeight: _lineHeight,
            markerWidth: markerWidth,
            selectionCueWidth: _selectionCueWidth,
            metadataHeight: _widestGutterText.isEmpty
                ? 0
                : _measure(
                    _widestGutterText,
                    BirbReviewStyle.rowMetadataTextStyle(theme),
                    scaler,
                    maxWidth: (width - BirbSpacing.space2 * 2).clamp(
                      1.0,
                      double.infinity,
                    ),
                  ).height,
          )
        : _InlineRowLayout(
            sourceHeight: _lineHeight,
            markerWidth: markerWidth,
            gutterWidth: inlineGutterWidth,
            numberWidth: numberWidth,
          );

    final codeViewport = (width - _layout.codeInset).clamp(
      0.0,
      double.infinity,
    );
    var measured = 0.0;
    for (final candidate in _widthCandidates) {
      final candidateWidth = _measure(candidate, codeStyle, scaler).width;
      if (candidateWidth > measured) measured = candidateWidth;
    }
    _codeWidth = measured > codeViewport ? measured : codeViewport;
    _contentWidth = _layout.codeInset + _codeWidth;

    final rowExtent = _layout.contentHeight + _rowPadding * 2;
    final extents = <double>[];
    final offsets = <double>[];
    var running = 0.0;
    for (final row in _rows) {
      final extent = switch (row) {
        _LineRow() => rowExtent,
        _HeadingRow(:final heading) =>
          _measure(
                heading,
                headingStyle,
                scaler,
                maxWidth: (width - BirbSpacing.space2 * 2).clamp(
                  1.0,
                  double.infinity,
                ),
              ).height +
              _rowPadding * 2,
      };
      offsets.add(running);
      extents.add(extent);
      running += extent;
    }
    _extents = List<double>.unmodifiable(extents);
    _offsets = List<double>.unmodifiable(offsets);
  }

  Size _measure(
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
    final size = painter.size;
    painter.dispose();
    return size;
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
    final current = _lineIndexByLineId[_activeLineId];
    // With no active line, Down starts at the first line and Up at the last.
    final next =
        (current == null
                ? (delta > 0 ? 0 : _lines.length - 1)
                : current + delta)
            .clamp(0, _lines.length - 1);
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
      text: BirbSourceText.expandTabs(line.text),
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
    // Editor and native selection keystrokes belong to the descendant that
    // owns focus. Escape is handled diff-wide by the outer Focus, so it still
    // works once focus has moved to the action area.
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
      // Escape is handled for the whole diff, not just the navigation region,
      // so it still closes source selection once focus has tabbed to the
      // action area. DESIGN.md 9.5 states that contract unqualified.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyUpEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.escape) {
            return KeyEventResult.ignored;
          }
          if (_sourceSelectionLineId == null) return KeyEventResult.ignored;
          _exitSourceSelection();
          return KeyEventResult.handled;
        },
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
                    constraints: BoxConstraints(
                      maxHeight: available * _maximumHeaderShare,
                    ),
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
                      constraints: BoxConstraints(
                        maxHeight: available * _maximumChromeShare,
                      ),
                      child: SingleChildScrollView(child: _chrome(theme)),
                    ),
                  ],
                ],
              );
            },
          ),
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
                    child: _sourceDragTarget(
                      width: constraints.maxWidth,
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

  /// Pans the source column with a touch drag, without taking the gesture
  /// away from native text selection.
  ///
  /// [SelectableRegion] hosts its own drag recognizers above this point, so a
  /// plain [GestureDetector] here would win the arena for every pointer and
  /// remove drag-to-select entirely. Restricting the recognizer to touch and
  /// stylus leaves precise pointers selecting, and they still reach the offset
  /// through the scrollbar and the `Left`/`Right` keys. The recognizer is only
  /// installed when there is something to scroll.
  Widget _sourceDragTarget({required double width, required Widget child}) {
    if (_contentWidth <= width) return child;
    return RawGestureDetector(
      excludeFromSemantics: true,
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(
              () => HorizontalDragGestureRecognizer(
                debugOwner: this,
                supportedDevices: const <PointerDeviceKind>{
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                },
              ),
              (instance) {
                instance.onUpdate = (details) =>
                    _scrollSource(-details.delta.dx);
              },
            ),
      },
      child: child,
    );
  }

  /// The shared horizontal offset control for the source column.
  ///
  /// The thumb stays thin, but the scrollable fills the whole reserved
  /// interaction target so a drag anywhere in it moves the offset, and the
  /// scroll actions stay in semantics.
  Widget _horizontalStrip(ThemeData theme, double width) {
    final scrollable = _contentWidth > width;
    return Semantics(
      key: BirbDiffViewKeys.horizontalScroll,
      container: true,
      label: widget.labels.horizontalScrollLabel,
      child: SizedBox(
        height: BirbSizes.minimumInteractiveDimension,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: scrollable,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: _contentWidth,
              height: BirbSizes.minimumInteractiveDimension,
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
}
