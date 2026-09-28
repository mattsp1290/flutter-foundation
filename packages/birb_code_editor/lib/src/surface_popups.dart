part of 'editor_surface.dart';

enum _PopupKind { selection, completion, hover }

typedef _PopupPresentation = ({_PopupKind kind, Rect anchor});

extension _SurfacePopups on _EditorSurfaceState {
  _PopupPresentation? _resolvePopup(EditorGeometry geometry) {
    if (_toolbarAnchor case final anchor?) {
      return (kind: _PopupKind.selection, anchor: anchor);
    }
    final snapshot = widget.controller.snapshot;
    if (_items.isNotEmpty) {
      final anchor = geometry.caret(snapshot.selection.extentOffset);
      return anchor == null
          ? null
          : (kind: _PopupKind.completion, anchor: anchor);
    }
    if (widget.providers.hover != null) {
      final anchor = geometry.caret(
        widget.providers.hoverPosition ?? snapshot.selection.extentOffset,
      );
      if (anchor != null) return (kind: _PopupKind.hover, anchor: anchor);
    }
    return null;
  }

  bool get _completionOwnsKeys =>
      _resolvePopup(_geometry)?.kind == _PopupKind.completion;

  Map<Type, Action<Intent>> _popupActions(_PopupPresentation? popup) => {
    ...widget.actions,
    if (popup?.kind == _PopupKind.selection)
      CodeShortcutEscIntent: CallbackAction<CodeShortcutEscIntent>(
        onInvoke: (_) {
          _dismissToolbar();
          return null;
        },
      ),
    if (popup?.kind == _PopupKind.completion) ...{
      CodeShortcutCursorMoveIntent:
          CallbackAction<CodeShortcutCursorMoveIntent>(
            onInvoke: (intent) {
              if (_completionOwnsKeys) {
                _moveCompletion(intent.direction);
              } else {
                widget.engine.moveCursor(intent.direction);
              }
              return null;
            },
          ),
      CodeShortcutNewLineIntent: CallbackAction<CodeShortcutNewLineIntent>(
        onInvoke: (_) {
          if (_completionOwnsKeys) {
            _accept(_items[_selected]);
          } else {
            widget.engine.applyNewLine();
          }
          return null;
        },
      ),
    },
  };

  Widget _buildPopup(_PopupPresentation popup, Size size) {
    final snapshot = widget.controller.snapshot;
    return switch (popup.kind) {
      _PopupKind.selection => EditorProviderPopup(
        anchor: popup.anchor,
        size: size,
        title: 'Selection',
        close: _dismissToolbar,
        child: EditorSelectionToolbar(
          controller: widget.controller,
          dismiss: _dismissToolbar,
        ),
      ),
      _PopupKind.completion => EditorProviderPopup(
        anchor: popup.anchor,
        size: size,
        title: 'Completions',
        close: widget.providers.dismiss,
        child: EditorCompletionList(
          items: _items,
          selected: _selected,
          scrollController: _completionScroll,
          accept: (item) {
            if (_completionOwnsKeys) _accept(item);
          },
          enabled:
              snapshot.capabilities.canEdit && snapshot.composing.isCollapsed,
        ),
      ),
      _PopupKind.hover => EditorProviderPopup(
        anchor: popup.anchor,
        size: size,
        title: 'Hover information',
        fitContent: true,
        close: widget.providers.dismiss,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Text(widget.providers.hover!.text),
        ),
      ),
    };
  }
}
