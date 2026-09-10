import 'dart:ui' show Tristate;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/focus_test_support.dart';
import 'review_test_fixtures.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onSubmit,
    VoidCallback? onCancel,
    bool isSubmitting = false,
    bool enabled = true,
    String? errorText,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    TextEditingController? draft,
    Key? key,
    bool? settle,
  }) async {
    await tester.pumpWidget(
      themedHost(
        SingleChildScrollView(
          child: BirbReviewComposer(
            key: key,
            controller: draft ?? controller,
            focusNode: focusNode,
            onSubmit: onSubmit,
            onCancel: onCancel,
            isSubmitting: isSubmitting,
            enabled: enabled,
            errorText: errorText,
          ),
        ),
        brightness: brightness,
        textScale: textScale,
      ),
    );
    // An indeterminate progress indicator never settles.
    if (settle ?? !isSubmitting) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} renders a multiline ledger editor', (
      tester,
    ) async {
      await pump(tester, brightness: brightness, onSubmit: (_) {});
      expect(find.text('Reply'), findsOneWidget);
      final editor = tester.widget<TextField>(find.byType(TextField));
      expect(editor.minLines, 3);
      expect(editor.maxLines, 8);
      expect(editor.keyboardType, TextInputType.multiline);
      expect(editor.textInputAction, TextInputAction.newline);
      expect(editor.readOnly, isFalse);
    });
  }

  testWidgets('a whitespace-only draft is rejected with a visible correction', (
    tester,
  ) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);

    await tester.enterText(find.byType(TextField), '   \n  ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
    await tester.pumpAndSettle();

    expect(submitted, isEmpty);
    expect(find.text('Write something before sending.'), findsOneWidget);
    expect(controller.text, '   \n  ');

    await tester.enterText(find.byType(TextField), 'Now valid');
    await tester.pumpAndSettle();
    expect(find.text('Write something before sending.'), findsNothing);
  });

  testWidgets('a valid draft is emitted untrimmed and multiline', (
    tester,
  ) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);

    await tester.enterText(find.byType(TextField), '  first line\nsecond  ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
    await tester.pumpAndSettle();

    expect(submitted, <String>['  first line\nsecond  ']);
  });

  testWidgets('two activations before a host rebuild submit once', (
    tester,
  ) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(BirbReviewComposerKeys.submitAction),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pump();

    expect(submitted, <String>['Draft']);
  });

  testWidgets('the guard disables the action while it holds', (tester) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.pumpAndSettle();

    tester
        .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
        .onPressed!();
    // Within the same frame the action is visibly unavailable, not silently
    // inert.
    await tester.pump(Duration.zero);
    expect(
      tester
          .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
          .onPressed,
      isNull,
    );
    expect(submitted, hasLength(1));
  });

  testWidgets('the guard releases without any prop change', (tester) async {
    final submitted = <String>[];
    // A host that keeps a stable callback and never changes a prop must not
    // leave the composer permanently unable to submit.
    void onSubmit(String text) => submitted.add(text);

    await pump(tester, onSubmit: onSubmit);
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.pumpAndSettle();

    for (var attempt = 0; attempt < 3; attempt += 1) {
      await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
      await tester.pumpAndSettle();
    }
    expect(submitted, hasLength(3));
    expect(
      tester
          .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('an identical repeated failure still allows a retry', (
    tester,
  ) async {
    final submitted = <String>[];
    void onSubmit(String text) => submitted.add(text);

    await pump(tester, onSubmit: onSubmit, errorText: 'boom');
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.pumpAndSettle();

    for (var attempt = 0; attempt < 3; attempt += 1) {
      await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
      // The host reports the same error every time: no prop delta at all.
      await pump(tester, onSubmit: onSubmit, errorText: 'boom');
    }
    expect(submitted, hasLength(3));
  });

  testWidgets('while submitting the text stays visible and read-only, the '
      'actions are disabled, and progress is announced', (tester) async {
    controller.text = 'Pending draft';
    await pump(tester, onSubmit: (_) {}, onCancel: () {}, isSubmitting: true);

    expect(find.text('Pending draft'), findsOneWidget);
    expect(find.text('Sending reply'), findsWidgets);
    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.readOnly, isTrue);
    expect(editor.enabled, isTrue);

    expect(
      tester
          .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(BirbReviewComposerKeys.cancelAction),
          )
          .onPressed,
      isNull,
    );
    final pending = tester
        .getSemantics(find.byKey(BirbReviewComposerKeys.pendingStatus))
        .getSemanticsData();
    expect(pending.label, 'Sending reply');
    expect(pending.flagsCollection.isLiveRegion, isTrue);

    await tester.enterText(find.byType(TextField), 'Typed over');
    await tester.pump();
    expect(controller.text, 'Pending draft');
  });

  testWidgets('read-only while submitting is distinct from disabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    controller.text = 'Draft';

    await pump(tester, onSubmit: (_) {}, isSubmitting: true);
    expect(
      tester
          .getSemantics(find.byType(TextField))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      isNot(Tristate.isFalse),
    );

    await pump(tester, onSubmit: (_) {}, enabled: false);
    expect(
      tester
          .getSemantics(find.byType(TextField))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    handle.dispose();
  });

  testWidgets('a failure keeps the draft, shows the error, and retries', (
    tester,
  ) async {
    final submitted = <String>[];
    controller.text = 'Recoverable draft';

    await pump(tester, onSubmit: submitted.add, isSubmitting: true);
    await pump(
      tester,
      onSubmit: submitted.add,
      errorText: 'The server rejected the reply.',
    );

    expect(controller.text, 'Recoverable draft');
    expect(find.text('Recoverable draft'), findsOneWidget);
    expect(find.text('The server rejected the reply.'), findsOneWidget);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Error: The server rejected the reply.'),
      ),
      isNotNull,
    );

    await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
    await tester.pumpAndSettle();
    expect(submitted, <String>['Recoverable draft']);
  });

  testWidgets('the host clears the draft on success; the widget never does', (
    tester,
  ) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);
    await tester.enterText(find.byType(TextField), 'Sent draft');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BirbReviewComposerKeys.submitAction));
    await tester.pumpAndSettle();

    await pump(tester, onSubmit: submitted.add, isSubmitting: true);
    expect(controller.text, 'Sent draft');

    await pump(tester, onSubmit: submitted.add);
    expect(controller.text, 'Sent draft');

    controller.clear();
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
  });

  testWidgets('a disabled composer blocks input and every callback', (
    tester,
  ) async {
    final submitted = <String>[];
    var cancelled = 0;
    controller.text = 'Draft';
    await pump(
      tester,
      onSubmit: submitted.add,
      onCancel: () => cancelled += 1,
      enabled: false,
    );

    expect(
      tester
          .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(BirbReviewComposerKeys.cancelAction),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'Typed');
    await tester.pumpAndSettle();
    expect(controller.text, 'Draft');
    expect(submitted, isEmpty);
    expect(cancelled, 0);
  });

  testWidgets('cancel is hidden without a callback and reports otherwise', (
    tester,
  ) async {
    await pump(tester, onSubmit: (_) {});
    expect(find.byKey(BirbReviewComposerKeys.cancelAction), findsNothing);

    var cancelled = 0;
    await pump(tester, onSubmit: (_) {}, onCancel: () => cancelled += 1);
    await tester.tap(find.byKey(BirbReviewComposerKeys.cancelAction));
    await tester.pumpAndSettle();
    expect(cancelled, 1);
  });

  testWidgets('a null onSubmit disables submission', (tester) async {
    controller.text = 'Draft';
    await pump(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(BirbReviewComposerKeys.submitAction))
          .onPressed,
      isNull,
    );
  });

  testWidgets('borrowed controllers and focus nodes survive replacement and '
      'disposal', (tester) async {
    final first = TextEditingController(text: 'First');
    final second = TextEditingController(text: 'Second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await pump(tester, onSubmit: (_) {}, draft: first);
    expect(find.text('First'), findsOneWidget);

    await pump(tester, onSubmit: (_) {}, draft: second);
    expect(find.text('Second'), findsOneWidget);
    expect(first.text, 'First');

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(first.text, 'First');
    expect(second.text, 'Second');
    expect(() => focusNode.hasFocus, returnsNormally);
  });

  testWidgets('Enter inserts a newline instead of submitting', (tester) async {
    final submitted = <String>[];
    await pump(tester, onSubmit: submitted.add);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(submitted, isEmpty);
  });

  testWidgets('at 320 logical pixels and 200 percent text nothing clips and '
      'both actions are keyboard reachable', (tester) async {
    useViewport(tester, const Size(320, 600));
    final submitted = <String>[];
    controller.text =
        'A draft long enough to wrap across several lines at a '
        'narrow width and a large text scale.';
    await pump(
      tester,
      onSubmit: submitted.add,
      onCancel: () {},
      errorText: 'A correction message that also has to wrap without clipping.',
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final error = tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.textContaining('A correction message').first,
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(error.didExceedMaxLines, isFalse);

    for (final key in <Key>[
      BirbReviewComposerKeys.submitAction,
      BirbReviewComposerKeys.cancelAction,
    ]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      focusIsInside(find.byKey(BirbReviewComposerKeys.submitAction)),
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(submitted, hasLength(1));
  });
}
