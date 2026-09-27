import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('engine retains homogeneous separators and full folded source', () {
    for (final lineBreak in TextLineBreak.values) {
      final source = [
        'package main',
        'func main() {',
        '\tprintln("😀")',
        '}',
        '',
      ].join(lineBreak.value);
      final controller = CodeLineEditingController.fromText(
        source,
        CodeLineOptions(lineBreak: lineBreak),
      );
      addTearDown(controller.dispose);
      expect(utf8.encode(controller.text), utf8.encode(source));
      controller.collapseChunk(1, 3);
      expect(utf8.encode(controller.text), utf8.encode(source));
      controller.selectAll();
      expect(controller.selectedText, source);
    }
  });

  test('source mutation is observable in the same call stack', () {
    final controller = CodeLineEditingController.fromText('');
    addTearDown(controller.dispose);
    var observed = '';
    controller.addListener(() => observed = controller.text);
    controller.replaceSelection('package main');
    expect(observed, 'package main');
    controller.undo();
    expect(observed, '');
    controller.redo();
    expect(observed, 'package main');
  });

  test('qualification: mixed separators must round trip exactly', () {
    const source = 'a\r\nb\rc\n';
    final controller = CodeLineEditingController.fromText(source);
    addTearDown(controller.dispose);
    expect(utf8.encode(controller.text), utf8.encode(source));
  });

  test('engine values lose the distinction between replacement separators', () {
    final lf = CodeLineEditingController.fromText('');
    final mixed = CodeLineEditingController.fromText('');
    addTearDown(lf.dispose);
    addTearDown(mixed.dispose);
    lf.replaceSelection('a\nb\nc\n');
    mixed.replaceSelection('a\r\nb\rc\n');
    expect(mixed.value, lf.value);
    mixed.undo();
    mixed.redo();
    expect(mixed.value, lf.value);
  });
}
