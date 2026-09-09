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
      (states) =>
          _checkboxForeground(_SelectionState.from(states), colors, semantics),
    ),
    fillColor: WidgetStateColor.resolveWith((states) {
      final state = _SelectionState.from(states);
      return state.error ? colors.surface : _fill(state, colors);
    }),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(_SelectionState.from(states), colors, semantics),
    ),
    shape: const RoundedRectangleBorder(borderRadius: BirbRadii.none),
    side: WidgetStateBorderSide.resolveWith(
      (states) =>
          _checkboxSide(_SelectionState.from(states), colors, semantics),
    ),
    visualDensity: VisualDensity.standard,
  );

  static RadioThemeData radio(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => RadioThemeData(
    backgroundColor: WidgetStateColor.resolveWith((states) {
      final state = _SelectionState.from(states);
      if (state.disabled) return colors.surface;
      if (state.pressed) return colors.primaryContainer;
      if (state.focused) return colors.surface;
      if (state.hovered) return colors.surfaceContainerHigh;
      return colors.surface;
    }),
    fillColor: WidgetStateColor.resolveWith((states) {
      final state = _SelectionState.from(states);
      if (state.disabled) return semantics.disabled;
      if (state.pressed) return colors.onPrimaryContainer;
      if (state.hovered) return colors.onSurface;
      return state.selected ? colors.primary : colors.outline;
    }),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(_SelectionState.from(states), colors, semantics),
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => _side(_SelectionState.from(states), colors, semantics),
    ),
    visualDensity: VisualDensity.standard,
  );

  static SwitchThemeData toggle(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    overlayColor: WidgetStateColor.resolveWith(
      (states) => _overlay(_SelectionState.from(states), colors, semantics),
    ),
    thumbColor: WidgetStateColor.resolveWith(
      (states) => _foreground(_SelectionState.from(states), colors, semantics),
    ),
    trackColor: WidgetStateColor.resolveWith(
      (states) => _fill(_SelectionState.from(states), colors),
    ),
    trackOutlineColor: WidgetStateColor.resolveWith((states) {
      final state = _SelectionState.from(states);
      if (state.disabled) return semantics.disabled;
      if (state.focused) return semantics.focus;
      if (state.pressed) return colors.onPrimaryContainer;
      return state.selected ? colors.primary : colors.outline;
    }),
    trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
      final state = _SelectionState.from(states);
      return state.focused && !state.disabled
          ? BirbBorders.strong
          : BirbBorders.thin;
    }),
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
      (states) => _foreground(_SelectionState.from(states), colors, semantics),
    );
    return ChipThemeData(
      // ChipThemeData does not resolve this color by widget state. Disabled
      // selected chips use `BirbFilterChip`'s concrete per-instance override.
      checkmarkColor: colors.onPrimary,
      color: WidgetStateColor.resolveWith(
        (states) => _fill(_SelectionState.from(states), colors),
      ),
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
        (states) => _side(_SelectionState.from(states), colors, semantics),
      ),
      surfaceTintColor: WidgetStateColor.transparent,
    );
  }
}

Color _fill(_SelectionState state, ColorScheme colors) {
  if (state.disabled) return colors.surface;
  if (state.pressed) return colors.primaryContainer;
  if (state.focused) {
    return state.selected ? colors.primary : colors.surface;
  }
  if (state.hovered) return colors.surfaceContainerHigh;
  return state.selected ? colors.primary : colors.surface;
}

Color _foreground(
  _SelectionState state,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (state.disabled) return semantics.disabled;
  if (state.pressed) return colors.onPrimaryContainer;
  if (state.focused) {
    return state.selected ? colors.onPrimary : colors.onSurface;
  }
  if (state.hovered) return colors.onSurface;
  return state.selected ? colors.onPrimary : colors.onSurface;
}

BorderSide _side(
  _SelectionState state,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (state.disabled) {
    return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
  }
  if (state.focused) {
    return BorderSide(color: semantics.focus, width: BirbBorders.strong);
  }
  return BorderSide(
    color: state.selected ? colors.primary : colors.outline,
    width: BirbBorders.thin,
  );
}

Color _overlay(
  _SelectionState state,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (state.disabled) return WidgetStateColor.transparent;
  if (state.pressed) return colors.primaryContainer;
  if (state.focused) return semantics.focus;
  if (state.hovered) return colors.surfaceContainerHigh;
  return WidgetStateColor.transparent;
}

Color _checkboxForeground(
  _SelectionState state,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (state.disabled) return semantics.disabled;
  if (state.error) return semantics.errorIndicator;
  return _foreground(state, colors, semantics);
}

BorderSide _checkboxSide(
  _SelectionState state,
  ColorScheme colors,
  BirbSemanticColors semantics,
) {
  if (state.disabled) {
    return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
  }
  if (state.error) {
    return BorderSide(
      color: semantics.errorIndicator,
      width: state.focused ? BirbBorders.strong : BirbBorders.thin,
    );
  }
  return _side(state, colors, semantics);
}

final class _SelectionState {
  const _SelectionState({
    required this.disabled,
    required this.error,
    required this.focused,
    required this.hovered,
    required this.pressed,
    required this.selected,
  });

  factory _SelectionState.from(Set<WidgetState> states) => _SelectionState(
    disabled: states.contains(WidgetState.disabled),
    error: states.contains(WidgetState.error),
    focused: states.contains(WidgetState.focused),
    hovered: states.contains(WidgetState.hovered),
    pressed: states.contains(WidgetState.pressed),
    selected: states.contains(WidgetState.selected),
  );

  final bool disabled;
  final bool error;
  final bool focused;
  final bool hovered;
  final bool pressed;
  final bool selected;
}
