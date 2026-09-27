import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import 'edit_transaction.dart';
import 'engine_adapter.dart';
import 'editor_surface.dart';
import 'editor_status.dart';
import 'diagnostics_panel.dart';
import 'editor_chrome.dart';
import 'find_model.dart';
import 'find_panel.dart';
import 'guarded_engine.dart';
import 'language_provider.dart';
import 'provider_coordinator.dart';
import 'snapshot.dart';
import 'source_coordinates.dart';

part 'editor.dart';
part 'editor_commands.dart';
part 'view_binding.dart';

/// Host-owned exact source and engine history. Dispose after detaching the view.
///
/// Text listeners run synchronously. Nested mutations return [BirbEditorEditResult.reentrant].
/// Listener failures are reported through FlutterError with source-free details.
class BirbEditorController implements Listenable {
  BirbEditorController({
    required this._documentId,
    String source = '',
    this._readOnly = false,
  }) {
    _adapter = _createAdapter(source);
    _snapshot = _capture(BirbEditorOrigin.hostReplacement);
  }

  late EngineAdapter _adapter;
  late BirbEditorSnapshot _snapshot;
  String _documentId;
  int _generation = 0;
  int _mutationEpoch = 0;
  bool _readOnly;
  bool _disposed = false;
  bool _notifying = false;
  int _batchDepth = 0;
  final _listeners = <VoidCallback>[];
  final _textListeners = <ValueChanged<BirbEditorSnapshot>>[];
  Object? _viewOwner;
  EngineAdapter? _viewAdapter;
  final _retiredAdapters = <EngineAdapter>[];
  Offset _scrollOffset = Offset.zero;

  BirbEditorSnapshot get snapshot => _snapshot;

  EngineAdapter _createAdapter(String source) {
    final adapter = EngineAdapter(source, onSourceChanged: (_) {});
    adapter.engine.addListener(_engineChanged);
    return adapter;
  }

