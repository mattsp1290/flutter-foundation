part of 'controller.dart';

/// Native Go source view. The host owns [controller] and [provider].
/// Give this widget finite width and height; one view may attach per controller.
class BirbSourceEditor extends StatefulWidget {
  const BirbSourceEditor({
    super.key,
    required this.controller,
    this.provider,
    this.focusNode,
    this.label = 'Go source',
    this.codeTheme = BirbCodeTheme.foundation,
    this.onProviderError,
    this.providerTimeout = BirbEditorProviderLimits.timeout,
  });

  final BirbEditorController controller;
  final BirbEditorProvider? provider;
  final FocusNode? focusNode;
  final String label;
  final BirbCodeTheme codeTheme;
  final ValueChanged<BirbEditorProviderStatus>? onProviderError;
  final Duration providerTimeout;

  @override
  State<BirbSourceEditor> createState() => _SourceEditorState();
}

class _SourceEditorState extends State<BirbSourceEditor> {
  late FocusNode _focus;
  late CodeScrollController _scroll;
  late EditorProviderCoordinator _providers;
  late GuardedEditorEngine _engine;
  late EngineAdapter _adapter;
  bool _attached = false;
  bool _wrap = false;
  double _fontScale = 1;
  Offset _lastOffset = Offset.zero;
  bool _rebuildScheduled = false;
  bool _restoreFocus = false;
  bool _findOpen = false;
  bool _diagnosticsOpen = false;
  bool _tabTraversal = false;
  late EditorFindModel _find;
  final _headerScroll = ScrollController();
  final _footerScroll = ScrollController();
  final _boundary = FocusNode(
    debugLabel: 'Editor boundary',
    canRequestFocus: false,
    skipTraversal: true,
  );

