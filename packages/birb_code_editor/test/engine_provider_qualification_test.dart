import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

// W1 feasibility experiment, not the W2 provider contract. Exercises only
// exported geometry and transaction hooks with an independently delayed result.
void main() {
  testWidgets(
    'async provider UI uses public geometry and rejects stale results',
    (tester) async {
      final controller = CodeLineEditingController.fromText(
        'bad\r\nsource',
        const CodeLineOptions(preserveLineBreaks: true),
      );
      final first = Completer<String>();
      final key = GlobalKey<_ProviderProbeState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ProviderProbe(key: key, controller: controller),
          ),
        ),
      );
      await tester.pump();
      key.currentState!.request(first.future);
      controller.replaceSelection('x');
      first.complete('stale completion');
      await tester.pump();
      expect(find.text('stale completion'), findsNothing);
      final next = Completer<String>();
      key.currentState!.request(next.future);
      next.complete('replacement');
      await tester.pump();
      await tester.pump();
      expect(find.text('replacement'), findsOneWidget);
      expect(find.byKey(const ValueKey('diagnostic-range')), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Warning on line 1: test diagnostic'),
        findsOneWidget,
      );
      expect(find.text('Hover: fixture information'), findsOneWidget);
      final sourceBefore = controller.text;
      await tester.tap(find.text('replacement'));
      await tester.pump();
      expect(controller.text, 'replacement\r\nsource');
      controller.undo();
      expect(controller.text, sourceBefore);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
    variant: TargetPlatformVariant.desktop(),
  );
}

class _ProviderProbe extends StatefulWidget {
  const _ProviderProbe({super.key, required this.controller});
  final CodeLineEditingController controller;
  @override
  State<_ProviderProbe> createState() => _ProviderProbeState();
}

class _ProviderProbeState extends State<_ProviderProbe> {
  final _scroll = CodeScrollController();
  CodeIndicatorValueNotifier? _geometry;
  String? _result;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_invalidate);
  }

  void _invalidate() {
    _request++;
    if (_result != null) setState(() => _result = null);
  }

  void request(Future<String> response) {
    final token = ++_request;
    response.then((value) {
      if (mounted && token == _request) setState(() => _result = value);
    });
  }

  @override
  void dispose() {
    _request++;
    widget.controller.removeListener(_invalidate);
    _scroll.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final paragraph = _geometry?.value?.paragraphs.first;
    // W1 uses no gutter so the paragraph and overlay have the same origin.
    // The final product must also account for gutter placement and clipping.
    final caret = paragraph?.getOffset(const TextPosition(offset: 0));
    final range = paragraph?.getRangeRects(const TextRange(start: 0, end: 3));
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              CodeEditor(
                controller: widget.controller,
                scrollController: _scroll,
                autofocus: false,
                wordWrap: true,
                indicatorBuilder: (context, controller, chunks, notifier) {
                  _geometry = notifier;
                  return const SizedBox.shrink();
                },
              ),
              if (result != null && paragraph != null && range != null)
                for (final rect in range)
                  Positioned.fromRect(
                    rect: rect.shift(paragraph.offset),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('diagnostic-range'),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              if (result != null && caret != null && paragraph != null)
                Positioned(
                  left: caret.dx + paragraph.offset.dx,
                  top:
                      caret.dy +
                      paragraph.offset.dy +
                      paragraph.preferredLineHeight,
                  child: Material(
                    child: TextButton(
                      onPressed: () => widget.controller.runRevocableOp(() {
                        widget.controller.replaceSelection(
                          result,
                          CodeLineSelection(
                            baseIndex: 0,
                            baseOffset: 0,
                            extentIndex: 0,
                            extentOffset:
                                widget.controller.codeLines.first.length,
                          ),
                        );
                      }),
                      child: Text(result),
                    ),
                  ),
                ),
              if (result != null && caret != null && paragraph != null)
                Positioned(
                  left: caret.dx + paragraph.offset.dx,
                  top:
                      caret.dy +
                      paragraph.offset.dy +
                      3 * paragraph.preferredLineHeight,
                  child: const Material(
                    child: Text('Hover: fixture information'),
                  ),
                ),
            ],
          ),
        ),
        if (result != null) ...[
          TextButton(
            onPressed: () => widget.controller.selectLine(0),
            child: const Text('Warning on line 1: test diagnostic'),
          ),
        ],
      ],
    );
  }
}
