import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic, synthetic review fixtures shared by the review tests.
///
/// Nothing here reads a real repository, a network resource, or a secret.
final BirbReviewFile textFile = BirbReviewFile(
  id: 'file-text',
  path: 'lib/src/review/birb_diff_view.dart',
  change: BirbReviewFileChange.modified,
  additions: 3,
  deletions: 2,
);

final BirbReviewFile addedFile = BirbReviewFile(
  id: 'file-added',
  path: 'lib/src/review/birb_review_models.dart',
  change: BirbReviewFileChange.added,
  additions: 12,
);

final BirbReviewFile deletedFile = BirbReviewFile(
  id: 'file-deleted',
  path: 'lib/src/legacy/old_diff.dart',
  change: BirbReviewFileChange.deleted,
  deletions: 40,
);

final BirbReviewFile renamedFile = BirbReviewFile(
  id: 'file-renamed',
  path: 'lib/src/review/birb_changed_file_list.dart',
  previousPath: 'lib/src/review/changed_files.dart',
  change: BirbReviewFileChange.renamed,
  additions: 1,
  deletions: 1,
);

final BirbReviewFile binaryFile = BirbReviewFile(
  id: 'file-binary',
  path: 'examples/catalog/assets/preview.png',
  change: BirbReviewFileChange.added,
  content: BirbReviewContentAvailability.binary,
);

final BirbReviewFile unavailableFile = BirbReviewFile(
  id: 'file-unavailable',
  path:
      'examples/catalog/very/long/directory/name/that/keeps/going/'
      'past_a_narrow_viewport_width.dart',
  change: BirbReviewFileChange.modified,
  additions: 1,
  content: BirbReviewContentAvailability.unavailable,
);

final BirbReviewFile emptyTextFile = BirbReviewFile(
  id: 'file-empty',
  path: 'tool/placeholder.dart',
  change: BirbReviewFileChange.modified,
);

/// Every fixture file in a stable display order.
final List<BirbReviewFile> allFiles = <BirbReviewFile>[
  textFile,
  addedFile,
  deletedFile,
  renamedFile,
  binaryFile,
  unavailableFile,
  emptyTextFile,
];

/// A snapshot with a context line, a deletion, an addition, and a heading.
BirbDiffSnapshot modifiedSnapshot({String revisionId = 'rev-1'}) =>
    BirbDiffSnapshot(
      file: textFile,
      revisionId: revisionId,
      hunks: <BirbDiffHunk>[
        BirbDiffHunk(
          id: 'hunk-1',
          heading: '@@ -10,4 +10,5 @@ Widget build(BuildContext context)',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'line-context-10',
              kind: BirbDiffLineKind.context,
              text: 'Widget build(BuildContext context) {',
              oldNumber: 10,
              newNumber: 10,
            ),
            BirbDiffLine(
              id: 'line-deleted-11',
              kind: BirbDiffLineKind.deletion,
              text: '\treturn const Placeholder();',
              oldNumber: 11,
            ),
            BirbDiffLine(
              id: 'line-added-11',
              kind: BirbDiffLineKind.addition,
              text: '\treturn const BirbDiffView(snapshot: snapshot);',
              newNumber: 11,
            ),
            BirbDiffLine(
              id: 'line-added-12',
              kind: BirbDiffLineKind.addition,
              text: '\t// Unicode kept verbatim: naïve — 🐦 — <b>literal</b>',
              newNumber: 12,
            ),
            BirbDiffLine(
              id: 'line-context-13',
              kind: BirbDiffLineKind.context,
              text: '}',
              oldNumber: 12,
              newNumber: 13,
              hasNoFinalNewline: true,
            ),
          ],
        ),
        BirbDiffHunk(
          id: 'hunk-2',
          heading: '@@ -90,2 +91,2 @@',
          lines: <BirbDiffLine>[
            BirbDiffLine(
              id: 'line-context-9998',
              kind: BirbDiffLineKind.context,
              text: '// Large line numbers stay legible.',
              oldNumber: 9998,
              newNumber: 9999,
            ),
            BirbDiffLine(
              id: 'line-added-10000',
              kind: BirbDiffLineKind.addition,
              text: '// tail',
              newNumber: 10000,
            ),
          ],
        ),
      ],
    );

