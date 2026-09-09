import 'dart:io';

// This workspace-root tool intentionally delegates to a member package.
// ignore: depend_on_referenced_packages
import 'package:birb_design_system/design_system_audit.dart';

void main() {
  exitCode = writeDesignSystemAuditReport(
    Directory.current,
    output: stdout,
    errors: stderr,
  );
}
