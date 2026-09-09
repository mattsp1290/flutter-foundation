part of 'design_system_audit.dart';

const _standalonePalettePath = 'lib/src/foundation/birb_palette.dart';
const _workspacePalettePath =
    'packages/birb_design_system/lib/src/foundation/birb_palette.dart';
const _standaloneAuditBarrel = 'lib/design_system_audit.dart';
const _workspaceAuditBarrel =
    'packages/birb_design_system/lib/design_system_audit.dart';
const _forbiddenColorMembers = {
  'withAlpha',
  'withOpacity',
  'withValues',
  'withRed',
  'withGreen',
  'withBlue',
};

const _forbiddenIdentifiers = {
  'HSLColor': 'HSLColor usage',
  'HSVColor': 'HSVColor usage',
  'ColorSwatch': 'ColorSwatch usage',
  'MaterialColor': 'MaterialColor usage',
  'MaterialAccentColor': 'MaterialAccentColor usage',
  'CupertinoDynamicColor': 'CupertinoDynamicColor usage',
  'LinearGradient': 'LinearGradient usage',
  'RadialGradient': 'RadialGradient usage',
  'SweepGradient': 'SweepGradient usage',
  'BackdropFilter': 'BackdropFilter usage',
};
List<DesignSystemViolation> _tokenViolations(
  String relativePath,
  List<_Token> tokens, {
  required bool standaloneDesignSystem,
}) {
  final violations = <DesignSystemViolation>[];
  final insideDesignSystem =
      (standaloneDesignSystem && relativePath.startsWith('lib/src/')) ||
      relativePath.startsWith('packages/birb_design_system/lib/src/');

  void add(_Token token, String message) {
    violations.add(
      DesignSystemViolation(
        relativePath: relativePath,
        line: token.line,
        message: message,
      ),
    );
  }

  bool sequence(int index, List<String> lexemes) {
    if (index + lexemes.length > tokens.length) return false;
    for (var offset = 0; offset < lexemes.length; offset += 1) {
      if (tokens[index + offset].lexeme != lexemes[offset]) return false;
    }
    return true;
  }

  for (var index = 0; index < tokens.length; index += 1) {
    final token = tokens[index];
    if (token.kind != _TokenKind.identifier) continue;

    final forbiddenMessage = _forbiddenIdentifiers[token.lexeme];
    if (forbiddenMessage != null) add(token, forbiddenMessage);

    if (token.lexeme == 'Color' &&
        !_isPalettePath(relativePath, standaloneDesignSystem)) {
      final directConstructor = sequence(index + 1, ['(']);
      final namedConstructor =
          index + 2 < tokens.length &&
          sequence(index + 1, ['.']) &&
          (tokens[index + 2].lexeme == 'new' ||
              tokens[index + 2].lexeme.startsWith('from'));
      if (directConstructor || namedConstructor) {
        add(token, 'direct Color construction');
      }
    }

    if (token.lexeme == 'Color' && sequence(index + 1, ['.', 'lerp'])) {
      add(token, 'Color.lerp transformation');
    }
    if (token.lexeme == 'Color' && sequence(index + 1, ['.', 'alphaBlend'])) {
      add(token, 'Color.alphaBlend transformation');
    }
    if (token.lexeme == 'Colors' && sequence(index + 1, ['.'])) {
      add(token, 'Material Colors palette usage');
    }
    if (token.lexeme == 'CupertinoColors' && sequence(index + 1, ['.'])) {
      add(token, 'CupertinoColors palette usage');
    }
    if (_forbiddenColorMembers.contains(token.lexeme) &&
        index > 0 &&
        tokens[index - 1].lexeme == '.') {
      add(token, 'authored color transformation');
    }
    if (token.lexeme == 'ColorScheme' &&
        sequence(index + 1, ['.', 'fromSeed'])) {
      add(token, 'generated ColorScheme usage');
    }
    if (token.lexeme == 'BirbPalette' && !insideDesignSystem) {
      add(token, 'private BirbPalette boundary violation');
    }

    if (!{'import', 'export', 'part'}.contains(token.lexeme)) continue;
    final directiveEnd = tokens.indexWhere(
      (candidate) => candidate.lexeme == ';',
      index + 1,
    );
    final end = directiveEnd == -1 ? tokens.length : directiveEnd;
    final directiveStrings = tokens
        .sublist(index + 1, end)
        .where((candidate) => candidate.kind == _TokenKind.string)
        .toList();
    final directivePaths = <String>[];
    for (final candidate in directiveStrings) {
      if (candidate.lexeme.contains(r'\')) {
        add(candidate, 'escaped directive URIs are forbidden');
        continue;
      }
      try {
        directivePaths.add(
          Uri.parse(candidate.lexeme).path.replaceAll(r'\', '/'),
        );
      } on FormatException {
        add(candidate, 'malformed directive URI');
      }
    }
    final exposesPalette = directivePaths.any(
      (path) => path.endsWith('birb_palette.dart'),
    );
    if (exposesPalette && token.lexeme == 'export') {
      add(token, 'private palette export is forbidden');
    } else if (exposesPalette && !insideDesignSystem) {
      add(token, 'private BirbPalette boundary violation');
    }
    final exposesAudit = directivePaths.any(
      (path) =>
          path.endsWith('design_system_audit.dart') || path.contains('/audit/'),
    );
    final isAuditBarrel =
        relativePath == _workspaceAuditBarrel ||
        (standaloneDesignSystem && relativePath == _standaloneAuditBarrel);
    if (!isAuditBarrel && token.lexeme == 'export' && exposesAudit) {
      add(token, 'audit APIs may only be exported by design_system_audit.dart');
    }
  }

  return violations;
}

bool _isPalettePath(String path, bool standaloneDesignSystem) =>
    path == _workspacePalettePath ||
    (standaloneDesignSystem && path == _standalonePalettePath);

bool _isStandaloneDesignSystem(Directory root) {
  final pubspec = File.fromUri(root.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  try {
    return RegExp(
      r'^name:\s*birb_design_system\s*(?:#.*)?$',
      multiLine: true,
    ).hasMatch(pubspec.readAsStringSync());
  } on FileSystemException {
    return false;
  }
}
