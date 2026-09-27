import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

/// Guards command entry points, including input arriving before a readonly
/// rebuild. The upstream delegate forwards methods directly, so guarding just
/// its value setter would not guard edits executed inside the raw controller.
class GuardedEditorEngine extends CodeLineEditingControllerDelegate {
  GuardedEditorEngine({
    required super.delegate,
    required this.mutate,
    required this.onUndo,
    required this.onRedo,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
  });

  final void Function(VoidCallback operation, bool changesSource) mutate;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Future<void> Function() onCopy;
  final VoidCallback onCut;
  final VoidCallback onPaste;

  bool _changesSource(CodeLines lines) =>
      lines.asString(options.lineBreak, true, true) != text;

  @override
  set value(CodeLineEditingValue next) =>
      mutate(() => super.value = next, _changesSource(next.codeLines));
  @override
  set codeLines(CodeLines next) =>
      mutate(() => super.codeLines = next, _changesSource(next));
  @override
  set text(String next) => mutate(() => super.text = next, next != text);
  @override
  set textAsync(String next) => text = next;
  @override
  void edit(TextEditingValue newValue) =>
      mutate(() => super.edit(newValue), true);
  @override
  void replaceSelection(String replacement, [CodeLineSelection? selection]) =>
      mutate(() => super.replaceSelection(replacement, selection), true);
  @override
  void replaceAll(Pattern pattern, String replacement) =>
      mutate(() => super.replaceAll(pattern, replacement), true);
  @override
  void applyIndent() => mutate(super.applyIndent, true);
  @override
  void applyOutdent() => mutate(super.applyOutdent, true);
  @override
  void applyNewLine() => mutate(super.applyNewLine, true);
  @override
  void deleteSelectionLines([bool keepExtentOffset = true]) =>
      mutate(() => super.deleteSelectionLines(keepExtentOffset), true);
  @override
  void deleteLineForward() => mutate(super.deleteLineForward, true);
  @override
  void deleteLineBackward() => mutate(super.deleteLineBackward, true);
  @override
  void deleteSelection() => mutate(super.deleteSelection, true);
  @override
  void deleteBackward() => mutate(super.deleteBackward, true);
  @override
  void deleteForward() => mutate(super.deleteForward, true);
  @override
  void deleteWordBackward() => mutate(super.deleteWordBackward, true);
  @override
  void deleteWordForward() => mutate(super.deleteWordForward, true);
  @override
  void moveSelectionLinesUp() => mutate(super.moveSelectionLinesUp, true);
  @override
  void moveSelectionLinesDown() => mutate(super.moveSelectionLinesDown, true);
  @override
  void transposeCharacters() => mutate(super.transposeCharacters, true);
  @override
  void undo() => onUndo();
  @override
  void redo() => onRedo();
  @override
  Future<void> copy() => onCopy();
  @override
  void cut() => onCut();
  @override
  void paste() => onPaste();
}
