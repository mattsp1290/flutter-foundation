import 'package:flutter/material.dart';

import '../../birb_design_system.dart';

/// Families represented by the reusable design-system preview.
enum BirbHarnessFamily {
  typography,
  surfaces,
  interactiveControls,
  overlays,
  statuses,
  navigation,
  inputs,
}

/// One stable, named preview fixture.
typedef BirbHarnessFixture = ({BirbHarnessFamily family, String name});

/// Closed fixture inventories shared by catalogs and tests.
abstract final class BirbThemeHarnessInventory {
  static const typography = <String>[
    'displayLarge',
    'displayMedium',
    'displaySmall',
    'headlineLarge',
    'headlineMedium',
    'headlineSmall',
    'titleLarge',
    'titleMedium',
    'titleSmall',
    'bodyLarge',
    'bodyMedium',
    'bodySmall',
    'labelLarge',
    'labelMedium',
    'labelSmall',
  ];

  static const surfaces = <String>[
    'surface',
    'surfaceDim',
    'surfaceBright',
    'surfaceContainerLowest',
    'surfaceContainerLow',
    'surfaceContainer',
    'surfaceContainerHigh',
    'surfaceContainerHighest',
    'card',
    'divider',
  ];

  static const interactiveControls = <String>[
    'filledButton',
    'elevatedButton',
    'outlinedButton',
    'textButton',
    'iconButton',
    'disabledButton',
    'checkboxSelected',
    'checkboxUnselected',
    'checkboxError',
    'checkboxDisabled',
    'radioSelected',
    'radioUnselected',
    'radioDisabled',
    'switchSelected',
    'switchUnselected',
    'switchDisabled',
    'sliderEnabled',
    'sliderDisabled',
    'chipSelected',
    'chipUnselected',
    'chipDisabled',
  ];

  static const overlays = <String>[
    'dialogTrigger',
    'menuTrigger',
    'snackbarTrigger',
    'tooltip',
  ];

  static const statuses = <String>[
    'success',
    'warning',
    'info',
    'error',
    'selected',
    'loading',
    'disabled',
  ];

  static const navigation = <String>['navigationBar', 'navigationRail'];

  static const inputs = <String>['enabled', 'error', 'disabled'];

  static const byFamily = <BirbHarnessFamily, List<String>>{
    BirbHarnessFamily.typography: typography,
    BirbHarnessFamily.surfaces: surfaces,
    BirbHarnessFamily.interactiveControls: interactiveControls,
    BirbHarnessFamily.overlays: overlays,
    BirbHarnessFamily.statuses: statuses,
    BirbHarnessFamily.navigation: navigation,
    BirbHarnessFamily.inputs: inputs,
  };

  static Iterable<BirbHarnessFixture> get all sync* {
    for (final MapEntry(key: family, value: names) in byFamily.entries) {
      for (final name in names) {
        yield (family: family, name: name);
      }
    }
  }
}

/// Stable lookup keys for every fixture and transient overlay.
abstract final class BirbThemeHarnessKeys {
  static const root = ValueKey<String>('birb-theme-harness');
  static const dialog = ValueKey<String>('birb-theme-harness-dialog');
  static const dialogDismiss = ValueKey<String>(
    'birb-theme-harness-dialog-dismiss',
  );
  static const menuItem = ValueKey<String>('birb-theme-harness-menu-item');
  static const snackbar = ValueKey<String>('birb-theme-harness-snackbar');

  static ValueKey<String> fixture(BirbHarnessFixture fixture) =>
      ValueKey<String>('birb-${fixture.family.name}-${fixture.name}');
}

/// A host-neutral gallery of every design-system component family and state.
class BirbThemeHarness extends StatefulWidget {
  const BirbThemeHarness({super.key});

  @override
  State<BirbThemeHarness> createState() => _BirbThemeHarnessState();
}

