import 'dart:convert';
import 'dart:io';

import 'package:birb_design_system/design_system_audit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('design-system source audit', () {
    test('allows the private palette and compliant package sources', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/birb_design_system/lib/src/foundation/birb_palette.dart',
        'abstract final class BirbPalette { '
            'static const black = Color(0xFF1A1C2C); }\n',
      );
      _write(
        root,
        'packages/birb_design_system/lib/birb_design_system.dart',
        "export 'src/tokens/birb_tokens.dart';\n",
      );
      _write(
        root,
        'examples/catalog/lib/main.dart',
        "const message = 'Color(0) is inert string text';\n",
      );

      final result = auditDesignSystemSources(root);

      expect(result.filesScanned, 3);
      expect(result.violations, isEmpty);
    });

    final forbiddenCases = <String, String>{
      'Color(0xFF000000)': 'direct Color construction',
      'ui.Color(0xFF000000)': 'direct Color construction',
      'Color.new(0xFF000000)': 'direct Color construction',
      'Color.new': 'direct Color construction',
      'Color.fromARGB(255, 0, 0, 0)': 'direct Color construction',
      'Color.fromARGB.call(255, 0, 0, 0)': 'direct Color construction',
      'Color.fromRGBO(0, 0, 0, 1)': 'direct Color construction',
      'Color.from(alpha: 1, red: 0, green: 0, blue: 0)':
          'direct Color construction',
      'Color.fromUnchecked(alpha: 1, red: 0, green: 0, blue: 0)':
          'direct Color construction',
      'Color.lerp(first, second, 0.5)': 'Color.lerp transformation',
      'Color.lerp': 'Color.lerp transformation',
      'Color.alphaBlend(first, second)': 'Color.alphaBlend transformation',
      'Color.alphaBlend.call(first, second)': 'Color.alphaBlend transformation',
      'HSLColor.fromColor(color)': 'HSLColor usage',
      'HSVColor.fromColor(color)': 'HSVColor usage',
      'ColorSwatch<int>(0, values)': 'ColorSwatch usage',
      'MaterialColor(0, values)': 'MaterialColor usage',
      'MaterialAccentColor(0, values)': 'MaterialAccentColor usage',
      'Colors.red': 'Material Colors palette usage',
      'CupertinoColors.activeBlue': 'CupertinoColors palette usage',
      'CupertinoDynamicColor.withBrightness(color: first, darkColor: second)':
          'CupertinoDynamicColor usage',
      'color.withAlpha(128)': 'authored color transformation',
      'color.withOpacity(0.5)': 'authored color transformation',
      'color.withOpacity': 'authored color transformation',
      'color.withValues(alpha: 0.5)': 'authored color transformation',
      'color.withRed(128)': 'authored color transformation',
      'color.withRed': 'authored color transformation',
      'color.withGreen(128)': 'authored color transformation',
      'color.withGreen': 'authored color transformation',
      'color.withBlue(128)': 'authored color transformation',
      'color.withBlue': 'authored color transformation',
      'ColorScheme.fromSeed(seedColor: color)': 'generated ColorScheme usage',
      'ColorScheme.fromSeed': 'generated ColorScheme usage',
      'LinearGradient(colors: colors)': 'LinearGradient usage',
      'RadialGradient(colors: colors)': 'RadialGradient usage',
      'SweepGradient(colors: colors)': 'SweepGradient usage',
      'BackdropFilter(filter: filter)': 'BackdropFilter usage',
    };

    for (final MapEntry(key: source, value: message)
        in forbiddenCases.entries) {
      test('rejects $source', () {
        final root = _fixtureRoot();
        _write(
          root,
          'packages/app/lib/example.dart',
          'void f() { $source; }\n',
        );

        expect(
          _violations(root),
          contains('packages/app/lib/example.dart:1:$message'),
        );
      });
    }

    test('handles multiline forms, interpolation, comments, and strings', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/app/lib/example.dart',
        r"""// Color(0) and Colors.red are comments.
const inert = 'LinearGradient(colors: [])';
const raw = r'${Color(0xFF000000)}';
final direct = Color
  .
  fromARGB
  (255, 0, 0, 0);
final generated = '''
${ColorScheme.fromSeed(seedColor: color)}
''';
final nested = '${condition ? '${BirbPalette.blue}' : ''}';
""",
      );

      expect(_violations(root), <String>[
        'packages/app/lib/example.dart:4:direct Color construction',
        'packages/app/lib/example.dart:9:generated ColorScheme usage',
        'packages/app/lib/example.dart:11:private BirbPalette boundary violation',
      ]);
    });

    test('ignores nested comments and escaped interpolation', () {
      final root = _fixtureRoot();
      _write(root, 'lib/example.dart', r"""
/* Color(0) /* Colors.red */ ColorScheme.fromSeed(seedColor: color) */
const escaped = '\${Color(0xFF000000)}';
const inert = '''BackdropFilter(filter: filter)''';
""");

      expect(_violations(root), isEmpty);
    });

    test('scans direct and workspace lib directories together', () {
      final root = _fixtureRoot();
      _write(root, 'lib/root.dart', 'void rootEntry() {}\n');
      _write(root, 'packages/app/lib/app.dart', 'void appEntry() {}\n');

      final result = auditDesignSystemSources(root);

      expect(result.filesScanned, 2);
      expect(result.violations, isEmpty);
    });

    test('rejects palette imports, references, and conditional exports', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/app/lib/feature.dart',
        "import\n  'package:birb_design_system/src/foundation/"
            "birb_palette.dart';\nfinal value = BirbPalette.blue;\n",
      );
      _write(
        root,
        'packages/birb_design_system/lib/leak.dart',
        "export 'safe.dart'\n"
            "  if (dart.library.io) 'src/foundation/birb_palette.dart';\n",
      );

      expect(
        _violations(root),
        containsAll(<String>[
          'packages/app/lib/feature.dart:1:'
              'private BirbPalette boundary violation',
          'packages/app/lib/feature.dart:3:'
              'private BirbPalette boundary violation',
          'packages/birb_design_system/lib/leak.dart:1:'
              'private palette export is forbidden',
        ]),
      );
    });

    test('does not grant standalone consumers design-system exemptions', () {
      final root = _fixtureRoot();
      _write(root, 'pubspec.yaml', 'name: consumer_app\n');
      _write(
        root,
        'lib/src/feature.dart',
        "import 'package:birb_design_system/src/foundation/"
            "birb_palette.dart';\nfinal value = BirbPalette.blue;\n",
      );
      _write(
        root,
        'lib/src/foundation/birb_palette.dart',
        'final value = Color(0xFF000000);\n',
      );

      expect(
        _violations(root),
        containsAll(<String>[
          'lib/src/feature.dart:1:private BirbPalette boundary violation',
          'lib/src/feature.dart:2:private BirbPalette boundary violation',
          'lib/src/foundation/birb_palette.dart:1:direct Color construction',
        ]),
      );
    });

    test('recognizes a standalone birb_design_system package', () {
      final root = _fixtureRoot();
      _write(root, 'pubspec.yaml', 'name: birb_design_system\n');
      _write(
        root,
        'lib/src/foundation/birb_palette.dart',
        'final value = Color(0xFF000000);\n',
      );
      _write(root, 'lib/src/tokens.dart', 'final value = BirbPalette.blue;\n');

      expect(_violations(root), isEmpty);
    });

    test('rejects encoded and escaped directive boundary bypasses', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/app/lib/palette.dart',
        "export 'package:birb_design_system/src/foundation/"
            "birb_%70alette.dart';\n",
      );
      _write(
        root,
        'packages/birb_design_system/lib/encoded_barrel.dart',
        "export 'design_system_%61udit.dart';\n"
            "export 'src/%61udit/design_system_audit.dart';\n",
      );
      _write(
        root,
        'packages/app/lib/escaped.dart',
        r"export 'birb_\x70alette.dart';"
            '\n',
      );

      expect(
        _violations(root),
        containsAll(<String>[
          'packages/app/lib/palette.dart:1:private palette export is forbidden',
          'packages/birb_design_system/lib/encoded_barrel.dart:1:'
              'audit APIs may only be exported by design_system_audit.dart',
          'packages/birb_design_system/lib/encoded_barrel.dart:2:'
              'audit APIs may only be exported by design_system_audit.dart',
          'packages/app/lib/escaped.dart:1:'
              'escaped directive URIs are forbidden',
        ]),
      );
    });

    test('keeps file-system audit APIs behind the dedicated barrel', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/birb_design_system/lib/birb_design_system.dart',
        "export 'design_system_audit.dart';\n",
      );

      expect(_violations(root), <String>[
        'packages/birb_design_system/lib/birb_design_system.dart:1:'
            'audit APIs may only be exported by design_system_audit.dart',
      ]);
    });

    test('rejects audit exports from an intermediate runtime barrel', () {
      final root = _fixtureRoot();
      _write(
        root,
        'packages/birb_design_system/lib/birb_design_system.dart',
        "export 'tooling.dart';\n",
      );
      _write(
        root,
        'packages/birb_design_system/lib/tooling.dart',
        "export 'design_system_audit.dart';\n",
      );
      _write(
        root,
        'packages/birb_design_system/lib/design_system_audit.dart',
        "export 'src/audit/design_system_audit.dart';\n",
      );

      expect(_violations(root), <String>[
        'packages/birb_design_system/lib/tooling.dart:1:'
            'audit APIs may only be exported by design_system_audit.dart',
      ]);
    });

    test('rejects symlinks at package, lib, and nested source boundaries', () {
      final root = _fixtureRoot();
      final target = Directory.fromUri(root.uri.resolve('targets/source/'))
        ..createSync(recursive: true);
      _write(root, 'targets/source/linked.dart', 'void f() {}\n');
      Directory.fromUri(root.uri.resolve('packages/')).createSync();
      Link.fromUri(root.uri.resolve('packages/linked_package'))
          .createSync(target.path);
      final package = Directory.fromUri(root.uri.resolve('examples/app/'))
        ..createSync(recursive: true);
      Link.fromUri(package.uri.resolve('lib')).createSync(target.path);
      final lib = Directory.fromUri(root.uri.resolve('packages/real/lib/'))
        ..createSync(recursive: true);
      Link.fromUri(lib.uri.resolve('linked.dart'))
          .createSync(File.fromUri(target.uri.resolve('linked.dart')).path);

      expect(
        _violations(root),
        containsAll(<String>[
          'examples/app/lib:1:'
              'symbolic links are forbidden in audited source paths',
          'packages/linked_package:1:'
              'symbolic links are forbidden in audited source paths',
          'packages/real/lib/linked.dart:1:'
              'symbolic links are forbidden in audited source paths',
        ]),
      );
    }, skip: Platform.isWindows ? 'Unix symlink fixture.' : false);

    test('rejects direct-lib and workspace-group symlinks', () {
      final root = _fixtureRoot();
      final target = Directory.fromUri(root.uri.resolve('target/'))
        ..createSync();
      Link('${root.path}${Platform.pathSeparator}lib').createSync(target.path);
      Link('${root.path}${Platform.pathSeparator}packages')
          .createSync(target.path);

      expect(
        _violations(root),
        containsAll(<String>[
          'lib:1:symbolic links are forbidden in audited source paths',
          'packages:1:'
              'symbolic links are forbidden in audited source paths',
        ]),
      );
    }, skip: Platform.isWindows ? 'Unix symlink fixture.' : false);

    test('fails closed for unreadable package directories and Dart files', () {
      final root = _fixtureRoot();
      final closedPackage = Directory.fromUri(
        root.uri.resolve('packages/closed/'),
      )..createSync(recursive: true);
      final closedFile = _write(
        root,
        'packages/readable/lib/closed.dart',
        'void example() {}\n',
      );
      Process.runSync('chmod', <String>['000', closedPackage.path]);
      Process.runSync('chmod', <String>['000', closedFile.path]);
      addTearDown(() {
        Process.runSync('chmod', <String>['700', closedPackage.path]);
        Process.runSync('chmod', <String>['600', closedFile.path]);
      });

      final violations = _violations(root);
      expect(
        violations,
        contains(startsWith('packages/closed:1:scan root is unreadable:')),
      );
      expect(
        violations,
        contains(
          startsWith(
            'packages/readable/lib/closed.dart:1:'
            'source file is unreadable:',
          ),
        ),
      );
    }, skip: Platform.isWindows ? 'POSIX permission fixture.' : false);

    test('reports missing and empty audit roots', () {
      final root = _fixtureRoot();
      final missing = Directory.fromUri(root.uri.resolve('missing/'));

      expect(auditDesignSystemSources(missing).invalidRoot, isTrue);
      expect(_violations(missing), <String>['.:1:audit root does not exist']);
      expect(_violations(root), <String>[
        '.:1:audit root contains no package or example lib directories',
      ]);
      expect(auditDesignSystemSources(root).invalidRoot, isTrue);
    });

    test(
      'CLI returns 0, 1, and 64 for pass, violations, and invalid root',
      () async {
        final root = _fixtureRoot();
        _write(root, 'lib/main.dart', 'void main() {}\n');
        expect((await _runCli(root)).exitCode, 0);

        _write(root, 'lib/main.dart', 'final value = Colors.red;\n');
        final failed = await _runCli(root);
        expect(failed.exitCode, 1);
        expect(failed.stderr, contains('lib/main.dart:1:'));

        final missing = Directory.fromUri(root.uri.resolve('missing/'));
        final invalid = await _runCli(missing);
        expect(invalid.exitCode, 64);
        expect(invalid.stderr, contains('audit root does not exist'));

        final empty = _fixtureRoot();
        final emptyResult = await _runCli(empty);
        expect(emptyResult.exitCode, 64);
        expect(
          emptyResult.stderr,
          contains('audit root contains no package or example lib directories'),
        );
      },
    );

    test('real repository production sources pass', () {
      final result = auditDesignSystemSources(_repositoryRoot());

      expect(result.filesScanned, greaterThan(0));
      expect(result.violations, isEmpty);
    });
  });
}

