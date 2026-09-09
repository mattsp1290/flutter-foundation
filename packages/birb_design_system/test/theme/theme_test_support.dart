import 'dart:convert';
import 'dart:io';

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';

Map<String, Color> schemeColors(ColorScheme scheme) => <String, Color>{
  'primary': scheme.primary,
  'onPrimary': scheme.onPrimary,
  'primaryContainer': scheme.primaryContainer,
  'onPrimaryContainer': scheme.onPrimaryContainer,
  'primaryFixed': scheme.primaryFixed,
  'primaryFixedDim': scheme.primaryFixedDim,
  'onPrimaryFixed': scheme.onPrimaryFixed,
  'onPrimaryFixedVariant': scheme.onPrimaryFixedVariant,
  'secondary': scheme.secondary,
  'onSecondary': scheme.onSecondary,
  'secondaryContainer': scheme.secondaryContainer,
  'onSecondaryContainer': scheme.onSecondaryContainer,
  'secondaryFixed': scheme.secondaryFixed,
  'secondaryFixedDim': scheme.secondaryFixedDim,
  'onSecondaryFixed': scheme.onSecondaryFixed,
  'onSecondaryFixedVariant': scheme.onSecondaryFixedVariant,
  'tertiary': scheme.tertiary,
  'onTertiary': scheme.onTertiary,
  'tertiaryContainer': scheme.tertiaryContainer,
  'onTertiaryContainer': scheme.onTertiaryContainer,
  'tertiaryFixed': scheme.tertiaryFixed,
  'tertiaryFixedDim': scheme.tertiaryFixedDim,
  'onTertiaryFixed': scheme.onTertiaryFixed,
  'onTertiaryFixedVariant': scheme.onTertiaryFixedVariant,
  'error': scheme.error,
  'onError': scheme.onError,
  'errorContainer': scheme.errorContainer,
  'onErrorContainer': scheme.onErrorContainer,
  'surface': scheme.surface,
  'onSurface': scheme.onSurface,
  'surfaceDim': scheme.surfaceDim,
  'surfaceBright': scheme.surfaceBright,
  'surfaceContainerLowest': scheme.surfaceContainerLowest,
  'surfaceContainerLow': scheme.surfaceContainerLow,
  'surfaceContainer': scheme.surfaceContainer,
  'surfaceContainerHigh': scheme.surfaceContainerHigh,
  'surfaceContainerHighest': scheme.surfaceContainerHighest,
  'onSurfaceVariant': scheme.onSurfaceVariant,
  'outline': scheme.outline,
  'outlineVariant': scheme.outlineVariant,
  'shadow': scheme.shadow,
  'scrim': scheme.scrim,
  'inverseSurface': scheme.inverseSurface,
  'onInverseSurface': scheme.onInverseSurface,
  'inversePrimary': scheme.inversePrimary,
  'surfaceTint': scheme.surfaceTint,
};

Map<String, Color> semanticColors(BirbSemanticColors colors) => <String, Color>{
  'success': colors.success,
  'onSuccess': colors.onSuccess,
  'warning': colors.warning,
  'onWarning': colors.onWarning,
  'info': colors.info,
  'onInfo': colors.onInfo,
  'focus': colors.focus,
  'disabled': colors.disabled,
  'errorIndicator': colors.errorIndicator,
};

Map<String, TextStyle?> textStyles(TextTheme theme) => <String, TextStyle?>{
  'displayLarge': theme.displayLarge,
  'displayMedium': theme.displayMedium,
  'displaySmall': theme.displaySmall,
  'headlineLarge': theme.headlineLarge,
  'headlineMedium': theme.headlineMedium,
  'headlineSmall': theme.headlineSmall,
  'titleLarge': theme.titleLarge,
  'titleMedium': theme.titleMedium,
  'titleSmall': theme.titleSmall,
  'bodyLarge': theme.bodyLarge,
  'bodyMedium': theme.bodyMedium,
  'bodySmall': theme.bodySmall,
  'labelLarge': theme.labelLarge,
  'labelMedium': theme.labelMedium,
  'labelSmall': theme.labelSmall,
};

Map<String, Color> surfaces(ColorScheme scheme) => <String, Color>{
  'surface': scheme.surface,
  'surfaceDim': scheme.surfaceDim,
  'surfaceBright': scheme.surfaceBright,
  'surfaceContainerLowest': scheme.surfaceContainerLowest,
  'surfaceContainerLow': scheme.surfaceContainerLow,
  'surfaceContainer': scheme.surfaceContainer,
  'surfaceContainerHigh': scheme.surfaceContainerHigh,
  'surfaceContainerHighest': scheme.surfaceContainerHighest,
};

Directory birbDesignSystemPackageRoot() {
  final packageConfigPath = Platform.executableArguments
      .singleWhere((argument) => argument.startsWith('--packages='))
      .substring('--packages='.length);
  final configUri = Uri.file(packageConfigPath);
  final config = jsonDecode(
    File.fromUri(configUri).readAsStringSync(),
  ) as Map<String, Object?>;
  final packages = (config['packages']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final package = packages.singleWhere(
    (entry) => entry['name'] == 'birb_design_system',
  );
  return Directory.fromUri(configUri.resolve(package['rootUri']! as String));
}