/// A deterministic snapshot with [lineCount] lines and one very long line.
///
/// Used to prove bounded lazy row construction.
BirbDiffSnapshot largeSnapshot({
  int lineCount = 10000,
  int longLineLength = 2000,
  String revisionId = 'rev-large',
}) {
  final lines = <BirbDiffLine>[];
  for (var index = 1; index <= lineCount; index += 1) {
    if (index == 3) {
      lines.add(
        BirbDiffLine(
          id: 'large-line-$index',
          kind: BirbDiffLineKind.context,
          text: 'x' * longLineLength,
          oldNumber: index,
          newNumber: index,
        ),
      );
      continue;
    }
    if (index == lineCount) {
      lines.add(
        BirbDiffLine(
          id: 'large-line-$index',
          kind: BirbDiffLineKind.addition,
          text: '\tfinal last = $index;',
          newNumber: index,
        ),
      );
      continue;
    }
    lines.add(
      BirbDiffLine(
        id: 'large-line-$index',
        kind: BirbDiffLineKind.context,
        text: 'final value$index = $index;',
        oldNumber: index,
        newNumber: index,
      ),
    );
  }
  return BirbDiffSnapshot(
    file: BirbReviewFile(
      id: 'file-large',
      path: 'lib/generated/large_fixture.dart',
      change: BirbReviewFileChange.modified,
      additions: 1,
      deletions: 0,
    ),
    revisionId: revisionId,
    hunks: <BirbDiffHunk>[BirbDiffHunk(id: 'large-hunk', lines: lines)],
  );
}

/// An empty text snapshot: the file changed but has no textual line.
BirbDiffSnapshot emptyTextSnapshot() => BirbDiffSnapshot(
  file: emptyTextFile,
  revisionId: 'rev-empty',
  hunks: const <BirbDiffHunk>[],
);

/// A binary-content snapshot.
BirbDiffSnapshot binarySnapshot() => BirbDiffSnapshot(
  file: binaryFile,
  revisionId: 'rev-binary',
  hunks: const <BirbDiffHunk>[],
);

/// An unavailable-content snapshot.
BirbDiffSnapshot unavailableSnapshot() => BirbDiffSnapshot(
  file: unavailableFile,
  revisionId: 'rev-unavailable',
  hunks: const <BirbDiffHunk>[],
);

/// A renamed-file snapshot, so the rename header can be exercised.
BirbDiffSnapshot renamedSnapshot() => BirbDiffSnapshot(
  file: renamedFile,
  revisionId: 'rev-renamed',
  hunks: <BirbDiffHunk>[
    BirbDiffHunk(
      id: 'renamed-hunk',
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
);

/// A deleted-file snapshot whose lines are all deletions.
BirbDiffSnapshot deletedSnapshot() => BirbDiffSnapshot(
  file: deletedFile,
  revisionId: 'rev-deleted',
  hunks: <BirbDiffHunk>[
    BirbDiffHunk(
      id: 'deleted-hunk',
      lines: <BirbDiffLine>[
        BirbDiffLine(
          id: 'deleted-line-1',
          kind: BirbDiffLineKind.deletion,
          text: 'class OldDiff {}',
          oldNumber: 1,
        ),
      ],
    ),
  ],
);

/// A thread anchored to the added line of [modifiedSnapshot].
BirbReviewThread lineThread({
  bool resolved = false,
  bool outdated = false,
  String revisionId = 'rev-1',
}) => BirbReviewThread(
  id: 'thread-line',
  resolved: resolved,
  outdated: outdated,
  anchor: BirbDiffAnchor(
    fileId: textFile.id,
    revisionId: revisionId,
    lineId: 'line-added-11',
    side: BirbDiffSide.after,
    lineNumber: 11,
  ),
  comments: <BirbReviewComment>[
    BirbReviewComment(
      id: 'comment-1',
      author: 'Wren',
      timestamp: '2026-09-09 10:04',
      body: 'Does this keep the previous placeholder behaviour?',
    ),
    BirbReviewComment(
      id: 'comment-2',
      author: 'Ada',
      timestamp: '2026-09-09 10:12',
      body: 'It does.\n\nThe host still owns the snapshot: <b>not parsed</b>.',
    ),
  ],
);

/// A general discussion with no anchor.
BirbReviewThread generalThread() => BirbReviewThread(
  id: 'thread-general',
  comments: <BirbReviewComment>[
    BirbReviewComment(
      id: 'comment-general',
      author: 'Wren',
      timestamp: '2026-09-09 09:58',
      body: 'Overall this reads well.',
    ),
  ],
);

/// Wraps [child] in the package theme at [brightness] for a widget test.
///
/// Callers control the viewport with `tester.view.physicalSize`.
Widget themedHost(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? BirbTheme.light : BirbTheme.dark,
    builder: (context, view) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: view!,
    ),
    home: Scaffold(body: child),
  );
}

/// Captures every `Clipboard.setData` payload for the current test.
///
/// Inspecting the platform message proves the actual copy, not only that a
/// callback fired.
List<String> captureClipboard(WidgetTester tester) {
  final captured = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      captured.add(
        (call.arguments as Map<Object?, Object?>)['text']! as String,
      );
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return captured;
}

/// Sets the test viewport to [size] logical pixels for the current test.
void useViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
