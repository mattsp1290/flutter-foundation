import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final operation in ['copy', 'cut', 'paste']) {
    test('$operation failure is source-free and preserves history', () async {
      final controller = BirbEditorController(
        documentId: 'clipboard',
        source: 'exact\r\n',
      );
      addTearDown(controller.dispose);
      var fail = true;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (fail) {
          throw PlatformException(
            code: 'denied',
            message: 'private clipboard content',
          );
        }
        return call.method == 'Clipboard.getData'
            ? {'text': 'pasted\r\n'}
            : null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      controller.setSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final before = controller.snapshot;
      final command = switch (operation) {
        'copy' => controller.copy,
        'cut' => controller.cut,
        _ => controller.paste,
      };
      expect(await command(), BirbEditorEditResult.clipboardUnavailable);
      expect(controller.snapshot.clipboardUnavailable, isTrue);
      expect(controller.snapshot.source, before.source);
      expect(controller.snapshot.generation, before.generation);
      expect(controller.snapshot.selection, before.selection);
      expect(controller.snapshot.capabilities.canUndo, isFalse);
      fail = false;
      expect(await command(), BirbEditorEditResult.applied);
      expect(controller.snapshot.clipboardUnavailable, isFalse);
      if (operation != 'copy') {
        controller.undo();
        expect(controller.snapshot.source, before.source);
      }
    });
  }

  testWidgets('built-in copy announces neutral failure and clears on retry', (
    tester,
  ) async {
    final controller = BirbEditorController(
      documentId: 'clipboard',
      source: 'secret',
    );
    var fail = true;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData' && fail) {
        throw PlatformException(code: 'denied', message: 'secret');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BirbSourceEditor(controller: controller)),
      ),
    );
    Future<void> copy() async {
      await tester.tap(find.byTooltip('Editor commands'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
    }

    await copy();
    expect(
      find.text('Clipboard unavailable. Try the command again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    fail = false;
    await copy();
    expect(
      find.text('Clipboard unavailable. Try the command again.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}
