import 'package:flutter/material.dart';

import '../../color/birb_semantic_colors.dart';
import '../../tokens/birb_tokens.dart';

/// Internal builder for the shared input-decoration recipe.
abstract final class BirbInputDecorationTheme {
  static InputDecorationThemeData build(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) {
    final border = WidgetStateInputBorder.resolveWith(
      (states) => OutlineInputBorder(
        borderRadius: BirbRadii.none,
        borderSide: borderSide(
          colors: colors,
          semantics: semantics,
          enabled: !states.contains(WidgetState.disabled),
          hasError: states.contains(WidgetState.error),
          focused: states.contains(WidgetState.focused),
        ),
      ),
    );
    final decorationTextStyle = WidgetStateTextStyle.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return TextStyle(color: semantics.disabled);
      }
      return TextStyle(color: colors.onSurface);
    });
    final iconColor = WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantics.disabled;
      if (states.contains(WidgetState.error)) return semantics.errorIndicator;
      return colors.onSurface;
    });

    return InputDecorationThemeData(
      border: border,
      constraints: const BoxConstraints(
        minHeight: BirbSizes.minimumInteractiveDimension,
      ),
      counterStyle: decorationTextStyle,
      errorStyle: TextStyle(color: semantics.errorIndicator),
      fillColor: colors.surface,
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      floatingLabelStyle: decorationTextStyle,
      focusColor: semantics.focus,
      helperStyle: decorationTextStyle,
      hintStyle: decorationTextStyle,
      hoverColor: colors.surfaceContainerHigh,
      iconColor: iconColor,
      labelStyle: decorationTextStyle,
      prefixIconColor: iconColor,
      prefixStyle: decorationTextStyle,
      suffixIconColor: iconColor,
      suffixStyle: decorationTextStyle,
      visualDensity: VisualDensity.standard,
    );
  }

  /// Resolves the shared field boundary for the current interaction state.
  static BorderSide borderSide({
    required ColorScheme colors,
    required BirbSemanticColors semantics,
    required bool enabled,
    required bool hasError,
    required bool focused,
  }) {
    if (!enabled) {
      return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
    }

    return BorderSide(
      color: hasError
          ? semantics.errorIndicator
          : focused
          ? semantics.focus
          : colors.outline,
      width: focused ? BirbBorders.strong : BirbBorders.thin,
    );
  }
}
