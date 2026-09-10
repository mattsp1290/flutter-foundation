import 'package:birb_appearance/birb_appearance.dart';
import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';

import 'catalog_keys.dart';

enum CatalogThemePreview {
  persisted,
  light,
  dark;

  static CatalogThemePreview fromEnvironment(String value) => switch (value) {
    '' => persisted,
    'light' => light,
    'dark' => dark,
    _ => throw ArgumentError.value(
      value,
      'BIRB_THEME_PREVIEW',
      'must be empty, light, or dark',
    ),
  };

  ThemeMode? get themeMode => switch (this) {
    persisted => null,
    light => ThemeMode.light,
    dark => ThemeMode.dark,
  };
}

class CatalogApp extends StatefulWidget {
  const CatalogApp({
    required this.appearanceStore,
    super.key,
    this.preview = CatalogThemePreview.persisted,
  });

  final AppearanceStore appearanceStore;

  final CatalogThemePreview preview;

  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> {
  late AppearanceController _appearance;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(CatalogApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appearanceStore != oldWidget.appearanceStore) {
      _appearance.dispose();
      _createController();
    }
  }

  void _createController() {
    _appearance = AppearanceController(store: widget.appearanceStore);
    _appearance.initialize();
  }

  @override
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _appearance,
    builder: (context, _) => MaterialApp(
      title: 'Flutter Foundation Catalog',
      theme: BirbTheme.light,
      darkTheme: BirbTheme.dark,
      themeMode: widget.preview.themeMode ?? _appearance.themeMode,
      themeAnimationDuration: BirbDurations.instant,
      home: CatalogHome(controller: _appearance, preview: widget.preview),
    ),
  );
}

class CatalogHome extends StatefulWidget {
  const CatalogHome({
    required this.controller,
    required this.preview,
    super.key,
  });

  final AppearanceController controller;
  final CatalogThemePreview preview;

  @override
  State<CatalogHome> createState() => _CatalogHomeState();
}

class _CatalogHomeState extends State<CatalogHome> {
  CatalogSection _section = CatalogSection.components;
  bool _narrow = false;
  bool _largeText = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final useRail = constraints.maxWidth >= 720;
      final content = Column(
        children: <Widget>[
          _PreviewControls(
            narrow: _narrow,
            largeText: _largeText,
            onNarrowChanged: (value) => setState(() => _narrow = value),
            onLargeTextChanged: (value) => setState(() => _largeText = value),
          ),
          Expanded(child: _viewport()),
        ],
      );

      return Scaffold(
        key: CatalogKeys.root,
        appBar: AppBar(title: const Text('Flutter Foundation Catalog')),
        body: useRail
            ? Row(
                children: <Widget>[
                  NavigationRail(
                    key: CatalogKeys.navigationRail,
                    selectedIndex: _section.index,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: _selectIndex,
                    destinations: CatalogSection.values
                        .map(
                          (section) => NavigationRailDestination(
                            icon: Icon(
                              section.icon,
                              key: CatalogKeys.destination(section),
                            ),
                            label: Text(section.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                key: CatalogKeys.navigationBar,
                selectedIndex: _section.index,
                onDestinationSelected: _selectIndex,
                destinations: CatalogSection.values
                    .map(
                      (section) => NavigationDestination(
                        icon: Icon(
                          section.icon,
                          key: CatalogKeys.destination(section),
                        ),
                        label: section.label,
                      ),
                    )
                    .toList(growable: false),
              ),
      );
    },
  );

  void _selectIndex(int value) {
    setState(() => _section = CatalogSection.values[value]);
  }

  Widget _viewport() {
    final mediaQuery = MediaQuery.of(context);
    final child = MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: _largeText
            ? const TextScaler.linear(2)
            : mediaQuery.textScaler,
      ),
      child: KeyedSubtree(key: CatalogKeys.section(_section), child: _page()),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: CatalogKeys.contentViewport,
        width: _narrow ? 320 : null,
        child: child,
      ),
    );
  }

