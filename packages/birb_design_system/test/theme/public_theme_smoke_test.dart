import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    testWidgets('public barrel renders a ${theme.brightness.name} app', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Text('Birb')),
        ),
      );

      expect(find.text('Birb'), findsOneWidget);
      final context = tester.element(find.text('Birb'));
      expect(Theme.of(context).brightness, theme.brightness);
      expect(Theme.of(context).extension<BirbSemanticColors>(), isNotNull);
    });
  }
}
