import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/go.dart';

CodeEditorStyle editorStyle(
  ThemeData theme,
  BirbCodeTheme preset,
  double fontScale, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final colors = preset.resolve(theme);
  return CodeEditorStyle(
    fontSize: textScaler.scale(
      (BirbReviewStyle.codeTextStyle(theme).fontSize ?? 14) * fontScale,
    ),
    fontFamily: BirbReviewStyle.codeTextStyle(theme).fontFamily,
    fontFamilyFallback: BirbReviewStyle.codeTextStyle(theme).fontFamilyFallback,
    textColor: colors.foreground,
    backgroundColor: colors.background,
    selectionColor: colors.selection,
    cursorColor: colors.cursor,
    codeTheme: CodeHighlightTheme(
      languages: {'go': CodeHighlightThemeMode(mode: langGo)},
      theme: {
        'keyword': TextStyle(color: colors.keyword),
        'comment': TextStyle(color: colors.comment),
        'string': TextStyle(color: colors.string),
        'number': TextStyle(color: colors.number),
      },
    ),
  );
}
