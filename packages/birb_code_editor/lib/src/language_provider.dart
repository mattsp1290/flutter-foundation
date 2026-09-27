import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'snapshot.dart';

/// Host-owned provider. No server, transport, persistence or disposal is owned
/// by the editor. All text is plain text and all offsets are raw UTF-16.
abstract class BirbEditorProvider {
  Future<List<BirbEditorCompletion>> complete(BirbEditorRequest request);
  Future<BirbEditorHover?> hover(BirbEditorRequest request);
  Future<List<BirbEditorDiagnostic>> diagnose(BirbEditorRequest request);
}

@immutable
class BirbEditorRequest {
  const BirbEditorRequest({
    required this.documentId,
    required this.generation,
    required this.source,
    required this.position,
    required this.requestId,
  });
  final String documentId;
  final int generation;
  final String source;
  final int position;
  final int requestId;
}

@immutable
class BirbEditorCompletion {
  BirbEditorCompletion({
    required this.label,
    required this.edit,
    this.detail = '',
    Iterable<BirbEditorEdit> additionalEdits = const [],
    this.selectionAfter,
  }) : additionalEdits = List.unmodifiable(additionalEdits);
  final String label;
  final String detail;
  final BirbEditorEdit edit;
  final List<BirbEditorEdit> additionalEdits;
  final TextSelection? selectionAfter;
}

@immutable
class BirbEditorHover {
  const BirbEditorHover({required this.text, this.range});
  final String text;
  final TextRange? range;
}

enum BirbEditorDiagnosticSeverity { error, warning, information, hint }

@immutable
class BirbEditorDiagnostic {
  const BirbEditorDiagnostic({
    required this.range,
    required this.severity,
    required this.message,
    this.code,
  });
  final TextRange range;
  final BirbEditorDiagnosticSeverity severity;
  final String message;
  final String? code;
}

enum BirbEditorProviderStatus {
  unavailable,
  idle,
  loading,
  ready,
  failed,
  timedOut,
  invalidResponse,
}

/// Hard response limits. Responses exceeding any limit are rejected in full.
abstract final class BirbEditorProviderLimits {
  static const completionItems = 100;
  static const diagnostics = 500;
  static const messageBytes = 16 * 1024;
  static const responseBytes = 256 * 1024;
  static const timeout = Duration(seconds: 5);
}
