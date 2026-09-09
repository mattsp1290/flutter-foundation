import 'package:flutter/material.dart';

import '../color/birb_semantic_colors.dart';
import '../tokens/birb_tokens.dart';
import 'birb_color_schemes.dart';
import 'birb_typography.dart';
import 'components/birb_button_themes.dart';

/// Complete light and dark foundations for Birb Party applications.
///
/// Component recipes intentionally remain at Flutter defaults until the W2
/// theme modules add their documented state, square geometry, and duration
/// contracts. Flutter has no global shape or animation-duration theme field;
/// consumers use the exported duration tokens until those settings are added.
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

  return base.copyWith(
    applyElevationOverlayColor: false,
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BirbRadii.none),
    ),
    disabledColor: semanticColors.disabled,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: BirbButtonThemes.filled(colorScheme, semanticColors),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: BirbButtonThemes.filled(colorScheme, semanticColors),
    ),
    focusColor: semanticColors.focus,
    highlightColor: colorScheme.primaryContainer,
    hoverColor: colorScheme.surfaceContainerHigh,
    iconButtonTheme: IconButtonThemeData(
      style: BirbButtonThemes.borderless(colorScheme, semanticColors),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    menuButtonTheme: MenuButtonThemeData(
      style: BirbButtonThemes.menu(colorScheme, semanticColors),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: BirbButtonThemes.outlined(colorScheme, semanticColors),
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    splashColor: colorScheme.primaryContainer,
    textButtonTheme: TextButtonThemeData(
      style: BirbButtonThemes.borderless(colorScheme, semanticColors),
    ),
    textTheme: textTheme,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.inversePrimary,
      selectionHandleColor: colorScheme.primary,
    ),
    visualDensity: VisualDensity.standard,
    extensions: <ThemeExtension<dynamic>>[semanticColors],
  );
}
