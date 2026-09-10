import '../../birb_design_system.dart';
import 'birb_review_state.dart';

/// Stable fixture names for the review preview.
///
/// Every fixture is synthetic and deterministic. None contains a secret, a real
/// repository path, or a network resource.
abstract final class BirbReviewFixtures {
  static const String modifiedFile = 'fixture-modified';
  static const String addedFile = 'fixture-added';
  static const String deletedFile = 'fixture-deleted';
  static const String renamedFile = 'fixture-renamed';
  static const String binaryFile = 'fixture-binary';
  static const String unavailableFile = 'fixture-unavailable';
  static const String emptyFile = 'fixture-empty';
  static const String largeFile = 'fixture-large';

  static const String lineThread = 'fixture-thread-line';
  static const String generalThread = 'fixture-thread-general';
  static const String resolvedThread = 'fixture-thread-resolved';
  static const String outdatedThread = 'fixture-thread-outdated';

  static const String firstRevision = 'fixture-revision-1';

  /// Every fixture file identity in display order.
  static const List<String> fileNames = <String>[
    modifiedFile,
    addedFile,
    deletedFile,
    renamedFile,
    binaryFile,
    unavailableFile,
    emptyFile,
    largeFile,
  ];

  /// Every fixture thread identity in display order.
  static const List<String> threadNames = <String>[
    lineThread,
    generalThread,
    resolvedThread,
    outdatedThread,
  ];

  /// How many lines the large fixture contains.
  static const int largeLineCount = 10000;

  /// How many characters the long line in the large fixture contains.
  static const int longLineLength = 2000;
}

