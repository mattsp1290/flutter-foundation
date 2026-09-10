import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    testWidgets('${theme.brightness.name} dialog renders Birb theme', (
      tester,
    ) async {
      await _pumpThemedScaffold(
        tester,
        theme,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Dialog title'),
                content: Text('Dialog content'),
              ),
            ),
            child: const Text('Open dialog'),
          ),
        ),
      );
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final dialogMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Dialog content'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(dialogMaterial.color, theme.colorScheme.surfaceContainerHigh);
      expect(dialogMaterial.elevation, 0);
      expect(dialogMaterial.surfaceTintColor, WidgetStateColor.transparent);
      _expectSquareOutline(dialogMaterial.shape, theme.colorScheme.outline);
      expect(
        _effectiveTextStyle(tester, find.text('Dialog content')).color,
        theme.textTheme.bodyMedium?.color,
      );
      expect(
        tester
            .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier))
            .color
            .value,
        theme.colorScheme.scrim,
      );
    });

    testWidgets('${theme.brightness.name} menu renders Birb theme', (
      tester,
    ) async {
      await _pumpThemedScaffold(
        tester,
        theme,
        MenuAnchor(
          menuChildren: const [MenuItemButton(child: Text('Menu item'))],
          builder: (context, controller, child) => FilledButton(
            onPressed: controller.open,
            child: const Text('Open menu'),
          ),
        ),
      );
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Menu item'), findsOneWidget);
      final menuMaterial = tester.widget<Material>(
        find.ancestor(
          of: find.text('Menu item'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Material &&
                widget.color == theme.colorScheme.surfaceContainerHigh,
          ),
        ),
      );
      expect(menuMaterial.color, theme.colorScheme.surfaceContainerHigh);
      expect(menuMaterial.elevation, 0);
      expect(menuMaterial.surfaceTintColor, WidgetStateColor.transparent);
      _expectSquareOutline(menuMaterial.shape, theme.colorScheme.outline);
    });

    testWidgets('${theme.brightness.name} snackbar renders Birb theme', (
      tester,
    ) async {
      await _pumpThemedScaffold(
        tester,
        theme,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Snack message'))),
            child: const Text('Show snack'),
          ),
        ),
      );
      await tester.tap(find.text('Show snack'));
      await tester.pump();
      expect(find.text('Snack message'), findsOneWidget);
      final snackMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(snackMaterial.color, theme.colorScheme.inverseSurface);
      expect(snackMaterial.elevation, 0);
      expect(
        _effectiveTextStyle(tester, find.text('Snack message')).color,
        theme.colorScheme.onInverseSurface,
      );
    });

    testWidgets('${theme.brightness.name} tooltip renders Birb theme', (
      tester,
    ) async {
      final tooltipKey = GlobalKey<TooltipState>();
      await _pumpThemedScaffold(
        tester,
        theme,
        Tooltip(
          key: tooltipKey,
          message: 'Tooltip message',
          triggerMode: TooltipTriggerMode.manual,
          child: const Icon(Icons.info),
        ),
      );
      tooltipKey.currentState!.ensureTooltipVisible();
      await tester.pump();
      expect(find.text('Tooltip message'), findsOneWidget);
      final tooltipDecoration = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Tooltip message'),
              matching: find.byWidgetPredicate(
                (widget) => widget is DecoratedBox,
              ),
            )
            .first,
      );
      final tooltipBox = tooltipDecoration.decoration as BoxDecoration;
      expect(tooltipBox.color, theme.colorScheme.inverseSurface);
      expect(tooltipBox.borderRadius, BirbRadii.none);
      expect(
        _effectiveTextStyle(tester, find.text('Tooltip message')).color,
        theme.colorScheme.onInverseSurface,
      );
    });

    testWidgets('${theme.brightness.name} navigation rail paints focus', (
      tester,
    ) async {
      var selectedIndex = 0;
      const railKey = ValueKey('navigation-rail');
      const homeKey = ValueKey('navigation-home');
      const partyKey = ValueKey('navigation-party');
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    key: railKey,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() => selectedIndex = value);
                    },
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home, key: homeKey),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.groups, key: partyKey),
                        label: Text('Party'),
                      ),
                    ],
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );

      final rail = find.byKey(railKey);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      for (var tabs = 0; tabs < 20 && !focusIsInside(rail); tabs += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusIsInside(rail), isTrue);
      final homeInk = find.ancestor(
        of: find.byKey(homeKey),
        matching: find.byWidgetPredicate((widget) => widget is InkResponse),
      );
      expect(Theme.of(tester.element(homeInk)).focusColor, theme.focusColor);
      await tester.pump(BirbDurations.standard);
      expect(
        tester.renderObject<RenderBox>(rail),
        paints
          ..rect(color: theme.colorScheme.primaryContainer)
          ..rect(color: theme.focusColor),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final partyInk = find.ancestor(
        of: find.byKey(partyKey),
        matching: find.byWidgetPredicate((widget) => widget is InkResponse),
      );
      expect(focusIsInside(partyInk), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selectedIndex, 1);
    });
  }
}

Future<void> _pumpThemedScaffold(
  WidgetTester tester,
  ThemeData theme,
  Widget body,
) => tester.pumpWidget(
  MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: body)),
  ),
);

void _expectSquareOutline(ShapeBorder? shape, Color color) {
  final rectangle = shape! as RoundedRectangleBorder;
  expect(rectangle.borderRadius, BirbRadii.none);
  expect(rectangle.side, BorderSide(color: color, width: BirbBorders.thin));
}

TextStyle _effectiveTextStyle(WidgetTester tester, Finder text) {
  return tester
      .widget<DefaultTextStyle>(
        find.ancestor(of: text, matching: find.byType(DefaultTextStyle)).first,
      )
      .style;
}