  void _leaveEditor({required bool backward}) {
    // Exclude this editor's toolbar and panel controls for this one traversal.
    // They become reachable again when the user later tabs back into the view.
    final focused = FocusManager.instance.primaryFocus ?? _focus;
    final skipped = <FocusNode, bool>{
      for (final descendant in _boundary.descendants)
        if (!identical(descendant, focused))
          descendant: descendant.skipTraversal,
    };
    for (final descendant in skipped.keys) {
      descendant.skipTraversal = true;
    }
    try {
      if (backward) {
        focused.previousFocus();
      } else {
        focused.nextFocus();
      }
    } finally {
      for (final entry in skipped.entries) {
        entry.key.skipTraversal = entry.value;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    widget.controller._attachView(this);
    _attached = true;
    _focus = widget.focusNode ?? FocusNode(debugLabel: 'Source editor');
    final offset = widget.controller._scrollOffset;
    _lastOffset = offset;
    _scroll = CodeScrollController(
      verticalScroller: ScrollController(initialScrollOffset: offset.dy),
      horizontalScroller: ScrollController(initialScrollOffset: offset.dx),
    );
    _adapter = widget.controller._adapter;
    _scroll.verticalScroller.addListener(_saveScroll);
    _scroll.horizontalScroller.addListener(_saveScroll);
    _engine = widget.controller._bindEngine(this);
    _providers = EditorProviderCoordinator(
      controller: widget.controller,
      provider: widget.provider,
      timeout: widget.providerTimeout,
      onError: (status) => widget.onProviderError?.call(status),
    );
    _find = EditorFindModel(widget.controller);
    _providers.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  Offset get _offset => Offset(
    _scroll.horizontalScroller.hasClients
        ? _scroll.horizontalScroller.offset
        : _lastOffset.dx,
    _scroll.verticalScroller.hasClients
        ? _scroll.verticalScroller.offset
        : _lastOffset.dy,
  );

  void _saveScroll() => _lastOffset = _offset;

  void _detach(BirbSourceEditor oldWidget) {
    if (!_attached) return;
    final offset = _offset;
    oldWidget.controller.removeListener(_changed);
    _providers.dispose();
    _find.dispose();
    oldWidget.controller._detachView(this, offset);
    _scroll.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    if (oldWidget.focusNode == null) _focus.dispose();
    _attached = false;
  }

  void _changed() {
    if (!mounted || !_attached) return;
    if (!identical(_adapter, widget.controller._adapter) && _focus.hasFocus) {
      _restoreFocus = true;
      _focus.unfocus();
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted && _attached) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _openFind() => setState(() => _findOpen = true);

  void _closeFind() {
    setState(() => _findOpen = false);
    _focus.requestFocus();
  }

  void _escape() {
    if (_findOpen) {
      _closeFind();
    } else if (_providers.completions.isNotEmpty || _providers.hover != null) {
      _providers.dismiss();
    } else if (_diagnosticsOpen) {
      setState(() => _diagnosticsOpen = false);
    } else {
      setState(() => _tabTraversal = true);
    }
  }

  @override
  void didUpdateWidget(covariant BirbSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _restoreFocus = _focus.hasFocus;
      if (_restoreFocus) _focus.unfocus();
      _detach(oldWidget);
      _attach();
    } else {
      if (oldWidget.providerTimeout != widget.providerTimeout) {
        _providers.dispose();
        _providers = EditorProviderCoordinator(
          controller: widget.controller,
          provider: widget.provider,
          timeout: widget.providerTimeout,
          onError: (status) => widget.onProviderError?.call(status),
        )..addListener(_changed);
      } else {
        _providers.setProvider(widget.provider);
      }
      if (oldWidget.focusNode != widget.focusNode) {
        if (oldWidget.focusNode == null) _focus.dispose();
        _focus = widget.focusNode ?? FocusNode(debugLabel: 'Source editor');
      }
    }
  }

  @override
  void dispose() {
    _detach(widget);
    _boundary.dispose();
    _headerScroll.dispose();
    _footerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoreFocus) {
      _restoreFocus = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _attached) _focus.requestFocus();
      });
    }
    if (!identical(_adapter, widget.controller._adapter)) {
      _adapter = widget.controller._adapter;
      _engine = widget.controller._bindEngine(this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller._releaseRetiredAdapters();
      });
    }
    final snapshot = widget.controller.snapshot;
    return Focus(
      focusNode: _boundary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
            throw FlutterError(
              'BirbSourceEditor requires finite width and height',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .45,
                ),
                child: Scrollbar(
                  controller: _headerScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _headerScroll,
                    child: Column(
                      children: [
                        EditorChrome(
                          snapshot: snapshot,
                          label: widget.label,
                          wrap: _wrap,
                          fontScale: _fontScale,
                          hasProvider: widget.provider != null,
                          invoke: _invokeCommand,
                        ),
                        if (_findOpen)
                          EditorFindPanel(
                            key: ObjectKey(_find),
                            model: _find,
                            close: _closeFind,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: EditorSurface(
                  key: ObjectKey(_engine),
                  controller: widget.controller,
                  engine: _engine,
                  scroll: _scroll,
                  focus: _focus,
                  providers: _providers,
                  codeTheme: widget.codeTheme,
                  fontScale: _fontScale,
                  wrap: _wrap,
                  actions: _shortcutActions,
                  label: widget.label,
                ),
              ),
              if (_diagnosticsOpen)
                SizedBox(
                  height: constraints.maxHeight * .2,
                  child: EditorDiagnosticsPanel(
                    providers: _providers,
                    close: () => setState(() => _diagnosticsOpen = false),
                    navigate: (item) {
                      widget.controller.setSelection(
                        TextSelection(
                          baseOffset: item.range.start,
                          extentOffset: item.range.end,
                        ),
                      );
                      _focus.requestFocus();
                    },
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .25,
                ),
                child: Scrollbar(
                  controller: _footerScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _footerScroll,
                    child: EditorStatusBar(
                      snapshot: snapshot,
                      providers: _providers,
                      tabTraversal: _tabTraversal,
                      toggleTraversal: () =>
                          setState(() => _tabTraversal = !_tabTraversal),
                      showDiagnostics: () =>
                          setState(() => _diagnosticsOpen = !_diagnosticsOpen),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
