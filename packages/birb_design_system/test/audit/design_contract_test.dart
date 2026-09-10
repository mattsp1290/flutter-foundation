import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = _repositoryRoot();
  final contract = File('${repositoryRoot.path}/DESIGN.md').readAsStringSync();
  final coverage = File(
    '${repositoryRoot.path}/docs/verification/design-contract-coverage.md',
  ).readAsStringSync();

  test('publishes the complete design contract at repository scope', () {
    expect(
      contract,
      matches(
        RegExp(
          r'governs authored user-interface work under\s+'
          r'`packages/birb_design_system/` and `examples/catalog/`',
        ),
      ),
    );
    expect(contract, isNot(contains('work under `ui/`')));

    for (final heading in <String>[
      '## 3. Primitive palette',
      '## 4. Semantic color contract',
      '### Complete Material `ColorScheme` mapping',
      '### Custom semantic extension mapping',
      '### Assigned surface sets',
      '## 5. Foundation tokens',
      '## 6. Material component recipes',
      '### Shared interaction roles',
      '### Flutter 3.47.1 mechanisms',
      '## 8. Accessibility and responsive requirements',
      '## 9. Contribution checklist',
    ]) {
      expect(contract, contains(heading), reason: heading);
    }
  });

  test('keeps semantic and accessibility requirements explicit', () {
    final normalizedContract = contract.replaceAll(RegExp(r'\s+'), ' ');
    for (final requirement in <String>[
      '| `primary` | `blue` | `cyan` |',
      '| `surface` | `white` | `black` |',
      '| success | `green` / `black` | `lime` / `black` |',
      '| semantic `focus` | All surfaces | All surfaces |',
      'Normal text reaches 4.5:1',
      'meaningful non-text boundaries and states reach 3:1',
      'Status, error, selection, and progress retain a color-independent cue.',
      'Keyboard access and focus order remain intact on web and desktop.',
      'implementation uses the stricter 48×48 token.',
    ]) {
      expect(normalizedContract, contains(requirement), reason: requirement);
    }
  });

  test('maps every documented component family to committed evidence', () {
    for (final family in <String>[
      'Filled, elevated, outlined, text, and icon buttons',
      'Checkbox, radio, switch, slider, and chip',
      'App bar, card, dialog, divider, menu, navigation, snackbar, and tooltip',
      'Text input',
      'Preview inventory and responsive fixtures',
    ]) {
      expect(coverage, contains('| $family |'), reason: family);
    }

    final referencedPaths = RegExp(r'`((?:lib|test)/[^`]+\.(?:dart|md))`')
        .allMatches(coverage)
        .map((match) => match.group(1)!)
        .toSet();
    expect(referencedPaths, isNotEmpty);

    final packageRoot = Directory(
      '${repositoryRoot.path}/packages/birb_design_system',
    );
    for (final path in referencedPaths) {
      expect(
        File('${packageRoot.path}/$path').existsSync(),
        isTrue,
        reason: 'Missing contract evidence: $path',
      );
    }
  });
}

Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !Directory('${directory.path}/packages/birb_design_system')
          .existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Could not locate the repository root.');
    }
    directory = parent;
  }
  return directory;
}
