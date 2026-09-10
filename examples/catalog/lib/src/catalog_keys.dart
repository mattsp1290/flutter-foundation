import 'package:flutter/widgets.dart';

enum CatalogSection { components, appearance, accessibility }

abstract final class CatalogKeys {
  static const root = ValueKey<String>('catalog-root');
  static const contentViewport = ValueKey<String>('catalog-content-viewport');
  static const navigationRail = ValueKey<String>('catalog-navigation-rail');
  static const navigationBar = ValueKey<String>('catalog-navigation-bar');
  static const narrowToggle = ValueKey<String>('catalog-narrow-toggle');
  static const largeTextToggle = ValueKey<String>('catalog-large-text-toggle');
  static const appearanceSelector = ValueKey<String>(
    'catalog-appearance-selector',
  );
  static const forcedPreview = ValueKey<String>('catalog-forced-preview');
  static const keyboardSample = ValueKey<String>('catalog-keyboard-sample');
  static const errorSample = ValueKey<String>('catalog-error-sample');
  static const disabledSample = ValueKey<String>('catalog-disabled-sample');

  static ValueKey<String> section(CatalogSection section) =>
      ValueKey<String>('catalog-section-${section.name}');

  static ValueKey<String> destination(CatalogSection section) =>
      ValueKey<String>('catalog-destination-${section.name}');
}
