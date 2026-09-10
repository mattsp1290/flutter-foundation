import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandTabs', () {
    test('advances to the next four-column stop', () {
      expect(BirbSourceText.expandTabs('\ta'), '    a');
      expect(BirbSourceText.expandTabs('a\tb'), 'a   b');
      expect(BirbSourceText.expandTabs('abc\td'), 'abc d');
      expect(BirbSourceText.expandTabs('abcd\te'), 'abcd    e');
      expect(BirbSourceText.expandTabs('\t\tx'), '        x');
    });

    test('leaves text without tabs identical', () {
      const text = 'naïve — 🐦 — <b>literal</b>';
      expect(BirbSourceText.expandTabs(text), same(text));
    });

    test('honours a custom tab size and rejects a non-positive one', () {
      expect(BirbSourceText.expandTabs('a\tb', columns: 2), 'a b');
      expect(
        () => BirbSourceText.expandTabs('a\tb', columns: 0),
        throwsArgumentError,
      );
    });

    test('counts a surrogate pair as one display column', () {
      expect(BirbSourceText.expandTabs('🐦\tx'), '🐦   x');
    });
  });
}
