import 'package:flutter/material.dart';

import 'birb_code_palette.dart';

/// Named code palettes are independent of the application's light/dark mode.
enum BirbCodeTheme {
  foundation('Foundation'),
  dracula('Dracula'),
  githubLight('GitHub Light'),
  githubDark('GitHub Dark');

  const BirbCodeTheme(this.label);
  final String label;

  BirbCodeColors resolve(ThemeData theme) => this == foundation
      ? BirbCodeColors(
          background: theme.colorScheme.surface,
          foreground: theme.colorScheme.onSurface,
          gutter: theme.colorScheme.onSurfaceVariant,
          comment: theme.colorScheme.onSurfaceVariant,
          keyword: theme.colorScheme.primary,
          string: theme.colorScheme.secondary,
          number: theme.colorScheme.secondary,
          selection: theme.colorScheme.surfaceContainer,
          cursor: theme.colorScheme.primary,
        )
      : codePalette(this);
}

/// Complete code-surface roles, also available to other source renderers.
@immutable
class BirbCodeColors extends ThemeExtension<BirbCodeColors> {
  const BirbCodeColors({
    required this.background,
    required this.foreground,
    required this.gutter,
    required this.comment,
    required this.keyword,
    required this.string,
    required this.number,
    required this.selection,
    required this.cursor,
  });
  final Color background,
      foreground,
      gutter,
      comment,
      keyword,
      string,
      number,
      selection,
      cursor;
  @override
  BirbCodeColors copyWith({
    Color? background,
    Color? foreground,
    Color? gutter,
    Color? comment,
    Color? keyword,
    Color? string,
    Color? number,
    Color? selection,
    Color? cursor,
  }) => BirbCodeColors(
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    gutter: gutter ?? this.gutter,
    comment: comment ?? this.comment,
    keyword: keyword ?? this.keyword,
    string: string ?? this.string,
    number: number ?? this.number,
    selection: selection ?? this.selection,
    cursor: cursor ?? this.cursor,
  );
  @override
  BirbCodeColors lerp(covariant BirbCodeColors? other, double t) =>
      other != null && t >= .5 ? other : this;
}

/// Caller-owned selection; this control never persists preferences itself.
class BirbCodeThemeSelector extends StatelessWidget {
  const BirbCodeThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final BirbCodeTheme value;
  final ValueChanged<BirbCodeTheme> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    child: PopupMenuButton<BirbCodeTheme>(
      tooltip: 'Editor theme',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final theme in BirbCodeTheme.values)
          PopupMenuItem(value: theme, child: Text(theme.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Editor theme: ${value.label}'),
      ),
    ),
  );
}
