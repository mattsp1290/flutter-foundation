import 'package:flutter/services.dart';

import 'snapshot.dart';
import 'source_coordinates.dart';

/// Validates the entire transaction before the engine sees any mutation.
class PreparedEditorTransaction {
  PreparedEditorTransaction._(
    this.result,
    this.edits,
    this.source,
    this.selection,
  );

  factory PreparedEditorTransaction.prepare(
    String source,
    List<BirbEditorEdit> edits,
    TextSelection? selectionAfter,
  ) {
    PreparedEditorTransaction reject(BirbEditorEditResult reason) =>
        PreparedEditorTransaction._(reason, const [], source, null);
    final coordinates = BirbSourceCoordinates(source);
    if (edits.any((edit) => !coordinates.isRange(edit.range))) {
      return reject(BirbEditorEditResult.invalidRange);
    }
    final sorted = List<BirbEditorEdit>.of(edits)
      ..sort((a, b) => a.range.start.compareTo(b.range.start));
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1].range;
      final current = sorted[i].range;
      if (current.start < previous.end || current.start == previous.start) {
        return reject(BirbEditorEditResult.overlappingEdits);
      }
    }
    var next = source;
    for (final edit in sorted.reversed) {
      next = next.replaceRange(edit.range.start, edit.range.end, edit.text);
    }
    var selection =
        selectionAfter ??
        (sorted.isEmpty
            ? null
            : TextSelection.collapsed(
                offset: sorted.first.range.start + sorted.first.text.length,
              ));
    final nextCoordinates = BirbSourceCoordinates(next);
    if (selectionAfter == null &&
        selection != null &&
        !nextCoordinates.isBoundary(selection.extentOffset)) {
      // An insertion may join existing CR/LF or surrogate halves. The default
      // caret goes after that joined unit; explicit invalid selections reject.
      selection = TextSelection.collapsed(offset: selection.extentOffset + 1);
    }
    if (selection != null && !nextCoordinates.isSelection(selection)) {
      return reject(BirbEditorEditResult.invalidRange);
    }
    // Touching edits can temporarily join CR+LF or surrogate halves before
    // the preceding edit runs. Replace that contiguous region in one step.
    final contiguous = <BirbEditorEdit>[];
    for (final edit in sorted) {
      if (contiguous.isNotEmpty &&
          contiguous.last.range.end == edit.range.start) {
        final previous = contiguous.removeLast();
        contiguous.add(
          BirbEditorEdit(
            range: TextRange(start: previous.range.start, end: edit.range.end),
            text: previous.text + edit.text,
          ),
        );
      } else {
        contiguous.add(edit);
      }
    }
    return PreparedEditorTransaction._(
      next == source
          ? BirbEditorEditResult.unchanged
          : BirbEditorEditResult.applied,
      List.unmodifiable(contiguous.reversed),
      next,
      selection,
    );
  }

  final BirbEditorEditResult result;
  final List<BirbEditorEdit> edits;
  final String source;
  final TextSelection? selection;
}
