import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

/// W1 adapter: owns an exact-source engine and synchronous source subscription.
/// Product identity, provider and command contracts are added only after W1.
class EngineAdapter {
  EngineAdapter(String source, {required this.onSourceChanged})
    : engine = CodeLineEditingController.fromText(
        source,
        CodeLineOptions(
          preserveLineBreaks: true,
          lineBreak: _lineBreak(source),
        ),
      ),
      _source = source {
    engine.addListener(_onEngineChanged);
  }

  final CodeLineEditingController engine;
  final ValueChanged<String> onSourceChanged;
  String _source;

  String get source => _source;

  static TextLineBreak _lineBreak(String source) {
    final match = RegExp(r'\r\n|\r|\n').firstMatch(source)?.group(0);
    return switch (match) {
      '\r\n' => TextLineBreak.crlf,
      '\r' => TextLineBreak.cr,
      _ => TextLineBreak.lf,
    };
  }

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
