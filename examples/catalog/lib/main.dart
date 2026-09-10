import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter/material.dart';

import 'src/catalog_app.dart';

export 'src/catalog_app.dart';
export 'src/catalog_keys.dart';

void main() {
  final preview = CatalogThemePreview.fromEnvironment(
    const String.fromEnvironment('BIRB_THEME_PREVIEW'),
  );
  runApp(
    CatalogApp(
      appearanceStore: PreferencesAppearanceStore(
        applicationNamespace: 'flutter_foundation_catalog',
      ),
      preview: preview,
    ),
  );
}
