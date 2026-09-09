/// Test-only snapshot of Birbparty commit
/// 0a037dc0d696cf6ea09e006d9c7145b0ab9f8291.
const birbpartySourceCommit = '0a037dc0d696cf6ea09e006d9c7145b0ab9f8291';

const sourceFileSha256 = <String, String>{
  'birb_theme.dart':
      '2a94c09605094ef989193c67ee94228f19ac2b541b7f8ebc5aed2bdca915118e',
  'birb_semantic_colors.dart':
      '5e14ab7618e354156613962c1c5a19c0ae01829868647f877956ba468723322a',
  'birb_tokens.dart':
      'f7bb76c637972534aeccd11a9477548da5d93bc0a3c569f837fab803f62ec612',
  'birb_palette.dart':
      '6183a21ab11d3cf3651eba72997e8b32bd7592c150de4ec9028ce532ef284a95',
};

const sourcePalette = <String, int>{
  'black': 0xFF1A1C2C,
  'purple': 0xFF5D275D,
  'red': 0xFFB13E53,
  'orange': 0xFFEF7D57,
  'yellow': 0xFFFFCD75,
  'lime': 0xFFA7F070,
  'green': 0xFF38B764,
  'darkCyan': 0xFF257179,
  'darkBlue': 0xFF29366F,
  'blue': 0xFF3B5DC9,
  'lightBlue': 0xFF41A6F6,
  'cyan': 0xFF73EFF7,
  'white': 0xFFF4F4F4,
  'lightGray': 0xFF94B0C2,
  'gray': 0xFF566C86,
  'darkGray': 0xFF333C57,
};

const sourceLightScheme = <String, String>{
  'primary': 'blue',
  'onPrimary': 'white',
  'primaryContainer': 'darkBlue',
  'onPrimaryContainer': 'white',
  'primaryFixed': 'darkBlue',
  'primaryFixedDim': 'blue',
  'onPrimaryFixed': 'white',
  'onPrimaryFixedVariant': 'white',
  'secondary': 'darkCyan',
  'onSecondary': 'white',
  'secondaryContainer': 'purple',
  'onSecondaryContainer': 'white',
  'secondaryFixed': 'purple',
  'secondaryFixedDim': 'darkCyan',
  'onSecondaryFixed': 'white',
  'onSecondaryFixedVariant': 'white',
  'tertiary': 'green',
  'onTertiary': 'black',
  'tertiaryContainer': 'lime',
  'onTertiaryContainer': 'black',
  'tertiaryFixed': 'lime',
  'tertiaryFixedDim': 'green',
  'onTertiaryFixed': 'black',
  'onTertiaryFixedVariant': 'black',
  'error': 'red',
  'onError': 'white',
  'errorContainer': 'purple',
  'onErrorContainer': 'white',
  'surface': 'white',
  'onSurface': 'black',
  'surfaceDim': 'lightGray',
  'surfaceBright': 'white',
  'surfaceContainerLowest': 'white',
  'surfaceContainerLow': 'white',
  'surfaceContainer': 'lightGray',
  'surfaceContainerHigh': 'lightGray',
  'surfaceContainerHighest': 'lightGray',
  'onSurfaceVariant': 'black',
  'outline': 'black',
  'outlineVariant': 'black',
  'shadow': 'black',
  'scrim': 'black',
  'inverseSurface': 'black',
  'onInverseSurface': 'white',
  'inversePrimary': 'lightBlue',
  'surfaceTint': 'blue',
};

const sourceDarkScheme = <String, String>{
  'primary': 'cyan',
  'onPrimary': 'black',
  'primaryContainer': 'lightBlue',
  'onPrimaryContainer': 'black',
  'primaryFixed': 'darkBlue',
  'primaryFixedDim': 'blue',
  'onPrimaryFixed': 'white',
  'onPrimaryFixedVariant': 'white',
  'secondary': 'lime',
  'onSecondary': 'black',
  'secondaryContainer': 'green',
  'onSecondaryContainer': 'black',
  'secondaryFixed': 'purple',
  'secondaryFixedDim': 'darkCyan',
  'onSecondaryFixed': 'white',
  'onSecondaryFixedVariant': 'white',
  'tertiary': 'yellow',
  'onTertiary': 'black',
  'tertiaryContainer': 'orange',
  'onTertiaryContainer': 'black',
  'tertiaryFixed': 'lime',
  'tertiaryFixedDim': 'green',
  'onTertiaryFixed': 'black',
  'onTertiaryFixedVariant': 'black',
  'error': 'orange',
  'onError': 'black',
  'errorContainer': 'red',
  'onErrorContainer': 'white',
  'surface': 'black',
  'onSurface': 'white',
  'surfaceDim': 'black',
  'surfaceBright': 'darkGray',
  'surfaceContainerLowest': 'black',
  'surfaceContainerLow': 'black',
  'surfaceContainer': 'darkGray',
  'surfaceContainerHigh': 'darkBlue',
  'surfaceContainerHighest': 'darkGray',
  'onSurfaceVariant': 'white',
  'outline': 'lightGray',
  'outlineVariant': 'lightGray',
  'shadow': 'black',
  'scrim': 'black',
  'inverseSurface': 'white',
  'onInverseSurface': 'black',
  'inversePrimary': 'blue',
  'surfaceTint': 'cyan',
};

const sourceLightSemantics = <String, String>{
  'success': 'green',
  'onSuccess': 'black',
  'warning': 'orange',
  'onWarning': 'black',
  'info': 'blue',
  'onInfo': 'white',
  'focus': 'darkBlue',
  'disabled': 'gray',
  'errorIndicator': 'purple',
};

const sourceDarkSemantics = <String, String>{
  'success': 'lime',
  'onSuccess': 'black',
  'warning': 'yellow',
  'onWarning': 'black',
  'info': 'lightBlue',
  'onInfo': 'black',
  'focus': 'cyan',
  'disabled': 'lightGray',
  'errorIndicator': 'yellow',
};

const sourceTypography = <String, (double, int, double)>{
  'displayLarge': (40, 700, 1.2),
  'displayMedium': (36, 700, 1.2),
  'displaySmall': (32, 700, 1.2),
  'headlineLarge': (28, 700, 1.25),
  'headlineMedium': (24, 700, 1.25),
  'headlineSmall': (20, 700, 1.25),
  'titleLarge': (20, 600, 1.3),
  'titleMedium': (16, 600, 1.3),
  'titleSmall': (14, 600, 1.3),
  'bodyLarge': (16, 400, 1.5),
  'bodyMedium': (14, 400, 1.5),
  'bodySmall': (12, 400, 1.5),
  'labelLarge': (14, 700, 1.3),
  'labelMedium': (12, 700, 1.3),
  'labelSmall': (11, 700, 1.3),
};

const sourceSpacing = <double>[4, 8, 12, 16, 24, 32, 48];
const sourceBorders = <double>[1, 2];
const sourceRadii = <double>[0, 2];
const sourceMinimumInteractiveDimension = 48.0;
const sourceDurationsMs = <int>[0, 100, 200];

const sourceInputColors = <String, String>{
  'lightEnabled': 'black',
  'lightDisabled': 'gray',
  'darkEnabled': 'white',
  'darkDisabled': 'lightGray',
};
