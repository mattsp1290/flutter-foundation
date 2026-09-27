import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main() async {
  final root = Directory.current;
  final directory = Directory('${root.path}/testdata/ag_ui');
  final decoded = jsonDecode(
    await File('${directory.path}/manifest.json').readAsString(),
  );
  if (decoded is! Map || decoded['fixtures'] is! Map) {
    throw StateError('Invalid fixture manifest');
  }
  final fixtures = (decoded['fixtures'] as Map).cast<String, dynamic>();
  final actual = await directory
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.sse'))
      .map((entity) => entity.uri.pathSegments.last)
      .toList();
  if (actual.toSet().length != fixtures.length ||
      !actual.toSet().containsAll(fixtures.keys)) {
    throw StateError('Fixture inventory differs from manifest');
  }
  for (final entry in fixtures.entries) {
    final file = File('${directory.path}/${entry.key}');
    if (await file.length() > 1024 * 1024 ||
        await digestFile(file) != entry.value) {
      throw StateError('Fixture ${entry.key} has an invalid hash or size');
    }
  }
}

Future<String> digestFile(File file) async {
  return (await sha256.bind(file.openRead()).first).toString();
}
