import 'package:flutter/material.dart';

import '../color/birb_semantic_colors.dart';
import 'birb_color_schemes.dart';
import 'birb_typography.dart';
import 'components/birb_button_themes.dart';
import 'components/birb_selection_themes.dart';
import 'components/birb_surface_themes.dart';
import 'components/input_decoration_theme.dart';

/// Complete light and dark foundations for Birb Party applications.
///
/// Material component recipes provide the documented state, geometry, and
/// duration contracts.
abstract final class BirbTheme {
  static final ThemeData light = _buildTheme(
    colorScheme: BirbColorSchemes.light,
    semanticColors: BirbSemanticColors.light,
  );

  static final ThemeData dark = _buildTheme(
    colorScheme: BirbColorSchemes.dark,
    semanticColors: BirbSemanticColors.dark,
  );

  /// Exact editable-value colors for a Birb Party text input.
  ///
  /// Flutter otherwise synthesizes disabled Material 3 text with opacity.
  static WidgetStateTextStyle inputTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    return WidgetStateTextStyle.resolveWith((states) {
      return TextStyle(
        color: states.contains(WidgetState.disabled)
            ? theme.disabledColor
            : theme.colorScheme.onSurface,
      );
    });
  }
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required BirbSemanticColors semanticColors,
}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
  );
  final textTheme = buildBirbTextTheme(base.textTheme, colorScheme.onSurface);
  final filledButtonStyle = BirbButtonThemes.filled(
    colorScheme,
    semanticColors,
  );
  final borderlessButtonStyle = BirbButtonThemes.borderless(
    colorScheme,
    semanticColors,
  );

  return base.copyWith(
    applyElevationOverlayColor: false,
    appBarTheme: BirbSurfaceThemes.appBar(colorScheme),
    cardTheme: BirbSurfaceThemes.card(colorScheme),
    checkboxTheme: BirbSelectionThemes.checkbox(colorScheme, semanticColors),
    chipTheme: BirbSelectionThemes.chip(colorScheme, semanticColors),
    disabledColor: semanticColors.disabled,
    dialogTheme: BirbSurfaceThemes.dialog(colorScheme, textTheme),
    dividerTheme: BirbSurfaceThemes.divider(colorScheme),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filledButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
    focusColor: semanticColors.focus,
    highlightColor: colorScheme.primaryContainer,
    hoverColor: colorScheme.surfaceContainerHigh,
    iconButtonTheme: IconButtonThemeData(style: borderlessButtonStyle),
    inputDecorationTheme: BirbInputDecorationTheme.build(
      colorScheme,
      semanticColors,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    menuTheme: BirbSurfaceThemes.menu(colorScheme),
    menuButtonTheme: MenuButtonThemeData(
      style: BirbButtonThemes.menu(colorScheme, semanticColors),
    ),
    navigationBarTheme: BirbSurfaceThemes.navigationBar(
      colorScheme,
      semanticColors,
    ),
    navigationRailTheme: BirbSurfaceThemes.navigationRail(colorScheme),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: BirbButtonThemes.outlined(colorScheme, semanticColors),
    ),
    radioTheme: BirbSelectionThemes.radio(colorScheme, semanticColors),
    scaffoldBackgroundColor: colorScheme.surface,
    sliderTheme: BirbSelectionThemes.slider(colorScheme, semanticColors),
    snackBarTheme: BirbSurfaceThemes.snackBar(
      colorScheme,
      semanticColors,
      textTheme,
    ),
    splashColor: colorScheme.primaryContainer,
    switchTheme: BirbSelectionThemes.toggle(colorScheme, semanticColors),
    textButtonTheme: TextButtonThemeData(style: borderlessButtonStyle),
    textTheme: textTheme,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.inversePrimary,
      selectionHandleColor: colorScheme.primary,
    ),
    tooltipTheme: BirbSurfaceThemes.tooltip(colorScheme, textTheme),
    visualDensity: VisualDensity.standard,
    extensions: <ThemeExtension<dynamic>>[semanticColors],
  );
}
