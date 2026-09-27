import 'dart:async';

import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  BirbEditorController create([String source = 'ab\r\ncd\ref\n']) {
    final controller = BirbEditorController(
      documentId: 'document',
      source: source,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  BirbEditorEditResult replace(BirbEditorController controller, String text) =>
      controller.applyEdits(
        expectedDocumentId: controller.snapshot.documentId,
        expectedGeneration: controller.snapshot.generation,
        edits: [
          BirbEditorEdit(
            range: TextRange(start: 0, end: controller.snapshot.source.length),
            text: text,
          ),
        ],
      );

  test('initial source is synchronous; transaction notifies once and undoes atomically', () {
    final controller = create();
    const initial = 'ab\r\ncd\ref\n';
    expect(controller.snapshot.source, initial);
    controller.setSelection(
      const TextSelection(baseOffset: 5, extentOffset: 1),
    );
    final texts = <BirbEditorSnapshot>[];
    controller.addTextListener(texts.add);
    expect(
      controller.applyEdits(
        expectedDocumentId: 'document',
        expectedGeneration: 0,
        edits: [
          const BirbEditorEdit(range: TextRange(start: 7, end: 8), text: 'XYZ'),
          const BirbEditorEdit(range: TextRange(start: 0, end: 1), text: '😀'),
        ],
      ),
      BirbEditorEditResult.applied,
    );
    expect(texts, hasLength(1));
    expect(texts.single.source, '😀b\r\ncd\rXYZf\n');
    expect(texts.single.generation, 1);
    expect(controller.undo(), BirbEditorEditResult.applied);
    expect(controller.snapshot.source, initial);
    expect(
      controller.snapshot.selection,
      const TextSelection(baseOffset: 5, extentOffset: 1),
    );
    expect(controller.snapshot.origin, BirbEditorOrigin.undo);
    expect(controller.redo(), BirbEditorEditResult.applied);
    expect(controller.snapshot.source, '😀b\r\ncd\rXYZf\n');
    expect(texts.map((snapshot) => snapshot.generation), [1, 2, 3]);
  });

  test(
    'identical host reload clears history and invalidates the prior generation',
    () {
      final controller = create('');
      replace(controller, 'hello');
      final captured = controller.snapshot;
      final texts = <BirbEditorSnapshot>[];
      controller.addTextListener(texts.add);
      controller.replaceDocument(documentId: 'document', source: 'hello');
      expect(texts.single.generation, captured.generation + 1);
      expect(controller.snapshot.capabilities.canUndo, isFalse);
      expect(
        controller.snapshot.selection,
        const TextSelection.collapsed(offset: 0),
      );
      expect(
        controller.applyEdits(
          expectedDocumentId: captured.documentId,
          expectedGeneration: captured.generation,
          edits: const [
            BirbEditorEdit(range: TextRange(start: 0, end: 0), text: 'stale'),
          ],
        ),
        BirbEditorEditResult.stale,
      );
    },
  );

  test(
    'readonly rejects editing but permits navigation and explicit replacement',
    () {
      final controller = create('alpha');
      replace(controller, 'beta');
      final generation = controller.snapshot.generation;
      controller.setReadOnly(true);
      for (final operation in [
        () => replace(controller, 'oops'),
        controller.undo,
        controller.redo,
        controller.indent,
        controller.outdent,
        controller.toggleComment,
      ]) {
        expect(operation(), BirbEditorEditResult.readOnly);
      }
      expect(controller.selectAll(), BirbEditorEditResult.applied);
      expect(controller.find('et'), [const TextRange(start: 1, end: 3)]);
      expect(controller.snapshot.generation, generation);
      expect(
        controller.replaceDocument(documentId: 'next', source: ''),
        BirbEditorEditResult.applied,
      );
      expect(controller.snapshot.readOnly, isTrue);
      expect(controller.snapshot.source, '');
    },
  );

  test('invalid edits leave source selection and undo intact', () {
    final controller = create('a😀\r\nb');
    controller.setSelection(const TextSelection.collapsed(offset: 3));
    final before = controller.snapshot;
    expect(
      controller.applyEdits(
        expectedDocumentId: 'document',
        expectedGeneration: 0,
        edits: const [
          BirbEditorEdit(range: TextRange(start: 0, end: 1), text: 'X'),
          BirbEditorEdit(range: TextRange(start: 4, end: 5), text: 'Y'),
        ],
      ),
      BirbEditorEditResult.invalidRange,
    );
    expect(controller.snapshot, same(before));
    expect(controller.snapshot.capabilities.canUndo, isFalse);
  });

  test(
    'subscriber exceptions are sanitized; later listeners see coherent state',
    () {
      final controller = create('');
      final oldHandler = FlutterError.onError;
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = oldHandler);
      BirbEditorEditResult? nested;
      final observed = <String>[];
      controller.addTextListener((snapshot) {
        nested = controller.replaceDocument(
          documentId: 'nested',
          source: 'bad',
        );
        throw StateError('sensitive document content');
      });
      controller.addTextListener((snapshot) {
        expect(controller.snapshot, same(snapshot));
        observed.add(snapshot.source);
      });
      replace(controller, 'safe');
      expect(nested, BirbEditorEditResult.reentrant);
      expect(observed, ['safe']);
      expect(errors, hasLength(1));
      expect(
        errors.single.toString(),
        isNot(contains('sensitive document content')),
      );
    },
  );

  test(
    'clipboard result cannot cross a readonly transition or replacement',
    () async {
      final controller = create('initial');
      var response = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) => response.future,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final paste = controller.paste();
      controller.setReadOnly(true);
      response.complete({'text': 'clipboard'});
      expect(await paste, BirbEditorEditResult.readOnly);
      controller.setReadOnly(false);
      response = Completer<Object?>();
      final secondPaste = controller.paste();
      controller.replaceDocument(documentId: 'next', source: 'loaded');
      response.complete({'text': 'clipboard'});
      expect(await secondPaste, BirbEditorEditResult.stale);
      expect(controller.snapshot.source, 'loaded');
    },
  );

  test(
    'adjacent edits cannot create an invalid intermediate CRLF boundary',
    () {
      final controller = create('\ra');
      expect(
        controller.applyEdits(
          expectedDocumentId: 'document',
          expectedGeneration: 0,
          edits: const [
            BirbEditorEdit(range: TextRange(start: 0, end: 1), text: 'x'),
            BirbEditorEdit(range: TextRange(start: 1, end: 1), text: '\n'),
          ],
        ),
        BirbEditorEditResult.applied,
      );
      expect(controller.snapshot.source, 'x\na');
      controller.undo();
      expect(controller.snapshot.source, '\ra');
    },
  );

  test('CRLF formed at an insertion seam has valid source coordinates', () {
    final controller = create('\na');
    expect(
      controller.applyEdits(
        expectedDocumentId: 'document',
        expectedGeneration: 0,
        edits: const [
          BirbEditorEdit(range: TextRange(start: 0, end: 0), text: '\r'),
        ],
      ),
      BirbEditorEditResult.applied,
    );
    expect(controller.snapshot.source, '\r\na');
    expect(
      controller.snapshot.selection,
      const TextSelection.collapsed(offset: 2),
    );
    expect(
      controller.setSelection(const TextSelection.collapsed(offset: 3)),
      BirbEditorEditResult.applied,
    );
    controller.undo();
    expect(controller.snapshot.source, '\na');
  });

  test('disposed controller stops notifications and rejects mutation', () {
    final controller = create();
    controller.dispose();
    expect(replace(controller, 'late'), BirbEditorEditResult.disposed);
    expect(controller.undo(), BirbEditorEditResult.disposed);
    expect(() => controller.addListener(() {}), throwsStateError);
  });
}
