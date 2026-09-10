import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final themeCase in <(String, ThemeData)>[
    ('light', BirbTheme.light),
    ('dark', BirbTheme.dark),
  ]) {
    final (name, theme) = themeCase;
    final colors = theme.colorScheme;
    final semantics = theme.extension<BirbSemanticColors>()!;

    test('$name review style resolves only existing semantic roles', () {
      final allowed = <Color>{
        colors.surface,
        colors.onSurface,
        colors.onSurfaceVariant,
        colors.surfaceContainerLow,
        colors.surfaceContainerHigh,
        colors.outline,
        colors.error,
        colors.onError,
        semantics.success,
        semantics.onSuccess,
        semantics.warning,
        semantics.onWarning,
        semantics.info,
        semantics.onInfo,
        semantics.focus,
      };
      final used = <Color>{
        for (final kind in BirbDiffLineKind.values) ...<Color>[
          BirbReviewStyle.lineMarker(theme, kind).background,
          BirbReviewStyle.lineMarker(theme, kind).foreground,
        ],
        for (final status in BirbReviewStatus.values) ...<Color>[
          BirbReviewStyle.statusRoles(theme, status).background,
          BirbReviewStyle.statusRoles(theme, status).foreground,
        ],
        BirbReviewStyle.codeBackground(theme),
        BirbReviewStyle.selectedRowBackground(theme),
        BirbReviewStyle.hunkHeadingBackground(theme),
        BirbReviewStyle.codeTextStyle(theme).color!,
        BirbReviewStyle.gutterTextStyle(theme).color!,
        BirbReviewStyle.hunkHeadingTextStyle(theme).color!,
        BirbReviewStyle.objectSide(theme).color,
        BirbReviewStyle.activeRowSide(theme, focused: true).color,
        BirbReviewStyle.activeRowSide(theme, focused: false).color,
      };
      expect(used.difference(allowed), isEmpty);
    });

    test('$name review text pairs reach 4.5:1', () {
      final failures = <String>[];
      for (final pair in _textPairs(theme)) {
        final ratio = _contrastRatio(pair.foreground, pair.background);
        if (ratio < 4.5) {
          failures.add('${pair.name}: ${ratio.toStringAsFixed(4)} < 4.5');
        }
      }
      expect(failures, isEmpty);
    });

    test('$name review boundary and focus cues reach 3:1', () {
      final failures = <String>[];
      for (final pair in _boundaryPairs(theme)) {
        final ratio = _contrastRatio(pair.foreground, pair.background);
        if (ratio < 3) {
          failures.add('${pair.name}: ${ratio.toStringAsFixed(4)} < 3');
        }
      }
      expect(failures, isEmpty);
    });

    test('$name hunk heading carries the documented top boundary', () {
      expect(
        BirbReviewStyle.hunkHeadingBorder(theme),
        Border(top: BirbReviewStyle.objectSide(theme)),
      );
    });

    test('$name active row uses focus at 2 px and outline at 1 px', () {
      expect(
        BirbReviewStyle.activeRowSide(theme, focused: true),
        BorderSide(color: semantics.focus, width: BirbBorders.strong),
      );
      expect(
        BirbReviewStyle.activeRowSide(theme, focused: false),
        BorderSide(color: colors.outline, width: BirbBorders.thin),
      );
      expect(
        BirbReviewStyle.objectSide(theme),
        BorderSide(color: colors.outline, width: BirbBorders.thin),
      );
    });

    test(
      '$name code style keeps bodyMedium metrics and a monospace family',
      () {
        final body = theme.textTheme.bodyMedium!;
        final code = BirbReviewStyle.codeTextStyle(theme);
        expect(code.fontSize, body.fontSize);
        expect(code.height, body.height);
        expect(code.fontWeight, body.fontWeight);
        expect(code.color, colors.onSurface);
        // The intended family resolves first and the generic one last, so a
        // platform with a real monospace face never falls through to it early.
        expect(code.fontFamily, BirbReviewStyle.codeFontFamilyFallback.first);
        expect(<String>[
          code.fontFamily!,
          ...code.fontFamilyFallback!,
        ], BirbReviewStyle.codeFontFamilyFallback);
        expect(BirbReviewStyle.codeFontFamilyFallback.last, 'monospace');
      },
    );
  }

  test('every line kind has a distinct sign and kind word', () {
    final signs = BirbDiffLineKind.values.map(BirbReviewStyle.lineSign).toSet();
    final labels = BirbDiffLineKind.values
        .map(BirbReviewStyle.lineKindLabel)
        .toSet();
    expect(signs, hasLength(BirbDiffLineKind.values.length));
    expect(labels, hasLength(BirbDiffLineKind.values.length));
    expect(BirbReviewStyle.lineSign(BirbDiffLineKind.addition), '+');
    expect(BirbReviewStyle.lineSign(BirbDiffLineKind.deletion), '−');
  });

  test('every status has a distinct icon and label', () {
    expect(
      BirbReviewStatus.values.map(BirbReviewStyle.statusIcon).toSet(),
      hasLength(BirbReviewStatus.values.length),
    );
    expect(
      BirbReviewStatus.values.map(BirbReviewStyle.statusLabel).toSet(),
      hasLength(BirbReviewStatus.values.length),
    );
  });

  test('every file change kind has a distinct label', () {
    expect(
      BirbReviewFileChange.values.map(BirbReviewStyle.fileChangeLabel).toSet(),
      hasLength(BirbReviewFileChange.values.length),
    );
  });
}

