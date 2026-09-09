import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stateMatrix = <Set<WidgetState>>[
    {},
    {WidgetState.selected},
    {WidgetState.hovered, WidgetState.selected},
    {WidgetState.focused, WidgetState.selected},
    {WidgetState.pressed, WidgetState.focused, WidgetState.selected},
    {
      WidgetState.disabled,
      WidgetState.pressed,
      WidgetState.focused,
      WidgetState.selected,
    },
  ];

  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    group('${theme.brightness.name} selection themes', () {
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;
      final expectedFill = <Color>[
        colors.surface,
        colors.primary,
        colors.surfaceContainerHigh,
        colors.primary,
        colors.primaryContainer,
        colors.surface,
      ];
      final expectedForeground = <Color>[
        colors.onSurface,
        colors.onPrimary,
        colors.onSurface,
        colors.onPrimary,
        colors.onPrimaryContainer,
        semantics.disabled,
      ];
      final expectedSide = <BorderSide>[
        BorderSide(color: colors.outline, width: BirbBorders.thin),
        BorderSide(color: colors.primary, width: BirbBorders.thin),
        BorderSide(color: colors.primary, width: BirbBorders.thin),
        BorderSide(color: semantics.focus, width: BirbBorders.strong),
        BorderSide(color: semantics.focus, width: BirbBorders.strong),
        BorderSide(color: semantics.disabled, width: BirbBorders.thin),
      ];
      final expectedOverlay = <Color>[
        WidgetStateColor.transparent,
        WidgetStateColor.transparent,
        colors.surfaceContainerHigh,
        semantics.focus,
        colors.primaryContainer,
        WidgetStateColor.transparent,
      ];

      test('resolves checkbox matrix and error precedence', () {
        final checkbox = theme.checkboxTheme;
        expect(checkbox.materialTapTargetSize, MaterialTapTargetSize.padded);
        expect(checkbox.visualDensity, VisualDensity.standard);
        final shape = checkbox.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BirbRadii.none);

        for (var index = 0; index < stateMatrix.length; index++) {
          final states = stateMatrix[index];
          expect(checkbox.fillColor?.resolve(states), expectedFill[index]);
          expect(
            checkbox.checkColor?.resolve(states),
            expectedForeground[index],
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(checkbox.side, states),
            expectedSide[index],
          );
          expect(
            checkbox.overlayColor?.resolve(states),
            expectedOverlay[index],
          );
        }

        final errorCases = <(Set<WidgetState>, double)>[
          ({WidgetState.error}, BirbBorders.thin),
          ({WidgetState.error, WidgetState.selected}, BirbBorders.thin),
          ({WidgetState.error, WidgetState.focused}, BirbBorders.strong),
          ({WidgetState.error, WidgetState.pressed}, BirbBorders.thin),
        ];
        for (final (states, width) in errorCases) {
          expect(checkbox.fillColor?.resolve(states), colors.surface);
          expect(
            checkbox.checkColor?.resolve(states),
            semantics.errorIndicator,
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(checkbox.side, states),
            BorderSide(color: semantics.errorIndicator, width: width),
          );
        }
        final disabledError = {WidgetState.disabled, WidgetState.error};
        expect(checkbox.fillColor?.resolve(disabledError), colors.surface);
        expect(checkbox.checkColor?.resolve(disabledError), semantics.disabled);
        expect(
          WidgetStateProperty.resolveAs<BorderSide?>(
            checkbox.side,
            disabledError,
          ),
          BorderSide(color: semantics.disabled, width: BirbBorders.thin),
        );
      });

      test('resolves radio matrix', () {
        final radio = theme.radioTheme;
        expect(radio.materialTapTargetSize, MaterialTapTargetSize.padded);
        expect(radio.visualDensity, VisualDensity.standard);
        final expectedBackground = <Color>[
          colors.surface,
          colors.surface,
          colors.surfaceContainerHigh,
          colors.surface,
          colors.primaryContainer,
          colors.surface,
        ];
        final expectedRadioFill = <Color>[
          colors.outline,
          colors.primary,
          colors.onSurface,
          colors.primary,
          colors.onPrimaryContainer,
          semantics.disabled,
        ];
        for (var index = 0; index < stateMatrix.length; index++) {
          final states = stateMatrix[index];
          expect(
            radio.backgroundColor?.resolve(states),
            expectedBackground[index],
          );
          expect(radio.fillColor?.resolve(states), expectedRadioFill[index]);
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(radio.side, states),
            expectedSide[index],
          );
          expect(radio.overlayColor?.resolve(states), expectedOverlay[index]);
        }
      });

      test('resolves switch matrix', () {
        final toggle = theme.switchTheme;
        expect(toggle.materialTapTargetSize, MaterialTapTargetSize.padded);
        final expectedOutline = <Color>[
          colors.outline,
          colors.primary,
          colors.primary,
          semantics.focus,
          semantics.focus,
          semantics.disabled,
        ];
        final expectedOutlineWidth = <double>[
          BirbBorders.thin,
          BirbBorders.thin,
          BirbBorders.thin,
          BirbBorders.strong,
          BirbBorders.strong,
          BirbBorders.thin,
        ];
        for (var index = 0; index < stateMatrix.length; index++) {
          final states = stateMatrix[index];
          expect(toggle.trackColor?.resolve(states), expectedFill[index]);
          expect(toggle.thumbColor?.resolve(states), expectedForeground[index]);
          expect(toggle.overlayColor?.resolve(states), expectedOverlay[index]);
          expect(
            toggle.trackOutlineColor?.resolve(states),
            expectedOutline[index],
          );
          expect(
            toggle.trackOutlineWidth?.resolve(states),
            expectedOutlineWidth[index],
          );
        }
      });

      test('defines the complete slider recipe', () {
        final slider = theme.sliderTheme;
        expect(slider.activeTickMarkColor, colors.onPrimary);
        expect(slider.activeTrackColor, colors.primary);
        expect(slider.disabledActiveTickMarkColor, semantics.disabled);
        expect(slider.disabledActiveTrackColor, semantics.disabled);
        expect(slider.disabledInactiveTickMarkColor, semantics.disabled);
        expect(slider.disabledInactiveTrackColor, semantics.disabled);
        expect(slider.disabledSecondaryActiveTrackColor, semantics.disabled);
        expect(slider.disabledThumbColor, semantics.disabled);
        expect(slider.inactiveTickMarkColor, colors.onSurface);
        expect(slider.inactiveTrackColor, colors.outline);
        expect(slider.overlappingShapeStrokeColor, colors.onPrimary);
        expect(slider.overlayColor, semantics.focus);
        expect(
          (slider.overlayShape! as RoundSliderOverlayShape).overlayRadius,
          BirbSizes.minimumInteractiveDimension / 2,
        );
        expect(slider.secondaryActiveTrackColor, colors.primary);
        expect(slider.thumbColor, colors.primary);
        expect(slider.trackHeight, BirbBorders.strong);
        expect(slider.valueIndicatorColor, colors.primary);
        expect(slider.valueIndicatorStrokeColor, colors.primary);
        expect(slider.valueIndicatorTextStyle?.color, colors.onPrimary);
      });

      test('resolves chip matrix and geometry', () {
        final chip = theme.chipTheme;
        final labelColor = chip.labelStyle!.color! as WidgetStateColor;
        for (var index = 0; index < stateMatrix.length; index++) {
          final states = stateMatrix[index];
          expect(chip.color?.resolve(states), expectedFill[index]);
          expect(labelColor.resolve(states), expectedForeground[index]);
          expect(
            WidgetStateProperty.resolveAs<Color?>(chip.deleteIconColor, states),
            expectedForeground[index],
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(chip.side, states),
            expectedSide[index],
          );
          expect(
            WidgetStateProperty.resolveAs<Color?>(chip.checkmarkColor, states),
            index == stateMatrix.length - 1
                ? semantics.disabled
                : colors.onPrimary,
          );
        }
        expect(chip.disabledColor, colors.surface);
        expect(chip.elevation, 0);
        expect(chip.pressElevation, 0);
        expect(chip.selectedColor, colors.primary);
        expect(chip.selectedShadowColor, colors.shadow);
        expect(chip.shadowColor, colors.shadow);
        expect(chip.showCheckmark, isTrue);
        expect(chip.surfaceTintColor, WidgetStateColor.transparent);
        final shape = chip.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BirbRadii.pixel);
      });
    });
  }

  testWidgets('selection controls retain semantics and keyboard operation', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    final checkboxFocus = FocusNode(debugLabel: 'consent checkbox');
    final sliderFocus = FocusNode(debugLabel: 'volume slider');
    addTearDown(checkboxFocus.dispose);
    addTearDown(sliderFocus.dispose);
    var checked = true;
    var chipSelected = true;
    var sliderValue = 0.25;

    await tester.pumpWidget(
      MaterialApp(
        theme: BirbTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Consent',
                  child: Checkbox(
                    focusNode: checkboxFocus,
                    value: checked,
                    onChanged: (value) => setState(() => checked = value!),
                  ),
                ),
                Slider(
                  focusNode: sliderFocus,
                  value: sliderValue,
                  onChanged: (value) => setState(() => sliderValue = value),
                  semanticFormatterCallback: (value) => 'Volume $value',
                ),
                ChoiceChip(
                  label: const Text('Mode'),
                  selected: chipSelected,
                  onSelected: (value) => setState(() => chipSelected = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    checkboxFocus.requestFocus();
    await tester.pump();
    expect(checkboxFocus.hasPrimaryFocus, isTrue);
    expect(
      tester.getSemantics(find.byType(Checkbox)),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    final checkboxSize = tester.getSize(find.byType(Checkbox));
    expect(
      checkboxSize.width,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );
    expect(
      checkboxSize.height,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );

    sliderFocus.requestFocus();
    await tester.pump();
    expect(sliderFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(sliderValue, greaterThan(0.25));
    expect(
      tester.getSemantics(find.byType(ChoiceChip)),
      isSemantics(hasSelectedState: true, isSelected: true),
    );
    final chipSize = tester.getSize(find.byType(ChoiceChip));
    expect(
      chipSize.height,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );
    semanticsHandle.dispose();
  });
}
