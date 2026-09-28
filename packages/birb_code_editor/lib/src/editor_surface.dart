import 'dart:async';

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import 'controller.dart';
import 'diagnostic_markers.dart';
import 'editor_geometry.dart';
import 'editor_theme.dart';
import 'guarded_engine.dart';
import 'language_provider.dart';
import 'provider_coordinator.dart';
import 'provider_overlays.dart';
import 'snapshot.dart';
import 'selection_toolbar.dart';
import 'source_semantics.dart';

part 'surface_popups.dart';

class EditorSurface extends StatefulWidget {
  const EditorSurface({
    super.key,
    required this.controller,
    required this.engine,
    required this.scroll,
    required this.focus,
    required this.providers,
    required this.codeTheme,
    required this.fontScale,
    required this.wrap,
    required this.actions,
    required this.label,
  });
  final BirbEditorController controller;
  final GuardedEditorEngine engine;
  final CodeScrollController scroll;
  final FocusNode focus;
  final EditorProviderCoordinator providers;
  final BirbCodeTheme codeTheme;
  final double fontScale;
  final bool wrap;
  final Map<Type, Action<Intent>> actions;
  final String label;

  @override
  State<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends State<EditorSurface> {
  final _gutterKey = GlobalKey();
  final _surfaceKey = GlobalKey();
  final _completionScroll = ScrollController();
  CodeIndicatorValueNotifier? _notifier;
  Timer? _hoverTimer;
  int? _hoverOffset;
  int _selected = 0;
  List<BirbEditorCompletion> _items = const [];
  bool _frameScheduled = false;
  late final EditorSelectionToolbarBridge _toolbar;
  Rect? _toolbarAnchor;

  @override
  void initState() {
    super.initState();
    widget.providers.addListener(_providerChanged);
    widget.controller.addListener(_modelChanged);
    widget.focus.addListener(_scheduleFrame);
    _toolbar = EditorSelectionToolbarBridge(
      showAt: (global) {
        final box =
            _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && mounted) {
          setState(
            () => _toolbarAnchor = box.globalToLocal(global) & const Size(2, 2),
          );
        }
      },
      dismiss: _dismissToolbar,
    );
  }

  void _dismissToolbar() {
    if (mounted && _toolbarAnchor != null) {
      setState(() => _toolbarAnchor = null);
    }
  }

  void _modelChanged() {
    _hoverTimer?.cancel();
    _hoverOffset = null;
    _toolbarAnchor = null;
    _scheduleFrame();
  }

  void _providerChanged() {
    _hoverTimer?.cancel();
    if (!identical(_items, widget.providers.completions)) {
      _items = widget.providers.completions;
      _selected = 0;
    }
    _scheduleFrame();
  }

