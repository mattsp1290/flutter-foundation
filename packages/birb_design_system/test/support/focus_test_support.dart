import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether primary focus belongs to [finder] or one of its descendants.
bool focusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return false;
  if (context == target) return true;
  var inside = false;
  context.visitAncestorElements((element) {
    inside = element == target;
    return !inside;
  });
  return inside;
}
