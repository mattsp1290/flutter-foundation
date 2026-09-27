import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all raw boundaries round trip through logical coordinates', () {
    for (final source in ['', 'abc', 'a😀\r\nb\rc\n', '\r\n\n\r', '😀😀']) {
      final coordinates = BirbSourceCoordinates(source);
      for (var offset = 0; offset <= source.length; offset++) {
        if (coordinates.isBoundary(offset)) {
          expect(coordinates.offsetAt(coordinates.positionAt(offset)), offset);
        } else {
          expect(() => coordinates.positionAt(offset), throwsRangeError);
        }
      }
    }
  });

  test(
    'CRLF and surrogate interiors are invalid; logical columns exclude EOL',
    () {
      final coordinates = BirbSourceCoordinates('a😀\r\nb\rc\n');
      expect(coordinates.lineCount, 4);
      expect(coordinates.isBoundary(2), isFalse);
      expect(coordinates.isBoundary(4), isFalse);
      expect(coordinates.positionAt(5), const BirbEditorPosition(1, 0));
      expect(coordinates.lineRange(0), const TextRange(start: 0, end: 3));
      expect(
        () => coordinates.offsetAt(const BirbEditorPosition(0, 4)),
        throwsRangeError,
      );
      expect(
        coordinates.isSelection(
          const TextSelection(baseOffset: 8, extentOffset: 1),
        ),
        isTrue,
      );
      expect(coordinates.isRange(const TextRange(start: 5, end: 1)), isFalse);
    },
  );
}
