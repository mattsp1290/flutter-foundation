// Editor-only primitive exception, DESIGN.md section 11. No app surface uses it.
// Sources and MIT notices: docs/editor-themes.md and docs/licenses/.
import 'package:flutter/painting.dart';

import 'birb_code_theme.dart';

BirbCodeColors codePalette(BirbCodeTheme theme) => switch (theme) {
  BirbCodeTheme.dracula => const BirbCodeColors(
    background: Color(0xff282a36),
    foreground: Color(0xfff8f8f2),
    gutter: Color(0xffbd93f9),
    comment: Color(0xffbd93f9),
    keyword: Color(0xffff79c6),
    string: Color(0xfff1fa8c),
    number: Color(0xffbd93f9),
    selection: Color(0xff343746),
    cursor: Color(0xfff8f8f2),
  ),
  BirbCodeTheme.githubLight => const BirbCodeColors(
    background: Color(0xffffffff),
    foreground: Color(0xff24292f),
    gutter: Color(0xff57606a),
    comment: Color(0xff57606a),
    keyword: Color(0xffcf222e),
    string: Color(0xff0a3069),
    number: Color(0xff0550ae),
    selection: Color(0xffddf4ff),
    cursor: Color(0xff24292f),
  ),
  BirbCodeTheme.githubDark => const BirbCodeColors(
    background: Color(0xff0d1117),
    foreground: Color(0xffc9d1d9),
    gutter: Color(0xff8b949e),
    comment: Color(0xff8b949e),
    keyword: Color(0xffff7b72),
    string: Color(0xffa5d6ff),
    number: Color(0xff79c0ff),
    selection: Color(0xff163356),
    cursor: Color(0xffc9d1d9),
  ),
  BirbCodeTheme.foundation => throw ArgumentError(
    'Foundation resolves from the host theme',
  ),
};
