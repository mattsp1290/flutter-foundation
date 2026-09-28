import 'package:re_editor/re_editor.dart';

/// Preserve loaded separators and use the first one for newly inserted lines.
CodeLineEditingController createExactEngine(String source) {
  final separator = RegExp(r'\r\n|\r|\n').firstMatch(source)?.group(0);
  return CodeLineEditingController.fromText(
    source,
    CodeLineOptions(
      preserveLineBreaks: true,
      lineBreak: switch (separator) {
        '\r\n' => TextLineBreak.crlf,
        '\r' => TextLineBreak.cr,
        _ => TextLineBreak.lf,
      },
    ),
  );
}
