import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'theme_test_support.dart';

void main() {
  for (final themeCase in <(String, ThemeData)>[
    ('light', BirbTheme.light),
    ('dark', BirbTheme.dark),
  ]) {
    test('${themeCase.$1} documented contrast pairs pass', () {
      final failures = <String>[];
      for (final pair in _requiredPairs(themeCase.$2)) {
        final ratio = _contrastRatio(pair.foreground, pair.background);
        if (ratio < pair.minimum) {
          failures.add(
            '${pair.name}: ${ratio.toStringAsFixed(4)} '
            '< ${pair.minimum.toStringAsFixed(1)}',
          );
        }
      }
      expect(failures, isEmpty);
    });
  }
}

List<_ContrastPair> _requiredPairs(ThemeData theme) {
  final colors = theme.colorScheme;
  final semantics = theme.extension<BirbSemanticColors>()!;
  final pairs = <_ContrastPair>[
    _text('primary/onPrimary', colors.onPrimary, colors.primary),
    _text(
      'primaryContainer/onPrimaryContainer',
      colors.onPrimaryContainer,
      colors.primaryContainer,
    ),
    _text(
      'primaryFixed/onPrimaryFixed',
      colors.onPrimaryFixed,
      colors.primaryFixed,
    ),
    _text(
      'primaryFixedDim/onPrimaryFixedVariant',
      colors.onPrimaryFixedVariant,
      colors.primaryFixedDim,
    ),
    _text('secondary/onSecondary', colors.onSecondary, colors.secondary),
    _text(
      'secondaryContainer/onSecondaryContainer',
      colors.onSecondaryContainer,
      colors.secondaryContainer,
    ),
    _text(
      'secondaryFixed/onSecondaryFixed',
      colors.onSecondaryFixed,
      colors.secondaryFixed,
    ),
    _text(
      'secondaryFixedDim/onSecondaryFixedVariant',
      colors.onSecondaryFixedVariant,
      colors.secondaryFixedDim,
    ),
    _text('tertiary/onTertiary', colors.onTertiary, colors.tertiary),
    _text(
      'tertiaryContainer/onTertiaryContainer',
      colors.onTertiaryContainer,
      colors.tertiaryContainer,
    ),
    _text(
      'tertiaryFixed/onTertiaryFixed',
      colors.onTertiaryFixed,
      colors.tertiaryFixed,
    ),
    _text(
      'tertiaryFixedDim/onTertiaryFixedVariant',
      colors.onTertiaryFixedVariant,
      colors.tertiaryFixedDim,
    ),
    _text('error/onError', colors.onError, colors.error),
    _text(
      'errorContainer/onErrorContainer',
      colors.onErrorContainer,
      colors.errorContainer,
    ),
    _text(
      'inverseSurface/onInverseSurface',
      colors.onInverseSurface,
      colors.inverseSurface,
    ),
    _text(
      'inverseSurface/inversePrimary',
      colors.inversePrimary,
      colors.inverseSurface,
    ),
    _text('success/onSuccess', semantics.onSuccess, semantics.success),
    _text('warning/onWarning', semantics.onWarning, semantics.warning),
    _text('info/onInfo', semantics.onInfo, semantics.info),
  ];

  final assignedSurfaces = surfaces(colors);
  for (final surface in assignedSurfaces.entries) {
    pairs
      ..add(_text('${surface.key}/onSurface', colors.onSurface, surface.value))
      ..add(
        _text(
          '${surface.key}/onSurfaceVariant',
          colors.onSurfaceVariant,
          surface.value,
        ),
      )
      ..add(_boundary('${surface.key}/outline', colors.outline, surface.value))
      ..add(
        _boundary(
          '${surface.key}/outlineVariant',
          colors.outlineVariant,
          surface.value,
        ),
      )
      ..add(_boundary('${surface.key}/focus', semantics.focus, surface.value))
      ..add(
        _text(
          '${surface.key}/errorIndicator',
          semantics.errorIndicator,
          surface.value,
        ),
      );
  }

  final disabledSurfaces = colors.brightness == Brightness.light
      ? const <String>{
          'surface',
          'surfaceBright',
          'surfaceContainerLowest',
          'surfaceContainerLow',
        }
      : assignedSurfaces.keys.toSet();
  for (final name in disabledSurfaces) {
    pairs.add(
      _text('$name/disabled', semantics.disabled, assignedSurfaces[name]!),
    );
  }
  return pairs;
}

_ContrastPair _text(String name, Color foreground, Color background) =>
    _ContrastPair(name, foreground, background, 4.5);

_ContrastPair _boundary(String name, Color foreground, Color background) =>
    _ContrastPair(name, foreground, background, 3);

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

final class _ContrastPair {
  const _ContrastPair(
    this.name,
    this.foreground,
    this.background,
    this.minimum,
  );

  final String name;
  final Color foreground;
  final Color background;
  final double minimum;
}
