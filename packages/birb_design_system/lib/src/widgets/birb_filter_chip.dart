import 'package:flutter/material.dart';

/// A filter chip whose selected checkmark remains visible when disabled.
///
/// Flutter does not resolve a stateful [ChipThemeData.checkmarkColor], so a
/// theme alone cannot choose different enabled and disabled checkmark colors.
/// This wrapper supplies the concrete color that [FilterChip] paints.
final class BirbFilterChip extends StatelessWidget {
  const BirbFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      autofocus: autofocus,
      checkmarkColor: onSelected == null
          ? theme.disabledColor
          : theme.colorScheme.onPrimary,
      focusNode: focusNode,
      label: label,
      onSelected: onSelected,
      selected: selected,
    );
  }
}
