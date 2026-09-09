import 'dart:ui' show SemanticsAction;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    group('${theme.brightness.name} selection themes', () {
      final colors = theme.colorScheme;
      final semantics = theme.extension<BirbSemanticColors>()!;
      final cases = _stateCases(colors, semantics);

      test('resolves checkbox matrix and error precedence', () {
        final checkbox = theme.checkboxTheme;
        expect(checkbox.materialTapTargetSize, MaterialTapTargetSize.padded);
        expect(checkbox.visualDensity, VisualDensity.standard);
        final shape = checkbox.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BirbRadii.none);

        for (final stateCase in cases) {
          expect(
            checkbox.fillColor?.resolve(stateCase.states),
            stateCase.fill,
            reason: stateCase.name,
          );
          expect(
            checkbox.checkColor?.resolve(stateCase.states),
            stateCase.foreground,
            reason: stateCase.name,
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(
              checkbox.side,
              stateCase.states,
            ),
            stateCase.side,
            reason: stateCase.name,
          );
          expect(
            checkbox.overlayColor?.resolve(stateCase.states),
            stateCase.overlay,
            reason: stateCase.name,
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
        for (final stateCase in cases) {
          expect(
            radio.backgroundColor?.resolve(stateCase.states),
            stateCase.radioBackground,
            reason: stateCase.name,
          );
          expect(
            radio.fillColor?.resolve(stateCase.states),
            stateCase.radioFill,
            reason: stateCase.name,
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(
              radio.side,
              stateCase.states,
            ),
            stateCase.side,
            reason: stateCase.name,
          );
          expect(
            radio.overlayColor?.resolve(stateCase.states),
            stateCase.overlay,
            reason: stateCase.name,
          );
        }
      });

      test('resolves switch matrix', () {
        final toggle = theme.switchTheme;
        expect(toggle.materialTapTargetSize, MaterialTapTargetSize.padded);
        for (final stateCase in cases) {
          expect(
            toggle.trackColor?.resolve(stateCase.states),
            stateCase.fill,
            reason: stateCase.name,
          );
          expect(
            toggle.thumbColor?.resolve(stateCase.states),
            stateCase.foreground,
            reason: stateCase.name,
          );
          expect(
            toggle.overlayColor?.resolve(stateCase.states),
            stateCase.overlay,
            reason: stateCase.name,
          );
          expect(
            toggle.trackOutlineColor?.resolve(stateCase.states),
            stateCase.switchOutline,
            reason: stateCase.name,
          );
          expect(
            toggle.trackOutlineWidth?.resolve(stateCase.states),
            stateCase.switchOutlineWidth,
            reason: stateCase.name,
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
        for (final stateCase in cases) {
          expect(
            chip.color?.resolve(stateCase.states),
            stateCase.fill,
            reason: stateCase.name,
          );
          expect(
            labelColor.resolve(stateCase.states),
            stateCase.foreground,
            reason: stateCase.name,
          );
          expect(
            WidgetStateProperty.resolveAs<Color?>(
              chip.deleteIconColor,
              stateCase.states,
            ),
            stateCase.foreground,
            reason: stateCase.name,
          );
          expect(
            WidgetStateProperty.resolveAs<BorderSide?>(
              chip.side,
              stateCase.states,
            ),
            stateCase.side,
            reason: stateCase.name,
          );
          expect(
            WidgetStateProperty.resolveAs<Color?>(
              chip.checkmarkColor,
              stateCase.states,
            ),
            colors.onPrimary,
            reason: stateCase.name,
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
    final chipFocus = FocusNode(debugLabel: 'mode chip');
    final sliderFocus = FocusNode(debugLabel: 'volume slider');
    addTearDown(checkboxFocus.dispose);
    addTearDown(chipFocus.dispose);
    addTearDown(sliderFocus.dispose);
    var checked = true;
    var chipSelected = true;
    var sliderValue = 0.25;
    var switchValue = false;

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
                BirbFilterChip(
                  focusNode: chipFocus,
                  label: const Text('Mode'),
                  selected: chipSelected,
                  onSelected: (value) => setState(() => chipSelected = value),
                ),
                const Radio<bool>(value: true),
                Switch(
                  value: switchValue,
                  onChanged: (value) => setState(() => switchValue = value),
                ),
                const BirbFilterChip(
                  label: Text('Disabled mode'),
                  selected: true,
                  onSelected: null,
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
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(checked, isFalse);

    sliderFocus.requestFocus();
    await tester.pump();
    expect(sliderFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(sliderValue, greaterThan(0.25));
    final activeChip = find.widgetWithText(FilterChip, 'Mode');
    expect(
      tester.getSemantics(activeChip),
      isSemantics(hasSelectedState: true, isSelected: true),
    );
    final chipSize = tester.getSize(activeChip);
    expect(
      chipSize.height,
      greaterThanOrEqualTo(BirbSizes.minimumInteractiveDimension),
    );
    chipFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(chipSelected, isFalse);
    expect(find.byType(Radio<bool>), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(
      tester
          .getSemantics(find.widgetWithText(FilterChip, 'Disabled mode'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semanticsHandle.dispose();
  });

  for (final theme in <ThemeData>[BirbTheme.light, BirbTheme.dark]) {
    testWidgets(
      '${theme.brightness.name} selected chip paints an enabled and disabled checkmark',
      (tester) async {
        for (final enabled in <bool>[true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Material(
                child: Center(
                  child: BirbFilterChip(
                    label: const Text('Mode'),
                    selected: true,
                    onSelected: enabled ? (_) {} : null,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final paint = tester.firstRenderObject<RenderBox>(
            find.descendant(
              of: find.byType(FilterChip),
              matching: find.byType(CustomPaint),
            ),
          );
          expect(
            paint,
            paints..path(
              color: enabled
                  ? theme.colorScheme.onPrimary
                  : theme.disabledColor,
            ),
          );
        }
      },
    );
  }
}

List<_SelectionThemeCase> _stateCases(
  ColorScheme colors,
  BirbSemanticColors semantics,
) => <_SelectionThemeCase>[
  _SelectionThemeCase(
    name: 'enabled',
    states: const {},
    fill: colors.surface,
    foreground: colors.onSurface,
    side: BorderSide(color: colors.outline, width: BirbBorders.thin),
    overlay: WidgetStateColor.transparent,
    radioBackground: colors.surface,
    radioFill: colors.outline,
    switchOutline: colors.outline,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'selected',
    states: const {WidgetState.selected},
    fill: colors.primary,
    foreground: colors.onPrimary,
    side: BorderSide(color: colors.primary, width: BirbBorders.thin),
    overlay: WidgetStateColor.transparent,
    radioBackground: colors.surface,
    radioFill: colors.primary,
    switchOutline: colors.primary,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'hovered',
    states: const {WidgetState.hovered},
    fill: colors.surfaceContainerHigh,
    foreground: colors.onSurface,
    side: BorderSide(color: colors.outline, width: BirbBorders.thin),
    overlay: colors.surfaceContainerHigh,
    radioBackground: colors.surfaceContainerHigh,
    radioFill: colors.onSurface,
    switchOutline: colors.outline,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'hovered selected',
    states: const {WidgetState.hovered, WidgetState.selected},
    fill: colors.surfaceContainerHigh,
    foreground: colors.onSurface,
    side: BorderSide(color: colors.primary, width: BirbBorders.thin),
    overlay: colors.surfaceContainerHigh,
    radioBackground: colors.surfaceContainerHigh,
    radioFill: colors.onSurface,
    switchOutline: colors.primary,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'focused',
    states: const {WidgetState.focused},
    fill: colors.surface,
    foreground: colors.onSurface,
    side: BorderSide(color: semantics.focus, width: BirbBorders.strong),
    overlay: semantics.focus,
    radioBackground: colors.surface,
    radioFill: colors.outline,
    switchOutline: semantics.focus,
    switchOutlineWidth: BirbBorders.strong,
  ),
  _SelectionThemeCase(
    name: 'focused selected',
    states: const {WidgetState.focused, WidgetState.selected},
    fill: colors.primary,
    foreground: colors.onPrimary,
    side: BorderSide(color: semantics.focus, width: BirbBorders.strong),
    overlay: semantics.focus,
    radioBackground: colors.surface,
    radioFill: colors.primary,
    switchOutline: semantics.focus,
    switchOutlineWidth: BirbBorders.strong,
  ),
  _SelectionThemeCase(
    name: 'pressed',
    states: const {WidgetState.pressed},
    fill: colors.primaryContainer,
    foreground: colors.onPrimaryContainer,
    side: BorderSide(color: colors.outline, width: BirbBorders.thin),
    overlay: colors.primaryContainer,
    radioBackground: colors.primaryContainer,
    radioFill: colors.onPrimaryContainer,
    switchOutline: colors.onPrimaryContainer,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'pressed selected',
    states: const {WidgetState.pressed, WidgetState.selected},
    fill: colors.primaryContainer,
    foreground: colors.onPrimaryContainer,
    side: BorderSide(color: colors.primary, width: BirbBorders.thin),
    overlay: colors.primaryContainer,
    radioBackground: colors.primaryContainer,
    radioFill: colors.onPrimaryContainer,
    switchOutline: colors.onPrimaryContainer,
    switchOutlineWidth: BirbBorders.thin,
  ),
  _SelectionThemeCase(
    name: 'pressed focused selected',
    states: const {
      WidgetState.pressed,
      WidgetState.focused,
      WidgetState.selected,
    },
    fill: colors.primaryContainer,
    foreground: colors.onPrimaryContainer,
    side: BorderSide(color: semantics.focus, width: BirbBorders.strong),
    overlay: colors.primaryContainer,
    radioBackground: colors.primaryContainer,
    radioFill: colors.onPrimaryContainer,
    switchOutline: semantics.focus,
    switchOutlineWidth: BirbBorders.strong,
  ),
  _SelectionThemeCase(
    name: 'disabled error focused selected',
    states: const {
      WidgetState.disabled,
      WidgetState.error,
      WidgetState.focused,
      WidgetState.selected,
    },
    fill: colors.surface,
    foreground: semantics.disabled,
    side: BorderSide(color: semantics.disabled, width: BirbBorders.thin),
    overlay: WidgetStateColor.transparent,
    radioBackground: colors.surface,
    radioFill: semantics.disabled,
    switchOutline: semantics.disabled,
    switchOutlineWidth: BirbBorders.thin,
  ),
];

final class _SelectionThemeCase {
  const _SelectionThemeCase({
    required this.name,
    required this.states,
    required this.fill,
    required this.foreground,
    required this.side,
    required this.overlay,
    required this.radioBackground,
    required this.radioFill,
    required this.switchOutline,
    required this.switchOutlineWidth,
  });

  final String name;
  final Set<WidgetState> states;
  final Color fill;
  final Color foreground;
  final BorderSide side;
  final Color overlay;
  final Color radioBackground;
  final Color radioFill;
  final Color switchOutline;
  final double switchOutlineWidth;
}
