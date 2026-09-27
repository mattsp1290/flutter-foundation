import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Audits exported declarations, including parts, without importing an engine.
void main() {
  final library = Directory('packages/birb_code_editor/lib');
  final failures = <String>[];
  final manifest = File('${library.parent.path}/pubspec.yaml')
      .readAsStringSync();
  if (manifest.contains('dependency_overrides:') ||
      File('${library.parent.path}/pubspec_overrides.yaml').existsSync()) {
    failures.add('Editor dependency overrides are forbidden');
  }
  for (final path in RegExp(
    r'^\s*path:\s*(\S+)',
    multiLine: true,
  ).allMatches(manifest).map((match) => match[1]!)) {
    if (path != 'packages/birb_design_system') {
      failures.add('Unexpected dependency path: $path');
    }
  }
  for (final entity in library.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final unit = parseString(content: entity.readAsStringSync()).unit;
    for (final directive in unit.directives.whereType<UriBasedDirective>()) {
      final uri = directive.uri.stringValue ?? '';
      if (uri.startsWith('package:') &&
          RegExp(r'/(src|test|tool|examples?)/').hasMatch(uri)) {
        failures.add('${entity.path}: non-public runtime import $uri');
      }
    }
  }
  final visited = <String>{};
  final exposed = <CompilationUnit>[];
  void visit(File file) {
    if (!visited.add(file.absolute.path)) return;
    final unit = parseString(content: file.readAsStringSync()).unit;
    exposed.add(unit);
    for (final directive in unit.directives) {
      if (directive is! ExportDirective && directive is! PartDirective) {
        continue;
      }
      final uri = (directive as UriBasedDirective).uri.stringValue!;
      if (Uri.parse(uri).hasScheme || uri.contains('..')) {
        failures.add('External or parent export/part: $uri');
        continue;
      }
      visit(File.fromUri(file.absolute.uri.resolve(uri)));
    }
  }

  visit(File('${library.path}/birb_code_editor.dart'));
  final publicTypes = <String>{};
  for (final unit in exposed) {
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final name = declaration.namePart.typeName.lexeme;
        if (!name.startsWith('_')) publicTypes.add(name);
      } else if (declaration is EnumDeclaration) {
        publicTypes.add(declaration.namePart.typeName.lexeme);
      } else if (declaration is GenericTypeAlias) {
        publicTypes.add(declaration.name.lexeme);
      }
    }
  }
  if (publicTypes.any((name) => !name.startsWith('Birb'))) {
    failures.add('Non-Birb declaration exported: $publicTypes');
  }
  final checker = _SignatureTypes({
    ...publicTypes,
    'bool',
    'int',
    'double',
    'String',
    'void',
    'Object',
    'List',
    'Iterable',
    'Future',
    'Duration',
    'ValueChanged',
    'VoidCallback',
    'Listenable',
    'TextSelection',
    'TextRange',
    'Key',
    'FocusNode',
    'State',
    'StatefulWidget',
    'BirbCodeTheme',
  }, failures);
  for (final unit in exposed) {
    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      if (declaration.namePart.typeName.lexeme.startsWith('_')) continue;
      for (final member in declaration.body.members) {
        if (member is FieldDeclaration &&
            member.fields.variables.any(
              (v) => !v.name.lexeme.startsWith('_'),
            )) {
          member.fields.type?.accept(checker);
        } else if (member is MethodDeclaration &&
            !member.name.lexeme.startsWith('_')) {
          member.returnType?.accept(checker);
          member.parameters?.accept(checker);
        } else if (member is ConstructorDeclaration &&
            !(member.name?.lexeme.startsWith('_') ?? false)) {
          member.parameters.accept(checker);
        }
      }
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln(failures.join('\n'));
    exitCode = 1;
  } else {
    stdout.writeln('Editor public API and dependency boundary audit passed');
  }
}

class _SignatureTypes extends RecursiveAstVisitor<void> {
  _SignatureTypes(this.allowed, this.failures);
  final Set<String> allowed;
  final List<String> failures;

  @override
  void visitNamedType(NamedType node) {
    if (!allowed.contains(node.name.lexeme) || node.importPrefix != null) {
      failures.add('Unapproved public signature type: ${node.toSource()}');
    }
    super.visitNamedType(node);
  }
}
