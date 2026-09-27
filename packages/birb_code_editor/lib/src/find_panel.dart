import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'find_model.dart';

class EditorFindPanel extends StatelessWidget {
  const EditorFindPanel({super.key, required this.model, required this.close});
  final EditorFindModel model;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
    child: ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: model.query,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Find source'),
            onChanged: (value) {
              model.query = value;
              model.current = 0;
              model.refresh();
            },
            onFieldSubmitted: (_) => model.navigate(1),
          ),
          TextFormField(
            initialValue: model.replacement,
            decoration: const InputDecoration(
              labelText: 'Replace with (literal text)',
            ),
            onChanged: (value) => model.replacement = value,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Match case'),
                selected: model.caseSensitive,
                onSelected: (value) {
                  model.caseSensitive = value;
                  model.refresh();
                },
              ),
              FilterChip(
                label: const Text('Whole word'),
                selected: model.wholeWord,
                onSelected: (value) {
                  model.wholeWord = value;
                  model.refresh();
                },
              ),
              FilterChip(
                label: const Text('Regex'),
                selected: model.regex,
                onSelected: (value) {
                  model.regex = value;
                  model.refresh();
                },
              ),
              IconButton(
                tooltip: 'Previous match',
                onPressed: model.matches.isEmpty
                    ? null
                    : () => model.navigate(-1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Next match',
                onPressed: model.matches.isEmpty
                    ? null
                    : () => model.navigate(1),
                icon: const Icon(Icons.arrow_downward),
              ),
              TextButton(
                onPressed:
                    model.controller.snapshot.capabilities.canEdit &&
                        model.matches.isNotEmpty
                    ? () => model.replace(all: false)
                    : null,
                child: const Text('Replace one'),
              ),
              TextButton(
                onPressed:
                    model.controller.snapshot.capabilities.canEdit &&
                        model.matches.isNotEmpty
                    ? () => model.replace(all: true)
                    : null,
                child: const Text('Replace all'),
              ),
              IconButton(
                tooltip: 'Close find',
                onPressed: close,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              model.invalidPattern
                  ? 'Invalid regular expression'
                  : model.matches.isEmpty
                  ? 'No matches'
                  : '${model.current + 1} of ${model.matches.length} matches',
            ),
          ),
        ],
      ),
    ),
  );
}
