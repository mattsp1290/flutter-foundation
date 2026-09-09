import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    testWidgets('${theme.brightness.name} route overlays inherit Birb themes', (
      tester,
    ) async {
      final tooltipKey = GlobalKey<TooltipState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Wrap(
                children: [
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text('Dialog title'),
                        content: Text('Dialog content'),
                      ),
                    ),
                    child: const Text('Open dialog'),
                  ),
                  PopupMenuButton<void>(
                    itemBuilder: (_) => const [
                      PopupMenuItem<void>(child: Text('Menu item')),
                    ],
                    child: const Text('Open menu'),
                  ),
                  FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Snack message')),
                    ),
                    child: const Text('Show snack'),
                  ),
                  Tooltip(
                    key: tooltipKey,
                    message: 'Tooltip message',
                    triggerMode: TooltipTriggerMode.manual,
                    child: const Icon(Icons.info),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Dialog content'))).dialogTheme,
        theme.dialogTheme,
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Menu item'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Menu item'))).menuTheme,
        theme.menuTheme,
      );
      await tester.tap(find.text('Menu item'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show snack'));
      await tester.pump();
      expect(find.text('Snack message'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Snack message'))).snackBarTheme,
        theme.snackBarTheme,
      );

      tooltipKey.currentState!.ensureTooltipVisible();
      await tester.pump();
      expect(find.text('Tooltip message'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Tooltip message'))).tooltipTheme,
        theme.tooltipTheme,
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
      for (var tabs = 0; tabs < 20 && !_focusIsInside(rail); tabs += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_focusIsInside(rail), isTrue);
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
      expect(_focusIsInside(partyInk), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selectedIndex, 1);
    });
  }
}

bool _focusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return false;
  if (context == target) return true;
  var inside = false;
  context.visitAncestorElements((element) {
    inside = element == target;
    return !inside;
  });
  return inside;
}
