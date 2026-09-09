import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../theme/theme_test_support.dart';
import 'birbparty_foundation_oracle.dart';

void main() {
  test('foundation matches Birbparty $birbpartySourceCommit', () {
    for (final item in <(ThemeData, Map<String, String>, Map<String, String>)>[
      (BirbTheme.light, sourceLightScheme, sourceLightSemantics),
      (BirbTheme.dark, sourceDarkScheme, sourceDarkSemantics),
    ]) {
      expect(
        schemeColors(item.$1.colorScheme)
            .map((name, color) => MapEntry(name, color.toARGB32())),
        item.$2.map(
          (name, paletteName) => MapEntry(name, sourcePalette[paletteName]),
        ),
      );
      expect(
        semanticColors(item.$1.extension<BirbSemanticColors>()!)
            .map((name, color) => MapEntry(name, color.toARGB32())),
        item.$3.map(
          (name, paletteName) => MapEntry(name, sourcePalette[paletteName]),
        ),
      );
      expect(item.$1.scaffoldBackgroundColor, item.$1.colorScheme.surface);
      expect(item.$1.applyElevationOverlayColor, isFalse);
      final semantics = item.$1.extension<BirbSemanticColors>()!;
      expect(item.$1.disabledColor, semantics.disabled);
      expect(item.$1.focusColor, semantics.focus);
      expect(item.$1.hoverColor, item.$1.colorScheme.surfaceContainerHigh);
      expect(item.$1.highlightColor, item.$1.colorScheme.primaryContainer);
      expect(item.$1.splashColor, item.$1.colorScheme.primaryContainer);
      expect(
        textStyles(item.$1.textTheme).map(
          (name, style) => MapEntry(name, (
            style!.fontSize!,
            style.fontWeight!.value,
            style.height!,
          )),
        ),
        sourceTypography,
      );
    }

    expect(<double>[
      BirbSpacing.space1,
      BirbSpacing.space2,
      BirbSpacing.space3,
      BirbSpacing.space4,
      BirbSpacing.space6,
      BirbSpacing.space8,
      BirbSpacing.space12,
    ], sourceSpacing);
    expect(<double>[BirbBorders.thin, BirbBorders.strong], sourceBorders);
    expect(<double>[
      BirbRadii.none.topLeft.x,
      BirbRadii.pixel.topLeft.x,
    ], sourceRadii);
    expect(
      BirbSizes.minimumInteractiveDimension,
      sourceMinimumInteractiveDimension,
    );
    expect(<int>[
      BirbDurations.instant.inMilliseconds,
      BirbDurations.fast.inMilliseconds,
      BirbDurations.standard.inMilliseconds,
    ], sourceDurationsMs);
  });

  testWidgets('input colors match the source snapshot', (tester) async {
    for (final item in <(ThemeData, String, String)>[
      (BirbTheme.light, 'lightEnabled', 'lightDisabled'),
      (BirbTheme.dark, 'darkEnabled', 'darkDisabled'),
    ]) {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: item.$1,
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final style = BirbTheme.inputTextStyle(context);
      expect(
        style.resolve(<WidgetState>{}).color?.toARGB32(),
        sourcePalette[sourceInputColors[item.$2]],
      );
      expect(
        style.resolve(<WidgetState>{WidgetState.disabled}).color?.toARGB32(),
        sourcePalette[sourceInputColors[item.$3]],
      );
    }
  });
}
