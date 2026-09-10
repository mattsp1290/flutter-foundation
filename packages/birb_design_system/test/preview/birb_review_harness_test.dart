import 'package:birb_design_system/birb_design_system.dart';
import 'package:birb_design_system/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';

void main() {
  Widget host({
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Duration delay = Duration.zero,
  }) {
    return MaterialApp(
      theme: brightness == Brightness.light ? BirbTheme.light : BirbTheme.dark,
      themeAnimationDuration: BirbDurations.instant,
      builder: (context, view) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: view!,
      ),
      home: BirbReviewHarness(completionDelay: delay),
    );
  }

  void useViewport(WidgetTester tester, Size size) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Taps [finder] after scrolling it into view.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> reply(
    WidgetTester tester, {
    required Key composerKey,
    required String text,
  }) async {
    final editor = find.descendant(
      of: find.byKey(composerKey),
      matching: find.byType(TextField),
    );
    await tester.enterText(editor, text);
    await tester.pump();
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(composerKey),
        matching: find.byKey(BirbReviewComposerKeys.submitAction),
      ),
    );
  }

  group('fixture inventory', () {
    test('is closed, unique, and deterministic', () {
      expect(
        BirbReviewFixtures.fileNames.toSet(),
        hasLength(BirbReviewFixtures.fileNames.length),
      );
      expect(
        BirbReviewFixtures.threadNames.toSet(),
        hasLength(BirbReviewFixtures.threadNames.length),
      );

      final state = birbReviewFixtureState();
      expect(state.files.map((file) => file.id), BirbReviewFixtures.fileNames);
      expect(
        state.threads.map((thread) => thread.id),
        BirbReviewFixtures.threadNames,
      );
      expect(
        state.snapshots.keys.toSet(),
        BirbReviewFixtures.fileNames.toSet(),
      );
      expect(state.selectedFileId, BirbReviewFixtures.modifiedFile);
      expect(state.loadState, BirbReviewLoadState.ready);
      expect(state.nextOutcome, BirbReviewOutcome.succeeds);
    });

    test(
      'covers every change kind, content availability, and thread shape',
      () {
        final state = birbReviewFixtureState();
        expect(
          state.files.map((file) => file.change).toSet(),
          BirbReviewFileChange.values.toSet(),
        );
        expect(
          state.files.map((file) => file.content).toSet(),
          BirbReviewContentAvailability.values.toSet(),
        );
        expect(
          state.threads.where((thread) => thread.anchor == null),
          hasLength(1),
        );
        expect(state.threads.where((thread) => thread.resolved), hasLength(1));
        expect(state.threads.where((thread) => thread.outdated), hasLength(1));

        final large = state.snapshots[BirbReviewFixtures.largeFile]!;
        expect(large.lines, hasLength(BirbReviewFixtures.largeLineCount));
        expect(
          large.lines
              .map((line) => line.text.length)
              .reduce((a, b) => a > b ? a : b),
          BirbReviewFixtures.longLineLength,
        );

        final modified = state.snapshots[BirbReviewFixtures.modifiedFile]!;
        expect(modified.lines.any((line) => line.text.contains('\t')), isTrue);
        expect(modified.lines.any((line) => line.text.contains('🐦')), isTrue);
        expect(modified.lines.any((line) => line.hasNoFinalNewline), isTrue);
        expect(state.snapshots[BirbReviewFixtures.emptyFile]!.isEmpty, isTrue);
      },
    );

    test('draft keys separate threads and anchors including revision', () {
      final anchor = BirbDiffAnchor(
        fileId: 'f',
        revisionId: 'r1',
        lineId: 'l',
        side: BirbDiffSide.after,
        lineNumber: 1,
      );
      final other = BirbDiffAnchor(
        fileId: 'f',
        revisionId: 'r2',
        lineId: 'l',
        side: BirbDiffSide.after,
        lineNumber: 1,
      );
      expect(
        BirbReviewDemoState.anchorDraftKey(anchor),
        isNot(BirbReviewDemoState.anchorDraftKey(other)),
      );
      expect(
        BirbReviewDemoState.replyDraftKey('t1'),
        isNot(BirbReviewDemoState.replyDraftKey('t2')),
      );
    });
  });

  testWidgets('says it is a simulation and never claims a review was sent', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.byKey(BirbReviewHarnessKeys.simulationNotice), findsOneWidget);
    expect(
      find.text('Simulated review — nothing is sent anywhere.'),
      findsOneWidget,
    );
  });

  testWidgets('walks the whole workflow: file, anchor, draft, failure, retry, '
      'success, resolve, reopen', (tester) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Select a file.
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(BirbReviewHarnessKeys.fileList),
        matching: find.text('lib/src/review/birb_review_models.dart'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Added · +4 additions · −0 deletions'), findsOneWidget);

    // Back to the modified file and choose a commentable line.
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(BirbReviewHarnessKeys.fileList),
        matching: find.text('lib/src/review/birb_diff_view.dart'),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(BirbDiffViewKeys.line('modified-added-11')),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(BirbDiffViewKeys.commentAction));
    await tester.pumpAndSettle();
    expect(find.text('New discussion on new line 11'), findsOneWidget);

    // Make the next request fail, then reply.
    await tapVisible(tester, find.byKey(BirbReviewHarnessKeys.failNextToggle));
    await tester.pumpAndSettle();
    await reply(
      tester,
      composerKey: BirbReviewHarnessKeys.newDiscussionComposer,
      text: 'First line\nSecond line',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('The simulated host rejected this reply. Your draft is kept.'),
      findsOneWidget,
    );
    expect(find.text('First line\nSecond line'), findsOneWidget);

    // Retry successfully with the same draft.
    await tapVisible(tester, find.byKey(BirbReviewHarnessKeys.failNextToggle));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(BirbReviewHarnessKeys.newDiscussionComposer),
        matching: find.byKey(BirbReviewComposerKeys.submitAction),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You · just now'), findsOneWidget);
    expect(
      find.text('The simulated host rejected this reply. Your draft is kept.'),
      findsNothing,
    );

    // Resolve and reopen the fixture line thread.
    final threadKey = BirbReviewHarnessKeys.thread(
      BirbReviewFixtures.lineThread,
    );
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(threadKey),
        matching: find.byKey(BirbReviewThreadKeys.resolutionAction),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(threadKey),
        matching: find.text('Resolved'),
      ),
      findsOneWidget,
    );

    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(threadKey),
        matching: find.byKey(BirbReviewThreadKeys.resolutionAction),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(threadKey),
        matching: find.text('Unresolved'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a pending submission never touches another draft', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host(delay: const Duration(seconds: 1)));
    await tester.pumpAndSettle();

    final lineThreadComposer = BirbReviewHarnessKeys.replyComposer(
      BirbReviewFixtures.lineThread,
    );
    final generalComposer = BirbReviewHarnessKeys.replyComposer(
      BirbReviewFixtures.generalThread,
    );

    // Type a draft into the general thread that must survive untouched.
    await tester.enterText(
      find.descendant(
        of: find.byKey(generalComposer),
        matching: find.byType(TextField),
      ),
      'Untouched draft',
    );
    await tester.pump();

    await reply(
      tester,
      composerKey: lineThreadComposer,
      text: 'Reply to the line thread',
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(lineThreadComposer),
              matching: find.byKey(BirbReviewComposerKeys.submitAction),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Reply to the line thread'), findsOneWidget);
    expect(find.text('Untouched draft'), findsOneWidget);
  });

  testWidgets('a completion for a replaced revision is reported as stale', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host(delay: const Duration(seconds: 1)));
    await tester.pumpAndSettle();

    await reply(
      tester,
      composerKey: BirbReviewHarnessKeys.replyComposer(
        BirbReviewFixtures.lineThread,
      ),
      text: 'Written against the old revision',
    );

    // Replace the revision while the submission is still pending. Settling
    // here would let the fake clock complete it first.
    final push = find.byKey(BirbReviewHarnessKeys.pushRevision);
    await tester.ensureVisible(push);
    await tester.pump();
    await tester.tap(push);
    await tester.pump();

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(BirbReviewHarnessKeys.staleNotice), findsOneWidget);
    expect(
      find.textContaining('was not attached to the current content'),
      findsOneWidget,
    );
    expect(find.text('You · just now'), findsNothing);
    // The thread anchored to the previous revision is now outdated.
    expect(
      find.descendant(
        of: find.byKey(
          BirbReviewHarnessKeys.thread(BirbReviewFixtures.lineThread),
        ),
        matching: find.text('Outdated location'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('unmounting with a pending submission throws nothing', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host(delay: const Duration(seconds: 1)));
    await tester.pumpAndSettle();

    await reply(
      tester,
      composerKey: BirbReviewHarnessKeys.replyComposer(
        BirbReviewFixtures.generalThread,
      ),
      text: 'Interrupted',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('host loading and retry surround the diff', (tester) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host(delay: const Duration(seconds: 1)));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(BirbReviewHarnessKeys.retryLoad));
    expect(find.byKey(BirbReviewHarnessKeys.loadingNotice), findsOneWidget);
    expect(find.byKey(BirbReviewHarnessKeys.diff), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(BirbReviewHarnessKeys.diff), findsOneWidget);
    expect(find.byKey(BirbReviewHarnessKeys.loadingNotice), findsNothing);
  });

  testWidgets('binary and unavailable files never look like an empty diff', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(BirbReviewHarnessKeys.fileList),
        matching: find.text('examples/catalog/assets/preview.png'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Binary file. No text diff is shown.'), findsOneWidget);

    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(BirbReviewHarnessKeys.fileList),
        matching: find.text('tool/placeholder.dart'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No textual changes'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final width in <double>[320, 800]) {
      for (final textScale in <double>[1, 2]) {
        testWidgets('${brightness.name} at $width logical pixels and '
            '${textScale}x text renders without overflow', (tester) async {
          useViewport(tester, Size(width, 900));
          await tester.pumpWidget(
            host(brightness: brightness, textScale: textScale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(BirbReviewHarnessKeys.diff), findsOneWidget);
          expect(
            find.byKey(BirbReviewHarnessKeys.simulationNotice),
            findsOneWidget,
          );
          for (final key in <Key>[
            BirbReviewHarnessKeys.retryLoad,
            BirbReviewHarnessKeys.pushRevision,
          ]) {
            expect(
              tester.getSize(find.byKey(key)).height,
              greaterThanOrEqualTo(48),
            );
          }
        });
      }
    }
  }

  testWidgets('the status legend shows every status with an icon and text', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    for (final status in BirbReviewStatus.values) {
      expect(find.byKey(BirbReviewHarnessKeys.status(status)), findsOneWidget);
      expect(find.text(BirbReviewStyle.statusLabel(status)), findsOneWidget);
    }
  });

  testWidgets('keyboard traversal reaches the diff and the composer', (
    tester,
  ) async {
    useViewport(tester, const Size(1200, 1400));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    var guard = 0;
    while (guard < 40 &&
        !focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion))) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      guard += 1;
    }
    expect(
      focusIsInside(find.byKey(BirbDiffViewKeys.navigationRegion)),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Comment on removed line 11'), findsOneWidget);
  });
}
