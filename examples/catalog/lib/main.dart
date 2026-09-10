import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CatalogApp());

/// Stable lookup keys for the catalog shell.
abstract final class CatalogKeys {
  static const ValueKey<String> themePreviewTab = ValueKey<String>(
    'catalog-tab-theme',
  );
  static const ValueKey<String> reviewPreviewTab = ValueKey<String>(
    'catalog-tab-review',
  );
  static const ValueKey<String> lightModeChip = ValueKey<String>(
    'catalog-mode-light',
  );
  static const ValueKey<String> darkModeChip = ValueKey<String>(
    'catalog-mode-dark',
  );
}

/// Which preview the catalog is showing.
enum CatalogPreview { theme, review }

/// The local host for the design-system previews.
///
/// Appearance persistence is out of scope here: the catalog keeps the selected
/// brightness in memory only.
class CatalogApp extends StatefulWidget {
  const CatalogApp({super.key});

  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> {
  Brightness _brightness = Brightness.light;
  CatalogPreview _preview = CatalogPreview.review;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Foundation Catalog',
      theme: BirbTheme.light,
      darkTheme: BirbTheme.dark,
      themeMode: _brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      themeAnimationDuration: BirbDurations.instant,
      home: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CatalogControls(
            brightness: _brightness,
            preview: _preview,
            onBrightnessChanged: (value) => setState(() => _brightness = value),
            onPreviewChanged: (value) => setState(() => _preview = value),
          ),
          Expanded(
            child: switch (_preview) {
              CatalogPreview.theme => const BirbThemeHarness(),
              CatalogPreview.review => const BirbReviewHarness(),
            },
          ),
        ],
      ),
    );
  }
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.brightness,
    required this.preview,
    required this.onBrightnessChanged,
    required this.onPreviewChanged,
  });

  final Brightness brightness;
  final CatalogPreview preview;
  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<CatalogPreview> onPreviewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(BirbSpacing.space2),
          child: Wrap(
            spacing: BirbSpacing.space2,
            runSpacing: BirbSpacing.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              BirbFilterChip(
                key: CatalogKeys.themePreviewTab,
                label: const Text('Theme preview'),
                selected: preview == CatalogPreview.theme,
                onSelected: (_) => onPreviewChanged(CatalogPreview.theme),
              ),
              BirbFilterChip(
                key: CatalogKeys.reviewPreviewTab,
                label: const Text('Code review preview'),
                selected: preview == CatalogPreview.review,
                onSelected: (_) => onPreviewChanged(CatalogPreview.review),
              ),
              const SizedBox(width: BirbSpacing.space4),
              BirbFilterChip(
                key: CatalogKeys.lightModeChip,
                label: const Text('Light'),
                selected: brightness == Brightness.light,
                onSelected: (_) => onBrightnessChanged(Brightness.light),
              ),
              BirbFilterChip(
                key: CatalogKeys.darkModeChip,
                label: const Text('Dark'),
                selected: brightness == Brightness.dark,
                onSelected: (_) => onBrightnessChanged(Brightness.dark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
