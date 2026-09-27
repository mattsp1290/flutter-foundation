import 'package:flutter/services.dart';

/// Zero-based logical source position, independent of wrapping and folding.
class BirbEditorPosition {
  const BirbEditorPosition(this.line, this.column);
  final int line;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is BirbEditorPosition &&
      line == other.line &&
      column == other.column;
  @override
  int get hashCode => Object.hash(line, column);
}

/// Exact raw UTF-16 coordinate index. CRLF occupies two code units.
class BirbSourceCoordinates {
  BirbSourceCoordinates(this.source) {
    final starts = <int>[0];
    final ends = <int>[];
    for (final separator in RegExp(r'\r\n|\r|\n').allMatches(source)) {
      ends.add(separator.start);
      starts.add(separator.end);
    }
    ends.add(source.length);
    _starts = List.unmodifiable(starts);
    _ends = List.unmodifiable(ends);
  }

  final String source;
  late final List<int> _starts;
  late final List<int> _ends;
  int get lineCount => _starts.length;

  bool isBoundary(int offset) {
    if (offset < 0 || offset > source.length) return false;
    if (offset == 0 || offset == source.length) return true;
    final before = source.codeUnitAt(offset - 1);
    final after = source.codeUnitAt(offset);
    return !(before == 13 && after == 10) &&
        !(before >= 0xd800 &&
            before <= 0xdbff &&
            after >= 0xdc00 &&
            after <= 0xdfff);
  }

  bool isRange(TextRange range) =>
      range.start <= range.end &&
      isBoundary(range.start) &&
      isBoundary(range.end);

  bool isSelection(TextSelection selection) =>
      isBoundary(selection.baseOffset) && isBoundary(selection.extentOffset);

  BirbEditorPosition positionAt(int offset) {
    if (!isBoundary(offset)) {
      throw RangeError.value(offset, 'offset', 'Invalid source boundary');
    }
    var low = 0;
    var high = _starts.length;
    while (low + 1 < high) {
      final middle = (low + high) ~/ 2;
      if (_starts[middle] <= offset) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return BirbEditorPosition(low, offset - _starts[low]);
  }

  int offsetAt(BirbEditorPosition position) {
    final line = position.line;
    if (line < 0 ||
        line >= lineCount ||
        position.column < 0 ||
        position.column > _ends[line] - _starts[line]) {
      throw RangeError('Position is outside the source');
    }
    final offset = _starts[line] + position.column;
    if (!isBoundary(offset)) {
      throw RangeError('Position splits a source character');
    }
    return offset;
  }

  TextRange lineRange(int line) {
    if (line < 0 || line >= lineCount) throw RangeError.index(line, _starts);
    return TextRange(start: _starts[line], end: _ends[line]);
  }
}
