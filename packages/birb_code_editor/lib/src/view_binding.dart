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
    _viewAdapter = null;
    _releaseRetiredAdapters();
  }

  void _releaseRetiredAdapters() {
    for (final adapter in List.of(_retiredAdapters)) {
      if (!identical(adapter, _viewAdapter)) {
        _retiredAdapters.remove(adapter);
        adapter.dispose();
      }
    }
  }

  GuardedEditorEngine _bindEngine(Object owner) {
    final adapter = _adapter;
    final attachment = _viewAttachment;
    _viewAdapter = adapter;
    bool current() =>
        !_disposed &&
        identical(_viewOwner, owner) &&
        identical(_viewAttachment, attachment) &&
        identical(_adapter, adapter);
    return GuardedEditorEngine(
      delegate: adapter.engine,
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
