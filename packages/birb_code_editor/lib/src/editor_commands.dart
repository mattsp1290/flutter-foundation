part of 'controller.dart';

extension _EditorCommands on _SourceEditorState {
  void _invokeCommand(EditorCommand command) {
    final controller = widget.controller;
    switch (command) {
      case EditorCommand.undo:
        controller.undo();
      case EditorCommand.redo:
        controller.redo();
      case EditorCommand.find:
        _openFind();
      case EditorCommand.copy:
        controller.copy();
      case EditorCommand.cut:
        controller.cut();
      case EditorCommand.paste:
        controller.paste();
      case EditorCommand.selectAll:
        controller.selectAll();
      case EditorCommand.indent:
        controller.indent();
      case EditorCommand.outdent:
        controller.outdent();
      case EditorCommand.comment:
        controller.toggleComment();
      case EditorCommand.wrap:
        _wrap = !_wrap;
        _changed();
      case EditorCommand.smaller:
        _fontScale = (_fontScale - .125).clamp(.75, 2);
        _changed();
      case EditorCommand.larger:
        _fontScale = (_fontScale + .125).clamp(.75, 2);
        _changed();
      case EditorCommand.fold:
        final selection = _engine.selection;
        if (selection.startIndex < selection.endIndex) {
          _engine.collapseChunk(selection.startIndex, selection.endIndex + 1);
        }
      case EditorCommand.unfold:
        for (var i = 0; i < _engine.codeLines.length; i++) {
          while (_engine.codeLines[i].chunkParent) {
            _engine.expandChunk(i);
          }
        }
      case EditorCommand.complete:
        _providers.requestCompletion();
      case EditorCommand.hover:
        _providers.requestHover();
      case EditorCommand.diagnostics:
        _providers.requestDiagnostics();
    }
  }

  Map<Type, Action<Intent>> get _shortcutActions => {
    CodeShortcutIndentIntent: CallbackAction<CodeShortcutIndentIntent>(
      onInvoke: (_) {
        if (_tabTraversal) {
          _leaveEditor(backward: false);
        } else {
          widget.controller.indent();
        }
        return null;
      },
    ),
    CodeShortcutOutdentIntent: CallbackAction<CodeShortcutOutdentIntent>(
      onInvoke: (_) {
        if (_tabTraversal) {
          _leaveEditor(backward: true);
        } else {
          widget.controller.outdent();
        }
        return null;
      },
    ),
    CodeShortcutFindIntent: CallbackAction<CodeShortcutFindIntent>(
      onInvoke: (_) {
        _openFind();
        return null;
      },
    ),
    CodeShortcutReplaceIntent: CallbackAction<CodeShortcutReplaceIntent>(
      onInvoke: (_) {
        _openFind();
        return null;
      },
    ),
    CodeShortcutEscIntent: CallbackAction<CodeShortcutEscIntent>(
      onInvoke: (_) {
        _escape();
        return null;
      },
    ),
  };
}
