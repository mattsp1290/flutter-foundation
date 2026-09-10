import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_test_fixtures.dart';

void main() {
  group('BirbReviewFile', () {
    test('rejects empty identity and blank display text', () {
      expect(
        () => BirbReviewFile(
          id: '',
          path: 'lib/main.dart',
          change: BirbReviewFileChange.modified,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbReviewFile(
          id: 'f1',
          path: '   ',
          change: BirbReviewFileChange.modified,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbReviewFile(
          id: 'f1',
          path: 'lib/a.dart\nlib/b.dart',
          change: BirbReviewFileChange.modified,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative counts', () {
      expect(
        () => BirbReviewFile(
          id: 'f1',
          path: 'lib/main.dart',
          change: BirbReviewFileChange.modified,
          additions: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbReviewFile(
          id: 'f1',
          path: 'lib/main.dart',
          change: BirbReviewFileChange.modified,
          deletions: -1,
        ),
        throwsArgumentError,
      );
    });

    test('requires a previous path for a rename', () {
      expect(
        () => BirbReviewFile(
          id: 'f1',
          path: 'lib/new.dart',
          change: BirbReviewFileChange.renamed,
        ),
        throwsArgumentError,
      );
      expect(
        BirbReviewFile(
          id: 'f1',
          path: 'lib/new.dart',
          previousPath: 'lib/old.dart',
          change: BirbReviewFileChange.renamed,
        ).previousPath,
        'lib/old.dart',
      );
    });

    test('zero counts and text content are the defaults', () {
      final file = BirbReviewFile(
        id: 'f1',
        path: 'lib/main.dart',
        change: BirbReviewFileChange.modified,
      );
      expect(file.additions, 0);
      expect(file.deletions, 0);
      expect(file.content, BirbReviewContentAvailability.text);
    });

    test('compares by value', () {
      BirbReviewFile build() => BirbReviewFile(
        id: 'f1',
        path: 'lib/main.dart',
        change: BirbReviewFileChange.modified,
        additions: 2,
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });
  });

  group('BirbDiffLine', () {
    test('context requires both numbers', () {
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.context,
          text: 'a',
          newNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.context,
          text: 'a',
          oldNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('an addition has only a new number', () {
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.addition,
          text: 'a',
          oldNumber: 1,
          newNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            BirbDiffLine(id: 'l1', kind: BirbDiffLineKind.addition, text: 'a'),
        throwsArgumentError,
      );
    });

    test('a deletion has only an old number', () {
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.deletion,
          text: 'a',
          oldNumber: 1,
          newNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            BirbDiffLine(id: 'l1', kind: BirbDiffLineKind.deletion, text: 'a'),
        throwsArgumentError,
      );
    });

    test('rejects a non-positive line number', () {
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.addition,
          text: 'a',
          newNumber: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an embedded line terminator', () {
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.addition,
          text: 'a\nb',
          newNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.addition,
          text: 'a\rb',
          newNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('empty text and no-final-newline are legal', () {
      final line = BirbDiffLine(
        id: 'l1',
        kind: BirbDiffLineKind.addition,
        text: '',
        newNumber: 9,
        hasNoFinalNewline: true,
      );
      expect(line.text, isEmpty);
      expect(line.hasNoFinalNewline, isTrue);
    });

    test('anchored side and number follow the kind', () {
      expect(
        BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.deletion,
          text: 'a',
          oldNumber: 7,
        ).side,
        BirbDiffSide.before,
      );
      expect(
        BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.deletion,
          text: 'a',
          oldNumber: 7,
        ).anchoredNumber,
        7,
      );
      expect(
        BirbDiffLine(
          id: 'l2',
          kind: BirbDiffLineKind.context,
          text: 'a',
          oldNumber: 7,
          newNumber: 9,
        ).side,
        BirbDiffSide.after,
      );
      expect(
        BirbDiffLine(
          id: 'l2',
          kind: BirbDiffLineKind.context,
          text: 'a',
          oldNumber: 7,
          newNumber: 9,
        ).anchoredNumber,
        9,
      );
    });
  });

  group('BirbDiffHunk', () {
    test('copies its lines defensively', () {
      final lines = <BirbDiffLine>[
        BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.addition,
          text: 'a',
          newNumber: 1,
        ),
      ];
      final hunk = BirbDiffHunk(id: 'h1', lines: lines);
      lines.add(
        BirbDiffLine(
          id: 'l2',
          kind: BirbDiffLineKind.addition,
          text: 'b',
          newNumber: 2,
        ),
      );
      expect(hunk.lines, hasLength(1));
      expect(
        () => hunk.lines.add(
          BirbDiffLine(
            id: 'l3',
            kind: BirbDiffLineKind.addition,
            text: 'c',
            newNumber: 3,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('an empty hunk is a legal empty state', () {
      expect(BirbDiffHunk(id: 'h1', lines: const []).lines, isEmpty);
    });

    test('rejects a blank or multiline heading', () {
      expect(
        () => BirbDiffHunk(id: 'h1', heading: '  ', lines: const []),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffHunk(id: 'h1', heading: 'a\nb', lines: const []),
        throwsArgumentError,
      );
    });
  });

  group('BirbDiffSnapshot', () {
    test('rejects duplicate hunk identities', () {
      expect(
        () => BirbDiffSnapshot(
          file: textFile,
          revisionId: 'r1',
          hunks: <BirbDiffHunk>[
            BirbDiffHunk(id: 'h1', lines: const []),
            BirbDiffHunk(id: 'h1', lines: const []),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate line identities across hunks', () {
      BirbDiffHunk hunk(String id) => BirbDiffHunk(
        id: id,
        lines: <BirbDiffLine>[
          BirbDiffLine(
            id: 'shared',
            kind: BirbDiffLineKind.addition,
            text: 'a',
            newNumber: 1,
          ),
        ],
      );
      expect(
        () => BirbDiffSnapshot(
          file: textFile,
          revisionId: 'r1',
          hunks: <BirbDiffHunk>[hunk('h1'), hunk('h2')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects hunks on non-text content', () {
      expect(
        () => BirbDiffSnapshot(
          file: binaryFile,
          revisionId: 'r1',
          hunks: <BirbDiffHunk>[
            BirbDiffHunk(
              id: 'h1',
              lines: <BirbDiffLine>[
                BirbDiffLine(
                  id: 'l1',
                  kind: BirbDiffLineKind.addition,
                  text: 'a',
                  newNumber: 1,
                ),
              ],
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        BirbDiffSnapshot(
          file: binaryFile,
          revisionId: 'r1',
          hunks: const [],
        ).isEmpty,
        isTrue,
      );
    });

    test('rejects an empty revision identity', () {
      expect(
        () => BirbDiffSnapshot(file: textFile, revisionId: '', hunks: const []),
        throwsArgumentError,
      );
    });

    test('anchorFor emits the exact stable anchor for each kind', () {
      final snapshot = modifiedSnapshot();
      final added = snapshot.lines.firstWhere(
        (line) => line.kind == BirbDiffLineKind.addition,
      );
      final removed = snapshot.lines.firstWhere(
        (line) => line.kind == BirbDiffLineKind.deletion,
      );
      final context = snapshot.lines.firstWhere(
        (line) => line.kind == BirbDiffLineKind.context,
      );

      expect(
        snapshot.anchorFor(added),
        BirbDiffAnchor(
          fileId: textFile.id,
          revisionId: snapshot.revisionId,
          lineId: added.id,
          side: BirbDiffSide.after,
          lineNumber: added.newNumber!,
        ),
      );
      expect(snapshot.anchorFor(removed).side, BirbDiffSide.before);
      expect(snapshot.anchorFor(removed).lineNumber, removed.oldNumber);
      expect(snapshot.anchorFor(context).side, BirbDiffSide.after);
      expect(snapshot.anchorFor(context).lineNumber, context.newNumber);
    });

    test('anchorFor rejects a foreign line', () {
      final snapshot = modifiedSnapshot();
      expect(
        () => snapshot.anchorFor(
          BirbDiffLine(
            id: 'foreign',
            kind: BirbDiffLineKind.addition,
            text: 'a',
            newNumber: 1,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('copies its hunks defensively', () {
      final hunks = <BirbDiffHunk>[BirbDiffHunk(id: 'h1', lines: const [])];
      final snapshot = BirbDiffSnapshot(
        file: textFile,
        revisionId: 'r1',
        hunks: hunks,
      );
      hunks.add(BirbDiffHunk(id: 'h2', lines: const []));
      expect(snapshot.hunks, hasLength(1));
      expect(
        () => snapshot.hunks.add(BirbDiffHunk(id: 'h3', lines: const [])),
        throwsUnsupportedError,
      );
    });
  });

  group('BirbDiffAnchor', () {
    test('rejects empty identities and non-positive numbers', () {
      expect(
        () => BirbDiffAnchor(
          fileId: '',
          revisionId: 'r1',
          lineId: 'l1',
          side: BirbDiffSide.after,
          lineNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffAnchor(
          fileId: 'f1',
          revisionId: '',
          lineId: 'l1',
          side: BirbDiffSide.after,
          lineNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffAnchor(
          fileId: 'f1',
          revisionId: 'r1',
          lineId: '',
          side: BirbDiffSide.after,
          lineNumber: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbDiffAnchor(
          fileId: 'f1',
          revisionId: 'r1',
          lineId: 'l1',
          side: BirbDiffSide.after,
          lineNumber: 0,
        ),
        throwsArgumentError,
      );
    });

    test('two anchors differing only by revision are not equal', () {
      BirbDiffAnchor build(String revision) => BirbDiffAnchor(
        fileId: 'f1',
        revisionId: revision,
        lineId: 'l1',
        side: BirbDiffSide.after,
        lineNumber: 3,
      );
      expect(build('r1'), isNot(build('r2')));
      expect(build('r1'), build('r1'));
      expect(build('r1').hashCode, build('r1').hashCode);
    });
  });

  group('BirbReviewComment', () {
    test('rejects a blank body, author, or timestamp', () {
      expect(
        () => BirbReviewComment(
          id: 'c1',
          author: 'Ada',
          timestamp: 'today',
          body: '   ',
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbReviewComment(
          id: 'c1',
          author: ' ',
          timestamp: 'today',
          body: 'ok',
        ),
        throwsArgumentError,
      );
      expect(
        () => BirbReviewComment(
          id: 'c1',
          author: 'Ada',
          timestamp: '',
          body: 'ok',
        ),
        throwsArgumentError,
      );
    });

    test('keeps a multiline body verbatim', () {
      final comment = BirbReviewComment(
        id: 'c1',
        author: 'Ada',
        timestamp: 'today',
        body: 'first\n\nsecond <b>literal</b>',
      );
      expect(comment.body, 'first\n\nsecond <b>literal</b>');
    });
  });

  group('BirbReviewThread', () {
    test('rejects duplicate comment identities', () {
      BirbReviewComment comment() => BirbReviewComment(
        id: 'c1',
        author: 'Ada',
        timestamp: 'today',
        body: 'ok',
      );
      expect(
        () => BirbReviewThread(
          id: 't1',
          comments: <BirbReviewComment>[comment(), comment()],
        ),
        throwsArgumentError,
      );
    });

    test('an empty comment list and a null anchor are legal', () {
      final thread = BirbReviewThread(id: 't1', comments: const []);
      expect(thread.comments, isEmpty);
      expect(thread.anchor, isNull);
      expect(thread.resolved, isFalse);
      expect(thread.outdated, isFalse);
    });

    test('copies its comments defensively', () {
      final comments = <BirbReviewComment>[
        BirbReviewComment(
          id: 'c1',
          author: 'Ada',
          timestamp: 'today',
          body: 'ok',
        ),
      ];
      final thread = BirbReviewThread(id: 't1', comments: comments);
      comments.add(
        BirbReviewComment(
          id: 'c2',
          author: 'Ada',
          timestamp: 'today',
          body: 'more',
        ),
      );
      expect(thread.comments, hasLength(1));
      expect(() => thread.comments.add(comments.last), throwsUnsupportedError);
    });

    test('compares by value including its anchor', () {
      BirbReviewThread build({required bool resolved}) => BirbReviewThread(
        id: 't1',
        resolved: resolved,
        anchor: BirbDiffAnchor(
          fileId: 'f1',
          revisionId: 'r1',
          lineId: 'l1',
          side: BirbDiffSide.after,
          lineNumber: 2,
        ),
        comments: const [],
      );
      expect(build(resolved: false), build(resolved: false));
      expect(build(resolved: false), isNot(build(resolved: true)));
    });
  });
}
