import 'package:flutter/material.dart';

import 'diagnostics_panel.dart';
import 'provider_coordinator.dart';
import 'snapshot.dart';
import 'source_coordinates.dart';

class EditorStatusBar extends StatelessWidget {
  const EditorStatusBar({
    super.key,
    required this.snapshot,
    required this.providers,
    required this.tabTraversal,
    required this.toggleTraversal,
    required this.showDiagnostics,
  });
  final BirbEditorSnapshot snapshot;
  final EditorProviderCoordinator providers;
  final bool tabTraversal;
  final VoidCallback toggleTraversal;
  final VoidCallback showDiagnostics;

  @override
  Widget build(BuildContext context) {
    final position = BirbSourceCoordinates(snapshot.source)
        .positionAt(snapshot.selection.extentOffset);
    final modifier = Theme.of(context).platform == TargetPlatform.macOS
        ? 'Cmd'
        : 'Ctrl';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorProviderStatus(
          providers: providers,
          showDiagnostics: showDiagnostics,
        ),
        Text(
          'Line ${position.line + 1}, column ${position.column + 1} · ${snapshot.readOnly ? 'Read only' : 'Editable'}',
        ),
        Semantics(
          liveRegion: true,
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: toggleTraversal,
            child: Text(
              tabTraversal
                  ? 'Tab moves focus — restore indentation'
                  : 'Tab indents · Esc enables focus traversal',
            ),
          ),
        ),
        Text(
          '$modifier+F Find · Ctrl+Space Complete · $modifier+K Hover · Shift+F10 Selection',
        ),
      ],
    );
  }
}
