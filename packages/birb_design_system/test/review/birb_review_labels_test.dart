import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// Label classes are compared by value in `didUpdateWidget`, so a host that
/// rebuilds them every frame must not force a re-measure of the whole
/// snapshot. These tests fail if the `==`/`hashCode` implementations are
/// removed.
void main() {
  group('BirbDiffViewLabels', () {
    test('two default instances are equal', () {
      expect(const BirbDiffViewLabels(), const BirbDiffViewLabels());
      expect(
        const BirbDiffViewLabels().hashCode,
        const BirbDiffViewLabels().hashCode,
      );
    });

    test('every field participates in equality', () {
      final variants = <BirbDiffViewLabels>[
        const BirbDiffViewLabels(emptyText: 'x'),
        const BirbDiffViewLabels(binaryText: 'x'),
        const BirbDiffViewLabels(unavailableText: 'x'),
        const BirbDiffViewLabels(navigationLabel: 'x'),
        const BirbDiffViewLabels(keyboardHelp: 'x'),
        const BirbDiffViewLabels(horizontalScrollLabel: 'x'),
        const BirbDiffViewLabels(copyActionLabel: 'x'),
        const BirbDiffViewLabels(selectSourceActionLabel: 'x'),
        const BirbDiffViewLabels(noActiveLineText: 'x'),
        const BirbDiffViewLabels(sourceSelectionLabel: 'x'),
        const BirbDiffViewLabels(noFinalNewlineText: 'x'),
        const BirbDiffViewLabels(renamedFrom: 'x'),
        const BirbDiffViewLabels(additions: 'x'),
        const BirbDiffViewLabels(deletions: 'x'),
      ];
      for (final variant in variants) {
        expect(variant, isNot(const BirbDiffViewLabels()));
      }
      expect(variants.toSet(), hasLength(variants.length));

      expect(
        BirbDiffViewLabels(activeLine: (line) => line.id),
        isNot(const BirbDiffViewLabels()),
      );
      expect(
        BirbDiffViewLabels(commentAction: (line) => line.id),
        isNot(const BirbDiffViewLabels()),
      );
    });
  });

  group('BirbChangedFileListLabels', () {
    test('compares by value across every field', () {
      expect(
        const BirbChangedFileListLabels(),
        const BirbChangedFileListLabels(),
      );
      final variants = <BirbChangedFileListLabels>[
        const BirbChangedFileListLabels(empty: 'x'),
        const BirbChangedFileListLabels(additions: 'x'),
        const BirbChangedFileListLabels(deletions: 'x'),
        const BirbChangedFileListLabels(renamedFrom: 'x'),
        const BirbChangedFileListLabels(binary: 'x'),
        const BirbChangedFileListLabels(unavailable: 'x'),
        const BirbChangedFileListLabels(selected: 'x'),
      ];
      for (final variant in variants) {
        expect(variant, isNot(const BirbChangedFileListLabels()));
      }
      expect(variants.toSet(), hasLength(variants.length));
    });
  });

  group('BirbReviewThreadLabels', () {
    test('compares by value across every field', () {
      expect(const BirbReviewThreadLabels(), const BirbReviewThreadLabels());
      final variants = <BirbReviewThreadLabels>[
        const BirbReviewThreadLabels(generalDiscussion: 'x'),
        const BirbReviewThreadLabels(resolvedLabel: 'x'),
        const BirbReviewThreadLabels(unresolvedLabel: 'x'),
        const BirbReviewThreadLabels(outdatedLabel: 'x'),
        const BirbReviewThreadLabels(resolveAction: 'x'),
        const BirbReviewThreadLabels(reopenAction: 'x'),
        const BirbReviewThreadLabels(pendingLabel: 'x'),
        const BirbReviewThreadLabels(emptyText: 'x'),
      ];
      for (final variant in variants) {
        expect(variant, isNot(const BirbReviewThreadLabels()));
      }
      expect(variants.toSet(), hasLength(variants.length));
      expect(
        BirbReviewThreadLabels(anchorLabel: (anchor) => anchor.lineId),
        isNot(const BirbReviewThreadLabels()),
      );
    });
  });

  group('BirbReviewComposerLabels', () {
    test('compares by value across every field', () {
      expect(
        const BirbReviewComposerLabels(),
        const BirbReviewComposerLabels(),
      );
      final variants = <BirbReviewComposerLabels>[
        const BirbReviewComposerLabels(caption: 'x'),
        const BirbReviewComposerLabels(hint: 'x'),
        const BirbReviewComposerLabels(submitAction: 'x'),
        const BirbReviewComposerLabels(cancelAction: 'x'),
        const BirbReviewComposerLabels(pendingLabel: 'x'),
        const BirbReviewComposerLabels(blankDraftError: 'x'),
      ];
      for (final variant in variants) {
        expect(variant, isNot(const BirbReviewComposerLabels()));
      }
      expect(variants.toSet(), hasLength(variants.length));
    });
  });
}
