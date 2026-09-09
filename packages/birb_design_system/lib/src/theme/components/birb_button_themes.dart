import 'package:flutter/material.dart';

import '../../color/birb_semantic_colors.dart';
import '../../tokens/birb_tokens.dart';

/// Internal builders for the shared button state contract.
abstract final class BirbButtonThemes {
  static ButtonStyle filled(ColorScheme colors, BirbSemanticColors semantics) =>
      _buttonStyle(
        background: (states) => switch (_visualState(states)) {
          _ButtonVisualState.disabled => colors.surface,
          _ButtonVisualState.pressed => colors.primaryContainer,
          _ButtonVisualState.focused => colors.primary,
          _ButtonVisualState.hovered => colors.primaryContainer,
          _ButtonVisualState.enabled => colors.primary,
        },
        foreground: (states) => switch (_visualState(states)) {
          _ButtonVisualState.disabled => semantics.disabled,
          _ButtonVisualState.pressed => colors.onPrimaryContainer,
          _ButtonVisualState.focused => colors.onPrimary,
          _ButtonVisualState.hovered => colors.onPrimaryContainer,
          _ButtonVisualState.enabled => colors.onPrimary,
        },
        side: (states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: semantics.disabled,
              width: BirbBorders.thin,
            );
          }
          if (states.contains(WidgetState.focused)) {
            return BorderSide(
              color: semantics.focus,
              width: BirbBorders.strong,
              strokeAlign: BorderSide.strokeAlignOutside,
            );
          }
          return BorderSide.none;
        },
      );

  static ButtonStyle outlined(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => _buttonStyle(
    background: (states) => switch (_visualState(states)) {
      _ButtonVisualState.disabled => colors.surface,
      _ButtonVisualState.pressed => colors.surfaceContainer,
      _ButtonVisualState.focused => colors.surface,
      _ButtonVisualState.hovered => colors.surfaceContainer,
      _ButtonVisualState.enabled => colors.surface,
    },
    foreground: (states) => _visualState(states) == _ButtonVisualState.disabled
        ? semantics.disabled
        : colors.onSurface,
    side: (states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: semantics.disabled, width: BirbBorders.thin);
      }
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: semantics.focus, width: BirbBorders.strong);
      }
      return BorderSide(color: colors.outline, width: BirbBorders.thin);
    },
  );

  static ButtonStyle borderless(
    ColorScheme colors,
    BirbSemanticColors semantics,
  ) => _buttonStyle(
    background: (states) => switch (_visualState(states)) {
      _ButtonVisualState.disabled => colors.surface,
      _ButtonVisualState.pressed => colors.surfaceContainer,
      _ButtonVisualState.focused => WidgetStateColor.transparent,
      _ButtonVisualState.hovered => colors.surfaceContainer,
      _ButtonVisualState.enabled => WidgetStateColor.transparent,
    },
    foreground: (states) => switch (_visualState(states)) {
      _ButtonVisualState.disabled => semantics.disabled,
      _ButtonVisualState.pressed => colors.onSurface,
      _ButtonVisualState.focused => colors.primary,
      _ButtonVisualState.hovered => colors.onSurface,
      _ButtonVisualState.enabled => colors.primary,
    },
    side: (states) {
      if (states.contains(WidgetState.focused) &&
          !states.contains(WidgetState.disabled)) {
        return BorderSide(color: semantics.focus, width: BirbBorders.strong);
      }
      return BorderSide.none;
    },
  );

  static ButtonStyle menu(ColorScheme colors, BirbSemanticColors semantics) {
    final foreground = WidgetStateColor.resolveWith(
      (states) => _componentForeground(states, colors, semantics),
    );
    return _buttonStyle(
      background: (states) => switch (_visualState(states)) {
        _ButtonVisualState.disabled => colors.surface,
        _ButtonVisualState.pressed => colors.primaryContainer,
        _ButtonVisualState.focused => WidgetStateColor.transparent,
        _ButtonVisualState.hovered => colors.surfaceContainerHigh,
        _ButtonVisualState.enabled => WidgetStateColor.transparent,
      },
      foreground: foreground.resolve,
      side: (states) {
        if (states.contains(WidgetState.focused) &&
            !states.contains(WidgetState.disabled)) {
          return BorderSide(color: semantics.focus, width: BirbBorders.strong);
        }
        return BorderSide.none;
      },
    ).copyWith(iconColor: foreground);
  }
}

ButtonStyle _buttonStyle({
  required Color Function(Set<WidgetState>) background,
  required Color Function(Set<WidgetState>) foreground,
  required BorderSide Function(Set<WidgetState>) side,
}) => ButtonStyle(
  animationDuration: BirbDurations.standard,
  backgroundColor: WidgetStateProperty.resolveWith(background),
  foregroundColor: WidgetStateProperty.resolveWith(foreground),
  overlayColor: const WidgetStatePropertyAll<Color>(
    WidgetStateColor.transparent,
  ),
  elevation: const WidgetStatePropertyAll<double>(0),
  minimumSize: const WidgetStatePropertyAll<Size>(
    Size.square(BirbSizes.minimumInteractiveDimension),
  ),
  side: WidgetStateProperty.resolveWith(side),
  shape: const WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BirbRadii.none),
  ),
  surfaceTintColor: const WidgetStatePropertyAll<Color>(
    WidgetStateColor.transparent,
  ),
  tapTargetSize: MaterialTapTargetSize.padded,
  visualDensity: VisualDensity.standard,
);

enum _ButtonVisualState { disabled, pressed, focused, hovered, enabled }

_ButtonVisualState _visualState(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return _ButtonVisualState.disabled;
  if (states.contains(WidgetState.pressed)) return _ButtonVisualState.pressed;
  if (states.contains(WidgetState.focused)) return _ButtonVisualState.focused;
  if (states.contains(WidgetState.hovered)) return _ButtonVisualState.hovered;
  return _ButtonVisualState.enabled;
}

Color _componentForeground(
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
