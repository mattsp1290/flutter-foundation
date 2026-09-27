import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'controller.dart';

/// Uses the engine's right-click/selection anchor, while the view owns the UI.
class EditorSelectionToolbarBridge implements SelectionToolbarController {
  EditorSelectionToolbarBridge({required this.showAt, required this.dismiss});
  final ValueChanged<Offset> showAt;
  final VoidCallback dismiss;

  @override
  void hide(BuildContext context) => dismiss();

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) => showAt(anchors.primaryAnchor);
}

class EditorSelectionToolbar extends StatelessWidget {
  const EditorSelectionToolbar({
    super.key,
    required this.controller,
    required this.dismiss,
  });
  final BirbEditorController controller;
  final VoidCallback dismiss;

  @override
  Widget build(BuildContext context) {
    final editable =
        controller.snapshot.capabilities.canEdit &&
        controller.snapshot.composing.isCollapsed;
    return ListView(
      children: [
        TextButton(
          onPressed: controller.snapshot.capabilities.canCopy
              ? () {
                  controller.copy();
                  dismiss();
                }
              : null,
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: editable
              ? () {
                  controller.cut();
                  dismiss();
                }
              : null,
          child: const Text('Cut'),
        ),
        TextButton(
          onPressed: editable
              ? () {
                  controller.paste();
                  dismiss();
                }
              : null,
          child: const Text('Paste'),
        ),
        TextButton(
          onPressed: () {
            controller.selectAll();
            dismiss();
          },
          child: const Text('Select all'),
        ),
      ].map((button) => SizedBox(height: 48, child: button)).toList(),
    );
  }
}
