import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';
import 'package:birb_code_editor/src/engine_factory.dart';

/// Test-only W1 observer; production recovery belongs to BirbEditorController.
class QualificationEngineObserver {
  QualificationEngineObserver(String source, {required this.onSourceChanged})
    : engine = createExactEngine(source),
      _source = source {
    engine.addListener(_onEngineChanged);
  }

  final CodeLineEditingController engine;
  final ValueChanged<String> onSourceChanged;
  String _source;

  String get source => _source;

  void _onEngineChanged() {
    final next = engine.text;
    if (next == _source) return;
    _source = next;
    onSourceChanged(next);
  }

  void dispose() {
    engine.removeListener(_onEngineChanged);
    engine.dispose();
  }
}
