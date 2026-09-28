import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native qualification input, recovery and undo', (tester) async {
    const initial =
        'package main\r\n\r\n// Mixed separators remain exact.\r'
        'func main() {\n\tprintln("hello", 42)\r\n}\n';
    final controller = BirbEditorController(
      documentId: 'native-qualification',
      source: initial,
    );
    final focus = FocusNode();
    var recovered = initial;
    controller.addTextListener((snapshot) => recovered = snapshot.source);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirbSourceEditor(controller: controller, focusNode: focus),
        ),
      ),
    );
    await tester.pumpAndSettle();
    focus.requestFocus();
    await tester.pump();
    final modifier = defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(modifier);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('TextInputClient.updateEditingStateWithDeltas', [
          -1,
          {
            'deltas': [
              {
                'oldText': 'package main',
                'deltaText': 'package native',
                'deltaStart': 0,
                'deltaEnd': 12,
                'selectionBase': 14,
                'selectionExtent': 14,
                'selectionAffinity': 'TextAffinity.downstream',
                'selectionIsDirectional': false,
                'composingBase': -1,
                'composingExtent': -1,
              },
            ],
          },
        ]),
      ),
      (_) {},
    );
    expect(recovered, 'package native');
    await tester.pump();
    expect(controller.snapshot.source, 'package native');
    await _sendDelta(
      tester,
      oldText: 'package native',
      replacement: '中',
      start: 8,
      end: 14,
      selection: 9,
      composing: const TextRange(start: 8, end: 9),
    );
    expect(recovered, 'package 中');
    await _sendDelta(
      tester,
      oldText: 'package 中',
      replacement: '中文',
      start: 8,
      end: 9,
      selection: 10,
    );
    expect(recovered, 'package 中文');
    await Future<void>.microtask(() => expect(recovered, 'package 中文'));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(recovered, 'package native');
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(recovered, initial);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _sendDelta(
  WidgetTester tester, {
  required String oldText,
  required String replacement,
  required int start,
  required int end,
  required int selection,
  TextRange composing = TextRange.empty,
}) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  SystemChannels.textInput.name,
  const JSONMethodCodec().encodeMethodCall(
    MethodCall('TextInputClient.updateEditingStateWithDeltas', [
      -1,
      {
        'deltas': [
          {
            'oldText': oldText,
            'deltaText': replacement,
            'deltaStart': start,
            'deltaEnd': end,
            'selectionBase': selection,
            'selectionExtent': selection,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': composing.start,
            'composingExtent': composing.end,
          },
        ],
      },
    ]),
  ),
  (_) {},
);
