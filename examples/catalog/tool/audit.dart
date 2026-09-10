import 'dart:io';

import 'package:birb_design_system/design_system_audit.dart';

void main(List<String> arguments) {
  final root = Directory(arguments.isEmpty ? '.' : arguments.single);
  exitCode = writeDesignSystemAuditReport(root, output: stdout, errors: stderr);
}
