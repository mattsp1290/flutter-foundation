import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime barrel does not expose private or preview APIs', () async {
    final packageConfigUri = Uri.file(
      Platform.executableArguments
          .singleWhere((argument) => argument.startsWith('--packages='))
          .substring('--packages='.length),
    );
    final packageConfig = jsonDecode(
      File.fromUri(packageConfigUri).readAsStringSync(),
    ) as Map<String, Object?>;
    final packages = packageConfig['packages']! as List<Object?>;
    final packageRoot = _packageRoot(
      packageConfigUri,
      packages,
      'birb_design_system',
    );
    final flutterRoot = _packageRoot(
      packageConfigUri,
      packages,
      'flutter',
    ).parent.parent;
    final dart = File.fromUri(
      flutterRoot.uri.resolve('bin/cache/dart-sdk/bin/dart'),
    );
    final probe = File.fromUri(
      packageRoot.uri.resolve('.dart_tool/palette_public_api_probe.dart'),
    );

    try {
      probe.writeAsStringSync('''
import 'package:birb_design_system/birb_design_system.dart';

void main() {
  print(BirbPalette.black);
  print(BirbThemeHarness);
}
''');
      final result = await Process.run(dart.path, <String>[
        'analyze',
        '--format=machine',
        probe.path,
      ]);
      final diagnostics = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, isNot(0), reason: diagnostics);
      expect(diagnostics, contains('UNDEFINED_IDENTIFIER'));
      expect(diagnostics, contains("Undefined name 'BirbPalette'"));
      expect(diagnostics, contains("Undefined name 'BirbThemeHarness'"));
    } finally {
      if (probe.existsSync()) {
        probe.deleteSync();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Directory _packageRoot(
  Uri packageConfigUri,
  List<Object?> packages,
  String packageName,
) {
  final package = packages.cast<Map<String, Object?>>().singleWhere(
    (entry) => entry['name'] == packageName,
  );
  return Directory.fromUri(
    packageConfigUri.resolve(package['rootUri']! as String),
  );
}
