import 'package:flutter/painting.dart';

/// Spacing values from the Birb Party design contract.
abstract final class BirbSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;
}

/// Border widths from the Birb Party design contract.
abstract final class BirbBorders {
  static const double thin = 1;
  static const double strong = 2;
}

/// Approved container radii from the Birb Party design contract.
abstract final class BirbRadii {
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius pixel = BorderRadius.all(Radius.circular(2));
}

/// Interactive dimensions from the Birb Party design contract.
abstract final class BirbSizes {
  static const double minimumInteractiveDimension = 48;
}

/// Motion durations from the Birb Party design contract.
abstract final class BirbDurations {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 200);
}
