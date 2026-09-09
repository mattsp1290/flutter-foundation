import 'dart:io';

const _standalonePalettePath = 'lib/src/foundation/birb_palette.dart';
const _workspacePalettePath =
    'packages/birb_design_system/lib/src/foundation/birb_palette.dart';
const _standaloneRuntimeBarrel = 'lib/birb_design_system.dart';
const _workspaceRuntimeBarrel =
    'packages/birb_design_system/lib/birb_design_system.dart';

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
final _identifierStart = RegExp(r'[A-Za-z_$]');
final _identifierPart = RegExp(r'[A-Za-z0-9_$]');

final class DesignSystemViolation {
  const DesignSystemViolation({
    required this.relativePath,
    required this.line,
    required this.message,
  });

  final String relativePath;
  final int line;
  final String message;

  @override
  String toString() => '$relativePath:$line: $message';
}

final class DesignSystemAuditResult {
  const DesignSystemAuditResult({
    required this.filesScanned,
    required this.violations,
    this.invalidRoot = false,
  });

  final int filesScanned;
  final List<DesignSystemViolation> violations;
  final bool invalidRoot;

  bool get passed => violations.isEmpty;
}

DesignSystemAuditResult auditDesignSystemSources(Directory requestedRoot) {
  if (!requestedRoot.existsSync()) {
    return _failedSurface('.', 'audit root does not exist');
  }

  final Directory root;
  try {
    root = Directory(requestedRoot.resolveSymbolicLinksSync());
  } on FileSystemException catch (error) {
    return _failedSurface('.', 'audit root is unreadable: ${error.message}');
  }

  final surface = _auditSurface(root);
  final violations = [...surface.violations];

  for (final file in surface.files) {
    final relativePath = _relativePath(root, file);
    try {
      final tokens = _DartTokenScanner(file.readAsStringSync()).scan();
      violations.addAll(_tokenViolations(relativePath, tokens));
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: relativePath,
          line: 1,
          message: 'source file is unreadable: ${error.message}',
        ),
      );
    }
  }

  violations.sort((left, right) {
    final pathOrder = left.relativePath.compareTo(right.relativePath);
    if (pathOrder != 0) return pathOrder;
    final lineOrder = left.line.compareTo(right.line);
    if (lineOrder != 0) return lineOrder;
    return left.message.compareTo(right.message);
  });

  return DesignSystemAuditResult(
    filesScanned: surface.files.length,
    violations: List.unmodifiable(violations),
    invalidRoot: surface.invalidRoot,
  );
}

int writeDesignSystemAuditReport(
  Directory root, {
  required StringSink output,
  required StringSink errors,
}) {
  final result = auditDesignSystemSources(root);
  if (!result.passed) {
    for (final violation in result.violations) {
      errors.writeln(violation);
    }
    errors.writeln(
      'Design-system source audit failed '
      '(${result.violations.length} violation(s)).',
    );
    return result.invalidRoot ? 64 : 1;
  }

  output.writeln(
    'Design-system source audit passed (${result.filesScanned} files scanned).',
  );
  return 0;
}

DesignSystemAuditResult _failedSurface(String path, String message) {
  return DesignSystemAuditResult(
    filesScanned: 0,
    violations: List.unmodifiable([
      DesignSystemViolation(relativePath: path, line: 1, message: message),
    ]),
    invalidRoot: true,
  );
}

