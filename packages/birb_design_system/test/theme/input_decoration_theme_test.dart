import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    test('${theme.brightness.name} input decoration resolves every state', () {
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;
      final input = theme.inputDecorationTheme;

      expect(input.filled, isTrue);
      expect(input.fillColor, colors.surface);
      expect(input.focusColor, semantics.focus);
      expect(input.hoverColor, colors.surfaceContainerHigh);
      expect(input.floatingLabelBehavior, FloatingLabelBehavior.never);
      expect(input.visualDensity, VisualDensity.standard);
      expect(
        input.constraints,
        const BoxConstraints(minHeight: BirbSizes.minimumInteractiveDimension),
      );
      expect(input.errorStyle?.color, semantics.errorIndicator);

      final border = input.border! as WidgetStateInputBorder;
      final borderCases =
          <({Set<WidgetState> states, Color color, double width})>[
            (states: const {}, color: colors.outline, width: BirbBorders.thin),
            (
              states: const {WidgetState.focused},
              color: semantics.focus,
              width: BirbBorders.strong,
            ),
            (
              states: const {WidgetState.error},
              color: semantics.errorIndicator,
              width: BirbBorders.thin,
            ),
            (
              states: const {WidgetState.error, WidgetState.focused},
              color: semantics.errorIndicator,
              width: BirbBorders.strong,
            ),
            (
              states: const {
                WidgetState.disabled,
                WidgetState.error,
                WidgetState.focused,
              },
              color: semantics.disabled,
              width: BirbBorders.thin,
            ),
          ];
      for (final stateCase in borderCases) {
        final resolved = border.resolve(stateCase.states) as OutlineInputBorder;
        expect(resolved.borderRadius, BirbRadii.none);
        expect(resolved.borderSide.color, stateCase.color);
        expect(resolved.borderSide.width, stateCase.width);
      }

      for (final entry in <(String, TextStyle?)>[
        ('label', input.labelStyle),
        ('helper', input.helperStyle),
        ('hint', input.hintStyle),
        ('prefix', input.prefixStyle),
        ('suffix', input.suffixStyle),
        ('counter', input.counterStyle),
        ('floating label', input.floatingLabelStyle),
      ]) {
        final (name, style) = entry;
        expect(style, isNotNull, reason: name);
        final stateful = style! as WidgetStateTextStyle;
        expect(stateful.resolve({}).color, colors.onSurface);
        expect(
          stateful.resolve({WidgetState.disabled}).color,
          semantics.disabled,
        );
      }

      for (final color in <Color?>[
        input.iconColor,
        input.prefixIconColor,
        input.suffixIconColor,
      ]) {
        final stateful = color! as WidgetStateColor;
        expect(stateful.resolve({}), colors.onSurface);
        expect(stateful.resolve({WidgetState.error}), semantics.errorIndicator);
        expect(stateful.resolve({WidgetState.disabled}), semantics.disabled);
      }
    });
  }
}
