import 'package:flutter/material.dart';

import '../foundation/birb_palette.dart';

/// Birb Party semantic roles that do not have a Material [ColorScheme] role.
@immutable
final class BirbSemanticColors extends ThemeExtension<BirbSemanticColors> {
  const BirbSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.focus,
    required this.disabled,
    required this.errorIndicator,
  });

  static const BirbSemanticColors light = BirbSemanticColors(
    success: BirbPalette.green,
    onSuccess: BirbPalette.black,
    warning: BirbPalette.orange,
    onWarning: BirbPalette.black,
    info: BirbPalette.blue,
    onInfo: BirbPalette.white,
    focus: BirbPalette.darkBlue,
    disabled: BirbPalette.gray,
    errorIndicator: BirbPalette.purple,
  );

  static const BirbSemanticColors dark = BirbSemanticColors(
    success: BirbPalette.lime,
    onSuccess: BirbPalette.black,
    warning: BirbPalette.yellow,
    onWarning: BirbPalette.black,
    info: BirbPalette.lightBlue,
    onInfo: BirbPalette.black,
    focus: BirbPalette.cyan,
    disabled: BirbPalette.lightGray,
    errorIndicator: BirbPalette.yellow,
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color focus;
  final Color disabled;
  final Color errorIndicator;

  @override
  BirbSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? focus,
    Color? disabled,
    Color? errorIndicator,
  }) {
    return BirbSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      focus: focus ?? this.focus,
      disabled: disabled ?? this.disabled,
      errorIndicator: errorIndicator ?? this.errorIndicator,
    );
  }

  @override
  BirbSemanticColors lerp(covariant BirbSemanticColors? other, double t) {
    if (other == null || t < 0.5) {
      return this;
    }
    return other;
  }
}
