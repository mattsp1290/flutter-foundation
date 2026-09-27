import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'source_coordinates.dart';

/// Converts public engine paragraph geometry into surface-local coordinates.
class EditorGeometry {
  EditorGeometry({
    required this.engine,
    required this.paragraphs,
    required this.gutter,
    required String source,
  }) : coordinates = BirbSourceCoordinates(source);
  final CodeLineEditingController engine;
  final List<CodeLineRenderParagraph> paragraphs;
  final Offset gutter;
  final BirbSourceCoordinates coordinates;

  int? _logicalLine(CodeLineRenderParagraph paragraph) {
    if (paragraph.index < 0 || paragraph.index >= engine.codeLines.length) {
      return null;
    }
    final line = engine.index2lineIndex(paragraph.index);
    return line >= 0 && line < coordinates.lineCount ? line : null;
  }

  Rect? caret(int rawOffset) {
    if (!coordinates.isBoundary(rawOffset)) return null;
    final position = coordinates.positionAt(rawOffset);
    for (final paragraph in paragraphs) {
      if (_logicalLine(paragraph) != position.line) continue;
      final offset = paragraph.getOffset(TextPosition(offset: position.column));
      if (offset == null) return null;
      return (offset + paragraph.offset + gutter) &
          Size(2, paragraph.preferredLineHeight);
    }
    return null;
  }

  List<Rect> range(TextRange rawRange) {
    final result = <Rect>[];
    for (final paragraph in paragraphs) {
      final logical = _logicalLine(paragraph);
      if (logical == null) continue;
      final line = coordinates.lineRange(logical);
      final start = math.max(line.start, rawRange.start);
      final end = math.min(line.end, rawRange.end);
      if (start > end || (start == end && !rawRange.isCollapsed)) continue;
      if (rawRange.isCollapsed) {
        final rect = caret(rawRange.start);
        if (rect != null) result.add(rect);
        break;
      }
      result.addAll(
        paragraph
            .getRangeRects(
              TextRange(start: start - line.start, end: end - line.start),
            )
            .map((rect) => rect.shift(paragraph.offset + gutter)),
      );
    }
    return result;
  }

  int? positionAt(Offset local) {
    if (local.dx < gutter.dx) return null;
    final point = local - gutter;
    for (final paragraph in paragraphs) {
      if (!paragraph.inVerticalRange(point)) continue;
      final position = paragraph.getPosition(point - paragraph.offset);
      final logical = _logicalLine(paragraph);
      if (logical == null) continue;
      final line = coordinates.lineRange(logical);
      final offset = (line.start + position.offset).clamp(line.start, line.end);
      return coordinates.isBoundary(offset) ? offset : null;
    }
    return null;
  }
}
