import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_test_fixtures.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} badges pair an icon with text', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? BirbTheme.light
          : BirbTheme.dark;
      for (final status in BirbReviewStatus.values) {
        await tester.pumpWidget(
          themedHost(
            BirbReviewStatusBadge(status: status),
            brightness: brightness,
          ),
        );

        final expectedText = BirbReviewStyle.statusLabel(status);
        expect(find.text(expectedText), findsOneWidget);

        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(BirbReviewStatusBadge),
            matching: find.byType(Icon),
          ),
        );
        final roles = BirbReviewStyle.statusRoles(theme, status);
        expect(icon.icon, BirbReviewStyle.statusIcon(status));
        expect(icon.color, roles.foreground);

        final box = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(BirbReviewStatusBadge),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(box.color, roles.background);

        final text = tester.widget<Text>(find.text(expectedText));
        expect(text.style?.color, roles.foreground);
      }
    });
  }

  testWidgets('the label is overridable and reaches semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themedHost(
        const BirbReviewStatusBadge(
          status: BirbReviewStatus.approved,
          label: 'Genehmigt',
        ),
      ),
    );

    expect(find.text('Genehmigt'), findsOneWidget);
    expect(find.text('Approved'), findsNothing);
    expect(tester.getSemantics(find.bySemanticsLabel('Genehmigt')), isNotNull);
    handle.dispose();
  });

  testWidgets('a long label wraps at 320 logical pixels and 200 percent', (
    tester,
  ) async {
    useViewport(tester, const Size(320, 600));
    await tester.pumpWidget(
      themedHost(
        const BirbReviewStatusBadge(
          status: BirbReviewStatus.changesRequested,
          label:
              'Changes requested by a reviewer with a very long name '
              'that must wrap instead of clipping',
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(BirbReviewStatusBadge));
    expect(size.width, lessThanOrEqualTo(320));
  });
}
