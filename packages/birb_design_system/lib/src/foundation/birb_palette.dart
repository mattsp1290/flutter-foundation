import 'dart:ui';

/// The exact SWEETIE-16 primitives selected for Birb Party.
///
/// This palette is private to the design-system implementation. Product code
/// must consume semantic theme roles instead of these primitives.
abstract final class BirbPalette {
  static const Color black = Color(0xFF1A1C2C);
  static const Color purple = Color(0xFF5D275D);
  static const Color red = Color(0xFFB13E53);
  static const Color orange = Color(0xFFEF7D57);
  static const Color yellow = Color(0xFFFFCD75);
  static const Color lime = Color(0xFFA7F070);
  static const Color green = Color(0xFF38B764);
  static const Color darkCyan = Color(0xFF257179);
  static const Color darkBlue = Color(0xFF29366F);
  static const Color blue = Color(0xFF3B5DC9);
  static const Color lightBlue = Color(0xFF41A6F6);
  static const Color cyan = Color(0xFF73EFF7);
  static const Color white = Color(0xFFF4F4F4);
  static const Color lightGray = Color(0xFF94B0C2);
  static const Color gray = Color(0xFF566C86);
  static const Color darkGray = Color(0xFF333C57);

  static const List<Color> values = <Color>[
    black,
    purple,
    red,
    orange,
    yellow,
    lime,
    green,
    darkCyan,
    darkBlue,
    blue,
    lightBlue,
    cyan,
    white,
    lightGray,
    gray,
    darkGray,
  ];
}
