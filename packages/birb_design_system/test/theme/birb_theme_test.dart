import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final themeCase in <(String, ThemeData, Color)>[
    ('light', BirbTheme.light, const Color(0xFF41A6F6)),
    ('dark', BirbTheme.dark, const Color(0xFF3B5DC9)),
  ]) {
    test('${themeCase.$1} configures the shared theme foundation', () {
      final theme = themeCase.$2;
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, colors.brightness);
      expect(theme.applyElevationOverlayColor, isFalse);
      expect(theme.scaffoldBackgroundColor, colors.surface);
      expect(theme.disabledColor, semantics.disabled);
      expect(theme.focusColor, semantics.focus);
      expect(theme.hoverColor, colors.surfaceContainerHigh);
      expect(theme.splashColor, colors.primaryContainer);
      expect(theme.highlightColor, colors.primaryContainer);
      expect(theme.visualDensity, VisualDensity.standard);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(
        (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
        BirbRadii.none,
      );
      expect(theme.textSelectionTheme.cursorColor, colors.primary);
      expect(theme.textSelectionTheme.selectionHandleColor, colors.primary);
      expect(theme.textSelectionTheme.selectionColor, themeCase.$3);
    });

    testWidgets('${themeCase.$1} keeps editable text on palette', (
      tester,
    ) async {
      final enabled = TextEditingController(text: 'Enabled');
      final disabled = TextEditingController(text: 'Disabled');
      addTearDown(enabled.dispose);
      addTearDown(disabled.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: themeCase.$2,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: <Widget>[
                  TextField(
                    key: const ValueKey('enabled'),
                    controller: enabled,
                    style: BirbTheme.inputTextStyle(context),
                  ),
                  TextField(
                    key: const ValueKey('disabled'),
                    controller: disabled,
                    enabled: false,
                    style: BirbTheme.inputTextStyle(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      TextStyle editableStyle(String key) => tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(EditableText),
            ),
          )
          .style;

      expect(
        editableStyle('enabled').color,
        themeCase.$2.colorScheme.onSurface,
      );
      expect(
        editableStyle('disabled').color,
        themeCase.$2.extension<BirbSemanticColors>()!.disabled,
      );
    });
  }

  testWidgets('disabled input color wins over combined states', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: BirbTheme.light,
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final style = BirbTheme.inputTextStyle(context);
    expect(
      style.resolve({WidgetState.disabled, WidgetState.error}).color,
      BirbSemanticColors.light.disabled,
    );
  });
}
