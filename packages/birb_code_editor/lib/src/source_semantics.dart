import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controller.dart';
import 'guarded_engine.dart';
import 'snapshot.dart';

/// Flutter web needs a semantic text field to create its accessible DOM input.
class EditorSourceSemantics extends StatelessWidget {
  const EditorSourceSemantics({
    super.key,
    required this.controller,
    required this.engine,
    required this.focus,
    required this.label,
    required this.child,
  });

  final BirbEditorController controller;
  final GuardedEditorEngine engine;
  final FocusNode focus;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    var expectedGeneration = snapshot.generation;
    bool isCurrent() =>
        engine.isCurrent() &&
        controller.snapshot.documentId == snapshot.documentId &&
        controller.snapshot.generation == expectedGeneration;
    void move(bool forward, bool word, bool extend) {
      if (!isCurrent()) return;
      if (word) {
        if (forward) {
          extend
              ? engine.extendSelectionToWordBoundaryForward()
              : engine.moveCursorToWordBoundaryForward();
        } else {
          extend
              ? engine.extendSelectionToWordBoundaryBackward()
              : engine.moveCursorToWordBoundaryBackward();
        }
      } else {
        final direction = forward ? AxisDirection.right : AxisDirection.left;
        extend
            ? engine.extendSelection(direction)
            : engine.moveCursor(direction);
      }
    }

    final editable =
        snapshot.capabilities.canEdit && snapshot.composing.isCollapsed;
    return _SelectionSemantics(
      selection: snapshot.selection,
      properties: SemanticsProperties(
        label: label,
        value: snapshot.source,
        textField: true,
        multiline: true,
        enabled: true,
        readOnly: snapshot.readOnly,
        focused: focus.hasFocus,
        onFocus: () {
          if (isCurrent()) focus.requestFocus();
        },
        onSetSelection: (selection) {
          if (isCurrent()) controller.setSelection(selection);
        },
        onMoveCursorForwardByCharacter: (extend) => move(true, false, extend),
        onMoveCursorBackwardByCharacter: (extend) => move(false, false, extend),
        onMoveCursorForwardByWord: (extend) => move(true, true, extend),
        onMoveCursorBackwardByWord: (extend) => move(false, true, extend),
        onSetText: editable
            ? (value) {
                if (!isCurrent()) return;
                final current = controller.snapshot;
                final result = controller.applyEdits(
                  expectedDocumentId: current.documentId,
                  expectedGeneration: current.generation,
                  edits: [
                    BirbEditorEdit(
                      range: TextRange(start: 0, end: current.source.length),
                      text: value,
                    ),
                  ],
                );
                // A second valid semantic event may arrive before the next
                // frame. Only this callback's own edits advance its provenance.
                if (result == BirbEditorEditResult.applied) {
                  expectedGeneration = controller.snapshot.generation;
                }
              }
            : null,
        onCopy: () {
          if (isCurrent()) unawaited(controller.copy());
        },
        onCut: editable
            ? () {
                if (isCurrent()) unawaited(controller.cut());
              }
            : null,
        onPaste: editable
            ? () {
                if (isCurrent()) unawaited(controller.paste());
              }
            : null,
      ),
      child: child,
    );
  }
}

/// Adds the selection omitted by the pinned SDK's Semantics widget to the
/// same text-field node, retaining Flutter's standard semantic action wiring.
class _SelectionSemantics extends Semantics {
  const _SelectionSemantics({
    required this.selection,
    required super.properties,
    required super.child,
  }) : super.fromProperties(container: true, explicitChildNodes: true);
  final TextSelection selection;

  @override
  _RenderSelectionSemantics createRenderObject(BuildContext context) =>
      _RenderSelectionSemantics(
        selection,
        properties: properties,
        textDirection: Directionality.maybeOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSelectionSemantics renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.selection = selection;
  }
}

class _RenderSelectionSemantics extends RenderSemanticsAnnotations {
  _RenderSelectionSemantics(
    this._selection, {
    required super.properties,
    super.textDirection,
  }) : super(container: true, explicitChildNodes: true);
  TextSelection _selection;

  set selection(TextSelection value) {
    if (value == _selection) return;
    _selection = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.textSelection = _selection;
  }
}
