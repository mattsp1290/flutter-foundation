import 'dart:convert';

import 'edit_transaction.dart';
import 'language_provider.dart';
import 'snapshot.dart';
import 'source_coordinates.dart';

/// Counts UTF-8 payload bytes before responses enter presentation state.
class ProviderResponseBudget {
  int _bytes = 0;

  bool add(String text, {bool message = true}) {
    // UTF-8 uses at least one byte per UTF-16 unit for valid input, except a
    // surrogate pair (four bytes for two units), so this avoids large encoding.
    if (text.length > BirbEditorProviderLimits.responseBytes ||
        (message && text.length > BirbEditorProviderLimits.messageBytes)) {
      return false;
    }
    final length = utf8.encode(text).length;
    _bytes += length;
    return (!message || length <= BirbEditorProviderLimits.messageBytes) &&
        _bytes <= BirbEditorProviderLimits.responseBytes;
  }
}

bool validCompletions(
  BirbEditorRequest request,
  List<BirbEditorCompletion> items,
) {
  if (items.length > BirbEditorProviderLimits.completionItems) return false;
  final budget = ProviderResponseBudget();
  for (final item in items) {
    if (!budget.add(item.label) || !budget.add(item.detail)) return false;
    // Also bound object count: zero-length edit strings must not evade limits.
    if (item.additionalEdits.length >
        BirbEditorProviderLimits.completionItems) {
      return false;
    }
    final edits = [item.edit, ...item.additionalEdits];
    for (final edit in edits) {
      if (!budget.add(edit.text, message: false)) return false;
    }
    final transaction = PreparedEditorTransaction.prepare(
      request.source,
      edits,
      item.selectionAfter,
    );
    if (transaction.result != BirbEditorEditResult.applied &&
        transaction.result != BirbEditorEditResult.unchanged) {
      return false;
    }
  }
  return true;
}

bool validHover(BirbEditorRequest request, BirbEditorHover? hover) =>
    hover == null ||
    (ProviderResponseBudget().add(hover.text) &&
        (hover.range == null ||
            BirbSourceCoordinates(request.source).isRange(hover.range!)));

bool validDiagnostics(
  BirbEditorRequest request,
  List<BirbEditorDiagnostic> items,
) {
  if (items.length > BirbEditorProviderLimits.diagnostics) return false;
  final budget = ProviderResponseBudget();
  final coordinates = BirbSourceCoordinates(request.source);
  for (final item in items) {
    if (!coordinates.isRange(item.range) ||
        !budget.add(item.message) ||
        (item.code != null && !budget.add(item.code!))) {
      return false;
    }
  }
  return true;
}
