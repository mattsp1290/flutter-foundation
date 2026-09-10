import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_audit.dart';
import 'package:birb_design_system/src/foundation/birb_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'expected_theme_values.dart';
import 'theme_test_support.dart';

void main() {
  for (final themeCase in <(String, ThemeData, Map<String, String>)>[
    ('light', BirbTheme.light, expectedLightScheme),
    ('dark', BirbTheme.dark, expectedDarkScheme),
  ]) {
    test('${themeCase.$1} maps all active ColorScheme roles exactly', () {
      final actual = schemeColors(themeCase.$2.colorScheme);
      final expected = themeCase.$3.map(
        (role, paletteName) => MapEntry(role, expectedPalette[paletteName]),
      );

      expect(actual.keys.toSet(), birbMappedColorSchemeRoles);
      expect(
        actual.map((role, color) => MapEntry(role, color.toARGB32())),
        expected,
        reason: designSourceCommit,
      );
      expect(
        actual.values.toSet().difference(BirbPalette.values.toSet()),
        isEmpty,
      );

      final scheme = themeCase.$2.colorScheme;
      // ignore: deprecated_member_use
      expect(scheme.background, scheme.surface);
      // ignore: deprecated_member_use
      expect(scheme.onBackground, scheme.onSurface);
      // ignore: deprecated_member_use
      expect(scheme.surfaceVariant, scheme.surface);
    });
  }

  test('both constructors explicitly author every active color role', () {
    final source = File.fromUri(
      birbDesignSystemPackageRoot().uri.resolve(
        'lib/src/theme/birb_color_schemes.dart',
      ),
    ).readAsStringSync();
    final visitor = _ColorSchemeConstructorVisitor();
    parseString(content: source, throwIfDiagnostics: true).unit.accept(visitor);

    expect(visitor.namedArguments, hasLength(2));
    for (final arguments in visitor.namedArguments) {
      expect(arguments, contains('brightness'));
      expect(arguments.difference({'brightness'}), birbMappedColorSchemeRoles);
    }
  });
}

final class _ColorSchemeConstructorVisitor extends RecursiveAstVisitor<void> {
  final namedArguments = <Set<String>>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'ColorScheme') {
      namedArguments.add({
        for (final argument in node.argumentList.arguments)
          if (argument is NamedArgument) argument.name.lexeme,
      });
    }
    super.visitMethodInvocation(node);
  }
}
