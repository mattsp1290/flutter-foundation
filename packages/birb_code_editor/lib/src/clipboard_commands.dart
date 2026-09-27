part of 'controller.dart';

extension _EditorClipboard on BirbEditorController {
  void _clipboardStatus(bool unavailable) {
    if (_disposed || _clipboardUnavailable == unavailable) return;
    _clipboardUnavailable = unavailable;
    _publish(_snapshot.origin);
  }

  Future<({bool succeeded, T? value})> _clipboardRequest<T>(
    Future<T> Function() request,
    int epoch,
  ) async {
    try {
      return (succeeded: true, value: await request());
    } on PlatformException {
      // Platform messages can include clipboard/source contents. Never expose
      // them, and never apply a late failure to a replacement document.
      if (epoch == _mutationEpoch) _clipboardStatus(true);
      return (succeeded: false, value: null);
    } on MissingPluginException {
      if (epoch == _mutationEpoch) _clipboardStatus(true);
      return (succeeded: false, value: null);
    }
  }

  TextRange _copyRange(BirbEditorSnapshot snapshot) {
    if (!snapshot.selection.isCollapsed) return snapshot.selection;
    final coordinates = BirbSourceCoordinates(snapshot.source);
    return coordinates.lineRange(
      coordinates.positionAt(snapshot.selection.extentOffset).line,
    );
  }

  Future<BirbEditorEditResult> _copy() async {
    final rejected = _guard(editing: false);
    if (rejected != null) return rejected;
    final epoch = _mutationEpoch;
    final range = _copyRange(_snapshot);
    final text = _snapshot.source.substring(range.start, range.end);
    final response = await _clipboardRequest(
      () => Clipboard.setData(ClipboardData(text: text)),
      epoch,
    );
    if (!response.succeeded) return BirbEditorEditResult.clipboardUnavailable;
    final afterCopy = _guard(editing: false);
    if (afterCopy != null) return afterCopy;
    if (epoch != _mutationEpoch) return BirbEditorEditResult.stale;
    _clipboardStatus(false);
    return BirbEditorEditResult.applied;
  }

  Future<BirbEditorEditResult> _paste() async {
    final rejected = _guard();
    if (rejected != null) return rejected;
    final captured = _snapshot;
    final epoch = _mutationEpoch;
    final response = await _clipboardRequest(
      () => Clipboard.getData(Clipboard.kTextPlain),
      epoch,
    );
    if (!response.succeeded) return BirbEditorEditResult.clipboardUnavailable;
    final afterRead = _guard();
    if (afterRead != null) return afterRead;
    if (epoch != _mutationEpoch || _snapshot.selection != captured.selection) {
      return BirbEditorEditResult.stale;
    }
    _clipboardStatus(false);
    final data = response.value;
    if (data?.text == null) return BirbEditorEditResult.unchanged;
    return applyEdits(
      expectedDocumentId: captured.documentId,
      expectedGeneration: captured.generation,
      edits: [BirbEditorEdit(range: captured.selection, text: data!.text!)],
    );
  }

  Future<BirbEditorEditResult> _cut() async {
    final rejected = _guard();
    if (rejected != null) return rejected;
    final captured = _snapshot;
    final epoch = _mutationEpoch;
    final range = _copyRange(captured);
    final response = await _clipboardRequest(
      () => Clipboard.setData(
        ClipboardData(text: captured.source.substring(range.start, range.end)),
      ),
      epoch,
    );
    if (!response.succeeded) return BirbEditorEditResult.clipboardUnavailable;
    final afterCopy = _guard();
    if (afterCopy != null) return afterCopy;
    if (epoch != _mutationEpoch) return BirbEditorEditResult.stale;
    _clipboardStatus(false);
    return applyEdits(
      expectedDocumentId: captured.documentId,
      expectedGeneration: captured.generation,
      edits: [BirbEditorEdit(range: range, text: '')],
    );
  }
}
