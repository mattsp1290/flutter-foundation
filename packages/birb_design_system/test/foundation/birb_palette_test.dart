import 'package:birb_design_system/src/foundation/birb_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binds every SWEETIE-16 name to its exact source value', () {
    expect(
      <String, int>{
        'black': BirbPalette.black.toARGB32(),
        'purple': BirbPalette.purple.toARGB32(),
        'red': BirbPalette.red.toARGB32(),
        'orange': BirbPalette.orange.toARGB32(),
        'yellow': BirbPalette.yellow.toARGB32(),
        'lime': BirbPalette.lime.toARGB32(),
        'green': BirbPalette.green.toARGB32(),
        'darkCyan': BirbPalette.darkCyan.toARGB32(),
        'darkBlue': BirbPalette.darkBlue.toARGB32(),
        'blue': BirbPalette.blue.toARGB32(),
        'lightBlue': BirbPalette.lightBlue.toARGB32(),
        'cyan': BirbPalette.cyan.toARGB32(),
        'white': BirbPalette.white.toARGB32(),
        'lightGray': BirbPalette.lightGray.toARGB32(),
        'gray': BirbPalette.gray.toARGB32(),
        'darkGray': BirbPalette.darkGray.toARGB32(),
      },
      <String, int>{
        'black': 0xFF1A1C2C,
        'purple': 0xFF5D275D,
        'red': 0xFFB13E53,
        'orange': 0xFFEF7D57,
        'yellow': 0xFFFFCD75,
        'lime': 0xFFA7F070,
        'green': 0xFF38B764,
        'darkCyan': 0xFF257179,
        'darkBlue': 0xFF29366F,
        'blue': 0xFF3B5DC9,
        'lightBlue': 0xFF41A6F6,
        'cyan': 0xFF73EFF7,
        'white': 0xFFF4F4F4,
        'lightGray': 0xFF94B0C2,
        'gray': 0xFF566C86,
        'darkGray': 0xFF333C57,
      },
    );
  });

  test('keeps palette values in source order', () {
    expect(BirbPalette.values, <Object>[
      BirbPalette.black,
      BirbPalette.purple,
      BirbPalette.red,
      BirbPalette.orange,
      BirbPalette.yellow,
      BirbPalette.lime,
      BirbPalette.green,
      BirbPalette.darkCyan,
      BirbPalette.darkBlue,
      BirbPalette.blue,
      BirbPalette.lightBlue,
      BirbPalette.cyan,
      BirbPalette.white,
      BirbPalette.lightGray,
      BirbPalette.gray,
      BirbPalette.darkGray,
    ]);
  });
}
