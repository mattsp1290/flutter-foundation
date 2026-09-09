import 'package:flutter/material.dart';

TextTheme buildBirbTextTheme(TextTheme platformTheme, Color color) {
  TextStyle style(
    TextStyle? platformStyle, {
    required double size,
    required FontWeight weight,
    required double height,
  }) {
    return (platformStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  return TextTheme(
    displayLarge: style(
      platformTheme.displayLarge,
      size: 40,
      weight: FontWeight.w700,
      height: 1.2,
    ),
    displayMedium: style(
      platformTheme.displayMedium,
      size: 36,
      weight: FontWeight.w700,
      height: 1.2,
    ),
    displaySmall: style(
      platformTheme.displaySmall,
      size: 32,
      weight: FontWeight.w700,
      height: 1.2,
    ),
    headlineLarge: style(
      platformTheme.headlineLarge,
      size: 28,
      weight: FontWeight.w700,
      height: 1.25,
    ),
    headlineMedium: style(
      platformTheme.headlineMedium,
      size: 24,
      weight: FontWeight.w700,
      height: 1.25,
    ),
    headlineSmall: style(
      platformTheme.headlineSmall,
      size: 20,
      weight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: style(
      platformTheme.titleLarge,
      size: 20,
      weight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: style(
      platformTheme.titleMedium,
      size: 16,
      weight: FontWeight.w600,
      height: 1.3,
    ),
    titleSmall: style(
      platformTheme.titleSmall,
      size: 14,
      weight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: style(
      platformTheme.bodyLarge,
      size: 16,
      weight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: style(
      platformTheme.bodyMedium,
      size: 14,
      weight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: style(
      platformTheme.bodySmall,
      size: 12,
      weight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: style(
      platformTheme.labelLarge,
      size: 14,
      weight: FontWeight.w700,
      height: 1.3,
    ),
    labelMedium: style(
      platformTheme.labelMedium,
      size: 12,
      weight: FontWeight.w700,
      height: 1.3,
    ),
    labelSmall: style(
      platformTheme.labelSmall,
      size: 11,
      weight: FontWeight.w700,
      height: 1.3,
    ),
  );
}
