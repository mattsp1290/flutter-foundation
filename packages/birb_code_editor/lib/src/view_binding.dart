part of 'controller.dart';

extension _EditorViewBinding on BirbEditorController {
  void _attachView(Object owner) {
    if (_disposed) throw StateError('Editor controller is disposed');
    if (_viewOwner != null) {
      throw StateError('An editor controller supports one attached view');
    }
    _viewOwner = owner;
    _viewAttachment = Object();
    _mutationEpoch++;
  }

  void _detachView(Object owner, Offset offset) {
    if (!identical(_viewOwner, owner)) return;
    _scrollOffset = offset;
    _mutationEpoch++;
    _viewOwner = null;
    _viewAttachment = null;
    _viewEngine = null;
    _releaseRetiredEngines();
  }

  void _releaseRetiredEngines() {
    for (final engine in List.of(_retiredEngines)) {
      if (!identical(engine, _viewEngine)) {
        _retiredEngines.remove(engine);
        engine.dispose();
      }
    }
  }

  GuardedEditorEngine _bindEngine(Object owner) {
    final engine = _engine;
    final attachment = _viewAttachment;
    _viewEngine = engine;
    bool current() =>
        !_disposed &&
        identical(_viewOwner, owner) &&
        identical(_viewAttachment, attachment) &&
        identical(_engine, engine);
    return GuardedEditorEngine(
      delegate: engine,
      isCurrent: current,
      mutate: (operation, changesSource) {
        if (!current() || _notifying || (changesSource && _readOnly)) return;
        _batchDepth++;
        try {
          operation();
        } finally {
          _batchDepth--;
          if (_batchDepth == 0) _publish(BirbEditorOrigin.user);
        }
      },
      onUndo: () {
        if (current()) undo();
      },
      onRedo: () {
        if (current()) redo();
      },
      onCopy: () async {
        if (current()) await copy();
      },
      onCut: () {
        if (current()) cut();
      },
      onPaste: () {
        if (current()) paste();
      },
    );
  }
}
