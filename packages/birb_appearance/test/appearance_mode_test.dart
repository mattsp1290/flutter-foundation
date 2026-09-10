import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses stable persisted values and Flutter theme modes', () {
    expect(AppearanceMode.values.map((mode) => mode.persistedValue), <String>[
      'system',
      'light',
      'dark',
    ]);
    expect(AppearanceMode.values.map((mode) => mode.themeMode), <ThemeMode>[
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ]);
  });

  test('strictly parses only exact persisted values', () {
    for (final mode in AppearanceMode.values) {
      expect(AppearanceMode.parse(mode.persistedValue), mode);
    }
    for (final invalid in <String>[
      '',
      'Light',
      ' light',
      'light ',
      'unknown',
    ]) {
      expect(() => AppearanceMode.parse(invalid), throwsFormatException);
    }
  });
}
