import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'snapshot.dart';

/// Flutter web needs a semantic text field to create its accessible DOM input.
class EditorSourceSemantics extends StatelessWidget {
  const EditorSourceSemantics({
    super.key,
    required this.controller,
    required this.focus,
    required this.label,
    required this.child,
  });

  final BirbEditorController controller;
  final FocusNode focus;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final editable =
        snapshot.capabilities.canEdit && snapshot.composing.isCollapsed;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      value: snapshot.source,
      textField: true,
      multiline: true,
      enabled: true,
      readOnly: snapshot.readOnly,
      focusable: true,
      focused: focus.hasFocus,
      onFocus: focus.requestFocus,
      onSetSelection: controller.setSelection,
      onSetText: editable
          ? (value) {
              final current = controller.snapshot;
              controller.applyEdits(
                expectedDocumentId: current.documentId,
                expectedGeneration: current.generation,
                edits: [
                  BirbEditorEdit(
                    range: TextRange(start: 0, end: current.source.length),
                    text: value,
                  ),
                ],
              );
            }
          : null,
      onCopy: () => unawaited(controller.copy()),
      onCut: editable ? () => unawaited(controller.cut()) : null,
      onPaste: editable ? () => unawaited(controller.paste()) : null,
      child: child,
    );
  }
}
