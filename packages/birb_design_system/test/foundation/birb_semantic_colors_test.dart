import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lightValues = <Color>[
    Color(0xFF38B764),
    Color(0xFF1A1C2C),
    Color(0xFFEF7D57),
    Color(0xFF1A1C2C),
    Color(0xFF3B5DC9),
    Color(0xFFF4F4F4),
    Color(0xFF29366F),
    Color(0xFF566C86),
    Color(0xFF5D275D),
  ];
  const darkValues = <Color>[
    Color(0xFFA7F070),
    Color(0xFF1A1C2C),
    Color(0xFFFFCD75),
    Color(0xFF1A1C2C),
    Color(0xFF41A6F6),
    Color(0xFF1A1C2C),
    Color(0xFF73EFF7),
    Color(0xFF94B0C2),
    Color(0xFFFFCD75),
  ];

  test('maps every light and dark semantic role', () {
    expect(_values(BirbSemanticColors.light), lightValues);
    expect(_values(BirbSemanticColors.dark), darkValues);
  });

  test('copyWith preserves omitted roles and replaces every supplied role', () {
    expect(_values(BirbSemanticColors.light.copyWith()), lightValues);

    const replacements = <Color>[
      Color(0xFF000001),
      Color(0xFF000002),
      Color(0xFF000003),
      Color(0xFF000004),
      Color(0xFF000005),
      Color(0xFF000006),
      Color(0xFF000007),
      Color(0xFF000008),
      Color(0xFF000009),
    ];
    final copied = BirbSemanticColors.light.copyWith(
      success: replacements[0],
      onSuccess: replacements[1],
      warning: replacements[2],
      onWarning: replacements[3],
      info: replacements[4],
      onInfo: replacements[5],
      focus: replacements[6],
      disabled: replacements[7],
      errorIndicator: replacements[8],
    );

    expect(_values(copied), replacements);
  });

  test('lerp switches discretely at the midpoint', () {
    const light = BirbSemanticColors.light;
    const dark = BirbSemanticColors.dark;

    expect(identical(light.lerp(null, 1), light), isTrue);
    for (final t in <double>[-1, 0, 0.49]) {
      expect(identical(light.lerp(dark, t), light), isTrue);
    }
    for (final t in <double>[0.5, 1, 2]) {
      expect(identical(light.lerp(dark, t), dark), isTrue);
    }
  });
}

List<Color> _values(BirbSemanticColors colors) => <Color>[
  colors.success,
  colors.onSuccess,
  colors.warning,
  colors.onWarning,
  colors.info,
  colors.onInfo,
  colors.focus,
  colors.disabled,
  colors.errorIndicator,
];
