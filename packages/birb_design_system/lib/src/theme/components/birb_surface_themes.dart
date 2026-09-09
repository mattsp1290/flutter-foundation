import 'package:flutter/material.dart';

import '../../color/birb_semantic_colors.dart';
import '../../tokens/birb_tokens.dart';
import 'interaction_overlay.dart';

/// Internal builders for surfaces, navigation, and route overlays.
abstract final class BirbSurfaceThemes {
  static AppBarThemeData appBar(ColorScheme colors) => AppBarThemeData(
    backgroundColor: colors.surface,
    foregroundColor: colors.onSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: colors.shadow,
    surfaceTintColor: WidgetStateColor.transparent,
  );

  static CardThemeData card(ColorScheme colors) => CardThemeData(
    color: colors.surfaceContainerLow,
    elevation: 0,
    shadowColor: colors.shadow,
    shape: RoundedRectangleBorder(
      borderRadius: BirbRadii.none,
      side: BorderSide(color: colors.outline, width: BirbBorders.thin),
    ),
    surfaceTintColor: WidgetStateColor.transparent,
  );

  static DialogThemeData dialog(ColorScheme colors, TextTheme textTheme) =>
      DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        barrierColor: colors.scrim,
        contentTextStyle: textTheme.bodyMedium,
        elevation: 0,
        iconColor: colors.onSurface,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BirbRadii.none,
          side: BorderSide(color: colors.outline, width: BirbBorders.thin),
        ),
        surfaceTintColor: WidgetStateColor.transparent,
        titleTextStyle: textTheme.headlineSmall,
      );

  static DividerThemeData divider(ColorScheme colors) =>
      DividerThemeData(color: colors.outline, thickness: BirbBorders.thin);

  static MenuThemeData menu(ColorScheme colors) => MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(
        colors.surfaceContainerHigh,
      ),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: WidgetStatePropertyAll<Color>(colors.shadow),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BirbRadii.none),
      ),
      side: WidgetStatePropertyAll<BorderSide>(
        BorderSide(color: colors.outline, width: BirbBorders.thin),
      ),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(
        WidgetStateColor.transparent,
      ),
      visualDensity: VisualDensity.standard,
    ),
  );

  static NavigationBarThemeData navigationBar(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => NavigationBarThemeData(
    backgroundColor: colors.surface,
    elevation: 0,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: _navigationForeground(states, colors, semantics),
      ),
    ),
    indicatorColor: colors.primaryContainer,
    indicatorShape: const RoundedRectangleBorder(borderRadius: BirbRadii.none),
    labelTextStyle: WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(
        color: _navigationForeground(states, colors, semantics),
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w400,
      ),
    ),
    overlayColor: WidgetStateColor.resolveWith(
      (states) => BirbInteractionOverlay.resolve(states, colors, semantics),
    ),
    shadowColor: colors.shadow,
    surfaceTintColor: WidgetStateColor.transparent,
  );

  static NavigationRailThemeData navigationRail(ColorScheme colors) =>
      NavigationRailThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: colors.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BirbRadii.none,
        ),
        selectedIconTheme: IconThemeData(color: colors.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        useIndicator: true,
      );

  static SnackBarThemeData snackBar(
    ColorScheme colors,
    BirbSemanticColors semantics,
    TextTheme textTheme,
  ) => SnackBarThemeData(
    actionBackgroundColor: colors.inverseSurface,
    actionTextColor: colors.inversePrimary,
    backgroundColor: colors.inverseSurface,
    closeIconColor: colors.onInverseSurface,
    contentTextStyle: textTheme.bodyMedium?.copyWith(
      color: colors.onInverseSurface,
    ),
    disabledActionBackgroundColor: colors.inverseSurface,
    disabledActionTextColor: semantics.disabled,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: BirbRadii.none),
  );

  static TooltipThemeData tooltip(ColorScheme colors, TextTheme textTheme) =>
      TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BirbRadii.none,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colors.onInverseSurface,
        ),
      );
}

Color _navigationForeground(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) return semantics.disabled;
  return states.contains(WidgetState.selected)
      ? colors.onPrimaryContainer
      : colors.onSurfaceVariant;
}