  @override
  void addListener(VoidCallback listener) {
    if (_disposed) throw StateError('Editor controller is disposed');
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void addTextListener(ValueChanged<BirbEditorSnapshot> listener) {
    if (_disposed) throw StateError('Editor controller is disposed');
    _textListeners.add(listener);
  }

  void removeTextListener(ValueChanged<BirbEditorSnapshot> listener) =>
      _textListeners.remove(listener);

  BirbEditorEditResult? _guard({bool editing = true}) {
    if (_disposed) return BirbEditorEditResult.disposed;
    if (_notifying) return BirbEditorEditResult.reentrant;
    if (editing && _readOnly) return BirbEditorEditResult.readOnly;
    if (editing &&
        !_snapshot.composing.isCollapsed &&
        _snapshot.composing.isValid) {
      return BirbEditorEditResult.composing;
    }
    return null;
  }

  BirbEditorSnapshot _capture(BirbEditorOrigin origin) {
    final engine = _adapter.engine;
    final source = engine.text;
    final coordinates = BirbSourceCoordinates(source);
    final selection = engine.unfoldLineSelection;
    final composing = engine.composing;
    final lineStart = coordinates.lineRange(selection.baseIndex).start;
    return BirbEditorSnapshot(
      documentId: _documentId,
      generation: _generation,
      source: source,
      selection: TextSelection(
        baseOffset: coordinates.offsetAt(
          BirbEditorPosition(selection.baseIndex, selection.baseOffset),
        ),
        extentOffset: coordinates.offsetAt(
          BirbEditorPosition(selection.extentIndex, selection.extentOffset),
        ),
        affinity: selection.extentAffinity,
      ),
      composing: composing.isValid
          ? TextRange(
              start: lineStart + composing.start,
              end: lineStart + composing.end,
            )
          : TextRange.empty,
      readOnly: _readOnly,
      capabilities: BirbEditorCapabilities(
        canEdit: !_readOnly,
        canUndo: !_readOnly && !engine.isComposing && engine.canUndo,
        canRedo: !_readOnly && !engine.isComposing && engine.canRedo,
        canCopy: source.isNotEmpty,
      ),
      origin: origin,
    );
  }

  void _engineChanged() {
    if (_batchDepth == 0 && !_disposed) _publish(BirbEditorOrigin.user);
  }

  void _publish(BirbEditorOrigin origin, {bool replacement = false}) {
    final textChanged = replacement || _adapter.engine.text != _snapshot.source;
    if (textChanged) _generation++;
    _mutationEpoch++;
    _snapshot = _capture(origin);
    _notifying = true;
    try {
      if (textChanged) {
        for (final listener in List.of(_textListeners)) {
          if (_textListeners.contains(listener)) {
            _callListener(() => listener(_snapshot));
          }
        }
      }
      for (final listener in List.of(_listeners)) {
        if (_listeners.contains(listener)) _callListener(listener);
      }
    } finally {
      _notifying = false;
    }
  }

  void _callListener(VoidCallback listener) {
    try {
      listener();
    } catch (_, stack) {
      // A subscriber's exception may itself contain document text.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError('An editor subscriber failed'),
          stack: stack,
          library: 'birb_code_editor',
        ),
      );
    }
  }

  BirbEditorEditResult _command(VoidCallback command, BirbEditorOrigin origin) {
    final rejected = _guard();
    if (rejected != null) return rejected;
    final before = _snapshot.source;
    _batchDepth++;
    try {
      command();
    } finally {
      _batchDepth--;
      _publish(origin);
    }
    return before == _snapshot.source
        ? BirbEditorEditResult.unchanged
        : BirbEditorEditResult.applied;
  }

  BirbEditorEditResult replaceDocument({
    required String documentId,
    required String source,
  }) {
    final rejected = _guard(editing: false);
    if (rejected != null) return rejected;
    final previous = _adapter;
    _adapter = _createAdapter(source);
    previous.engine.removeListener(_engineChanged);
    _retiredAdapters.add(previous);
    _releaseRetiredAdapters();
    _documentId = documentId;
    _publish(BirbEditorOrigin.hostReplacement, replacement: true);
    return BirbEditorEditResult.applied;
  }

  BirbEditorEditResult setReadOnly(bool value) {
    final rejected = _guard(editing: false);
    if (rejected != null) return rejected;
    if (value == _readOnly) return BirbEditorEditResult.unchanged;
    _readOnly = value;
    _publish(_snapshot.origin);
    return BirbEditorEditResult.applied;
  }

  CodeLineSelection _engineSelection(TextSelection selection) {
    final coordinates = BirbSourceCoordinates(_adapter.engine.text);
    final base = coordinates.positionAt(selection.baseOffset);
    final extent = coordinates.positionAt(selection.extentOffset);
    int reveal(int line) {
      var index = _adapter.engine.lineIndex2Index(line);
      while (_adapter.engine.index2lineIndex(index.index) != line) {
        _adapter.engine.expandChunk(index.index);
        index = _adapter.engine.lineIndex2Index(line);
      }
      return index.index;
    }

    // Expanding either endpoint can change the other's visible index.
    reveal(base.line);
    reveal(extent.line);
    return CodeLineSelection(
      baseIndex: reveal(base.line),
      baseOffset: base.column,
      extentIndex: reveal(extent.line),
      extentOffset: extent.column,
      baseAffinity: selection.affinity,
      extentAffinity: selection.affinity,
    );
  }

  BirbEditorEditResult setSelection(TextSelection selection) {
    final rejected = _guard(editing: false);
    if (rejected != null) return rejected;
    if (!BirbSourceCoordinates(_snapshot.source).isSelection(selection)) {
      return BirbEditorEditResult.invalidRange;
    }
    _batchDepth++;
    try {
      _adapter.engine.selection = _engineSelection(selection);
      _adapter.engine.makeCursorVisible();
    } finally {
      _batchDepth--;
      _publish(_snapshot.origin);
    }
    return BirbEditorEditResult.applied;
  }

  BirbEditorEditResult applyEdits({
    required String expectedDocumentId,
    required int expectedGeneration,
    required List<BirbEditorEdit> edits,
    TextSelection? selectionAfter,
  }) {
    final rejected = _guard();
    if (rejected != null) return rejected;
    if (expectedDocumentId != _documentId ||
        expectedGeneration != _generation) {
      return BirbEditorEditResult.stale;
    }
    final prepared = PreparedEditorTransaction.prepare(
      _snapshot.source,
      edits,
      selectionAfter,
    );
    if (prepared.result != BirbEditorEditResult.applied &&
        prepared.result != BirbEditorEditResult.unchanged) {
      return prepared.result;
    }
    return _command(() {
      _adapter.engine.runRevocableOp(() {
        for (final edit in prepared.edits) {
          _adapter.engine.replaceSelection(
            edit.text,
            _engineSelection(
              TextSelection(
                baseOffset: edit.range.start,
                extentOffset: edit.range.end,
              ),
            ),
          );
        }
        if (prepared.selection != null) {
          _adapter.engine.selection = _engineSelection(prepared.selection!);
        }
      });
    }, BirbEditorOrigin.command);
  }

  BirbEditorEditResult undo() =>
      _command(_adapter.engine.undo, BirbEditorOrigin.undo);
  BirbEditorEditResult redo() =>
      _command(_adapter.engine.redo, BirbEditorOrigin.redo);
  BirbEditorEditResult indent() =>
      _command(_adapter.engine.applyIndent, BirbEditorOrigin.command);
  BirbEditorEditResult outdent() =>
      _command(_adapter.engine.applyOutdent, BirbEditorOrigin.command);
  BirbEditorEditResult selectAll() => setSelection(
    TextSelection(baseOffset: 0, extentOffset: _snapshot.source.length),
  );

  BirbEditorEditResult toggleComment() => _command(() {
    _adapter.engine.runRevocableOp(() {
      _adapter.engine.value = DefaultCodeCommentFormatter(
        singleLinePrefix: '//',
      ).format(_adapter.engine.value, '  ', true);
    });
  }, BirbEditorOrigin.command);

  Future<BirbEditorEditResult> copy() async {
    final rejected = _guard(editing: false);
    if (rejected != null) return rejected;
    final selection = _snapshot.selection;
    final range = selection.isCollapsed
        ? BirbSourceCoordinates(_snapshot.source).lineRange(
            BirbSourceCoordinates(_snapshot.source)
                .positionAt(selection.extentOffset)
                .line,
          )
        : selection;
    await Clipboard.setData(
      ClipboardData(text: _snapshot.source.substring(range.start, range.end)),
    );
    return BirbEditorEditResult.applied;
  }

  Future<BirbEditorEditResult> paste() async {
    final rejected = _guard();
    if (rejected != null) return rejected;
    final captured = _snapshot;
    final epoch = _mutationEpoch;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final afterRead = _guard();
    if (afterRead != null) return afterRead;
    if (epoch != _mutationEpoch) return BirbEditorEditResult.stale;
    if (_snapshot.selection != captured.selection) {
      return BirbEditorEditResult.stale;
    }
    if (data == null) return BirbEditorEditResult.unchanged;
    return applyEdits(
      expectedDocumentId: captured.documentId,
      expectedGeneration: captured.generation,
      edits: [BirbEditorEdit(range: captured.selection, text: data.text ?? '')],
    );
  }

  Future<BirbEditorEditResult> cut() async {
    final rejected = _guard();
    if (rejected != null) return rejected;
    final captured = _snapshot;
    final epoch = _mutationEpoch;
    final coordinates = BirbSourceCoordinates(captured.source);
    final range = captured.selection.isCollapsed
        ? coordinates.lineRange(
            coordinates.positionAt(captured.selection.extentOffset).line,
          )
        : captured.selection;
    await Clipboard.setData(
      ClipboardData(text: captured.source.substring(range.start, range.end)),
    );
    final afterCopy = _guard();
    if (afterCopy != null) return afterCopy;
    if (_mutationEpoch != epoch) return BirbEditorEditResult.stale;
    return applyEdits(
      expectedDocumentId: captured.documentId,
      expectedGeneration: captured.generation,
      edits: [BirbEditorEdit(range: range, text: '')],
    );
  }

  List<TextRange> find(String query, {bool caseSensitive = true}) {
    if (query.isEmpty || _disposed) return const [];
    final coordinates = BirbSourceCoordinates(_snapshot.source);
    return List.unmodifiable(
      RegExp(RegExp.escape(query), caseSensitive: caseSensitive)
          .allMatches(_snapshot.source)
          .map((match) => TextRange(start: match.start, end: match.end))
          .where(coordinates.isRange),
    );
  }

  void dispose() {
    if (_disposed) return;
    if (_viewOwner != null) {
      throw StateError(
        'Detach the editor view before disposing its controller',
      );
    }
    if (_notifying) {
      throw StateError('Cannot dispose the editor during notification');
    }
    _disposed = true;
    _adapter.engine.removeListener(_engineChanged);
    _adapter.dispose();
    _releaseRetiredAdapters();
    _listeners.clear();
    _textListeners.clear();
  }
}
