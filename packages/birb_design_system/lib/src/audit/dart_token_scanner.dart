part of 'design_system_audit.dart';

final _identifierStart = RegExp(r'[A-Za-z_$]');
final _identifierPart = RegExp(r'[A-Za-z0-9_$]');

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
