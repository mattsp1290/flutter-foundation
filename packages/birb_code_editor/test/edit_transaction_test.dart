import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:birb_code_editor/src/edit_transaction.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BirbEditorEdit edit(int start, int end, String text) => BirbEditorEdit(
    range: TextRange(start: start, end: end),
    text: text,
  );

  test(
    'transaction preserves untouched separators and uses original offsets',
    () {
      final result = PreparedEditorTransaction.prepare('ab\r\ncd\ref\n', [
        edit(7, 8, 'XYZ'),
        edit(0, 1, '😀'),
      ], const TextSelection(baseOffset: 10, extentOffset: 2));
      expect(result.result, BirbEditorEditResult.applied);
      expect(result.source, '😀b\r\ncd\rXYZf\n');
      expect(result.edits.first.range.start, 7);
      expect(result.selection!.baseOffset, 10);
    },
  );

  test(
    'bad ranges, overlaps and resulting selection reject the whole batch',
    () {
      for (final edits in [
        [edit(0, 1, 'X'), edit(2, 3, 'Y')], // surrogate interior
        [edit(0, 1, 'X'), edit(4, 5, 'Y')], // CRLF interior
        [edit(0, 3, 'X'), edit(1, 3, 'Y')],
        [edit(1, 1, 'X'), edit(1, 1, 'Y')],
        [edit(-1, 0, 'X')],
      ]) {
        final result = PreparedEditorTransaction.prepare(
          'a😀\r\nb',
          edits,
          null,
        );
        expect(
          result.result,
          isIn([
            BirbEditorEditResult.invalidRange,
            BirbEditorEditResult.overlappingEdits,
          ]),
        );
        expect(result.source, 'a😀\r\nb');
        expect(result.edits, isEmpty);
      }
      final invalidSelection = PreparedEditorTransaction.prepare('abc', [
        edit(0, 1, '😀'),
      ], const TextSelection.collapsed(offset: 1));
      expect(invalidSelection.result, BirbEditorEditResult.invalidRange);
      expect(invalidSelection.source, 'abc');
    },
  );
}
