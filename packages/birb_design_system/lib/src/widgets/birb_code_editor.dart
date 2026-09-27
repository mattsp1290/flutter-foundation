import 'package:flutter/material.dart';

import '../review/birb_review_style.dart';
import 'birb_code_controller.dart';
import 'birb_code_theme.dart';

/// A bounded native editor with logical line numbers and soft-wrapped source.
///
/// The host owns [controller] and [focusNode], source limits, persistence and
/// formatting. This widget never rewrites the source (including real tabs).
/// Tab retains platform focus traversal. Supply finite width and height.
class BirbCodeEditor extends StatefulWidget {
  const BirbCodeEditor({
    required this.controller,
    super.key,
    this.focusNode,
    this.onChanged,
    this.readOnly = false,
    this.label = 'Source code',
    this.theme = BirbCodeTheme.foundation,
  });

  final BirbCodeController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String label;
  final BirbCodeTheme theme;

  @override
  State<BirbCodeEditor> createState() => _BirbCodeEditorState();
}

class _BirbCodeEditorState extends State<BirbCodeEditor> {
  final _scroll = ScrollController();
  bool _focused = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.theme.resolve(theme);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! BirbCodeColors),
          colors,
        ],
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colors.cursor,
          selectionColor: colors.selection,
          selectionHandleColor: colors.cursor,
        ),
      ),
      child: Builder(builder: (context) => _editor(context, theme, colors)),
    );
  }

  Widget _editor(BuildContext context, ThemeData theme, BirbCodeColors colors) {
    final style = BirbReviewStyle.codeTextStyle(theme)
        .copyWith(color: colors.foreground);
    final scale = MediaQuery.textScalerOf(context);
    return Focus(
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(
            color: _focused ? colors.cursor : colors.gutter,
            width: _focused ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => LayoutBuilder(
              builder: (context, constraints) {
                final digits = (('\n'.allMatches(value.text).length) + 1)
                    .toString()
                    .length;
                final measure = TextPainter(
                  text: TextSpan(text: '9' * digits, style: style),
                  textDirection: TextDirection.ltr,
                  textScaler: scale,
                )..layout();
                final gutterWidth = measure.width + 16;
                measure.dispose();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: gutterWidth,
                        child: ClipRect(
                          child: CustomPaint(
                            painter: _LineNumbers(
                              source: widget.controller.buildTextSpan(
                                context: context,
                                style: style,
                                withComposing: true,
                              ),
                              text: value.text,
                              style: style.copyWith(color: colors.gutter),
                              scale: scale,
                              sourceWidth: (constraints.maxWidth - gutterWidth)
                                  .clamp(1, double.infinity),
                              scroll: _scroll,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        label: widget.label,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          scrollController: _scroll,
                          onChanged: widget.onChanged,
                          readOnly: widget.readOnly,
                          textDirection: TextDirection.ltr,
                          textAlignVertical: TextAlignVertical.top,
                          style: style,
                          strutStyle: StrutStyle.fromTextStyle(style),
                          maxLines: null,
                          expands: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isCollapsed: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            // A hint is announced as the native field label without
                            // inserting a floating row that would offset the gutter.
                            hintText: null,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LineNumbers extends CustomPainter {
  _LineNumbers({
    required this.source,
    required this.text,
    required this.style,
    required this.scale,
    required this.sourceWidth,
    required this.scroll,
  }) : super(repaint: scroll);

  final TextSpan source;
  final String text;
  final TextStyle style;
  final TextScaler scale;
  final double sourceWidth;
  final ScrollController scroll;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TextPainter(
      text: source,
      textDirection: TextDirection.ltr,
      textScaler: scale,
      strutStyle: StrutStyle.fromTextStyle(style),
    )..layout(maxWidth: sourceWidth);
    final number = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scale,
    );
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    var line = 1;
    var start = 0;
    while (true) {
      final caret = layout.getOffsetForCaret(
        TextPosition(offset: start),
        Rect.zero,
      );
      number.text = TextSpan(text: '$line', style: style);
      number.layout();
      final top = caret.dy - offset;
      if (top + number.height >= 0 && top < size.height) {
        number.paint(canvas, Offset(size.width - number.width - 12, top));
      }
      final newline = text.indexOf('\n', start);
      if (newline == -1) break;
      start = newline + 1;
      line++;
    }
    layout.dispose();
    number.dispose();
  }

  @override
  bool shouldRepaint(_LineNumbers oldDelegate) => true;
}
