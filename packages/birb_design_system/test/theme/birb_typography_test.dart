import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../source_oracle/birbparty_foundation_oracle.dart';
import 'theme_test_support.dart';

void main() {
  for (final themeCase in <(String, ThemeData)>[
    ('light', BirbTheme.light),
    ('dark', BirbTheme.dark),
  ]) {
    test('${themeCase.$1} preserves platform type metadata', () {
      final theme = themeCase.$2;
      final actual = textStyles(theme.textTheme);
      final platform = textStyles(
        ThemeData(
          useMaterial3: true,
          brightness: theme.brightness,
          colorScheme: theme.colorScheme,
        ).textTheme,
      );

      expect(actual.keys, sourceTypography.keys);
      for (final entry in sourceTypography.entries) {
        final style = actual[entry.key]!;
        final baseline = platform[entry.key]!;
        expect(style.fontSize, entry.value.$1, reason: entry.key);
        expect(style.fontWeight?.value, entry.value.$2, reason: entry.key);
        expect(style.height, entry.value.$3, reason: entry.key);
        expect(style.color, theme.colorScheme.onSurface, reason: entry.key);
        expect(style.fontFamily, baseline.fontFamily, reason: entry.key);
        expect(
          style.fontFamilyFallback,
          baseline.fontFamilyFallback,
          reason: entry.key,
        );
        expect(style.fontFeatures, baseline.fontFeatures, reason: entry.key);
        expect(
          style.fontVariations,
          baseline.fontVariations,
          reason: entry.key,
        );
      }
    });
  }
}
