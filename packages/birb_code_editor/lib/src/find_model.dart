import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'snapshot.dart';
import 'source_coordinates.dart';

/// View-owned search state; replacement uses the controller's atomic edit API.
class EditorFindModel extends ChangeNotifier {
  EditorFindModel(this.controller) {
    _generation = controller.snapshot.generation;
    controller.addListener(_documentChanged);
  }

  final BirbEditorController controller;
  late int _generation;
  String query = '';
  String replacement = '';
  bool caseSensitive = false;
  bool wholeWord = false;
  bool regex = false;
  bool invalidPattern = false;
  List<TextRange> matches = const [];
  int current = 0;

  void _documentChanged() {
    if (_generation == controller.snapshot.generation) return;
    _generation = controller.snapshot.generation;
    refresh();
  }

  void refresh() {
    invalidPattern = false;
    matches = const [];
    if (query.isNotEmpty) {
      try {
        final pattern = regex ? query : RegExp.escape(query);
        final expression = RegExp(
          wholeWord ? '\\b(?:$pattern)\\b' : pattern,
          caseSensitive: caseSensitive,
          multiLine: true,
        );
        final source = controller.snapshot.source;
        final coordinates = BirbSourceCoordinates(source);
        matches = List.unmodifiable(
          expression
              .allMatches(source)
              .map((match) => TextRange(start: match.start, end: match.end))
              .where(coordinates.isRange),
        );
      } on FormatException {
        invalidPattern = true;
      }
    }
    current = matches.isEmpty ? 0 : current.clamp(0, matches.length - 1);
    notifyListeners();
  }

  void navigate(int delta) {
    if (matches.isEmpty) return;
    current = (current + delta) % matches.length;
    final range = matches[current];
    controller.setSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    notifyListeners();
  }

  BirbEditorEditResult replace({required bool all}) {
    if (matches.isEmpty) return BirbEditorEditResult.unchanged;
    final snapshot = controller.snapshot;
    return controller.applyEdits(
      expectedDocumentId: snapshot.documentId,
      expectedGeneration: snapshot.generation,
      edits: (all ? matches : [matches[current]])
          .map((range) => BirbEditorEdit(range: range, text: replacement))
          .toList(),
    );
  }

  @override
  void dispose() {
    controller.removeListener(_documentChanged);
    super.dispose();
  }
}