class _BirbThemeHarnessState extends State<BirbThemeHarness> {
  bool _checkbox = true;
  String _radio = 'selected';
  bool _toggle = true;
  double _slider = 0.5;
  bool _chip = true;
  int _navigationBarIndex = 0;
  int _navigationRailIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: BirbThemeHarnessKeys.root,
      appBar: AppBar(title: const Text('Design system preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BirbSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Section(title: 'Typography', child: _typography(theme.textTheme)),
            _Section(title: 'Surfaces', child: _surfaces(theme.colorScheme)),
            _Section(
              title: 'Interactive controls',
              child: _interactiveControls(),
            ),
            _Section(title: 'Overlays', child: _overlays()),
            _Section(title: 'Statuses', child: _statuses(theme)),
            _Section(title: 'Navigation', child: _navigation()),
            _Section(title: 'Inputs', child: _inputs()),
          ],
        ),
      ),
    );
  }

  Widget _typography(TextTheme textTheme) {
    final styles = <String, TextStyle?>{
      'displayLarge': textTheme.displayLarge,
      'displayMedium': textTheme.displayMedium,
      'displaySmall': textTheme.displaySmall,
      'headlineLarge': textTheme.headlineLarge,
      'headlineMedium': textTheme.headlineMedium,
      'headlineSmall': textTheme.headlineSmall,
      'titleLarge': textTheme.titleLarge,
      'titleMedium': textTheme.titleMedium,
      'titleSmall': textTheme.titleSmall,
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'labelLarge': textTheme.labelLarge,
      'labelMedium': textTheme.labelMedium,
      'labelSmall': textTheme.labelSmall,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final name in BirbThemeHarnessInventory.typography)
          Text(
            name,
            key: _key(BirbHarnessFamily.typography, name),
            style: styles[name],
          ),
      ],
    );
  }

  Widget _surfaces(ColorScheme colors) {
    final surfaces = <String, Color>{
      'surface': colors.surface,
      'surfaceDim': colors.surfaceDim,
      'surfaceBright': colors.surfaceBright,
      'surfaceContainerLowest': colors.surfaceContainerLowest,
      'surfaceContainerLow': colors.surfaceContainerLow,
      'surfaceContainer': colors.surfaceContainer,
      'surfaceContainerHigh': colors.surfaceContainerHigh,
      'surfaceContainerHighest': colors.surfaceContainerHighest,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry(key: name, value: color) in surfaces.entries)
          ColoredBox(
            key: _key(BirbHarnessFamily.surfaces, name),
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(BirbSpacing.space2),
              child: Text(name),
            ),
          ),
        Card(
          key: _key(BirbHarnessFamily.surfaces, 'card'),
          child: const Padding(
            padding: EdgeInsets.all(BirbSpacing.space3),
            child: Text('Card'),
          ),
        ),
        Divider(key: _key(BirbHarnessFamily.surfaces, 'divider')),
      ],
    );
  }

  Widget _interactiveControls() => Wrap(
    spacing: BirbSpacing.space2,
    runSpacing: BirbSpacing.space2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      FilledButton(
        key: _controlKey('filledButton'),
        onPressed: () {},
        child: const Text('Filled'),
      ),
      ElevatedButton(
        key: _controlKey('elevatedButton'),
        onPressed: () {},
        child: const Text('Elevated'),
      ),
      OutlinedButton(
        key: _controlKey('outlinedButton'),
        onPressed: () {},
        child: const Text('Outlined'),
      ),
      TextButton(
        key: _controlKey('textButton'),
        onPressed: () {},
        child: const Text('Text'),
      ),
      IconButton(
        key: _controlKey('iconButton'),
        onPressed: () {},
        tooltip: 'Favorite',
        icon: const Icon(Icons.favorite),
      ),
      FilledButton(
        key: _controlKey('disabledButton'),
        onPressed: null,
        child: const Text('Disabled'),
      ),
      Checkbox(
        key: _controlKey('checkboxSelected'),
        value: _checkbox,
        onChanged: (value) => setState(() => _checkbox = value!),
      ),
      Checkbox(
        key: _controlKey('checkboxUnselected'),
        value: false,
        onChanged: (_) {},
      ),
      Checkbox(
        key: _controlKey('checkboxError'),
        value: false,
        isError: true,
        onChanged: (_) {},
      ),
      Checkbox(
        key: _controlKey('checkboxDisabled'),
        value: false,
        onChanged: null,
      ),
      RadioGroup<String>(
        groupValue: _radio,
        onChanged: (value) => setState(() => _radio = value!),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(key: _controlKey('radioSelected'), value: 'selected'),
            Radio<String>(
              key: _controlKey('radioUnselected'),
              value: 'unselected',
            ),
            Radio<String>(
              key: _controlKey('radioDisabled'),
              value: 'disabled',
              enabled: false,
            ),
          ],
        ),
      ),
      Switch(
        key: _controlKey('switchSelected'),
        value: _toggle,
        onChanged: (value) => setState(() => _toggle = value),
      ),
      Switch(
        key: _controlKey('switchUnselected'),
        value: false,
        onChanged: (_) {},
      ),
      Switch(key: _controlKey('switchDisabled'), value: false, onChanged: null),
      SizedBox(
        key: _controlKey('sliderEnabled'),
        width: 160,
        child: Slider(
          value: _slider,
          onChanged: (value) => setState(() => _slider = value),
        ),
      ),
      SizedBox(
        key: _controlKey('sliderDisabled'),
        width: 160,
        child: const Slider(value: 0.5, onChanged: null),
      ),
      BirbFilterChip(
        key: _controlKey('chipSelected'),
        label: const Text('Selected'),
        selected: _chip,
        onSelected: (value) => setState(() => _chip = value),
      ),
      BirbFilterChip(
        key: _controlKey('chipUnselected'),
        label: const Text('Unselected'),
        selected: false,
        onSelected: (_) {},
      ),
      BirbFilterChip(
        key: _controlKey('chipDisabled'),
        label: const Text('Disabled'),
        selected: false,
        onSelected: null,
      ),
    ],
  );

  Widget _overlays() => Wrap(
    spacing: BirbSpacing.space2,
    runSpacing: BirbSpacing.space2,
    children: <Widget>[
      FilledButton(
        key: _key(BirbHarnessFamily.overlays, 'dialogTrigger'),
        onPressed: _showDialog,
        child: const Text('Dialog'),
      ),
      PopupMenuButton<String>(
        key: _key(BirbHarnessFamily.overlays, 'menuTrigger'),
        tooltip: 'Menu',
        itemBuilder: (_) => const [
          PopupMenuItem<String>(
            key: BirbThemeHarnessKeys.menuItem,
            value: 'inspect',
            child: Text('Inspect'),
          ),
        ],
      ),
      FilledButton(
        key: _key(BirbHarnessFamily.overlays, 'snackbarTrigger'),
        onPressed: _showSnackbar,
        child: const Text('Snackbar'),
      ),
      Tooltip(
        key: _key(BirbHarnessFamily.overlays, 'tooltip'),
        message: 'Theme tooltip',
        child: const Icon(Icons.info),
      ),
    ],
  );

  Widget _statuses(ThemeData theme) {
    final semantic = theme.extension<BirbSemanticColors>()!;
    final colors = theme.colorScheme;
    final statuses = <String, (Color, Color, IconData)>{
      'success': (semantic.success, semantic.onSuccess, Icons.check),
      'warning': (semantic.warning, semantic.onWarning, Icons.warning),
      'info': (semantic.info, semantic.onInfo, Icons.info),
      'error': (colors.error, colors.onError, Icons.error),
      'selected': (colors.primary, colors.onPrimary, Icons.star),
      'loading': (semantic.info, semantic.onInfo, Icons.sync),
      'disabled': (colors.surface, semantic.disabled, Icons.block),
    };
    return Wrap(
      spacing: BirbSpacing.space2,
      runSpacing: BirbSpacing.space2,
      children: [
        for (final MapEntry(key: name, value: appearance) in statuses.entries)
          Semantics(
            key: _key(BirbHarnessFamily.statuses, name),
            label: '$name status',
            selected: name == 'selected',
            enabled: name != 'disabled',
            child: Material(
              color: appearance.$1,
              child: Padding(
                padding: const EdgeInsets.all(BirbSpacing.space2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(appearance.$3, color: appearance.$2),
                    const SizedBox(width: BirbSpacing.space1),
                    Text(name, style: TextStyle(color: appearance.$2)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _navigation() => Column(
    children: <Widget>[
      NavigationBar(
        key: _key(BirbHarnessFamily.navigation, 'navigationBar'),
        selectedIndex: _navigationBarIndex,
        onDestinationSelected: (value) {
          setState(() => _navigationBarIndex = value);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.group), label: 'People'),
        ],
      ),
      SizedBox(
        height: 160,
        child: NavigationRail(
          key: _key(BirbHarnessFamily.navigation, 'navigationRail'),
          selectedIndex: _navigationRailIndex,
          onDestinationSelected: (value) {
            setState(() => _navigationRailIndex = value);
          },
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.home),
              label: Text('Home'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.group),
              label: Text('People'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _inputs() => Column(
    children: <Widget>[
      BirbTextFormField(
        key: _key(BirbHarnessFamily.inputs, 'enabled'),
        label: 'Enabled input',
        required: true,
      ),
      const SizedBox(height: BirbSpacing.space2),
      BirbTextFormField(
        key: _key(BirbHarnessFamily.inputs, 'error'),
        label: 'Error input',
        errorText: 'Example error',
      ),
      const SizedBox(height: BirbSpacing.space2),
      BirbTextFormField(
        key: _key(BirbHarnessFamily.inputs, 'disabled'),
        label: 'Disabled input',
        enabled: false,
      ),
    ],
  );

  Future<void> _showDialog() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: BirbThemeHarnessKeys.dialog,
      title: const Text('Theme dialog'),
      content: const Text('Reusable dialog content'),
      actions: [
        TextButton(
          key: BirbThemeHarnessKeys.dialogDismiss,
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
      ],
    ),
  );

  void _showSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: BirbThemeHarnessKeys.snackbar,
        content: Text('Theme snackbar'),
      ),
    );
  }

  Key _controlKey(String name) =>
      _key(BirbHarnessFamily.interactiveControls, name);

  Key _key(BirbHarnessFamily family, String name) =>
      BirbThemeHarnessKeys.fixture((family: family, name: name));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BirbSpacing.space6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: BirbSpacing.space2),
        child,
      ],
    ),
  );
}
