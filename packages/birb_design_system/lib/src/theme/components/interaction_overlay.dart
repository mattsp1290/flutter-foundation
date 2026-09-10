import 'package:flutter/material.dart';

import '../../color/birb_semantic_colors.dart';

/// Internal resolver shared by controls with the Birb interaction-state policy.
abstract final class BirbInteractionOverlay {
  static Color resolve(
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
}
