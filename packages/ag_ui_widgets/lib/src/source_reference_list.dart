import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:flutter/material.dart';

/// Controlled presentation of opaque, host-authorized source references.
final class SourceReferenceList extends StatelessWidget {
  const SourceReferenceList({required this.references, this.onOpen, super.key});

  final List<SourceReferenceView> references;
  final ValueChanged<SourceReferenceView>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final reference in references)
          _SourceReferenceTile(reference: reference, onOpen: onOpen),
      ],
    );
  }
}

final class _SourceReferenceTile extends StatelessWidget {
  const _SourceReferenceTile({required this.reference, this.onOpen});

  final SourceReferenceView reference;
  final ValueChanged<SourceReferenceView>? onOpen;

  @override
  Widget build(BuildContext context) {
    final availability = switch (reference.availability) {
      SourceReferenceAvailability.current => 'Current source',
      SourceReferenceAvailability.stale => 'Source may be stale',
      SourceReferenceAvailability.unavailable => 'Source unavailable',
    };
    final canOpen =
        onOpen != null &&
        reference.availability != SourceReferenceAvailability.unavailable;
    return Semantics(
      button: canOpen,
      label: '${reference.label}, $availability',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: canOpen ? () => onOpen!(reference) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.article_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reference.label)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reference.startLine}-${reference.endLine} · '
                    '${reference.revisionLabel ?? availability}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectionArea(
                    child: Text(
                      _numberedPassage(reference),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (reference.availability !=
                      SourceReferenceAvailability.current) ...[
                    const SizedBox(height: 6),
                    Text(availability),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _numberedPassage(SourceReferenceView value) => value.passage
      .split('\n')
      .indexed
      .map((entry) => '${value.startLine + entry.$1}: ${entry.$2}')
      .join('\n');
}
