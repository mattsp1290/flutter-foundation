import 'dart:io';

import 'package:birb_design_system/src/foundation/birb_palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contains the exact SWEETIE-16 palette in source order', () {
    expect(BirbPalette.values, const <Color>[
      Color(0xFF1A1C2C),
      Color(0xFF5D275D),
      Color(0xFFB13E53),
      Color(0xFFEF7D57),
      Color(0xFFFFCD75),
      Color(0xFFA7F070),
      Color(0xFF38B764),
      Color(0xFF257179),
      Color(0xFF29366F),
      Color(0xFF3B5DC9),
      Color(0xFF41A6F6),
      Color(0xFF73EFF7),
      Color(0xFFF4F4F4),
      Color(0xFF94B0C2),
      Color(0xFF566C86),
      Color(0xFF333C57),
    ]);
  });

  test('does not export palette primitives from the runtime barrel', () {
    final barrel = File('lib/birb_design_system.dart').readAsStringSync();

    expect(barrel, isNot(contains('birb_palette.dart')));
    expect(barrel, isNot(contains('BirbPalette')));
  });
}