/// Builds the deterministic starting state of the review preview.
BirbReviewDemoState birbReviewFixtureState() {
  final files = <BirbReviewFile>[
    BirbReviewFile(
      id: BirbReviewFixtures.modifiedFile,
      path: 'lib/src/review/birb_diff_view.dart',
      change: BirbReviewFileChange.modified,
      additions: 3,
      deletions: 2,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.addedFile,
      path: 'lib/src/review/birb_review_models.dart',
      change: BirbReviewFileChange.added,
      additions: 4,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.deletedFile,
      path: 'lib/src/legacy/old_diff.dart',
      change: BirbReviewFileChange.deleted,
      deletions: 2,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.renamedFile,
      path: 'lib/src/review/birb_changed_file_list.dart',
      previousPath: 'lib/src/review/changed_files.dart',
      change: BirbReviewFileChange.renamed,
      additions: 1,
      deletions: 1,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.binaryFile,
      path: 'examples/catalog/assets/preview.png',
      change: BirbReviewFileChange.added,
      content: BirbReviewContentAvailability.binary,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.unavailableFile,
      path:
          'examples/catalog/a/deliberately/long/directory/chain/that/keeps/'
          'going/past_a_narrow_viewport.dart',
      change: BirbReviewFileChange.modified,
      additions: 1,
      content: BirbReviewContentAvailability.unavailable,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.emptyFile,
      path: 'tool/placeholder.dart',
      change: BirbReviewFileChange.modified,
    ),
    BirbReviewFile(
      id: BirbReviewFixtures.largeFile,
      path: 'lib/generated/large_fixture.dart',
      change: BirbReviewFileChange.modified,
      additions: 1,
    ),
  ];

  final byId = <String, BirbReviewFile>{
    for (final file in files) file.id: file,
  };

  const revision = BirbReviewFixtures.firstRevision;
  final snapshots = <String, BirbDiffSnapshot>{
    BirbReviewFixtures.modifiedFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.modifiedFile]!,
      revisionId: revision,
      hunks: <BirbDiffHunk>[
        BirbDiffHunk(
          id: 'modified-hunk-1',
          heading: '@@ -10,4 +10,5 @@ Widget build(BuildContext context)',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'modified-context-10',
              kind: BirbDiffLineKind.context,
              text: 'Widget build(BuildContext context) {',
              oldNumber: 10,
              newNumber: 10,
            ),
            BirbDiffLine(
              id: 'modified-deleted-11',
              kind: BirbDiffLineKind.deletion,
              text: '\treturn const Placeholder();',
              oldNumber: 11,
            ),
            BirbDiffLine(
              id: 'modified-added-11',
              kind: BirbDiffLineKind.addition,
              text: '\treturn BirbDiffView(snapshot: snapshot);',
              newNumber: 11,
            ),
            BirbDiffLine(
              id: 'modified-added-12',
              kind: BirbDiffLineKind.addition,
              text:
                  '\t// Tabs, Unicode, and markup stay literal: naïve 🐦 '
                  '<b>not parsed</b>',
              newNumber: 12,
            ),
            BirbDiffLine(
              id: 'modified-context-13',
              kind: BirbDiffLineKind.context,
              text: '}',
              oldNumber: 12,
              newNumber: 13,
            ),
          ],
        ),
        BirbDiffHunk(
          id: 'modified-hunk-2',
          heading: '@@ -9998,1 +9999,2 @@',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'modified-context-9998',
              kind: BirbDiffLineKind.context,
              text: '// Large line numbers stay aligned.',
              oldNumber: 9998,
              newNumber: 9999,
            ),
            BirbDiffLine(
              id: 'modified-added-10000',
              kind: BirbDiffLineKind.addition,
              text: '// tail',
              newNumber: 10000,
              hasNoFinalNewline: true,
            ),
          ],
        ),
      ],
    ),
    BirbReviewFixtures.addedFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.addedFile]!,
      revisionId: revision,
      hunks: <BirbDiffHunk>[
        BirbDiffHunk(
          id: 'added-hunk-1',
          heading: '@@ -0,0 +1,4 @@',
          lines: <BirbDiffLine>[
            for (var index = 1; index <= 4; index += 1)
              BirbDiffLine(
                id: 'added-line-$index',
                kind: BirbDiffLineKind.addition,
                text: switch (index) {
                  1 => 'final class BirbReviewFile {',
                  2 => '\tconst BirbReviewFile({required this.id});',
                  3 => '\tfinal String id;',
                  _ => '}',
                },
                newNumber: index,
              ),
          ],
        ),
      ],
    ),
    BirbReviewFixtures.deletedFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.deletedFile]!,
      revisionId: revision,
      hunks: <BirbDiffHunk>[
        BirbDiffHunk(
          id: 'deleted-hunk-1',
          heading: '@@ -1,2 +0,0 @@',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'deleted-line-1',
              kind: BirbDiffLineKind.deletion,
              text: 'class OldDiff {}',
              oldNumber: 1,
            ),
            BirbDiffLine(
              id: 'deleted-line-2',
              kind: BirbDiffLineKind.deletion,
              text: '// superseded by BirbDiffView',
              oldNumber: 2,
            ),
          ],
        ),
      ],
    ),
    BirbReviewFixtures.renamedFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.renamedFile]!,
      revisionId: revision,
      hunks: <BirbDiffHunk>[
        BirbDiffHunk(
          id: 'renamed-hunk-1',
          heading: '@@ -1,1 +1,1 @@',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'renamed-deleted-1',
              kind: BirbDiffLineKind.deletion,
              text: 'class ChangedFiles {}',
              oldNumber: 1,
            ),
            BirbDiffLine(
              id: 'renamed-added-1',
              kind: BirbDiffLineKind.addition,
              text: 'class BirbChangedFileList {}',
              newNumber: 1,
            ),
          ],
        ),
      ],
    ),
    BirbReviewFixtures.binaryFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.binaryFile]!,
      revisionId: revision,
      hunks: const <BirbDiffHunk>[],
    ),
    BirbReviewFixtures.unavailableFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.unavailableFile]!,
      revisionId: revision,
      hunks: const <BirbDiffHunk>[],
    ),
    BirbReviewFixtures.emptyFile: BirbDiffSnapshot(
      file: byId[BirbReviewFixtures.emptyFile]!,
      revisionId: revision,
      hunks: const <BirbDiffHunk>[],
    ),
    BirbReviewFixtures.largeFile: _largeSnapshot(
      byId[BirbReviewFixtures.largeFile]!,
      revision,
    ),
  };

  final threads = <BirbReviewThread>[
    BirbReviewThread(
      id: BirbReviewFixtures.lineThread,
      anchor: BirbDiffAnchor(
        fileId: BirbReviewFixtures.modifiedFile,
        revisionId: revision,
        lineId: 'modified-added-11',
        side: BirbDiffSide.after,
        lineNumber: 11,
      ),
      comments: <BirbReviewComment>[
        BirbReviewComment(
          id: 'fixture-comment-1',
          author: 'Wren',
          timestamp: '2026-09-09 10:04',
          body: 'Does the host still own the snapshot here?',
        ),
        BirbReviewComment(
          id: 'fixture-comment-2',
          author: 'Ada',
          timestamp: '2026-09-09 10:12',
          body: 'It does.\n\nThe widget only reports the anchor it was given.',
        ),
      ],
    ),
    BirbReviewThread(
      id: BirbReviewFixtures.generalThread,
      comments: <BirbReviewComment>[
        BirbReviewComment(
          id: 'fixture-comment-3',
          author: 'Wren',
          timestamp: '2026-09-09 09:58',
          body: 'Overall this reads well.',
        ),
      ],
    ),
    BirbReviewThread(
      id: BirbReviewFixtures.resolvedThread,
      resolved: true,
      anchor: BirbDiffAnchor(
        fileId: BirbReviewFixtures.modifiedFile,
        revisionId: revision,
        lineId: 'modified-deleted-11',
        side: BirbDiffSide.before,
        lineNumber: 11,
      ),
      comments: <BirbReviewComment>[
        BirbReviewComment(
          id: 'fixture-comment-4',
          author: 'Ada',
          timestamp: '2026-09-09 10:20',
          body: 'The placeholder is gone. Resolving.',
        ),
      ],
    ),
    BirbReviewThread(
      id: BirbReviewFixtures.outdatedThread,
      outdated: true,
      anchor: BirbDiffAnchor(
        fileId: BirbReviewFixtures.modifiedFile,
        revisionId: 'fixture-revision-0',
        lineId: 'retired-line-7',
        side: BirbDiffSide.after,
        lineNumber: 7,
      ),
      comments: <BirbReviewComment>[
        BirbReviewComment(
          id: 'fixture-comment-5',
          author: 'Wren',
          timestamp: '2026-09-08 17:41',
          body: 'This line moved in a later push, so the location is stale.',
        ),
      ],
    ),
  ];

  return BirbReviewDemoState(
    files: files,
    snapshots: snapshots,
    threads: threads,
    selectedFileId: BirbReviewFixtures.modifiedFile,
  );
}

BirbDiffSnapshot _largeSnapshot(BirbReviewFile file, String revisionId) {
  const count = BirbReviewFixtures.largeLineCount;
  final lines = <BirbDiffLine>[
    for (var index = 1; index <= count; index += 1)
      if (index == 3)
        BirbDiffLine(
          id: 'large-line-$index',
          kind: BirbDiffLineKind.context,
          text: 'x' * BirbReviewFixtures.longLineLength,
          oldNumber: index,
          newNumber: index,
        )
      else if (index == count)
        BirbDiffLine(
          id: 'large-line-$index',
          kind: BirbDiffLineKind.addition,
          text: '\tfinal last = $index;',
          newNumber: index,
        )
      else
        BirbDiffLine(
          id: 'large-line-$index',
          kind: BirbDiffLineKind.context,
          text: 'final value$index = $index;',
          oldNumber: index,
          newNumber: index,
        ),
  ];
  return BirbDiffSnapshot(
    file: file,
    revisionId: revisionId,
    hunks: <BirbDiffHunk>[BirbDiffHunk(id: 'large-hunk', lines: lines)],
  );
}
