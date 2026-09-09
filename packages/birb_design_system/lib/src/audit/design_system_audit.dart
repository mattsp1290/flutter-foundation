import 'dart:io';

part 'dart_token_scanner.dart';
part 'source_audit_policy.dart';
part 'source_audit_surface.dart';

final class DesignSystemViolation {
  const DesignSystemViolation({
    required this.relativePath,
    required this.line,
    required this.message,
  });

  final String relativePath;
  final int line;
  final String message;

  @override
  String toString() => '$relativePath:$line: $message';
}

final class DesignSystemAuditResult {
  const DesignSystemAuditResult({
    required this.filesScanned,
    required this.violations,
    this.invalidRoot = false,
  });

  final int filesScanned;
  final List<DesignSystemViolation> violations;
  final bool invalidRoot;

  bool get passed => violations.isEmpty;
}

DesignSystemAuditResult auditDesignSystemSources(Directory requestedRoot) {
  if (!requestedRoot.existsSync()) {
    return _failedSurface('.', 'audit root does not exist');
  }

  final Directory root;
  try {
    root = Directory(requestedRoot.resolveSymbolicLinksSync());
  } on FileSystemException catch (error) {
    return _failedSurface('.', 'audit root is unreadable: ${error.message}');
  }

  final surface = _auditSurface(root);
  final violations = [...surface.violations];
  final standaloneDesignSystem = _isStandaloneDesignSystem(root);

  for (final file in surface.files) {
    final relativePath = _relativePath(root, file);
    try {
      final tokens = _DartTokenScanner(file.readAsStringSync()).scan();
      violations.addAll(
        _tokenViolations(
          relativePath,
          tokens,
          standaloneDesignSystem: standaloneDesignSystem,
        ),
      );
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: relativePath,
          line: 1,
          message: 'source file is unreadable: ${error.message}',
        ),
      );
    }
  }

  violations.sort((left, right) {
    final pathOrder = left.relativePath.compareTo(right.relativePath);
    if (pathOrder != 0) return pathOrder;
    final lineOrder = left.line.compareTo(right.line);
    if (lineOrder != 0) return lineOrder;
    return left.message.compareTo(right.message);
  });

  return DesignSystemAuditResult(
    filesScanned: surface.files.length,
    violations: List.unmodifiable(violations),
    invalidRoot: surface.invalidRoot,
  );
}

int writeDesignSystemAuditReport(
  Directory root, {
  required StringSink output,
  required StringSink errors,
}) {
  final result = auditDesignSystemSources(root);
  if (!result.passed) {
    for (final violation in result.violations) {
      errors.writeln(violation);
    }
    errors.writeln(
      'Design-system source audit failed '
      '(${result.violations.length} violation(s)).',
    );
    return result.invalidRoot ? 64 : 1;
  }

  output.writeln(
    'Design-system source audit passed (${result.filesScanned} files scanned).',
  );
  return 0;
}

DesignSystemAuditResult _failedSurface(String path, String message) {
  return DesignSystemAuditResult(
    filesScanned: 0,
    violations: List.unmodifiable([
      DesignSystemViolation(relativePath: path, line: 1, message: message),
    ]),
    invalidRoot: true,
  );
}
