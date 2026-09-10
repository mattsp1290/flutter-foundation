/// Display transformations for source text.
///
/// This is a pure string algorithm with no theme or layout dependency, so it
/// lives beside the review widgets rather than inside `BirbReviewStyle`, whose
/// documented job is resolving semantic roles from the ambient theme.
abstract final class BirbSourceText {
  /// Display columns one tab advances to. See `DESIGN.md` section 9.1.
  static const int tabSize = 4;

  /// Expands tab characters in [text] to the next [columns] display column.
  ///
  /// Flutter does not lay tabs out as columns, so display text is expanded
  /// while `Copy source line` keeps the original characters.
  ///
  /// A column is counted as one Unicode code point. Fullwidth, combining, and
  /// multi-code-point emoji text therefore reaches a tab stop that does not
  /// match its rendered advance. Such text still renders and copies correctly;
  /// only its alignment to the four-column grid is approximate. See
  /// `DESIGN.md` section 9.1.
  static String expandTabs(String text, {int columns = tabSize}) {
    if (columns < 1) {
      throw ArgumentError.value(columns, 'columns', 'must be positive');
    }
    if (!text.contains('\t')) return text;
    final buffer = StringBuffer();
    var column = 0;
    for (final rune in text.runes) {
      if (rune == 0x09) {
        final advance = columns - (column % columns);
        buffer.write(' ' * advance);
        column += advance;
      } else {
        buffer.writeCharCode(rune);
        column += 1;
      }
    }
    return buffer.toString();
  }
}