List<DesignSystemViolation> _tokenViolations(
  String relativePath,
  List<_Token> tokens,
) {
  final violations = <DesignSystemViolation>[];
  final insideDesignSystem =
      relativePath == _standalonePalettePath ||
      relativePath.startsWith('lib/src/') ||
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

    if (token.lexeme == 'Color' && !_isPalettePath(relativePath)) {
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
    if ({'withAlpha', 'withOpacity', 'withValues'}.contains(token.lexeme) &&
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
    final exposesPalette = tokens
        .sublist(index + 1, end)
        .where((candidate) => candidate.kind == _TokenKind.string)
        .any((candidate) => candidate.lexeme.endsWith('birb_palette.dart'));
    if (exposesPalette && token.lexeme == 'export') {
      add(token, 'private palette export is forbidden');
    } else if (exposesPalette && !insideDesignSystem) {
      add(token, 'private BirbPalette boundary violation');
    }
    final runtimeBarrel =
        relativePath == _standaloneRuntimeBarrel ||
        relativePath == _workspaceRuntimeBarrel;
    final exposesAudit = tokens
        .sublist(index + 1, end)
        .where((candidate) => candidate.kind == _TokenKind.string)
        .any(
          (candidate) =>
              candidate.lexeme.endsWith('design_system_audit.dart') ||
              candidate.lexeme.contains('/audit/'),
        );
    if (runtimeBarrel && token.lexeme == 'export' && exposesAudit) {
      add(token, 'runtime barrel must not export audit APIs');
    }
  }

  return violations;
}

bool _isPalettePath(String path) =>
    path == _standalonePalettePath || path == _workspacePalettePath;

_AuditSurface _auditSurface(Directory root) {
  final files = <File>[];
  final violations = <DesignSystemViolation>[];
  final libDirectories = _libDirectories(root, violations);
  final invalidRoot = libDirectories.isEmpty && violations.isEmpty;
  if (invalidRoot) {
    violations.add(
      const DesignSystemViolation(
        relativePath: '.',
        line: 1,
        message: 'audit root contains no package or example lib directories',
      ),
    );
  }

  for (final directory in libDirectories) {
    try {
      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity);
        } else if (entity is Link) {
          violations.add(
            DesignSystemViolation(
              relativePath: _relativeEntityPath(root, entity.path),
              line: 1,
              message: 'symbolic links are forbidden in audited source paths',
            ),
          );
        }
      }
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: _relativeEntityPath(root, directory.path),
          line: 1,
          message: 'scan root is unreadable: ${error.message}',
        ),
      );
    }
  }

  files.sort((left, right) => left.path.compareTo(right.path));
  return _AuditSurface(
    files: files,
    violations: violations,
    invalidRoot: invalidRoot,
  );
}

List<Directory> _libDirectories(
  Directory root,
  List<DesignSystemViolation> violations,
) {
  final result = <Directory>[];
  final directLib = Directory('${root.path}${Platform.pathSeparator}lib');
  final directType = FileSystemEntity.typeSync(
    directLib.path,
    followLinks: false,
  );
  if (directType == FileSystemEntityType.link) {
    violations.add(_symlinkViolation(root, directLib.path));
  } else if (directType == FileSystemEntityType.directory) {
    result.add(directLib);
  }

  for (final group in ['packages', 'examples']) {
    final parent = Directory('${root.path}${Platform.pathSeparator}$group');
    final parentType = FileSystemEntity.typeSync(
      parent.path,
      followLinks: false,
    );
    if (parentType == FileSystemEntityType.link) {
      violations.add(_symlinkViolation(root, parent.path));
      continue;
    }
    if (parentType != FileSystemEntityType.directory) continue;

    try {
      for (final entity in parent.listSync(followLinks: false)) {
        if (entity is Link) {
          violations.add(_symlinkViolation(root, entity.path));
          continue;
        }
        if (entity is! Directory) continue;
        try {
          for (final child in entity.listSync(followLinks: false)) {
            if (_basename(child.path) != 'lib') continue;
            if (child is Link) {
              violations.add(_symlinkViolation(root, child.path));
            } else if (child is Directory) {
              result.add(child);
            }
          }
        } on FileSystemException catch (error) {
          violations.add(
            DesignSystemViolation(
              relativePath: _relativeEntityPath(root, entity.path),
              line: 1,
              message: 'scan root is unreadable: ${error.message}',
            ),
          );
        }
      }
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: group,
          line: 1,
          message: 'scan root is unreadable: ${error.message}',
        ),
      );
    }
  }
  return result;
}

String _basename(String path) {
  final normalized = path.endsWith(Platform.pathSeparator)
      ? path.substring(0, path.length - Platform.pathSeparator.length)
      : path;
  final separator = normalized.lastIndexOf(Platform.pathSeparator);
  return separator == -1 ? normalized : normalized.substring(separator + 1);
}

DesignSystemViolation _symlinkViolation(Directory root, String path) {
  return DesignSystemViolation(
    relativePath: _relativeEntityPath(root, path),
    line: 1,
    message: 'symbolic links are forbidden in audited source paths',
  );
}

String _relativePath(Directory root, File file) =>
    _relativeEntityPath(root, file.absolute.path);

String _relativeEntityPath(Directory root, String entityPath) {
  final rootPath = root.absolute.path;
  final filePath = File(entityPath).absolute.path;
  final prefix = rootPath.endsWith(Platform.pathSeparator)
      ? rootPath
      : '$rootPath${Platform.pathSeparator}';
  if (!filePath.startsWith(prefix)) {
    throw ArgumentError.value(
      entityPath,
      'entity',
      'Source path escapes audit root',
    );
  }
  return filePath
      .substring(prefix.length)
      .replaceAll(Platform.pathSeparator, '/');
}

final class _AuditSurface {
  const _AuditSurface({
    required this.files,
    required this.violations,
    required this.invalidRoot,
  });

  final List<File> files;
  final List<DesignSystemViolation> violations;
  final bool invalidRoot;
}

