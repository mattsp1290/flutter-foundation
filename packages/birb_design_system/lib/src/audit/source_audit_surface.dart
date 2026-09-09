part of 'design_system_audit.dart';

_AuditSurface _auditSurface(Directory root) {
  final files = <File>[];
  final violations = <DesignSystemViolation>[];
  final libDirectories = _libDirectories(root, violations);
  final invalidRoot = libDirectories.isEmpty && violations.isEmpty;
  if (invalidRoot) {
    violations.add(
      const DesignSystemViolation(
        relativePath: '.',
        line: 1,
        message: 'audit root contains no package or example lib directories',
      ),
    );
  }

  for (final directory in libDirectories) {
    try {
      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity);
        } else if (entity is Link) {
          violations.add(
            DesignSystemViolation(
              relativePath: _relativeEntityPath(root, entity.path),
              line: 1,
              message: 'symbolic links are forbidden in audited source paths',
            ),
          );
        }
      }
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: _relativeEntityPath(root, directory.path),
          line: 1,
          message: 'scan root is unreadable: ${error.message}',
        ),
      );
    }
  }

  files.sort((left, right) => left.path.compareTo(right.path));
  return _AuditSurface(
    files: files,
    violations: violations,
    invalidRoot: invalidRoot,
  );
}

List<Directory> _libDirectories(
  Directory root,
  List<DesignSystemViolation> violations,
) {
  final result = <Directory>[];
  final directLib = Directory('${root.path}${Platform.pathSeparator}lib');
  final directType = FileSystemEntity.typeSync(
    directLib.path,
    followLinks: false,
  );
  if (directType == FileSystemEntityType.link) {
    violations.add(_symlinkViolation(root, directLib.path));
  } else if (directType == FileSystemEntityType.directory) {
    result.add(directLib);
  }

  for (final group in ['packages', 'examples']) {
    final parent = Directory('${root.path}${Platform.pathSeparator}$group');
    final parentType = FileSystemEntity.typeSync(
      parent.path,
      followLinks: false,
    );
    if (parentType == FileSystemEntityType.link) {
      violations.add(_symlinkViolation(root, parent.path));
      continue;
    }
    if (parentType != FileSystemEntityType.directory) continue;

    try {
      for (final entity in parent.listSync(followLinks: false)) {
        if (entity is Link) {
          violations.add(_symlinkViolation(root, entity.path));
          continue;
        }
        if (entity is! Directory) continue;
        try {
          for (final child in entity.listSync(followLinks: false)) {
            if (_basename(child.path) != 'lib') continue;
            if (child is Link) {
              violations.add(_symlinkViolation(root, child.path));
            } else if (child is Directory) {
              result.add(child);
            }
          }
        } on FileSystemException catch (error) {
          violations.add(
            DesignSystemViolation(
              relativePath: _relativeEntityPath(root, entity.path),
              line: 1,
              message: 'scan root is unreadable: ${error.message}',
            ),
          );
        }
      }
    } on FileSystemException catch (error) {
      violations.add(
        DesignSystemViolation(
          relativePath: group,
          line: 1,
          message: 'scan root is unreadable: ${error.message}',
        ),
      );
    }
  }
  return result;
}

String _basename(String path) {
  final normalized = path.endsWith(Platform.pathSeparator)
      ? path.substring(0, path.length - Platform.pathSeparator.length)
      : path;
  final separator = normalized.lastIndexOf(Platform.pathSeparator);
  return separator == -1 ? normalized : normalized.substring(separator + 1);
}

DesignSystemViolation _symlinkViolation(Directory root, String path) {
  return DesignSystemViolation(
    relativePath: _relativeEntityPath(root, path),
    line: 1,
    message: 'symbolic links are forbidden in audited source paths',
  );
}

String _relativePath(Directory root, File file) =>
    _relativeEntityPath(root, file.absolute.path);

String _relativeEntityPath(Directory root, String entityPath) {
  final rootPath = root.absolute.path;
  final filePath = File(entityPath).absolute.path;
  final prefix = rootPath.endsWith(Platform.pathSeparator)
      ? rootPath
      : '$rootPath${Platform.pathSeparator}';
  if (!filePath.startsWith(prefix)) {
    throw ArgumentError.value(
      entityPath,
      'entity',
      'Source path escapes audit root',
    );
  }
  return filePath
      .substring(prefix.length)
      .replaceAll(Platform.pathSeparator, '/');
}

final class _AuditSurface {
  const _AuditSurface({
    required this.files,
    required this.violations,
    required this.invalidRoot,
  });

  final List<File> files;
  final List<DesignSystemViolation> violations;
  final bool invalidRoot;
}
