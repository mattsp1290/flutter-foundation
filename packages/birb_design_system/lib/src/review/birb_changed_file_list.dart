import 'package:flutter/material.dart';

import '../tokens/birb_tokens.dart';
import 'birb_review_models.dart';
import 'birb_review_style.dart';

/// Caller-supplied text for [BirbChangedFileList].
///
/// Defaults are English. Hosts localize by supplying their own values.
@immutable
final class BirbChangedFileListLabels {
  const BirbChangedFileListLabels({
    this.empty = 'No changed files',
    this.additions = 'additions',
    this.deletions = 'deletions',
    this.renamedFrom = 'Renamed from',
    this.binary = 'Binary file',
    this.unavailable = 'Content unavailable',
    this.selected = 'Selected',
  });

  final String empty;
  final String additions;
  final String deletions;
  final String renamedFrom;
  final String binary;
  final String unavailable;
  final String selected;

  @override
  bool operator ==(Object other) =>
      other is BirbChangedFileListLabels &&
      other.empty == empty &&
      other.additions == additions &&
      other.deletions == deletions &&
      other.renamedFrom == renamedFrom &&
      other.binary == binary &&
      other.unavailable == unavailable &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(
    empty,
    additions,
    deletions,
    renamedFrom,
    binary,
    unavailable,
    selected,
  );
}

/// A controlled list of the files changed in a review.
///
/// [selectedFileId] is owned by the host: this widget keeps no competing
/// selection store, so changing that value externally updates the rendering.
/// A null [onFileSelected] disables navigation, and no callback is emitted in
/// that state.
///
/// Items are ordinary themed [OutlinedButton]s, so keyboard traversal,
/// `Enter`/`Space` activation, the 48×48 target, and the focus boundary come
/// from the tested button recipes. Long paths wrap instead of hiding their
/// distinguishing suffix. The widget lays out with its intrinsic height so a
/// host can place it inside its own scroll view.
final class BirbChangedFileList extends StatelessWidget {
  const BirbChangedFileList({
    required this.files,
    super.key,
    this.selectedFileId,
    this.onFileSelected,
    this.labels = const BirbChangedFileListLabels(),
  });

  /// The changed files in display order.
  final List<BirbReviewFile> files;

  /// The host-selected file identity, or null when nothing is selected.
  final String? selectedFileId;

  /// Reports the file identity the user chose. Null disables navigation.
  final ValueChanged<String>? onFileSelected;

  /// Overridable display text.
  final BirbChangedFileListLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(BirbSpacing.space3),
        child: Text(labels.empty, style: theme.textTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final file in files)
          Padding(
            padding: const EdgeInsets.only(bottom: BirbSpacing.space1),
            child: _ChangedFileItem(
              file: file,
              selected: file.id == selectedFileId,
              labels: labels,
              onPressed: onFileSelected == null
                  ? null
                  : () => onFileSelected!(file.id),
            ),
          ),
      ],
    );
  }
}

class _ChangedFileItem extends StatelessWidget {
  const _ChangedFileItem({
    required this.file,
    required this.selected,
    required this.labels,
    required this.onPressed,
  });

  final BirbReviewFile file;
  final bool selected;
  final BirbChangedFileListLabels labels;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = BirbReviewStyle.fileChangeLabel(file.change);
    final counts =
        '+${file.additions} ${labels.additions}, '
        '−${file.deletions} ${labels.deletions}';
    final availability = switch (file.content) {
      BirbReviewContentAvailability.text => null,
      BirbReviewContentAvailability.binary => labels.binary,
      BirbReviewContentAvailability.unavailable => labels.unavailable,
    };
    final previousPath = file.previousPath;
    final renameNote = previousPath == null
        ? null
        : '${labels.renamedFrom} $previousPath';
    final semanticLabel = <String>[
      file.path,
      kind,
      ?renameNote,
      counts,
      ?availability,
    ].join(', ');

    // Merge rather than exclude: excluding the button would drop its tap
    // action, leaving a node that advertises an operable button no assistive
    // technology can activate. Only the redundant visible strings are excluded.
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        label: semanticLabel,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(
              horizontal: BirbSpacing.space3,
              vertical: BirbSpacing.space2,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  selected ? Icons.check : Icons.insert_drive_file_outlined,
                  size: BirbSpacing.space4,
                ),
                const SizedBox(width: BirbSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        file.path,
                        style: selected
                            ? theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                      if (renameNote != null)
                        Text(renameNote, style: theme.textTheme.bodySmall),
                      Text(
                        selected
                            ? '$kind · $counts · ${labels.selected}'
                            : '$kind · $counts',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (availability != null)
                        Text(availability, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
