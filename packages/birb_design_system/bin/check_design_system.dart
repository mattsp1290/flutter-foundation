import 'dart:io';

import 'package:birb_design_system/design_system_audit.dart';

void main(List<String> arguments) {
  if (arguments.length > 1 ||
      (arguments.length == 1 && arguments.single == '--help')) {
    stderr.writeln(
      'Usage: dart run birb_design_system:check_design_system [root]',
    );
    exitCode = 64;
    return;
  }
  exitCode = writeDesignSystemAuditReport(
    Directory(arguments.singleOrNull ?? Directory.current.path),
    output: stdout,
    errors: stderr,
  );
}
