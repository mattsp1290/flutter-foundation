import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native qualification releases highlighter workers on detach', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await Future<void>.delayed(const Duration(milliseconds: 500));
    debugPrint('EDITOR_WORKERS baseline');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (var cycle = 0; cycle < 20; cycle++) {
      final controller = BirbEditorController(
        documentId: 'worker-$cycle',
        source: 'package main\nfunc main() { println("hello", 42) }\n',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BirbSourceEditor(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('EDITOR_WORKERS mounted $cycle');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('EDITOR_WORKERS detached $cycle');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
  });
}
