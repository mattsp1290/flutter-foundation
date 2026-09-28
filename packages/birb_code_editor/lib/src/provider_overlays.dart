import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'language_provider.dart';

/// A surface-contained popup; editor chrome and exit controls stay unobscured.
class EditorProviderPopup extends StatelessWidget {
  const EditorProviderPopup({
    super.key,
    required this.anchor,
    required this.size,
    required this.title,
    required this.close,
    required this.child,
    this.fitContent = false,
  });
  final Rect anchor;
  final Size size;
  final String title;
  final VoidCallback close;
  final Widget child;
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final width = math.min(360.0, size.width);
    final height = math.min(
      size.height,
      math.min(280.0, math.max(96.0, size.height * .75)),
    );
    final left = anchor.left.clamp(0.0, math.max(0.0, size.width - width));
    final below = size.height - anchor.bottom;
    final top = (below >= height ? anchor.bottom : anchor.top - height).clamp(
      0.0,
      math.max(0.0, size.height - height),
    );
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: math.max(96, height)),
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: title,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: Border.all(color: Theme.of(context).colorScheme.outline),
            child: Column(
              mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss $title',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  fit: fitContent ? FlexFit.loose : FlexFit.tight,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Positioned(
      left: left.toDouble(),
      top: fitContent && below < height ? null : top.toDouble(),
      bottom: fitContent && below < height
          ? (size.height - anchor.top).clamp(0.0, size.height - height)
          : null,
      width: width,
      height: fitContent && height >= 96 ? null : height,
      child: height < 96
          ? SingleChildScrollView(child: SizedBox(height: 96, child: content))
          : content,
    );
  }
}

class EditorCompletionList extends StatelessWidget {
  const EditorCompletionList({
    super.key,
    required this.items,
    required this.selected,
    required this.scrollController,
    required this.accept,
    required this.enabled,
  });
  final List<BirbEditorCompletion> items;
  final int selected;
  final ScrollController scrollController;
  final ValueChanged<BirbEditorCompletion> accept;
  final bool enabled;

  static double rowHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final title = theme.bodyMedium;
    final detail = theme.bodySmall;
    final textHeight =
        (title?.fontSize ?? 14) * (title?.height ?? 1.5) +
        (detail?.fontSize ?? 12) * (detail?.height ?? 1.5);
    return math.max(
      48,
      MediaQuery.textScalerOf(context).scale(textHeight) + 24,
    );
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: scrollController,
    itemCount: items.length,
    itemExtent: rowHeight(context),
    itemBuilder: (context, index) {
      final item = items[index];
      final theme = Theme.of(context);
      final foreground = index == selected
          ? theme.colorScheme.onSecondaryContainer
          : theme.colorScheme.onSurface;
      return Semantics(
        selected: index == selected,
        button: true,
        child: Material(
          color: index == selected
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          child: InkWell(
            onTap: enabled ? () => accept(item) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
