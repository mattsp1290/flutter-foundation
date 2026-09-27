import 'package:flutter/material.dart';

import 'birb_code_theme.dart';

/// Presentation grammars supported by [BirbCodeController].
enum BirbCodeLanguage { plain, go }

/// Host-owned native editing state with presentation-only Go highlighting.
///
/// Tokens never change source, selection, undo history or composing text.
class BirbCodeController extends TextEditingController {
  BirbCodeController({super.text, this.language = BirbCodeLanguage.go});

  final BirbCodeLanguage language;

  static final _tokens = RegExp(
    r'''//[^\n]*|/\*[\s\S]*?(?:\*/|$)|`[^`]*(?:`|$)|"(?:\\[^\n]|[^"\\\n])*(?:"|$)|'(?:\\[^\n]|[^'\\\n])*(?:'|$)|\b(?:break|default|func|interface|select|case|defer|go|map|struct|chan|else|goto|package|switch|const|fallthrough|if|range|type|continue|for|import|return|var)\b|\b(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|[0-9][0-9_]*(?:\.[0-9_]*)?(?:[eE][+-]?[0-9_]+)?i?)\b''',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Preserve Flutter's native composing underline and range checks. Syntax
    // resumes after composition commits; never alter IME-owned text.
    if (language == BirbCodeLanguage.plain ||
        (withComposing &&
            value.isComposingRangeValid &&
            !value.composing.isCollapsed)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final theme = Theme.of(context);
    final colors =
        theme.extension<BirbCodeColors>() ??
        BirbCodeTheme.foundation.resolve(theme);
    final children = <TextSpan>[];
    var end = 0;
    for (final token in _tokens.allMatches(text)) {
      if (token.start > end) {
        children.add(TextSpan(text: text.substring(end, token.start)));
      }
      final word = token.group(0)!;
      final comment = word.startsWith('//') || word.startsWith('/*');
      final literal =
          word.startsWith('"') || word.startsWith("'") || word.startsWith('`');
      final number = RegExp(r'^[0-9]').hasMatch(word);
      children.add(
        TextSpan(
          text: word,
          style: TextStyle(
            color: comment
                ? colors.comment
                : literal || number
                ? (number ? colors.number : colors.string)
                : colors.keyword,
            fontStyle: comment ? FontStyle.italic : FontStyle.normal,
            fontWeight: !comment && !literal && !number
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      );
      end = token.end;
    }
    if (end < text.length) children.add(TextSpan(text: text.substring(end)));
    return TextSpan(style: style, children: children);
  }
}