Directory _fixtureRoot() {
  final root = Directory.systemTemp.createTempSync('birb_design_audit_');
  addTearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  return root;
}

File _write(Directory root, String relativePath, String contents) {
  final file = File.fromUri(root.uri.resolve(relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return file;
}

List<String> _violations(Directory root) =>
    auditDesignSystemSources(root).violations
        .map((item) => '${item.relativePath}:${item.line}:${item.message}')
        .toList();

Future<ProcessResult> _runCli(Directory root) {
  final repository = _repositoryRoot();
  final flutterRoot = _flutterPackageRoot().parent.parent;
  final dart = File.fromUri(
    flutterRoot.uri.resolve('bin/cache/dart-sdk/bin/dart'),
  );
  return Process.run(dart.path, <String>[
    'run',
    File.fromUri(
      repository.uri.resolve(
        'packages/birb_design_system/bin/check_design_system.dart',
      ),
    ).path,
    root.path,
  ], workingDirectory: repository.path);
}

Directory _repositoryRoot() {
  final packageRoot = _packageRoot('birb_design_system');
  return packageRoot.parent.parent;
}

Directory _flutterPackageRoot() => _packageRoot('flutter');

Directory _packageRoot(String packageName) {
  final packageConfigPath = Platform.executableArguments
      .singleWhere((argument) => argument.startsWith('--packages='))
      .substring('--packages='.length);
  final configUri = Uri.file(packageConfigPath);
  final config = jsonDecode(
    File.fromUri(configUri).readAsStringSync(),
  ) as Map<String, Object?>;
  final packages = (config['packages']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final package = packages.singleWhere((entry) => entry['name'] == packageName);
  final rootUri = package['rootUri']! as String;
  return Directory.fromUri(configUri.resolve(rootUri));
}
