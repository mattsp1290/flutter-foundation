import 'package:flutter/material.dart';

/// A user-selectable application appearance.
enum AppearanceMode {
  system('system', ThemeMode.system),
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark);

  const AppearanceMode(this.persistedValue, this.themeMode);

  /// The stable value written to persistent storage.
  final String persistedValue;

  /// The corresponding Flutter theme mode.
  final ThemeMode themeMode;

  /// Parses an exact persisted value.
  ///
  /// Unknown values are rejected so callers must choose their own fallback.
  static AppearanceMode parse(String value) {
    for (final mode in values) {
      if (mode.persistedValue == value) {
        return mode;
      }
    }
    throw FormatException('Unknown appearance mode: $value', value);
  }
}
