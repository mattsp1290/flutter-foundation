import 'dart:io';

const _agentPackages = {
  'ag_ui_view_state',
  'ag_ui_widgets',
  'birb_ag_ui_widgets',
};

const _forbiddenRuntimeTerms = {
  'eino',
  'genkit',
  'rook',
  'benchy',
  'authorization',
  'credential',
  'workspace',
};

void main(List<String> arguments) {
  final root = Directory.current;
  final failures = <String>[];
  for (final package in _agentPackages) {
    final packageDirectory = Directory('${root.path}/packages/$package');
    final manifest = File('${packageDirectory.path}/pubspec.yaml');
    if (!manifest.existsSync()) {
      failures.add('missing package manifest: ${manifest.path}');
      continue;
    }
    final manifestText = manifest.readAsStringSync();
    if (!manifestText.contains('resolution: workspace')) {
      failures.add('$package must use workspace resolution');
    }
    final hasLocalPath = manifestText.split('\n').any((line) {
      final match = RegExp(r'^\s*path:\s*(\S+)\s*$').firstMatch(line);
      final value = match?.group(1);
      return value != null && (value.startsWith('/') || value.contains('..'));
    });
    if (hasLocalPath ||
        RegExp(r'^\s*dependency_overrides:', multiLine: true)
            .hasMatch(manifestText)) {
      failures.add('$package must not use path dependencies or overrides');
    }
    final library = Directory('${packageDirectory.path}/lib');
    for (final entity in library.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      final normalized = text.toLowerCase();
      for (final term in _forbiddenRuntimeTerms) {
        if (normalized.contains(term)) {
          failures.add('${entity.path}: forbidden runtime term "$term"');
        }
      }
      if (text.contains('package:') && text.contains('/src/')) {
        failures.add('${entity.path}: imports another package private src API');
      }
    }
  }

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(root.path.length + 1);
    if (relative != 'pubspec.lock' && relative.endsWith('pubspec.lock')) {
      failures.add('member lockfile is forbidden: $relative');
    }
    if (relative.endsWith('pubspec_overrides.yaml')) {
      failures.add('dependency override file is forbidden: $relative');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Agent package boundary audit failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
  }
}
