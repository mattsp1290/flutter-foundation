import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum BirbEditorOrigin { user, command, undo, redo, hostReplacement }

enum BirbEditorState { ready, error }

enum BirbEditorEditResult {
  applied,
  unchanged,
  stale,
  readOnly,
  composing,
  invalidRange,
  overlappingEdits,
  reentrant,
  disposed,
  clipboardUnavailable,
}

@immutable
class BirbEditorCapabilities {
  const BirbEditorCapabilities({
    required this.canEdit,
    required this.canUndo,
    required this.canRedo,
    required this.canCopy,
    this.canFind = true,
  });
  final bool canEdit;
  final bool canUndo;
  final bool canRedo;
  final bool canCopy;
  final bool canFind;
}

/// One complete immutable observation of the host's exact document.
@immutable
class BirbEditorSnapshot {
  const BirbEditorSnapshot({
    required this.documentId,
    required this.generation,
    required this.source,
    required this.selection,
    required this.composing,
    required this.readOnly,
    required this.capabilities,
    required this.origin,
    this.state = BirbEditorState.ready,
    this.clipboardUnavailable = false,
  });
  final String documentId;
  final int generation;
  final String source;
  final TextSelection selection;
  final TextRange composing;
  final bool readOnly;
  final BirbEditorCapabilities capabilities;
  final BirbEditorOrigin origin;
  final BirbEditorState state;

  /// The last current clipboard operation failed; a successful retry clears it.
  final bool clipboardUnavailable;
}

@immutable
class BirbEditorEdit {
  const BirbEditorEdit({required this.range, required this.text});
  final TextRange range;
  final String text;
}
