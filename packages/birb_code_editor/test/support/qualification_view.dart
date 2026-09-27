import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/go.dart';

import 'package:birb_code_editor/src/engine_adapter.dart';

/// Temporary interactive W1 probe; not the production editor API.
class BirbEditorQualification extends StatefulWidget {
  const BirbEditorQualification({super.key, this.onSourceChanged});

  final ValueChanged<String>? onSourceChanged;

  @override
  State<BirbEditorQualification> createState() => _QualificationState();
}

class _QualificationState extends State<BirbEditorQualification> {
  late final EngineAdapter _adapter;
  final _scroll = CodeScrollController();
  String _recovery = '';
  bool _wrap = false;

  @override
  void initState() {
    super.initState();
    _adapter = EngineAdapter(
      'package main\r\n\r\n// Mixed separators remain exact.\r'
      'func main() {\n\tprintln("hello", 42)\r\n}\n',
      onSourceChanged: (source) {
        widget.onSourceChanged?.call(source);
        setState(() => _recovery = source);
      },
    );
    _recovery = _adapter.source;
  }

  @override
  void dispose() {
    _adapter.dispose();
    _scroll.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BirbCodeTheme.foundation.resolve(theme);
    final textStyle = BirbReviewStyle.codeTextStyle(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Native editor qualification — W1 in progress'),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('Probe wrap'),
              selected: _wrap,
              onSelected: (value) => setState(() => _wrap = value),
            ),
            TextButton(
              onPressed: _adapter.engine.undo,
              child: const Text('Probe undo'),
            ),
            TextButton(
              onPressed: _adapter.engine.redo,
              child: const Text('Probe redo'),
            ),
            Text('Recovery: ${_recovery.length} UTF-16 units'),
          ],
        ),
        SizedBox(
          height: 320,
          child: CodeEditor(
            controller: _adapter.engine,
            scrollController: _scroll,
            wordWrap: _wrap,
            maxLengthSingleLineRendering: 65536,
            style: CodeEditorStyle(
              fontSize: textStyle.fontSize,
              fontFamily: BirbReviewStyle.codeTextStyle(theme).fontFamily,
              fontFamilyFallback: BirbReviewStyle.codeTextStyle(theme)
                  .fontFamilyFallback,
              textColor: colors.foreground,
              backgroundColor: colors.background,
              selectionColor: colors.selection,
              cursorColor: colors.cursor,
              codeTheme: CodeHighlightTheme(
                languages: {'go': CodeHighlightThemeMode(mode: langGo)},
                theme: {
                  'keyword': TextStyle(color: colors.keyword),
                  'comment': TextStyle(color: colors.comment),
                  'string': TextStyle(color: colors.string),
                  'number': TextStyle(color: colors.number),
                },
              ),
            ),
            indicatorBuilder: (context, controller, chunks, notifier) => Row(
              children: [
                DefaultCodeLineNumber(
                  notifier: notifier,
                  controller: controller,
                  textStyle: textStyle.copyWith(color: colors.gutter),
                ),
                DefaultCodeChunkIndicator(
                  width: 24,
                  controller: chunks,
                  notifier: notifier,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
