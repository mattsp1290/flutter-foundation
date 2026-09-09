import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports the complete spacing scale', () {
    expect(
      <double>[
        BirbSpacing.space1,
        BirbSpacing.space2,
        BirbSpacing.space3,
        BirbSpacing.space4,
        BirbSpacing.space6,
        BirbSpacing.space8,
        BirbSpacing.space12,
      ],
      <double>[4, 8, 12, 16, 24, 32, 48],
    );
  });

  test('exports border, radius, size, and duration tokens', () {
    expect(BirbBorders.thin, 1);
    expect(BirbBorders.strong, 2);
    expect(BirbRadii.none, BorderRadius.zero);
    expect(BirbRadii.pixel, const BorderRadius.all(Radius.circular(2)));
    expect(BirbSizes.minimumInteractiveDimension, 48);
    expect(BirbDurations.instant, Duration.zero);
    expect(BirbDurations.fast, const Duration(milliseconds: 100));
    expect(BirbDurations.standard, const Duration(milliseconds: 200));
  });
}
