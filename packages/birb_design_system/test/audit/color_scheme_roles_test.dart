import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:birb_design_system/design_system_audit.dart';
import 'package:flutter_test/flutter_test.dart';

const _deprecatedColorSchemeRoles = <String>{
  'background',
  'onBackground',
  'surfaceVariant',
};

void main() {
  test('maps every active Flutter ColorScheme color role explicitly', () {
    final flutterPackage = _flutterPackageRoot();
    final flutterRoot = flutterPackage.parent.parent;
    final version = jsonDecode(
      File.fromUri(flutterRoot.uri.resolve('bin/cache/flutter.version.json'))
          .readAsStringSync(),
    ) as Map<String, Object?>;
    expect(version['frameworkVersion'], '3.47.1');
    expect(
      version['frameworkRevision'],
      '6655482ec06e547f90abf8ae7590466f4415978d',
    );
    final sourceFile = flutterPackage.uri.resolve(
      'lib/src/material/color_scheme.dart',
    );
    final parsed = parseFile(
      path: File.fromUri(sourceFile).resolveSymbolicLinksSync(),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    expect(parsed.errors, isEmpty);
    final declaration = parsed.unit.declarations
        .whereType<ClassDeclaration>()
        .singleWhere((node) => node.namePart.typeName.lexeme == 'ColorScheme');
    final inventory = <String, bool>{};

    for (final member in declaration.body.members) {
      final names = _colorRoleNames(member);
      if (names.isEmpty) continue;
      for (final name in names.where((name) => !name.startsWith('_'))) {
        expect(inventory, isNot(contains(name)), reason: 'duplicate $name');
        inventory[name] = _isDeprecated(member);
      }
    }
    final active = inventory.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
    final deprecated = inventory.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();

    expect(inventory.keys.toSet(), <String>{
      ...birbMappedColorSchemeRoles,
      ..._deprecatedColorSchemeRoles,
    });
    expect(deprecated, _deprecatedColorSchemeRoles);
    expect(active, birbMappedColorSchemeRoles);
    expect(active, hasLength(46));
    expect(active.intersection(deprecated), isEmpty);
  });
}

Iterable<String> _colorRoleNames(ClassMember member) {
  if (member is FieldDeclaration &&
      !member.isStatic &&
      _isColor(member.fields.type)) {
    return member.fields.variables.map((variable) => variable.name.lexeme);
  }
  if (member is MethodDeclaration &&
      !member.isStatic &&
      member.isGetter &&
      _isColor(member.returnType)) {
    return <String>[member.name.lexeme];
  }
  return const <String>[];
}

bool _isColor(TypeAnnotation? type) =>
    type is NamedType && type.name.lexeme == 'Color' && type.question == null;

bool _isDeprecated(ClassMember member) => member.metadata.any((annotation) {
  final name = annotation.name.toSource();
  return name == 'Deprecated' ||
      name == 'deprecated' ||
      name.endsWith('.Deprecated') ||
      name.endsWith('.deprecated');
});

Directory _flutterPackageRoot() {
  final packageConfigPath = Platform.executableArguments
      .singleWhere((argument) => argument.startsWith('--packages='))
      .substring('--packages='.length);
  final packageConfigUri = Uri.file(packageConfigPath);
  final packageConfig = jsonDecode(
    File.fromUri(packageConfigUri).readAsStringSync(),
  ) as Map<String, Object?>;
  final packages = packageConfig['packages']! as List<Object?>;
  final flutter = packages.cast<Map<String, Object?>>().singleWhere(
    (entry) => entry['name'] == 'flutter',
  );
  return Directory.fromUri(
    packageConfigUri.resolve(flutter['rootUri']! as String),
  );
}