enum _TokenKind { identifier, string, symbol }

final class _Token {
  const _Token(this.kind, this.lexeme, this.line);

  final _TokenKind kind;
  final String lexeme;
  final int line;
}

final class _DartTokenScanner {
  _DartTokenScanner(this.source);

  final String source;
  final tokens = <_Token>[];
  var _index = 0;
  var _line = 1;

  List<_Token> scan() {
    _scanCode();
    return List.unmodifiable(tokens);
  }

  void _scanCode({bool stopAtClosingBrace = false}) {
    var nestedBraces = 0;
    while (_index < source.length) {
      final character = source[_index];
      final next = _peek(1);

      if (character == '\n') {
        _line += 1;
        _index += 1;
      } else if (_isWhitespace(character)) {
        _index += 1;
      } else if (character == '/' && next == '/') {
        _scanLineComment();
      } else if (character == '/' && next == '*') {
        _scanBlockComment();
      } else if ((character == 'r' || character == 'R') &&
          (_peek(1) == "'" || _peek(1) == '"') &&
          (_index == 0 || !_isIdentifierPart(source[_index - 1]))) {
        _index += 1;
        _scanString(raw: true);
      } else if (character == "'" || character == '"') {
        _scanString(raw: false);
      } else if (_isIdentifierStart(character)) {
        _scanIdentifier();
      } else if (character == '{') {
        nestedBraces += 1;
        _addSymbol(character);
      } else if (character == '}' && stopAtClosingBrace) {
        if (nestedBraces == 0) {
          _index += 1;
          return;
        }
        nestedBraces -= 1;
        _addSymbol(character);
      } else {
        _addSymbol(character);
      }
    }
  }

  void _scanIdentifier() {
    final start = _index;
    while (_index < source.length && _isIdentifierPart(source[_index])) {
      _index += 1;
    }
    tokens.add(
      _Token(_TokenKind.identifier, source.substring(start, _index), _line),
    );
  }

  void _scanString({required bool raw}) {
    final quote = source[_index];
    final tokenLine = _line;
    final triple = source.startsWith(quote * 3, _index);
    final delimiterLength = triple ? 3 : 1;
    _index += delimiterLength;
    final contentStart = _index;
    final tokenPosition = tokens.length;

    while (_index < source.length) {
      final character = source[_index];
      if (character == '\n') {
        _line += 1;
        _index += 1;
        continue;
      }
      if (!raw && character == '\\' && _peek(1).isNotEmpty) {
        _index += 2;
        continue;
      }
      if (!raw && character == r'$') {
        if (_peek(1) == '{') {
          _index += 2;
          _scanCode(stopAtClosingBrace: true);
          continue;
        }
        if (_isIdentifierStart(_peek(1))) {
          _index += 1;
          _scanIdentifier();
          continue;
        }
      }
      if (triple && source.startsWith(quote * 3, _index)) {
        final contents = source.substring(contentStart, _index);
        _index += 3;
        tokens.insert(
          tokenPosition,
          _Token(_TokenKind.string, contents, tokenLine),
        );
        return;
      }
      if (!triple && character == quote) {
        final contents = source.substring(contentStart, _index);
        _index += 1;
        tokens.insert(
          tokenPosition,
          _Token(_TokenKind.string, contents, tokenLine),
        );
        return;
      }
      _index += 1;
    }

    tokens.insert(
      tokenPosition,
      _Token(_TokenKind.string, source.substring(contentStart), tokenLine),
    );
  }

  void _scanLineComment() {
    _index += 2;
    while (_index < source.length && source[_index] != '\n') {
      _index += 1;
    }
  }

  void _scanBlockComment() {
    _index += 2;
    var depth = 1;
    while (_index < source.length && depth > 0) {
      if (source[_index] == '/' && _peek(1) == '*') {
        depth += 1;
        _index += 2;
      } else if (source[_index] == '*' && _peek(1) == '/') {
        depth -= 1;
        _index += 2;
      } else {
        if (source[_index] == '\n') {
          _line += 1;
        }
        _index += 1;
      }
    }
  }

  void _addSymbol(String symbol) {
    tokens.add(_Token(_TokenKind.symbol, symbol, _line));
    _index += 1;
  }

  String _peek(int offset) {
    final target = _index + offset;
    return target < source.length ? source[target] : '';
  }

  static bool _isWhitespace(String character) =>
      character == ' ' || character == '\t' || character == '\r';

  static bool _isIdentifierStart(String character) =>
      character.isNotEmpty && _identifierStart.hasMatch(character);

  static bool _isIdentifierPart(String character) =>
      character.isNotEmpty && _identifierPart.hasMatch(character);
}
