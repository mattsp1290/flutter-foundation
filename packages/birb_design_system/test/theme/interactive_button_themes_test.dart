import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    group('${theme.brightness.name} buttons', () {
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;
      final filled = <ButtonStyle>[
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
      ];
      final borderless = <ButtonStyle>[
        theme.textButtonTheme.style!,
        theme.iconButtonTheme.style!,
      ];

      test('share exact geometry and motion', () {
        for (final style in <ButtonStyle>[
          ...filled,
          theme.outlinedButtonTheme.style!,
          ...borderless,
          theme.menuButtonTheme.style!,
        ]) {
          expect(style.animationDuration, BirbDurations.standard);
          expect(style.elevation?.resolve({}), 0);
          expect(
            style.minimumSize?.resolve({}),
            const Size.square(BirbSizes.minimumInteractiveDimension),
          );
          expect(style.overlayColor?.resolve({}), WidgetStateColor.transparent);
          expect(
            style.surfaceTintColor?.resolve({}),
            WidgetStateColor.transparent,
          );
          expect(style.tapTargetSize, MaterialTapTargetSize.padded);
          expect(style.visualDensity, VisualDensity.standard);
          final shape = style.shape?.resolve({})! as RoundedRectangleBorder;
          expect(shape.borderRadius, BirbRadii.none);
        }
      });

      test('resolve filled and elevated state precedence', () {
        for (final style in filled) {
          _expect(style, {}, colors.primary, colors.onPrimary, BorderSide.none);
          for (final state in [WidgetState.hovered, WidgetState.pressed]) {
            _expect(
              style,
              {state},
              colors.primaryContainer,
              colors.onPrimaryContainer,
              BorderSide.none,
            );
          }
          final focusSide = BorderSide(
            color: semantics.focus,
            width: BirbBorders.strong,
            strokeAlign: BorderSide.strokeAlignOutside,
          );
          _expect(
            style,
            {WidgetState.focused},
            colors.primary,
            colors.onPrimary,
            focusSide,
          );
          _expect(
            style,
            {WidgetState.pressed, WidgetState.focused},
            colors.primaryContainer,
            colors.onPrimaryContainer,
            focusSide,
          );
          _expect(
            style,
            {WidgetState.hovered, WidgetState.focused},
            colors.primary,
            colors.onPrimary,
            focusSide,
          );
          final disabledSide = BorderSide(
            color: semantics.disabled,
            width: BirbBorders.thin,
          );
          for (final states in [
            {WidgetState.disabled},
            {WidgetState.disabled, WidgetState.pressed, WidgetState.focused},
          ]) {
            _expect(
              style,
              states,
              colors.surface,
              semantics.disabled,
              disabledSide,
            );
          }
        }
      });

      test('resolves outlined state precedence', () {
        final style = theme.outlinedButtonTheme.style!;
        final outline = BorderSide(
          color: colors.outline,
          width: BirbBorders.thin,
        );
        _expect(style, {}, colors.surface, colors.onSurface, outline);
        for (final state in [WidgetState.hovered, WidgetState.pressed]) {
          _expect(
            style,
            {state},
            colors.surfaceContainer,
            colors.onSurface,
            outline,
          );
        }
        final focus = BorderSide(
          color: semantics.focus,
          width: BirbBorders.strong,
        );
        _expect(
          style,
          {WidgetState.focused},
          colors.surface,
          colors.onSurface,
          focus,
        );
        _expect(
          style,
          {WidgetState.pressed, WidgetState.focused},
          colors.surfaceContainer,
          colors.onSurface,
          focus,
        );
        _expect(
          style,
          {WidgetState.disabled, WidgetState.focused},
          colors.surface,
          semantics.disabled,
          BorderSide(color: semantics.disabled, width: BirbBorders.thin),
        );
      });

      test('resolves text, icon, and menu button differences', () {
        for (final style in borderless) {
          _expect(
            style,
            {},
            WidgetStateColor.transparent,
            colors.primary,
            BorderSide.none,
          );
          _expect(
            style,
            {WidgetState.hovered},
            colors.surfaceContainer,
            colors.onSurface,
            BorderSide.none,
          );
          _expect(
            style,
            {WidgetState.hovered, WidgetState.focused},
            WidgetStateColor.transparent,
            colors.primary,
            BorderSide(color: semantics.focus, width: BirbBorders.strong),
          );
          _expect(
            style,
            {WidgetState.pressed, WidgetState.focused},
            colors.surfaceContainer,
            colors.onSurface,
            BorderSide(color: semantics.focus, width: BirbBorders.strong),
          );
          _expect(
            style,
            {WidgetState.disabled, WidgetState.focused},
            colors.surface,
            semantics.disabled,
            BorderSide.none,
          );
        }

        final menu = theme.menuButtonTheme.style!;
        _expect(
          menu,
          {},
          WidgetStateColor.transparent,
          colors.onSurface,
          BorderSide.none,
        );
        _expect(
          menu,
          {WidgetState.hovered},
          colors.surfaceContainerHigh,
          colors.onSurface,
          BorderSide.none,
        );
        _expect(
          menu,
          {WidgetState.focused},
          WidgetStateColor.transparent,
          colors.onSurface,
          BorderSide(color: semantics.focus, width: BirbBorders.strong),
        );
        _expect(
          menu,
          {WidgetState.pressed, WidgetState.focused},
          colors.primaryContainer,
          colors.onPrimaryContainer,
          BorderSide(color: semantics.focus, width: BirbBorders.strong),
        );
        _expect(
          menu,
          {WidgetState.disabled, WidgetState.pressed},
          colors.surface,
          semantics.disabled,
          BorderSide.none,
        );
        for (final states in <Set<WidgetState>>[
          {},
          {WidgetState.hovered},
          {WidgetState.pressed},
          {WidgetState.focused},
          {WidgetState.disabled},
        ]) {
          expect(
            menu.iconColor?.resolve(states),
            menu.foregroundColor?.resolve(states),
          );
        }
      });
    });
  }

  testWidgets('keyboard traversal exposes the focused button recipe', (
    tester,
  ) async {
    final focusNode = FocusNode(debugLabel: 'keyboard button');
    final states = WidgetStatesController();
    addTearDown(focusNode.dispose);
    addTearDown(states.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirbTheme.light,
        home: Scaffold(
          body: Center(
            child: FilledButton(
              focusNode: focusNode,
              statesController: states,
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(states.value, contains(WidgetState.focused));
    expect(
      BirbTheme.light.filledButtonTheme.style?.side?.resolve(states.value),
      BorderSide(
        color: BirbSemanticColors.light.focus,
        width: BirbBorders.strong,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(
      size.width,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );
    expect(
      size.height,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );
  });
}

void _expect(
  ButtonStyle style,
  Set<WidgetState> states,
  Color background,
  Color foreground,
  BorderSide side,
) {
  expect(style.backgroundColor?.resolve(states), background, reason: '$states');
  expect(style.foregroundColor?.resolve(states), foreground, reason: '$states');
  expect(style.side?.resolve(states), side, reason: '$states');
}
