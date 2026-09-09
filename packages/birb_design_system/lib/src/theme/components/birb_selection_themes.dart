import 'package:flutter/material.dart';

import '../../color/birb_semantic_colors.dart';
import '../../tokens/birb_tokens.dart';

/// Internal builders for selection-control state recipes.
abstract final class BirbSelectionThemes {
  static CheckboxThemeData checkbox(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => CheckboxThemeData(
    checkColor: WidgetStateColor.resolveWith(
      (states) => _checkboxForeground(states, colors, semantics),
    ),
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.error)
          ? colors.surface
          : _fill(states, colors),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(states, colors, semantics),
    ),
    shape: const RoundedRectangleBorder(borderRadius: BirbRadii.none),
    side: WidgetStateBorderSide.resolveWith(
      (states) => _checkboxSide(states, colors, semantics),
    ),
    visualDensity: VisualDensity.standard,
  );

  static RadioThemeData radio(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => RadioThemeData(
    backgroundColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return colors.surface;
      if (states.contains(WidgetState.pressed)) {
        return colors.primaryContainer;
      }
      if (states.contains(WidgetState.focused)) return colors.surface;
      if (states.contains(WidgetState.hovered)) {
        return colors.surfaceContainerHigh;
      }
      return colors.surface;
    }),
    fillColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantics.disabled;
      if (states.contains(WidgetState.pressed)) {
        return colors.onPrimaryContainer;
      }
      if (states.contains(WidgetState.hovered)) return colors.onSurface;
      return states.contains(WidgetState.selected)
          ? colors.primary
          : colors.outline;
    }),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(states, colors, semantics),
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => _side(states, colors, semantics),
    ),
    visualDensity: VisualDensity.standard,
  );

  static SwitchThemeData toggle(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(states, colors, semantics),
    ),
    thumbColor: WidgetStateColor.resolveWith(
      (states) => _foreground(states, colors, semantics),
    ),
    trackColor: WidgetStateColor.resolveWith((states) => _fill(states, colors)),
    trackOutlineColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantics.disabled;
      if (states.contains(WidgetState.focused)) return semantics.focus;
      if (states.contains(WidgetState.pressed)) {
        return colors.onPrimaryContainer;
      }
      return states.contains(WidgetState.selected)
          ? colors.primary
          : colors.outline;
    }),
    trackOutlineWidth: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) &&
              !states.contains(WidgetState.disabled)
          ? BirbBorders.strong
          : BirbBorders.thin,
    ),
  );

  static SliderThemeData slider(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => SliderThemeData(
    activeTickMarkColor: colors.onPrimary,
    activeTrackColor: colors.primary,
    disabledActiveTickMarkColor: semantics.disabled,
    disabledActiveTrackColor: semantics.disabled,
    disabledInactiveTickMarkColor: semantics.disabled,
    disabledInactiveTrackColor: semantics.disabled,
    disabledSecondaryActiveTrackColor: semantics.disabled,
    disabledThumbColor: semantics.disabled,
    inactiveTickMarkColor: colors.onSurface,
    inactiveTrackColor: colors.outline,
    overlappingShapeStrokeColor: colors.onPrimary,
    overlayColor: semantics.focus,
    overlayShape: const RoundSliderOverlayShape(
      overlayRadius: BirbSizes.minimumInteractiveDimension / 2,
    ),
    secondaryActiveTrackColor: colors.primary,
    thumbColor: colors.primary,
    trackHeight: BirbBorders.strong,
    valueIndicatorColor: colors.primary,
    valueIndicatorStrokeColor: colors.primary,
    valueIndicatorTextStyle: TextStyle(color: colors.onPrimary),
  );

  static ChipThemeData chip(ColorScheme colors, BirbSemanticColors semantics) {
    final foreground = WidgetStateColor.resolveWith(
      (states) => _foreground(states, colors, semantics),
    );
    return ChipThemeData(
      checkmarkColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? semantics.disabled
            : colors.onPrimary,
      ),
      color: WidgetStateColor.resolveWith((states) => _fill(states, colors)),
      deleteIconColor: foreground,
      disabledColor: colors.surface,
      elevation: 0,
      // RawChip resolves a stateful color stored on TextStyle.color. It does
      // not resolve a WidgetStateTextStyle supplied as the whole labelStyle.
      labelStyle: TextStyle(color: foreground),
      pressElevation: 0,
      selectedColor: colors.primary,
      selectedShadowColor: colors.shadow,
      shadowColor: colors.shadow,
      shape: const RoundedRectangleBorder(borderRadius: BirbRadii.pixel),
      showCheckmark: true,
      side: WidgetStateBorderSide.resolveWith(
        (states) => _side(states, colors, semantics),
      ),
      surfaceTintColor: WidgetStateColor.transparent,
    );
  }
}

Color _fill(Set<WidgetState> states, ColorScheme colors) {
  if (states.contains(WidgetState.disabled)) return colors.surface;
  if (states.contains(WidgetState.pressed)) return colors.primaryContainer;
  if (states.contains(WidgetState.focused)) {
    return states.contains(WidgetState.selected)
        ? colors.primary
        : colors.surface;
  }
  if (states.contains(WidgetState.hovered)) {
    return colors.surfaceContainerHigh;
  }
  return states.contains(WidgetState.selected)
      ? colors.primary
      : colors.surface;
}

Color _foreground(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) return semantics.disabled;
  if (states.contains(WidgetState.pressed)) return colors.onPrimaryContainer;
  if (states.contains(WidgetState.focused)) {
    return states.contains(WidgetState.selected)
        ? colors.onPrimary
        : colors.onSurface;
  }
  if (states.contains(WidgetState.hovered)) return colors.onSurface;
  return states.contains(WidgetState.selected)
      ? colors.onPrimary
      : colors.onSurface;
}

BorderSide _side(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) {
    return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
  }
  if (states.contains(WidgetState.focused)) {
    return BorderSide(color: semantics.focus, width: BirbBorders.strong);
  }
  return BorderSide(
    color: states.contains(WidgetState.selected)
        ? colors.primary
        : colors.outline,
    width: BirbBorders.thin,
  );
}

Color _overlay(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) {
    return WidgetStateColor.transparent;
  }
  if (states.contains(WidgetState.pressed)) return colors.primaryContainer;
  if (states.contains(WidgetState.focused)) return semantics.focus;
  if (states.contains(WidgetState.hovered)) {
    return colors.surfaceContainerHigh;
  }
  return WidgetStateColor.transparent;
}

Color _checkboxForeground(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) return semantics.disabled;
  if (states.contains(WidgetState.error)) return semantics.errorIndicator;
  return _foreground(states, colors, semantics);
}

BorderSide _checkboxSide(
  Set<WidgetState> states,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (states.contains(WidgetState.disabled)) {
    return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
  }
  if (states.contains(WidgetState.error)) {
    return BorderSide(
      color: semantics.errorIndicator,
      width: states.contains(WidgetState.focused)
          ? BirbBorders.strong
          : BirbBorders.thin,
    );
  }
  return _side(states, colors, semantics);
}
