import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../theme/theme_test_support.dart';
import 'birbparty_foundation_oracle.dart';

void main() {
  test('foundation matches Birbparty $birbpartySourceCommit', () {
    for (final item in <_ThemeCase>[
      (
        theme: BirbTheme.light,
        scheme: sourceLightScheme,
        semantics: sourceLightSemantics,
        brightness: sourceLightBaseTheme.brightness,
        selectionColor: sourceLightBaseTheme.selectionColor,
        textColor: sourceLightBaseTheme.textColor,
      ),
      (
        theme: BirbTheme.dark,
        scheme: sourceDarkScheme,
        semantics: sourceDarkSemantics,
        brightness: sourceDarkBaseTheme.brightness,
        selectionColor: sourceDarkBaseTheme.selectionColor,
        textColor: sourceDarkBaseTheme.textColor,
      ),
    ]) {
      expect(
        schemeColors(item.theme.colorScheme)
            .map((name, color) => MapEntry(name, color.toARGB32())),
        item.scheme.map(
          (name, paletteName) => MapEntry(name, sourcePalette[paletteName]),
        ),
      );
      expect(
        semanticColors(item.theme.extension<BirbSemanticColors>()!)
            .map((name, color) => MapEntry(name, color.toARGB32())),
        item.semantics.map(
          (name, paletteName) => MapEntry(name, sourcePalette[paletteName]),
        ),
      );
      expect(
        item.theme.scaffoldBackgroundColor,
        item.theme.colorScheme.surface,
      );
      expect(item.theme.useMaterial3, sourceBaseTheme.useMaterial3);
      expect(item.theme.brightness.name, item.brightness);
      expect(item.theme.colorScheme.brightness.name, item.brightness);
      expect(
        item.theme.applyElevationOverlayColor,
        sourceBaseTheme.applyElevationOverlayColor,
      );
      expect(
        item.theme.materialTapTargetSize.name,
        sourceBaseTheme.materialTapTargetSize,
      );
      expect(
        item.theme.visualDensity.horizontal,
        sourceBaseTheme.visualDensityHorizontal,
      );
      expect(
        item.theme.visualDensity.vertical,
        sourceBaseTheme.visualDensityVertical,
      );
      final cardShape = item.theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(
        (cardShape.borderRadius as BorderRadius).topLeft.x,
        sourceBaseTheme.cardRadius,
      );
      final semantics = item.theme.extension<BirbSemanticColors>()!;
      expect(item.theme.disabledColor, semantics.disabled);
      expect(item.theme.focusColor, semantics.focus);
      expect(
        item.theme.hoverColor,
        item.theme.colorScheme.surfaceContainerHigh,
      );
      expect(
        item.theme.highlightColor,
        item.theme.colorScheme.primaryContainer,
      );
      expect(item.theme.splashColor, item.theme.colorScheme.primaryContainer);
      expect(
        item.theme.textSelectionTheme.cursorColor?.toARGB32(),
        sourcePalette[item.scheme['primary']],
      );
      expect(
        item.theme.textSelectionTheme.selectionColor?.toARGB32(),
        sourcePalette[item.selectionColor],
      );
      expect(
        item.theme.textSelectionTheme.selectionHandleColor?.toARGB32(),
        sourcePalette[item.scheme['primary']],
      );
      expect(
        textStyles(item.theme.textTheme).map(
          (name, style) => MapEntry(name, (
            style!.fontSize!,
            style.fontWeight!.value,
            style.height!,
          )),
        ),
        sourceTypography,
      );
      for (final style in textStyles(item.theme.textTheme).values) {
        expect(style!.color?.toARGB32(), sourcePalette[item.textColor]);
      }
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

typedef _ThemeCase = ({
  ThemeData theme,
  Map<String, String> scheme,
  Map<String, String> semantics,
  String brightness,
  String selectionColor,
  String textColor,
});