List<_Pair> _textPairs(ThemeData theme) {
  final colors = theme.colorScheme;
  final pairs = <_Pair>[
    _Pair(
      'code/onSurface',
      BirbReviewStyle.codeTextStyle(theme).color!,
      BirbReviewStyle.codeBackground(theme),
    ),
    _Pair(
      'selectedRow/onSurface',
      colors.onSurface,
      BirbReviewStyle.selectedRowBackground(theme),
    ),
    _Pair(
      'selectedRowIcon/onSurface',
      colors.onSurface,
      BirbReviewStyle.selectedRowBackground(theme),
    ),
    _Pair(
      'hunkHeading',
      BirbReviewStyle.hunkHeadingTextStyle(theme).color!,
      BirbReviewStyle.hunkHeadingBackground(theme),
    ),
    _Pair(
      'gutter/code',
      BirbReviewStyle.gutterTextStyle(theme).color!,
      BirbReviewStyle.codeBackground(theme),
    ),
    _Pair(
      'gutter/selectedRow',
      BirbReviewStyle.gutterTextStyle(theme).color!,
      BirbReviewStyle.selectedRowBackground(theme),
    ),
    _Pair(
      'rowMetadata/code',
      BirbReviewStyle.rowMetadataTextStyle(theme).color!,
      BirbReviewStyle.codeBackground(theme),
    ),
    // Pairs the review widgets paint outside BirbReviewStyle: the thread's
    // error row, its state labels, and the diff header and action area.
    _Pair(
      'threadError/surface',
      theme.extension<BirbSemanticColors>()!.errorIndicator,
      colors.surface,
    ),
    _Pair('threadStateLabel/surface', colors.onSurfaceVariant, colors.surface),
    _Pair(
      'diffHeader/surfaceContainerLow',
      colors.onSurface,
      colors.surfaceContainerLow,
    ),
    _Pair(
      'diffHeaderSecondary/surfaceContainerLow',
      colors.onSurfaceVariant,
      colors.surfaceContainerLow,
    ),
  ];
  for (final kind in BirbDiffLineKind.values) {
    final roles = BirbReviewStyle.lineMarker(theme, kind);
    pairs.add(_Pair('marker/${kind.name}', roles.foreground, roles.background));
  }
  for (final status in BirbReviewStatus.values) {
    final roles = BirbReviewStyle.statusRoles(theme, status);
    pairs.add(
      _Pair('status/${status.name}', roles.foreground, roles.background),
    );
  }
  return pairs;
}

List<_Pair> _boundaryPairs(ThemeData theme) {
  final backgrounds = <String, Color>{
    'code': BirbReviewStyle.codeBackground(theme),
    'selectedRow': BirbReviewStyle.selectedRowBackground(theme),
    'hunkHeading': BirbReviewStyle.hunkHeadingBackground(theme),
  };
  return <_Pair>[
    for (final background in backgrounds.entries) ...<_Pair>[
      _Pair(
        'focusSide/${background.key}',
        BirbReviewStyle.activeRowSide(theme, focused: true).color,
        background.value,
      ),
      _Pair(
        'outlineSide/${background.key}',
        BirbReviewStyle.activeRowSide(theme, focused: false).color,
        background.value,
      ),
      _Pair(
        'objectSide/${background.key}',
        BirbReviewStyle.objectSide(theme).color,
        background.value,
      ),
    ],
  ];
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

final class _Pair {
  const _Pair(this.name, this.foreground, this.background);

  final String name;
  final Color foreground;
  final Color background;
}
