import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:birb_code_editor/src/engine_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('folded public positions map to exact CRLF and UTF-16 offsets', () {
    const source = 'a😀\r\nb\rc\n';
    final controller = CodeLineEditingController.fromText(
      source,
      const CodeLineOptions(preserveLineBreaks: true),
    );
    addTearDown(controller.dispose);
    controller.collapseChunk(0, 2);
    controller.selection = const CodeLineSelection.collapsed(
      index: 1,
      offset: 1,
    );
    expect(controller.unfoldLineSelection.extentIndex, 2);
    var rawOffset = controller.selection.extentOffset;
    for (var i = 0; i < controller.selection.extentIndex; i++) {
      final line = controller.codeLines[i];
      rawOffset +=
          line.asString(0, TextLineBreak.lf, true).length +
          line.trailingLineBreak(TextLineBreak.lf).value.length;
    }
    expect(rawOffset, 8);
    expect(source.substring(0, rawOffset), 'a😀\r\nb\rc');
    expect(controller.text, source);
  });

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
    final controller = CodeLineEditingController.fromText(
      source,
      const CodeLineOptions(preserveLineBreaks: true),
    );
    addTearDown(controller.dispose);
    expect(utf8.encode(controller.text), utf8.encode(source));
  });

  test('patched engine retains replacement separator identity in history', () {
    const options = CodeLineOptions(preserveLineBreaks: true);
    final lf = CodeLineEditingController.fromText('', options);
    final mixed = CodeLineEditingController.fromText('', options);
    addTearDown(lf.dispose);
    addTearDown(mixed.dispose);
    lf.replaceSelection('a\nb\nc\n');
    mixed.replaceSelection('a\r\nb\rc\n');
    expect(mixed.value, isNot(lf.value));
    expect(mixed.text, 'a\r\nb\rc\n');
    mixed.undo();
    mixed.redo();
    expect(mixed.value, isNot(lf.value));
    expect(mixed.text, 'a\r\nb\rc\n');
  });

  test(
    'adapter filters selection/fold events and publishes before reload task',
    () async {
      const initial = 'a\r\nb\rc\n';
      var recovered = initial;
      var count = 0;
      final adapter = EngineAdapter(
        initial,
        onSourceChanged: (source) {
          recovered = source;
          count++;
        },
      );
      addTearDown(adapter.dispose);
      adapter.engine.collapseChunk(0, 3);
      adapter.engine.selectAll();
      expect(count, 0);
      adapter.engine.replaceSelection('');
      expect(recovered, '');
      expect(count, 1);
      await Future<void>.microtask(() {
        final reload = EngineAdapter(recovered, onSourceChanged: (_) {});
        expect(reload.source, '');
        reload.dispose();
      });
    },
  );

  test(
    'format transaction preserves exact source and selection on one undo',
    () {
      final controller = CodeLineEditingController.fromText(
        'ab\rcd\nef',
        const CodeLineOptions(preserveLineBreaks: true),
      );
      addTearDown(controller.dispose);
      const selection = CodeLineSelection.collapsed(index: 1, offset: 1);
      controller.selection = selection;
      controller.runRevocableOp(() {
        controller.replaceSelection(
          'X',
          const CodeLineSelection(
            baseIndex: 2,
            baseOffset: 0,
            extentIndex: 2,
            extentOffset: 1,
          ),
        );
        controller.replaceSelection(
          'Y',
          const CodeLineSelection(
            baseIndex: 0,
            baseOffset: 0,
            extentIndex: 0,
            extentOffset: 1,
          ),
        );
      });
      expect(controller.text, 'Yb\rcd\nXf');
      controller.undo();
      expect(controller.text, 'ab\rcd\nef');
      expect(controller.selection, selection);
    },
  );
}
