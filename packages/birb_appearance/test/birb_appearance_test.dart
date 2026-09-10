import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exposes the appearance runtime', () {
    expect(AppearanceMode.system.themeMode, ThemeMode.system);
    expect(AppearanceController, isNotNull);
    expect(AppearanceSelector, isNotNull);
    expect(AppearanceStore, isNotNull);
    expect(PreferencesAppearanceStore, isNotNull);
  });
}
