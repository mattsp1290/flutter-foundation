import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';
import 'review_test_fixtures.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} renders author, timestamp, body, and '
        'location', (tester) async {
      await tester.pumpWidget(
        themedHost(
          SingleChildScrollView(
            child: BirbReviewThreadView(thread: lineThread()),
          ),
          brightness: brightness,
        ),
      );

      expect(find.text('On new line 11'), findsOneWidget);
      expect(find.text('Wren · 2026-09-09 10:04'), findsOneWidget);
      expect(find.text('Ada · 2026-09-09 10:12'), findsOneWidget);
      expect(
        find.text('Does this keep the previous placeholder behaviour?'),
        findsOneWidget,
      );
      expect(find.text('Unresolved'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);
    });
  }

  testWidgets('a plain-text body keeps newlines and never executes markup', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(thread: lineThread()),
        ),
      ),
    );

    final body = tester.widget<SelectableText>(
      find.byKey(BirbReviewThreadKeys.commentBody('comment-2')),
    );
    expect(
      body.data,
      'It does.\n\nThe host still owns the snapshot: <b>not parsed</b>.',
    );
    expect(find.textContaining('<b>not parsed</b>'), findsOneWidget);
  });

  testWidgets('a resolved thread keeps every comment visible', (tester) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(resolved: true),
            onResolutionRequested: (_, {required resolved}) {},
          ),
        ),
      ),
    );

    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Reopen thread'), findsOneWidget);
    expect(
      find.text('Does this keep the previous placeholder behaviour?'),
      findsOneWidget,
    );
    expect(find.textContaining('It does.'), findsOneWidget);
  });

  testWidgets('resolve and reopen report the requested state without '
      'mutating the model', (tester) async {
    final requests = <(String, bool)>[];
    final thread = lineThread();
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: thread,
            onResolutionRequested: (id, {required resolved}) =>
                requests.add((id, resolved)),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(BirbReviewThreadKeys.resolutionAction));
    await tester.pumpAndSettle();
    expect(requests, <(String, bool)>[('thread-line', true)]);
    // The widget still renders the unresolved model it was given.
    expect(find.text('Unresolved'), findsOneWidget);
    expect(thread.resolved, isFalse);

    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(resolved: true),
            onResolutionRequested: (id, {required resolved}) =>
                requests.add((id, resolved)),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(BirbReviewThreadKeys.resolutionAction));
    await tester.pumpAndSettle();
    expect(requests.last, ('thread-line', false));
  });

  testWidgets('a pending update disables the action and announces progress', (
    tester,
  ) async {
    final requests = <String>[];
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(),
            isUpdating: true,
            onResolutionRequested: (id, {required resolved}) =>
                requests.add(id),
          ),
        ),
      ),
    );

    expect(find.text('Updating thread state'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.byKey(BirbReviewThreadKeys.resolutionAction),
    );
    expect(button.onPressed, isNull);

    await tester.tap(
      find.byKey(BirbReviewThreadKeys.resolutionAction),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(requests, isEmpty);
    expect(
      tester.getSemantics(find.byKey(BirbReviewThreadKeys.pendingStatus)).label,
      'Updating thread state',
    );
  });

  testWidgets('an error stays visible in a live region and retries with the '
      'same action', (tester) async {
    final requests = <String>[];
    Widget build({required bool updating, String? error}) => themedHost(
      SingleChildScrollView(
        child: BirbReviewThreadView(
          thread: lineThread(),
          isUpdating: updating,
          errorText: error,
          onResolutionRequested: (id, {required resolved}) => requests.add(id),
        ),
      ),
    );

    await tester.pumpWidget(build(updating: false, error: 'Network failed'));
    expect(find.text('Network failed'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Error: Network failed')),
      isNotNull,
    );

    await tester.tap(find.byKey(BirbReviewThreadKeys.resolutionAction));
    await tester.pumpAndSettle();
    expect(requests, <String>['thread-line']);
  });

  testWidgets('an absent callback hides the action entirely', (tester) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(thread: lineThread()),
        ),
      ),
    );
    expect(find.byKey(BirbReviewThreadKeys.resolutionAction), findsNothing);
    expect(find.text('Resolve thread'), findsNothing);
  });

  testWidgets('a general discussion has no location and an empty thread says '
      'so', (tester) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(thread: generalThread()),
        ),
      ),
    );
    expect(find.text('General discussion'), findsOneWidget);

    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: BirbReviewThread(id: 'empty', comments: const []),
          ),
        ),
      ),
    );
    expect(find.text('No comments yet'), findsOneWidget);
    expect(find.text('General discussion'), findsOneWidget);
  });

  testWidgets('an outdated thread keeps its location and gains no jump '
      'action', (tester) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(outdated: true),
            onResolutionRequested: (_, {required resolved}) {},
          ),
        ),
      ),
    );

    expect(find.text('On new line 11'), findsOneWidget);
    expect(find.text('Outdated location'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('every label is overridable', (tester) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(),
            onResolutionRequested: (_, {required resolved}) {},
            labels: BirbReviewThreadLabels(
              unresolvedLabel: 'Offen',
              resolveAction: 'Erledigen',
              anchorLabel: (anchor) => 'Zeile ${anchor.lineNumber}',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Offen'), findsOneWidget);
    expect(find.text('Erledigen'), findsOneWidget);
    expect(find.text('Zeile 11'), findsOneWidget);
    expect(find.text('Unresolved'), findsNothing);
  });

  testWidgets('at 320 logical pixels and 200 percent text nothing clips and '
      'the action stays keyboard reachable', (tester) async {
    useViewport(tester, const Size(320, 600));
    final requests = <String>[];
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewThreadView(
            thread: lineThread(),
            onResolutionRequested: (id, {required resolved}) =>
                requests.add(id),
          ),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    // A selectable plain-text body wraps rather than clipping.
    final bodySize = tester.getSize(
      find.byKey(BirbReviewThreadKeys.commentBody('comment-1')),
    );
    expect(bodySize.width, lessThanOrEqualTo(320));
    expect(
      bodySize.height,
      greaterThan(BirbTheme.light.textTheme.bodyMedium!.fontSize! * 2),
    );

    final action = find.byKey(BirbReviewThreadKeys.resolutionAction);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(focusIsInside(action), isTrue);
    expect(requests, <String>['thread-line']);
  });
}
