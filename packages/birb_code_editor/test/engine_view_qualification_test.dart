import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/qualification_view.dart';

import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/go.dart';

void main() {
  testWidgets(
    'two views and repeated highlighted remounts release subscriptions',
    (tester) async {
      const source = 'package main\r\n// fixture\rfunc main() {}\n';
      final first = _TrackedController(
        CodeLineEditingController.fromText(
          source,
          const CodeLineOptions(preserveLineBreaks: true),
        ),
      );
      final second = _TrackedController(
        CodeLineEditingController.fromText('independent'),
      );
      first.replaceSelection('x');
      final expectedSource = first.text;
      final expectedSelection = first.selection;
      for (var cycle = 0; cycle < 20; cycle++) {
        final scrolls = [CodeScrollController(), CodeScrollController()];
        await tester.pumpWidget(
          MaterialApp(
            theme: cycle.isEven ? ThemeData.light() : ThemeData.dark(),
            home: Scaffold(
              body: Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    SizedBox(
                      height: 180,
                      child: CodeEditor(
                        controller: i == 0 ? first : second,
                        scrollController: scrolls[i],
                        autofocus: false,
                        style: CodeEditorStyle(
                          fontSize: cycle.isEven ? 14 : 18,
                          codeTheme: CodeHighlightTheme(
                            languages: {
                              'go': CodeHighlightThemeMode(mode: langGo),
                            },
                            theme: const {},
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(first.text, expectedSource);
        expect(first.selection, expectedSelection);
        expect(second.text, 'independent');
        expect(first.subscriptions, greaterThan(0));
        await tester.pumpWidget(const SizedBox());
        expect(first.subscriptions, 0);
        expect(second.subscriptions, 0);
        for (final scroll in scrolls) {
          scroll.dispose();
          scroll.verticalScroller.dispose();
          scroll.horizontalScroller.dispose();
        }
      }
      first.undo();
      expect(first.text, source);
      first.dispose();
      second.dispose();
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets('64 KiB single line is not replaced by a truncated paragraph', (
    tester,
  ) async {
    final controller = CodeLineEditingController.fromText('x' * 65536);
    CodeIndicatorValueNotifier? geometry;
    final scroll = CodeScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeEditor(
            controller: controller,
            scrollController: scroll,
            wordWrap: false,
            autofocus: false,
            maxLengthSingleLineRendering: 65536,
            indicatorBuilder: (context, controller, chunks, notifier) {
              geometry = notifier;
              return DefaultCodeLineNumber(
                controller: controller,
                notifier: notifier,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(geometry!.value!.paragraphs.single.length, 65536);
    expect(geometry!.value!.paragraphs.single.chunkLongText, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    scroll.dispose();
    scroll.verticalScroller.dispose();
    scroll.horizontalScroller.dispose();
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('catalog probe mounts, edits through input and detaches', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BirbEditorQualification())),
    );
    await tester.pump();
    expect(find.byType(DefaultCodeLineNumber), findsOneWidget);
    final engine = tester
        .widget<CodeEditor>(find.byType(CodeEditor))
        .controller!;
    final before = engine.text;
    await tester.tap(find.byType(CodeEditor));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isTrue);
    // A real framework keyboard command selects source before platform text input.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(engine.isAllSelected, isTrue);
    final editing = tester.testTextInput.editingState!;
    final client =
        (tester.testTextInput.log
                    .lastWhere((call) => call.method == 'TextInput.setClient')
                    .arguments
                as List)
            .first;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithDeltas', [
          client,
          {
            'deltas': [
              {
                'oldText': editing['text'],
                'deltaText': 'package changed',
                'deltaStart': editing['selectionBase'],
                'deltaEnd': editing['selectionExtent'],
                'selectionBase': 15,
                'selectionExtent': 15,
                'selectionAffinity': 'TextAffinity.downstream',
                'selectionIsDirectional': false,
                'composingBase': -1,
                'composingExtent': -1,
              },
            ],
          },
        ]),
      ),
      (_) {},
    );
    await tester.pump();
    expect(engine.text, 'package changed');
    await tester.pump();
    expect(find.text('Recovery: 15 UTF-16 units'), findsOneWidget);
    engine.undo();
    expect(engine.text, before);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('public paragraphs expose range geometry after wrap and scroll', (
    tester,
  ) async {
    final controller = CodeLineEditingController.fromText(
      List.generate(
        100,
        (i) => 'line $i has a long visible source range',
      ).join('\n'),
    );
    final scroll = CodeScrollController();
    CodeIndicatorValueNotifier? geometry;
    Future<void> mount(bool wrap) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 200,
            child: CodeEditor(
              controller: controller,
              scrollController: scroll,
              wordWrap: wrap,
              indicatorBuilder: (context, controller, chunks, notifier) {
                geometry = notifier;
                return DefaultCodeLineNumber(
                  controller: controller,
                  notifier: notifier,
                );
              },
            ),
          ),
        ),
      ),
    );
    await mount(false);
    await tester.pump();
    var paragraph = geometry!.value!.paragraphs.first;
    expect(paragraph.getOffset(const TextPosition(offset: 2)), isNotNull);
    expect(
      paragraph.getRangeRects(const TextRange(start: 0, end: 4)),
      isNotEmpty,
    );
    scroll.verticalScroller.jumpTo(500);
    await tester.pump();
    expect(geometry!.value!.paragraphs.first.index, greaterThan(0));
    await mount(true);
    await tester.pump();
    paragraph = geometry!.value!.paragraphs.first;
    expect(
      paragraph.getRangeRects(const TextRange(start: 0, end: 20)),
      isNotEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    scroll.dispose();
    scroll.verticalScroller.dispose();
    scroll.horizontalScroller.dispose();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}

class _TrackedController extends CodeLineEditingControllerDelegate {
  _TrackedController(CodeLineEditingController controller)
    : super(delegate: controller);
  int subscriptions = 0;

  @override
  void addListener(VoidCallback listener) {
    subscriptions++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    subscriptions--;
    super.removeListener(listener);
  }
}
