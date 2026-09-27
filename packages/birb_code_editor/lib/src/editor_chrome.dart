import 'package:flutter/material.dart';

import 'snapshot.dart';

enum EditorCommand {
  undo('Undo'),
  redo('Redo'),
  find('Find and replace'),
  copy('Copy'),
  cut('Cut'),
  paste('Paste'),
  selectAll('Select all'),
  indent('Indent'),
  outdent('Outdent'),
  comment('Toggle Go comment'),
  fold('Fold selected lines'),
  unfold('Unfold all'),
  wrap('Toggle wrap'),
  smaller('Smaller code'),
  larger('Larger code'),
  complete('Show completions'),
  hover('Show hover'),
  diagnostics('Refresh diagnostics');

  const EditorCommand(this.label);
  final String label;
}

class EditorChrome extends StatelessWidget {
  const EditorChrome({
    super.key,
    required this.snapshot,
    required this.label,
    required this.wrap,
    required this.fontScale,
    required this.hasProvider,
    required this.invoke,
  });
  final BirbEditorSnapshot snapshot;
  final String label;
  final bool wrap;
  final double fontScale;
  final bool hasProvider;
  final ValueChanged<EditorCommand> invoke;

  bool _enabled(EditorCommand command) => switch (command) {
    EditorCommand.undo => snapshot.capabilities.canUndo,
    EditorCommand.redo => snapshot.capabilities.canRedo,
    EditorCommand.copy => snapshot.capabilities.canCopy,
    EditorCommand.cut ||
    EditorCommand.paste ||
    EditorCommand.indent ||
    EditorCommand.outdent ||
    EditorCommand.comment =>
      snapshot.capabilities.canEdit && snapshot.composing.isCollapsed,
    EditorCommand.smaller => fontScale > .75,
    EditorCommand.larger => fontScale < 2,
    EditorCommand.complete ||
    EditorCommand.hover ||
    EditorCommand.diagnostics => hasProvider,
    _ => true,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          PopupMenuButton<EditorCommand>(
            tooltip: 'Editor commands',
            onSelected: invoke,
            itemBuilder: (_) => [
              for (final command in EditorCommand.values)
                PopupMenuItem(
                  value: command,
                  enabled: _enabled(command),
                  height: 48,
                  child: Text(command.label),
                ),
            ],
          ),
        ],
      ),
      Wrap(
        children: [
          for (final (command, icon) in [
            (EditorCommand.undo, Icons.undo),
            (EditorCommand.redo, Icons.redo),
            (EditorCommand.find, Icons.search),
            (EditorCommand.wrap, Icons.wrap_text),
          ])
            IconButton(
              tooltip: command == EditorCommand.wrap
                  ? (wrap ? 'Disable wrap' : 'Enable wrap')
                  : command.label,
              isSelected: command == EditorCommand.wrap ? wrap : null,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: _enabled(command) ? () => invoke(command) : null,
              icon: Icon(icon),
            ),
        ],
      ),
    ],
  );
}
