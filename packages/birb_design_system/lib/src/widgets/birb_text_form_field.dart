import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart';

import '../color/birb_semantic_colors.dart';
import '../theme/birb_theme.dart';
import '../theme/components/input_decoration_theme.dart';
import '../tokens/birb_tokens.dart';

/// A labeled Birb Party text field using the ledger-caption layout.
///
/// The caption occupies its own cell instead of floating through the field
/// outline. At narrow widths or large text scales the caption stacks above the
/// editable value so neither region has to truncate.
///
/// An outer [FormField] owns validation, forced errors, save, and reset state;
/// its borderless [TextField] owns editing, focus, and input callbacks. The
/// widget synchronizes those layers while borrowing any caller-provided
/// controller or focus node, and disposes only the objects it creates.
class BirbTextFormField extends StatefulWidget {
  const BirbTextFormField({
    required this.label,
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.enabled = true,
    this.required = false,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
  }) : assert(controller == null || initialValue == null);

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool enabled;
  final bool required;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  State<BirbTextFormField> createState() => _BirbTextFormFieldState();
}

class _BirbTextFormFieldState extends State<BirbTextFormField> {
  static const _stackBreakpoint = 480.0;
  static const _wideCaptionWidth = 152.0;
  static const _maximumInlineLabelScale = 1.35;

  final _formFieldKey = GlobalKey<FormFieldState<String>>();
  late TextEditingController _controller;
  late bool _ownsController;
  late String _initialText;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _hovered = false;
  bool _syncingController = false;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(BirbTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _detachController();
      _attachController(widget.controller);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncFormValue();
      });
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
    if (!widget.enabled && _hovered) {
      _hovered = false;
    }
  }

  @override
  void dispose() {
    _detachController();
    _detachFocusNode();
    super.dispose();
  }

  void _attachController(TextEditingController? suppliedController) {
    _ownsController = suppliedController == null;
    _controller =
        suppliedController ??
        TextEditingController(text: widget.initialValue ?? '');
    _initialText = _controller.text;
    _controller.addListener(_handleControllerChange);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerChange);
    if (_ownsController) _controller.dispose();
  }

  void _handleControllerChange() {
    if (!_syncingController) _syncFormValue();
  }

  void _syncFormValue() {
    _formFieldKey.currentState?.didChange(_controller.text);
  }

  void _resetController() {
    _syncingController = true;
    _controller.value = TextEditingValue(text: _initialText);
    _syncingController = false;
  }

  void _attachFocusNode(FocusNode? suppliedNode) {
    _ownsFocusNode = suppliedNode == null;
    _focusNode = suppliedNode ?? FocusNode(debugLabel: 'BirbTextFormField');
    _focusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantics = theme.extension<BirbSemanticColors>()!;
    final externalError = widget.errorText?.isNotEmpty ?? false
        ? widget.errorText
        : null;

    return FormField<String>(
      key: _formFieldKey,
      initialValue: _initialText,
      enabled: widget.enabled,
      forceErrorText: externalError,
      validator: widget.validator,
      onSaved: widget.onSaved,
      onReset: _resetController,
      autovalidateMode: widget.autovalidateMode,
      builder: (field) =>
          _buildLedger(theme, colors, semantics, errorText: field.errorText),
    );
  }

  Widget _buildLedger(
    ThemeData theme,
    ColorScheme colors,
    BirbSemanticColors semantics, {
    required String? errorText,
  }) {
    final hasError = errorText?.isNotEmpty ?? false;
    final side = BirbInputDecorationTheme.borderSide(
      colors: colors,
      semantics: semantics,
      enabled: widget.enabled,
      hasError: hasError,
      focused: _focusNode.hasFocus,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MouseRegion(
          onEnter: widget.enabled
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: widget.enabled
              ? (_) => setState(() => _hovered = false)
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(side),
              borderRadius: BirbRadii.none,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labelFontSize = theme.textTheme.labelLarge?.fontSize;
                final scaledLabelSize = labelFontSize == null
                    ? 0
                    : MediaQuery.textScalerOf(context).scale(labelFontSize);
                final stack =
                    constraints.maxWidth < _stackBreakpoint ||
                    (labelFontSize != null &&
                        scaledLabelSize >
                            labelFontSize * _maximumInlineLabelScale);
                final caption = _caption(theme, semantics, hasError: hasError);
                final editor = _editor(
                  colors,
                  hasError: hasError,
                  errorText: errorText,
                );

                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      caption,
                      _Divider(axis: Axis.horizontal, color: side.color),
                      editor,
                    ],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(width: _wideCaptionWidth, child: caption),
                      _Divider(axis: Axis.vertical, color: side.color),
                      Expanded(child: editor),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: BirbSpacing.space1),
          Semantics(
            container: true,
            liveRegion: true,
            label: 'Error: $errorText',
            child: ExcludeSemantics(
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    color: semantics.errorIndicator,
                    size: BirbSpacing.space4,
                  ),
                  const SizedBox(width: BirbSpacing.space1),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantics.errorIndicator,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _caption(
    ThemeData theme,
    BirbSemanticColors semantics, {
    required bool hasError,
  }) {
    final colors = theme.colorScheme;
    final suffix = !widget.enabled
        ? ' — Disabled'
        : widget.required
        ? ' (required)'
        : '';
    final color = !widget.enabled
        ? semantics.disabled
        : hasError
        ? semantics.errorIndicator
        : colors.onSurfaceVariant;

    return GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: ColoredBox(
        color: colors.surfaceContainerLow,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BirbSizes.minimumInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.all(BirbSpacing.space3),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ExcludeSemantics(
                child: Text(
                  '${widget.label}$suffix',
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor(
    ColorScheme colors, {
    required bool hasError,
    required String? errorText,
  }) {
    final semanticLabel = widget.required
        ? '${widget.label}, required'
        : widget.label;

    return ColoredBox(
      color: _hovered && widget.enabled
          ? colors.surfaceContainerHigh
          : colors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BirbSizes.minimumInteractiveDimension,
        ),
        child: MergeSemantics(
          child: Semantics(
            label: semanticLabel,
            enabled: widget.enabled,
            isRequired: widget.required,
            hint: hasError ? 'Error: $errorText' : null,
            validationResult: hasError
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              onChanged: widget.onChanged,
              onSubmitted: widget.onFieldSubmitted,
              style: BirbTheme.inputTextStyle(context),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: widget.hintText,
                contentPadding: const EdgeInsets.all(BirbSpacing.space3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.axis, required this.color});

  final Axis axis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.vertical ? BirbBorders.thin : null,
      height: axis == Axis.horizontal ? BirbBorders.thin : null,
      child: ColoredBox(color: color),
    );
  }
}