  @override
  void didUpdateWidget(covariant EditorSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers != widget.providers) {
      oldWidget.providers.removeListener(_providerChanged);
      widget.providers.addListener(_providerChanged);
      _providerChanged();
    }
    if (oldWidget.focus != widget.focus) {
      oldWidget.focus.removeListener(_scheduleFrame);
      widget.focus.addListener(_scheduleFrame);
    }
  }

  void _scheduleFrame() {
    if (_frameScheduled || !mounted) return;
    _frameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _bindGeometry(CodeIndicatorValueNotifier notifier) {
    if (identical(_notifier, notifier)) return;
    _notifier?.removeListener(_geometryChanged);
    _notifier = notifier;
    notifier.addListener(_geometryChanged);
  }

  void _geometryChanged() {
    _hoverTimer?.cancel();
    _hoverOffset = null;
    _toolbarAnchor = null;
    _scheduleFrame();
  }

  EditorGeometry get _geometry {
    final gutter = _gutterKey.currentContext?.findRenderObject() as RenderBox?;
    return EditorGeometry(
      engine: widget.engine,
      paragraphs: _notifier?.value?.paragraphs ?? const [],
      gutter: Offset(
        gutter != null && gutter.hasSize ? gutter.size.width : 0,
        0,
      ),
      source: widget.controller.snapshot.source,
    );
  }

  void _dismissHover() {
    _hoverTimer?.cancel();
    widget.providers.dismissHover();
  }

  void _hover(Offset position) {
    final offset = _geometry.positionAt(position);
    if (offset == _hoverOffset) return;
    _hoverOffset = offset;
    _dismissHover();
    if (offset == null) return;
    _hoverTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) widget.providers.requestHover(offset);
    });
  }

  void _moveCompletion(AxisDirection direction) {
    if (direction != AxisDirection.up && direction != AxisDirection.down) {
      widget.engine.moveCursor(direction);
      return;
    }
    if (_items.isEmpty) return;
    setState(
      () => _selected =
          (_selected + (direction == AxisDirection.down ? 1 : -1)) %
          _items.length,
    );
    if (_completionScroll.hasClients) {
      final rowHeight = EditorCompletionList.rowHeight(context);
      final top = _selected * rowHeight;
      final bottom = top + rowHeight;
      final position = _completionScroll.position;
      if (top < position.pixels ||
          bottom > position.pixels + position.viewportDimension) {
        _completionScroll.jumpTo(
          (top < position.pixels ? top : bottom - position.viewportDimension)
              .clamp(position.minScrollExtent, position.maxScrollExtent),
        );
      }
    }
  }

  void _accept(BirbEditorCompletion item) {
    final result = widget.providers.acceptCompletion(item);
    if (result == BirbEditorEditResult.applied ||
        result == BirbEditorEditResult.unchanged) {
      widget.providers.dismiss();
    }
    widget.focus.requestFocus();
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _notifier?.removeListener(_geometryChanged);
    widget.providers.removeListener(_providerChanged);
    widget.controller.removeListener(_modelChanged);
    widget.focus.removeListener(_scheduleFrame);
    _completionScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.codeTheme.resolve(theme);
    final scaler = MediaQuery.textScalerOf(context);
    final codeStyle = BirbReviewStyle.codeTextStyle(theme).copyWith(
      color: colors.gutter,
      fontSize: scaler.scale(
        (BirbReviewStyle.codeTextStyle(theme).fontSize ?? 14) *
            widget.fontScale,
      ),
    );
    final snapshot = widget.controller.snapshot;
    final geometry = _geometry;
    final popup = _resolvePopup(geometry);
    final mac = theme.platform == TargetPlatform.macOS;
    return LayoutBuilder(
      key: _surfaceKey,
      builder: (context, constraints) => ClipRect(
        child: MouseRegion(
          onExit: (_) => _dismissHover(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MouseRegion(
                onHover: (event) => _hover(event.localPosition),
                onExit: (_) {
                  _hoverTimer?.cancel();
                  _hoverOffset = null;
                },
                child: Listener(
                  onPointerDown: (_) => _dismissHover(),
                  onPointerSignal: (_) => _dismissHover(),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(
                        LogicalKeyboardKey.space,
                        control: true,
                      ): widget.providers.requestCompletion,
                      SingleActivator(
                        LogicalKeyboardKey.keyK,
                        meta: mac,
                        control: !mac,
                      ): () =>
                          widget.providers.requestHover(),
                      const SingleActivator(
                        LogicalKeyboardKey.f10,
                        shift: true,
                      ): () {
                        final anchor = _geometry.caret(
                          widget.controller.snapshot.selection.extentOffset,
                        );
                        if (anchor != null) {
                          setState(() => _toolbarAnchor = anchor);
                        }
                      },
                    },
                    child: EditorSourceSemantics(
                      controller: widget.controller,
                      engine: widget.engine,
                      focus: widget.focus,
                      label: widget.label,
                      child: CodeEditor(
                        controller: widget.engine,
                        toolbarController: _toolbar,
                        scrollController: widget.scroll,
                        focusNode: widget.focus,
                        readOnly: snapshot.readOnly,
                        wordWrap: widget.wrap,
                        autofocus: false,
                        shortcutOverrideActions: _popupActions(popup),
                        maxLengthSingleLineRendering: 0x7fffffff,
                        commentFormatter: DefaultCodeCommentFormatter(
                          singleLinePrefix: '//',
                          multiLinePrefix: '/*',
                          multiLineSuffix: '*/',
                        ),
                        style: editorStyle(
                          theme,
                          widget.codeTheme,
                          widget.fontScale,
                          textScaler: scaler,
                        ),
                        indicatorBuilder:
                            (context, controller, chunks, notifier) {
                              _bindGeometry(notifier);
                              return ExcludeSemantics(
                                child: Row(
                                  key: _gutterKey,
                                  children: [
                                    DefaultCodeLineNumber(
                                      notifier: notifier,
                                      controller: controller,
                                      textStyle: codeStyle,
                                      focusedTextStyle: codeStyle,
                                    ),
                                    DefaultCodeChunkIndicator(
                                      width: 48,
                                      controller: chunks,
                                      notifier: notifier,
                                    ),
                                  ],
                                ),
                              );
                            },
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('editor-diagnostic-markers'),
                  painter: EditorDiagnosticMarkers(
                    geometry: geometry,
                    diagnostics: widget.providers.diagnostics,
                    color: colors.foreground,
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('editor-focus-border'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.focus.hasFocus
                          ? colors.cursor
                          : colors.gutter,
                      width: widget.focus.hasFocus ? 2 : 1,
                    ),
                  ),
                ),
              ),
              if (popup != null) _buildPopup(popup, constraints.biggest),
            ],
          ),
        ),
      ),
    );
  }
}