  Widget _page() => switch (_section) {
    CatalogSection.components => const BirbThemeHarness(),
    CatalogSection.codeReview => const BirbReviewHarness(),
    CatalogSection.appearance => _AppearancePage(
      controller: widget.controller,
      preview: widget.preview,
    ),
    CatalogSection.accessibility => const _AccessibilityPage(),
  };
}

extension on CatalogSection {
  String get label => switch (this) {
    CatalogSection.components => 'Components',
    CatalogSection.codeReview => 'Code review',
    CatalogSection.appearance => 'Appearance',
    CatalogSection.accessibility => 'Accessibility',
  };

  IconData get icon => switch (this) {
    CatalogSection.components => Icons.widgets_outlined,
    CatalogSection.codeReview => Icons.rate_review_outlined,
    CatalogSection.appearance => Icons.brightness_6_outlined,
    CatalogSection.accessibility => Icons.accessibility_new,
  };
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({
    required this.narrow,
    required this.largeText,
    required this.onNarrowChanged,
    required this.onLargeTextChanged,
  });

  final bool narrow;
  final bool largeText;
  final ValueChanged<bool> onNarrowChanged;
  final ValueChanged<bool> onLargeTextChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BirbSpacing.space2),
    child: Wrap(
      spacing: BirbSpacing.space2,
      runSpacing: BirbSpacing.space1,
      children: <Widget>[
        FilterChip(
          key: CatalogKeys.narrowToggle,
          label: const Text('320 px preview'),
          selected: narrow,
          onSelected: onNarrowChanged,
        ),
        FilterChip(
          key: CatalogKeys.largeTextToggle,
          label: const Text('200% text'),
          selected: largeText,
          onSelected: onLargeTextChanged,
        ),
      ],
    ),
  );
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({required this.controller, required this.preview});

  final AppearanceController controller;
  final CatalogThemePreview preview;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(BirbSpacing.space4),
    children: <Widget>[
      Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: BirbSpacing.space3),
      if (preview == CatalogThemePreview.persisted)
        AppearanceSelector(
          key: CatalogKeys.appearanceSelector,
          controller: controller,
        )
      else
        Semantics(
          key: CatalogKeys.forcedPreview,
          container: true,
          label: '${preview.name} preview is forced; preference is unchanged',
          child: ExcludeSemantics(
            child: Text(
              '${preview.name[0].toUpperCase()}${preview.name.substring(1)} '
              'preview is forced by BIRB_THEME_PREVIEW. The persisted '
              'preference is not changed.',
            ),
          ),
        ),
      const SizedBox(height: BirbSpacing.space4),
      Text('Selected: ${controller.selectedMode.name}'),
      Text('Persisted: ${controller.lastPersistedMode?.name ?? 'none'}'),
      const Text('Storage namespace: flutter_foundation_catalog'),
    ],
  );
}

class _AccessibilityPage extends StatelessWidget {
  const _AccessibilityPage();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(BirbSpacing.space4),
    children: <Widget>[
      Text(
        'Accessibility inspection',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: BirbSpacing.space3),
      const Text(
        'Use the preview controls above to constrain any section to 320 logical '
        'pixels and scale text to 200 percent. Use Tab and arrow keys to inspect '
        'focus order, selection controls, overlays, disabled states, errors, and '
        'status semantics.',
      ),
      const SizedBox(height: BirbSpacing.space4),
      const BirbTextFormField(
        key: CatalogKeys.keyboardSample,
        label: 'Keyboard focus sample',
        hintText: 'Press Tab to focus',
      ),
      const SizedBox(height: BirbSpacing.space3),
      const BirbTextFormField(
        key: CatalogKeys.errorSample,
        label: 'Error sample',
        errorText: 'Inspect the error state',
      ),
      const SizedBox(height: BirbSpacing.space3),
      const BirbTextFormField(
        key: CatalogKeys.disabledSample,
        label: 'Disabled sample',
        enabled: false,
      ),
    ],
  );
}
