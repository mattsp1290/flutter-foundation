import 'package:flutter/material.dart';

import 'editor_geometry.dart';
import 'language_provider.dart';

class EditorDiagnosticMarkers extends CustomPainter {
  EditorDiagnosticMarkers({
    required this.geometry,
    required this.diagnostics,
    required this.color,
  });
  final EditorGeometry geometry;
  final List<BirbEditorDiagnostic> diagnostics;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        geometry.gutter.dx,
        0,
        size.width - geometry.gutter.dx,
        size.height,
      ),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (final diagnostic in diagnostics) {
      for (final rect in geometry.range(diagnostic.range)) {
        if (rect.bottom < 0 || rect.top > size.height) continue;
        final y = rect.bottom - 2;
        if (diagnostic.severity == BirbEditorDiagnosticSeverity.error) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
        } else {
          final dash =
              diagnostic.severity == BirbEditorDiagnosticSeverity.warning
              ? 5.0
              : 2.0;
          for (var x = rect.left; x < rect.right; x += dash + 3) {
            canvas.drawLine(
              Offset(x, y),
              Offset((x + dash).clamp(x, rect.right), y),
              paint,
            );
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EditorDiagnosticMarkers oldDelegate) => true;
}
