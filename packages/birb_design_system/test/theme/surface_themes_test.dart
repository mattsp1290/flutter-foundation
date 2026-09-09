import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    group('${theme.brightness.name} surface themes', () {
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;

      test('configures app bar, cards, dialogs, and dividers', () {
        final appBar = theme.appBarTheme;
        expect(appBar.backgroundColor, colors.surface);
        expect(appBar.foregroundColor, colors.onSurface);
        expect(appBar.elevation, 0);
        expect(appBar.scrolledUnderElevation, 0);
        expect(appBar.shadowColor, colors.shadow);
        expect(appBar.surfaceTintColor, WidgetStateColor.transparent);

        final card = theme.cardTheme;
        expect(card.color, colors.surfaceContainerLow);
        expect(card.elevation, 0);
        expect(card.shadowColor, colors.shadow);
        expect(card.surfaceTintColor, WidgetStateColor.transparent);
        _expectOutlinedShape(card.shape, colors.outline);

        final dialog = theme.dialogTheme;
        expect(dialog.backgroundColor, colors.surfaceContainerHigh);
        expect(dialog.barrierColor, colors.scrim);
        expect(dialog.contentTextStyle, theme.textTheme.bodyMedium);
        expect(dialog.titleTextStyle, theme.textTheme.headlineSmall);
        expect(dialog.elevation, 0);
        expect(dialog.iconColor, colors.onSurface);
        expect(dialog.shadowColor, colors.shadow);
        expect(dialog.surfaceTintColor, WidgetStateColor.transparent);
        _expectOutlinedShape(dialog.shape, colors.outline);

        expect(theme.dividerTheme.color, colors.outline);
        expect(theme.dividerTheme.thickness, BirbBorders.thin);
      });

      test('configures menu, snackbar, and tooltip overlays', () {
        final menu = theme.menuTheme.style!;
        expect(menu.backgroundColor?.resolve({}), colors.surfaceContainerHigh);
        expect(menu.elevation?.resolve({}), 0);
        expect(menu.shadowColor?.resolve({}), colors.shadow);
        expect(
          menu.surfaceTintColor?.resolve({}),
          WidgetStateColor.transparent,
        );
        expect(menu.visualDensity, VisualDensity.standard);
        final menuShape = menu.shape?.resolve({})! as RoundedRectangleBorder;
        expect(menuShape.borderRadius, BirbRadii.none);
        expect(
          menu.side?.resolve({}),
          BorderSide(color: colors.outline, width: BirbBorders.thin),
        );

        final snackBar = theme.snackBarTheme;
        expect(snackBar.backgroundColor, colors.inverseSurface);
        expect(snackBar.actionBackgroundColor, colors.inverseSurface);
        expect(snackBar.actionTextColor, colors.inversePrimary);
        expect(snackBar.closeIconColor, colors.onInverseSurface);
        expect(snackBar.contentTextStyle?.color, colors.onInverseSurface);
        expect(snackBar.disabledActionBackgroundColor, colors.inverseSurface);
        expect(snackBar.disabledActionTextColor, semantics.disabled);
        expect(snackBar.elevation, 0);
        expect(
          (snackBar.shape! as RoundedRectangleBorder).borderRadius,
          BirbRadii.none,
        );

        final tooltip = theme.tooltipTheme;
        final decoration = tooltip.decoration! as BoxDecoration;
        expect(decoration.color, colors.inverseSurface);
        expect(decoration.borderRadius, BirbRadii.none);
        expect(tooltip.textStyle?.color, colors.onInverseSurface);
      });

      test('resolves navigation states and square indicators', () {
        final bar = theme.navigationBarTheme;
        expect(bar.backgroundColor, colors.surface);
        expect(bar.elevation, 0);
        expect(bar.indicatorColor, colors.primaryContainer);
        expect(bar.shadowColor, colors.shadow);
        expect(bar.surfaceTintColor, WidgetStateColor.transparent);
        expect(
          (bar.indicatorShape! as RoundedRectangleBorder).borderRadius,
          BirbRadii.none,
        );

        final cases = <({Set<WidgetState> states, Color color, Color overlay})>[
          (
            states: const {},
            color: colors.onSurfaceVariant,
            overlay: WidgetStateColor.transparent,
          ),
          (
            states: const {WidgetState.selected},
            color: colors.onPrimaryContainer,
            overlay: WidgetStateColor.transparent,
          ),
          (
            states: const {WidgetState.hovered},
            color: colors.onSurfaceVariant,
            overlay: colors.surfaceContainerHigh,
          ),
          (
            states: const {WidgetState.focused},
            color: colors.onSurfaceVariant,
            overlay: semantics.focus,
          ),
          (
            states: const {WidgetState.pressed, WidgetState.focused},
            color: colors.onSurfaceVariant,
            overlay: colors.primaryContainer,
          ),
          (
            states: const {WidgetState.disabled, WidgetState.selected},
            color: semantics.disabled,
            overlay: WidgetStateColor.transparent,
          ),
        ];
        for (final stateCase in cases) {
          expect(
            bar.iconTheme?.resolve(stateCase.states)?.color,
            stateCase.color,
          );
          expect(
            bar.labelTextStyle?.resolve(stateCase.states)?.color,
            stateCase.color,
          );
          expect(
            bar.overlayColor?.resolve(stateCase.states),
            stateCase.overlay,
          );
        }
        expect(
          bar.labelTextStyle?.resolve({WidgetState.selected})?.fontWeight,
          FontWeight.w700,
        );
        expect(bar.labelTextStyle?.resolve({})?.fontWeight, FontWeight.w400);

        final rail = theme.navigationRailTheme;
        expect(rail.backgroundColor, colors.surface);
        expect(rail.elevation, 0);
        expect(rail.indicatorColor, colors.primaryContainer);
        expect(rail.useIndicator, isTrue);
        expect(rail.selectedIconTheme?.color, colors.onPrimaryContainer);
        expect(rail.selectedLabelTextStyle?.color, colors.onPrimaryContainer);
        expect(rail.selectedLabelTextStyle?.fontWeight, FontWeight.w700);
        expect(rail.unselectedIconTheme?.color, colors.onSurfaceVariant);
        expect(rail.unselectedLabelTextStyle?.color, colors.onSurfaceVariant);
        expect(rail.unselectedLabelTextStyle?.fontWeight, FontWeight.w400);
        expect(
          (rail.indicatorShape! as RoundedRectangleBorder).borderRadius,
          BirbRadii.none,
        );
      });
    });
  }
}

void _expectOutlinedShape(ShapeBorder? shape, Color color) {
  final rectangle = shape! as RoundedRectangleBorder;
  expect(rectangle.borderRadius, BirbRadii.none);
  expect(rectangle.side, BorderSide(color: color, width: BirbBorders.thin));
}
