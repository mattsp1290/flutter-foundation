import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/services.dart';

enum CatalogProviderMode { local, delayed, failing, unavailable }

/// Deterministic host fixture; no transport or external service is involved.
class CatalogEditorProvider implements BirbEditorProvider {
  const CatalogEditorProvider(this.mode);
  final CatalogProviderMode mode;

  Future<void> _respond() async {
    if (mode == CatalogProviderMode.delayed) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    if (mode == CatalogProviderMode.failing) {
      throw StateError('Fixture failure');
    }
  }

  @override
  Future<List<BirbEditorCompletion>> complete(BirbEditorRequest request) async {
    await _respond();
    return ['println', 'fmt.Println', 'return']
        .map(
          (label) => BirbEditorCompletion(
            label: label,
            detail: 'Local Go fixture',
            edit: BirbEditorEdit(
              range: TextRange.collapsed(request.position),
              text: label,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<BirbEditorHover?> hover(BirbEditorRequest request) async {
    await _respond();
    return const BirbEditorHover(
      text: 'Local Go fixture. The host supplies language information; editing works without it.',
    );
  }

  @override
  Future<List<BirbEditorDiagnostic>> diagnose(BirbEditorRequest request) async {
    await _respond();
    final start = request.source.indexOf('println');
    if (start < 0) return const [];
    return [
      BirbEditorDiagnostic(
        range: TextRange(start: start, end: start + 7),
        severity: BirbEditorDiagnosticSeverity.information,
        message: 'Local fixture: consider a structured output function.',
        code: 'demo',
      ),
    ];
  }
}
