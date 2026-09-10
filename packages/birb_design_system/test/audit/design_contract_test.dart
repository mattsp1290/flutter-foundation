import 'dart:convert';
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
      '## 10. Code review components',
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
      'Implementation uses the stricter 48×48 token and direct target '
          'assertions',
      'Product progress that is determinate must expose its current value',
    ]) {
      expect(normalizedContract, contains(requirement), reason: requirement);
    }
  });

  test('keeps the contract and evidence inventories closed', () {
    expect(_tableFirstColumn(coverage, 'Contract area'), <String>{
      'Primitive palette',
      'Semantic roles and assigned surfaces',
      'Spacing, borders, radii, targets, and motion',
      'Typography',
      'Complete light and dark color schemes',
      'Theme assembly and global interaction roles',
      'Filled, elevated, outlined, text, and icon buttons',
      'Checkbox, radio, switch, slider, and chip',
      'App bar, card, dialog, divider, menu, navigation, snackbar, and tooltip',
      'Text input',
      'Preview inventory and responsive fixtures',
      'Semantic-role consumption boundary',
      'Code review components',
      'Simulated review host',
    });
    expect(_tableFirstColumn(contract, 'Component/state'), <String>{
      'scaffold',
      'app bar, ordinary',
      'app bar, separated',
      'filled/elevated button, default',
      'filled/elevated button, hovered',
      'filled/elevated button, pressed',
      'filled/elevated button, disabled',
      'outlined button, default',
      'outlined button, hovered',
      'outlined button, pressed',
      'text/icon button, default',
      'text/icon button, hovered',
      'text/icon button, pressed',
      'outlined/text/icon button, disabled',
      'input, enabled',
      'input, focused',
      'input, error',
      'input, focused+error',
      'input, disabled',
      'checkbox, selected',
      'checkbox, unselected',
      'checkbox, disabled',
      'radio, selected',
      'radio, unselected',
      'radio, disabled',
      'switch, selected',
      'switch, unselected',
      'switch, disabled',
      'slider',
      'card',
      'chip, unselected',
      'chip, selected',
      'chip, disabled',
      'dialog/menu',
      'snackbar/tooltip',
      'divider',
      'navigation bar/rail, unselected',
      'navigation bar/rail, selected',
      'text selection/cursor/handle',
    });
    expect(_tableFirstColumn(contract, 'Family'), <String>{
      'filled/elevated/outlined/text buttons',
      'icon button',
      'text input',
      'checkbox',
      'radio',
      'switch',
      'slider',
      'chip',
      'navigation bar',
      'navigation rail',
      'menu/dialog/snackbar/tooltip',
    });

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

Set<String> _tableFirstColumn(String markdown, String heading) {
  final lines = markdown.split('\n');
  final headerIndex = lines.indexWhere(
    (line) => line.startsWith('| $heading |'),
  );
  if (headerIndex == -1) {
    return const <String>{};
  }

  return lines
      .skip(headerIndex + 2)
      .takeWhile((line) => line.startsWith('|'))
      .map((line) => line.split('|')[1].trim())
      .toSet();
}

Directory _repositoryRoot() {
  final packageConfigPath = Platform.executableArguments
      .singleWhere((argument) => argument.startsWith('--packages='))
      .substring('--packages='.length);
  final configUri = Uri.file(packageConfigPath);
  final config = jsonDecode(
    File.fromUri(configUri).readAsStringSync(),
  ) as Map<String, Object?>;
  final packages = (config['packages']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final package = packages.singleWhere(
    (entry) => entry['name'] == 'birb_design_system',
  );
  final packageRoot = Directory.fromUri(
    configUri.resolve(package['rootUri']! as String),
  );
  return packageRoot.parent.parent;
}
