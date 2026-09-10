# Birb Flutter Design Contract

## 1. Purpose and authority

This document governs authored user-interface work under
`packages/birb_design_system/` and `examples/catalog/`. When two
directions conflict, use this order of authority:

1. Accessibility requirements and platform semantics.
2. Semantic token contracts implemented by the design system.
3. This design document.
4. Screen-local styling, only for an exception explicitly allowed here.

Contributors and coding agents must explain a new token or exception in this
document before adding a raw color, radius, shadow, or decorative pattern.
Feature code consumes semantic theme roles; it does not choose primitive
colors by appearance.

## 2. Visual direction

The Birb design system uses a **fantasy-console utility** direction:

- limited, deliberate color;
- crisp boundaries and flat fills;
- compact, readable hierarchy;
- restrained, functional motion;
- direct product language;
- platform-native, scalable typography; and
- layouts shaped by the task rather than by a template.

This is not a literal TIC-80 emulator. Do not force tiny text, a fixed
240×136 layout, pixel-only input, inaccessible density, or jagged rendering on
ordinary text. The console influence lives in the palette, geometry, and
economy of presentation—not in reduced usability.

## 3. Primitive palette

The external authority is the requested
[Lospec TIC-80 palette](https://lospec.com/palette-list/tic-80-fantasy-console-rejected-uYKY).
Lospec marks that submitted entry as rejected, but its values are the standard
SWEETIE-16 values and remain the user's explicit selection. Moderation status
does not authorize substituting another palette.

| Index | Token | Hex |
| ---: | --- | --- |
| 0 | `black` | `#1a1c2c` |
| 1 | `purple` | `#5d275d` |
| 2 | `red` | `#b13e53` |
| 3 | `orange` | `#ef7d57` |
| 4 | `yellow` | `#ffcd75` |
| 5 | `lime` | `#a7f070` |
| 6 | `green` | `#38b764` |
| 7 | `darkCyan` | `#257179` |
| 8 | `darkBlue` | `#29366f` |
| 9 | `blue` | `#3b5dc9` |
| 10 | `lightBlue` | `#41a6f6` |
| 11 | `cyan` | `#73eff7` |
| 12 | `white` | `#f4f4f4` |
| 13 | `lightGray` | `#94b0c2` |
| 14 | `gray` | `#566c86` |
| 15 | `darkGray` | `#333c57` |

These names and this index order are stable. Only the private palette source
may contain the primitive literals. Do not create shades, alpha variants,
dynamic colors, or aliases that imply semantics.

## 4. Semantic color contract

The implementation may reuse one primitive for several roles. Product code
uses `Theme.of(context).colorScheme` or `BirbSemanticColors`, never the private
palette. The following Flutter 3.47.1 matrix explicitly authors every active,
non-deprecated color-bearing `ColorScheme` role. The deprecated compatibility
getters documented after the matrix use their named 3.47.1 fallback results;
no other role may inherit an SDK default.

### Complete Material `ColorScheme` mapping

| Role | Light token | Dark token | Pair or requirement |
| --- | --- | --- | --- |
| `brightness` | `Brightness.light` | `Brightness.dark` | Exact mode |
| `primary` | `blue` | `cyan` | `onPrimary`: 5.31:1 light, 12.37:1 dark |
| `onPrimary` | `white` | `black` | Normal text |
| `primaryContainer` | `darkBlue` | `lightBlue` | `onPrimaryContainer`: 10.31:1 light, 6.43:1 dark |
| `onPrimaryContainer` | `white` | `black` | Normal text |
| `primaryFixed` | `darkBlue` | `darkBlue` | `onPrimaryFixed`: 10.31:1 |
| `primaryFixedDim` | `blue` | `blue` | `onPrimaryFixedVariant`: 5.31:1 |
| `onPrimaryFixed` | `white` | `white` | Normal text on `primaryFixed` |
| `onPrimaryFixedVariant` | `white` | `white` | Normal text on `primaryFixedDim` |
| `secondary` | `darkCyan` | `lime` | `onSecondary`: 5.14:1 light, 12.31:1 dark |
| `onSecondary` | `white` | `black` | Normal text |
| `secondaryContainer` | `purple` | `green` | `onSecondaryContainer`: 9.98:1 light, 6.52:1 dark |
| `onSecondaryContainer` | `white` | `black` | Normal text |
| `secondaryFixed` | `purple` | `purple` | `onSecondaryFixed`: 9.98:1 |
| `secondaryFixedDim` | `darkCyan` | `darkCyan` | `onSecondaryFixedVariant`: 5.14:1 |
| `onSecondaryFixed` | `white` | `white` | Normal text on `secondaryFixed` |
| `onSecondaryFixedVariant` | `white` | `white` | Normal text on `secondaryFixedDim` |
| `tertiary` | `green` | `yellow` | `onTertiary`: 6.52:1 light, 11.43:1 dark |
| `onTertiary` | `black` | `black` | Normal text |
| `tertiaryContainer` | `lime` | `orange` | `onTertiaryContainer`: 12.31:1 light, 6.21:1 dark |
| `onTertiaryContainer` | `black` | `black` | Normal text |
| `tertiaryFixed` | `lime` | `lime` | `onTertiaryFixed`: 12.31:1 |
| `tertiaryFixedDim` | `green` | `green` | `onTertiaryFixedVariant`: 6.52:1 |
| `onTertiaryFixed` | `black` | `black` | Normal text on `tertiaryFixed` |
| `onTertiaryFixedVariant` | `black` | `black` | Normal text on `tertiaryFixedDim` |
| `error` | `red` | `orange` | `onError`: 5.18:1 light, 6.21:1 dark; filled role only |
| `onError` | `white` | `black` | Normal text |
| `errorContainer` | `purple` | `red` | `onErrorContainer`: 9.98:1 light, 5.18:1 dark |
| `onErrorContainer` | `white` | `white` | Normal text |
| `surface` | `white` | `black` | `onSurface`: 15.32:1 |
| `onSurface` | `black` | `white` | Normal text |
| `surfaceDim` | `lightGray` | `black` | 7.42:1 light; dark remains black |
| `surfaceBright` | `white` | `darkGray` | 15.32:1 light; 9.92:1 dark |
| `surfaceContainerLowest` | `white` | `black` | Uses `onSurface` |
| `surfaceContainerLow` | `white` | `black` | Uses `onSurface` |
| `surfaceContainer` | `lightGray` | `darkGray` | 7.42:1 light; 9.92:1 dark |
| `surfaceContainerHigh` | `lightGray` | `darkBlue` | 7.42:1 light; 10.31:1 dark |
| `surfaceContainerHighest` | `lightGray` | `darkGray` | 7.42:1 light; 9.92:1 dark |
| `onSurfaceVariant` | `black` | `white` | Passes on every assigned container |
| `outline` | `black` | `lightGray` | At least 4.8:1 on every adjacent surface |
| `outlineVariant` | `black` | `lightGray` | At least 4.8:1 on every adjacent surface |
| `shadow` | `black` | `black` | Opaque hard shadow only |
| `scrim` | `black` | `black` | Framework opacity may composite it |
| `inverseSurface` | `black` | `white` | `onInverseSurface`: 15.32:1 |
| `onInverseSurface` | `white` | `black` | Normal text |
| `inversePrimary` | `lightBlue` | `blue` | 6.43:1 on black; 5.31:1 on white |
| `surfaceTint` | `blue` | `cyan` | Palette member; component elevation tint is suppressed |

Fixed-role foregrounds are approved only with the matching fixed or fixed-dim
background named above. Do not assume `on*FixedVariant` is safe on the other
fixed background without computing that use.

### Deprecated Flutter 3.47.1 compatibility getters

These getters remain public in Flutter 3.47.1 but are not authored constructor
roles. Leave their deprecated constructor parameters unset and assert the
documented null-fallback results in the color audit.

| Getter | Light result | Dark result |
| --- | --- | --- |
| `background` | `surface` (`white`) | `surface` (`black`) |
| `onBackground` | `onSurface` (`black`) | `onSurface` (`white`) |
| `surfaceVariant` | `surface` (`white`) | `surface` (`black`) |

### Custom semantic extension mapping

| Role | Light fill / foreground | Dark fill / foreground | Contrast |
| --- | --- | --- | ---: |
| success | `green` / `black` | `lime` / `black` | 6.52:1 / 12.31:1 |
| warning | `orange` / `black` | `yellow` / `black` | 6.21:1 / 11.43:1 |
| info | `blue` / `white` | `lightBlue` / `black` | 5.31:1 / 6.43:1 |
| focus | `darkBlue` on assigned light surfaces | `cyan` on assigned dark surfaces | Safe lower bound 4.995:1 / 8.010:1 |
| disabled foreground/boundary | `gray` on assigned `white` surfaces | `lightGray` on assigned dark surfaces | Safe lower bound 4.91:1 / 4.804:1 |
| error indicator foreground/boundary | `purple` on `white`/`lightGray` | `yellow` on `black`/`darkGray`/`darkBlue` | Safe lower bound 4.832:1 / 7.399:1 |

The contrast column is executable contract data. Tests recompute it from the
RGB values and compare the unrounded WCAG ratio with the required threshold.
Other displayed ratios are rounded to two decimal places and are not strict
lower bounds. In particular, do not approve `green` on `white`, `cyan` on
`white`, or `gray` on `lightGray` because it looks plausible.

### Assigned surface sets

The following closed sets define “assigned,” “adjacent,” and “allowed surface”
for contrast tests and the theme harness. “All surfaces” means `surface`,
`surfaceDim`, `surfaceBright`, `surfaceContainerLowest`,
`surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, and
`surfaceContainerHighest` in the current brightness.

| Foreground/boundary | Light adjacent roles | Dark adjacent roles |
| --- | --- | --- |
| `onSurfaceVariant` | All surfaces | All surfaces |
| `outline`, `outlineVariant` | All surfaces | All surfaces |
| semantic `focus` | All surfaces | All surfaces |
| semantic `disabled` | `surface`, `surfaceBright`, `surfaceContainerLowest`, `surfaceContainerLow` | All surfaces |
| `errorIndicator` | All surfaces | All surfaces |

Contrast tests exhaustively verify every assigned foreground/background pair.
Component tests verify error and focused-error border resolution, while widget
tests render representative field states on standard theme surfaces. The
preview harness renders representative enabled, error, and disabled inputs.
Disabled boundaries are permitted only on the semantic `disabled` row's
assigned surfaces because `gray` is not a 3:1 boundary against `lightGray`.
Other component/state fixtures use the row for the foreground or boundary
under test. Adding a surface role or permitting a state on another background
requires updating this table and its exhaustive contrast rows first.

Status widgets combine color with a label, icon, border pattern, or shape.
Examples include success + check + “Live,” warning + triangle + “Degraded,”
and error + cross + correction text. These illustrate non-color cues; they do
not prescribe product copy before the corresponding feature exists.

Status, error, selection, and progress expose the same meaning to assistive
technology:

- visible labels participate in the semantic node;
- decorative icons are excluded, while an icon-only cue has an accessible
  label;
- determinate progress exposes its current value and indeterminate progress
  has a meaningful label;
- important dynamic status and error updates use an appropriately scoped live
  region; and
- native checked, selected, toggled, enabled, and value semantics remain
  intact.

The preview loading fixture uses its excluded spinner as a decorative status
glyph and exposes the meaningful label “Loading”; it does not represent a
measured product-progress value. Product progress that is determinate must
expose its current value as required above.

## 5. Foundation tokens

- Spacing: 4, 8, 12, 16, 24, 32, and 48 logical pixels, named `space1`,
  `space2`, `space3`, `space4`, `space6`, `space8`, and `space12`.
- Borders: `thin` is 1 px; `strong` is 2 px.
- Radius: `none` is 0 px; `pixel` is 2 px and is used only when geometry or
  platform clipping needs a softened edge. Never apply one radius everywhere.
- Elevation: Material elevation is zero by default. A component-specific,
  documented layering exception uses only `shadow` at offset `(2, 2)`, zero
  blur, and zero spread. Do not approximate it with Material elevation.
- Targets: every interactive control is at least 48×48 logical pixels. This
  also exceeds the iOS 44×44 minimum.
- Motion: `instant` is 0 ms, `fast` is 100 ms, and `standard` is 200 ms. Motion
  communicates state or continuity; it does not float, pulse, glow, delay
  content, or decorate scrolling. Custom motion honors
  `MediaQuery.disableAnimations`.
- Typography uses the platform Material typeface and preserves OS text
  scaling. Default text uses `onSurface`; variants select a semantic role.
  Section 10.1 documents the one authored exception: source code in the review
  components uses a platform monospace family at `bodyMedium` metrics.

| Text style | Size | Weight | Height |
| --- | ---: | ---: | ---: |
| `displayLarge` | 40 | 700 | 1.2 |
| `displayMedium` | 36 | 700 | 1.2 |
| `displaySmall` | 32 | 700 | 1.2 |
| `headlineLarge` | 28 | 700 | 1.25 |
| `headlineMedium` | 24 | 700 | 1.25 |
| `headlineSmall` | 20 | 700 | 1.25 |
| `titleLarge` | 20 | 600 | 1.3 |
| `titleMedium` | 16 | 600 | 1.3 |
| `titleSmall` | 14 | 600 | 1.3 |
| `bodyLarge` | 16 | 400 | 1.5 |
| `bodyMedium` | 14 | 400 | 1.5 |
| `bodySmall` | 12 | 400 | 1.5 |
| `labelLarge` | 14 | 700 | 1.3 |
| `labelMedium` | 12 | 700 | 1.3 |
| `labelSmall` | 11 | 700 | 1.3 |

## 6. Material component recipes

The 0/2 px radius rule applies to configurable container `ShapeBorder`s.
Preserve native radio, switch, and slider indicator geometry; this is an
explicit platform-semantics exception and does not authorize wrappers, custom
painting, or bespoke controls. Interactive controls use the 48 px target.
Combined states use this precedence:
**disabled; focused+error; error; pressed; focused; hovered; selected;
enabled**. A higher state overrides the same property from a lower state while
preserving independent cues such as a check, thumb position, disabled
semantics, or error correction text.

Explicit component-state rows are authoritative for every property they name.
The shared interaction table is a fallback only when a component row does not
assign that property. This specificity rule applies after the state-precedence
rule above.

| Component/state | Fill | Foreground | Boundary/elevation |
| --- | --- | --- | --- |
| scaffold | `surface` | `onSurface` | None |
| app bar, ordinary | `surface` | `onSurface` | No boundary; elevation/tint 0 |
| app bar, separated | `surface` | `onSurface` | Bottom `outline` 1 px; elevation/tint 0 |
| filled/elevated button, default | `primary` | `onPrimary` | Radius 0; elevation 0 |
| filled/elevated button, hovered | `primaryContainer` | `onPrimaryContainer` | Radius 0; elevation 0 |
| filled/elevated button, pressed | `primaryContainer` | `onPrimaryContainer` | Radius 0; elevation 0 |
| filled/elevated button, disabled | `surface` | semantic `disabled` | Disabled boundary 1 px |
| outlined button, default | `surface` | `onSurface` | `outline` 1 px |
| outlined button, hovered | `surfaceContainer` | `onSurface` | `outline` 1 px |
| outlined button, pressed | `surfaceContainer` | `onSurface` | `outline` 1 px |
| text/icon button, default | No authored fill | `primary` | No boundary until focus |
| text/icon button, hovered | `surfaceContainer` | `onSurface` | No elevation |
| text/icon button, pressed | `surfaceContainer` | `onSurface` | No elevation |
| outlined/text/icon button, disabled | `surface` | semantic `disabled` | Disabled boundary on outlined only |
| input, enabled | Caption `surfaceContainerLow`; editor `surface` | Caption `onSurfaceVariant`; editor `onSurface` | `outline` 1 px; caption occupies a separate ledger cell |
| input, focused | Caption `surfaceContainerLow`; editor `surface` | Caption `onSurfaceVariant`; editor `onSurface` | Semantic `focus` 2 px around the ledger |
| input, error | Caption `surfaceContainerLow`; editor `surface` | `errorIndicator` caption/message/icon; editor `onSurface` | `errorIndicator` 1 px plus external live correction row |
| input, focused+error | Caption `surfaceContainerLow`; editor `surface` | `errorIndicator` caption/message/icon; editor `onSurface` | `errorIndicator` 2 px plus external live correction row |
| input, disabled | Caption `surfaceContainerLow`; editor `surface` | semantic `disabled` | Disabled ledger boundary 1 px |
| checkbox, selected | Box `primary` | Check `onPrimary` | Check mark and checked semantics |
| checkbox, unselected | Box `surface` | n/a | `outline` 1 px and unchecked semantics |
| checkbox, disabled | Box `surface` | semantic `disabled` | Disabled side plus disabled semantics |
| radio, selected | Ring/dot `primary`; background `surface` | n/a | Inner dot and selected semantics |
| radio, unselected | Ring `outline`; background `surface` | n/a | Empty center and unselected semantics |
| radio, disabled | Ring `disabled`; background `surface` | n/a | Disabled semantics |
| switch, selected | Track `primary` | Thumb `onPrimary` | Thumb position and toggled semantics |
| switch, unselected | Track `surface` | Thumb `onSurface` | `outline` 1 px, position, and toggled semantics |
| switch, disabled | Track `surface` | Thumb/boundary `disabled` | Disabled semantics |
| slider | Active track/thumb `primary`; inactive track `outline` | Value indicator `onPrimary` on `primary` | Thumb position, semantic value, and exact focus overlay |
| card | `surfaceContainerLow` | `onSurface` | `outline` 1 px; radius/elevation/tint 0 |
| chip, unselected | `surface` | `onSurface` | `outline` 1 px; radius 2 px |
| chip, selected | `primary` | `onPrimary` | Check/selection mark; radius 2 px |
| chip, disabled | `surface` | semantic `disabled` | Disabled boundary 1 px |
| dialog/menu | `surfaceContainerHigh` | `onSurface` | `outline` 1 px; radius/elevation/tint 0 |
| snackbar/tooltip | `inverseSurface` | `onInverseSurface` | Radius/elevation 0; action uses `inversePrimary` |
| divider | n/a | `outline` | 1 px |
| navigation bar/rail, unselected | `surface` | `onSurfaceVariant` | Divider where separated |
| navigation bar/rail, selected | `primaryContainer` | `onPrimaryContainer` | Square indicator plus icon/label-weight cue |
| text selection/cursor/handle | Light mode: `lightBlue` under `black`; dark mode: `blue` under `white` | Selected text remains `black`/`white` | Cursor and handle use `primary` |

Cards use boundaries only for real grouped objects. Chips are for filters,
selection, or compact status. Labels never rely on placeholders. Navigation
selection changes icon/label treatment as well as color. Dialogs, menus,
snackbars, and tooltips remain opaque.

An app bar is “separated” only while content is visibly scrolling beneath it.
Until a screen implements and tests that state, use the ordinary no-boundary
recipe. A hard-offset layering exception must name the component and reason in
this document before implementation.

### Shared interaction roles

| State | Fill/overlay | Foreground | Boundary/additional cue |
| --- | --- | --- | --- |
| hovered | `surfaceContainerHigh` | `onSurface` | Preserve base boundary and semantic cue |
| pressed | `primaryContainer` | `onPrimaryContainer` | Preserve shape/position cue |
| focused | Preserve base fill | Preserve base foreground | Semantic `focus` at 2 px where a stateful side exists; otherwise exact global focus token |
| selected | Component-selected recipe | Selected foreground | Check, position, square indicator, or label weight |
| disabled | `surface` | semantic `disabled` | Disabled boundary, semantics, and blocked action |
| error | `surface` | `errorIndicator` message/icon | `errorIndicator` 1 px and correction text |
| focused+error | `surface` | `errorIndicator` message/icon | `focusedErrorBorder` is `errorIndicator` 2 px |

### Flutter 3.47.1 mechanisms

| Family | Mechanism | Focus/interaction acceptance |
| --- | --- | --- |
| filled/elevated/outlined/text buttons | `ButtonStyle` state properties for fill, foreground, side, overlay, shape, and minimum size | Resolve disabled/pressed/focused/hovered/default directly; visible stateful sides carry 2 px focus |
| icon button | `IconButtonThemeData.style` / `ButtonStyle` | Same precedence; stateful side or global `focusColor` when borderless |
| text input | `BirbTextFormField` ledger-caption wrapper plus a borderless themed `TextFormField` editor | Put the label in a separate caption cell; stack it above the value at narrow widths or large text scales; use `errorIndicator` and an external live error row; use a 2 px focus/focused-error boundary; test every allowed surface |
| checkbox | `CheckboxThemeData` fill, check, overlay, side, and shape properties | Check shape remains the selection cue; exact focus/hover/press resolution |
| radio | `RadioThemeData` fill, overlay, and side properties | Inner mark remains the cue; exact focus/hover/press resolution |
| switch | `SwitchThemeData` thumb, track, outline, and overlay properties | Thumb position remains the cue; exact focus/hover/press resolution |
| slider | `SliderThemeData` tracks, thumb, value indicator, overlay color/shape | Thumb position persists; exact semantic overlay; rendered keyboard focus test; no wrapper |
| chip | `ChipThemeData` with `WidgetStateColor` in `TextStyle.color`, plus stateful fill, side, checkmark, shape, and disabled/selected roles | `RawChip` resolves the nested label color rather than a whole `WidgetStateTextStyle`; check and semantics supplement fill; global focus when no stateful side exists |
| navigation bar | `NavigationBarThemeData` stateful icon/label/overlay and indicator roles | Square indicator and label weight supplement color |
| navigation rail | `NavigationRailThemeData` roles plus inherited `ThemeData.focusColor` | Rendered keyboard test proves inherited focus; do not claim a 2 px outline |
| menu/dialog/snackbar/tooltip | Component themes plus themed descendants | Surface geometry is static; descendant actions use the mechanisms above |

Labeled product inputs use `BirbTextFormField`; do not pass `labelText` to a
raw `TextField` or `TextFormField`. The theme disables floating labels so the
caption and outline cannot intersect again. Keep validation copy in the
component's external error row, where it remains visible and is announced as a
live error.

Set `ThemeData.focusColor`, `hoverColor`, `splashColor`, and `highlightColor` to
exact semantic palette roles. The membership audit enumerates these fields.
Framework compositing of exact authored interaction, scrim, and selection
tokens is permitted; authored `.withOpacity`, `.withAlpha`, or `.withValues`
transformations are not.

## 7. Research into common AI-generated visual defaults

This section records recurring defaults, not a detector of authorship. Any one
pattern can be legitimate. The failure is using a formula without a product
reason. Sources checked for this contract on 2026-08-28:

- [Signs of AI Design](https://github.com/febbhav/signs-of-ai-design) catalogs
  patterns and explicitly frames possible false positives.
- [Flutter app-wide theme guidance](https://docs.flutter.dev/cookbook/design/themes)
  establishes centralized theming.
- [Flutter `ColorScheme`](https://api.flutter.dev/flutter/material/ColorScheme-class.html)
  defines semantic roles and paired-role contrast.
- [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
  documents executable guideline checks.
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/) defines contrast, non-color,
  focus, target-size, and related accessibility criteria.

| Common default | Birb counter-rule | Legitimate exception |
| --- | --- | --- |
| Purple/indigo gradient hero and gradient buttons | Use flat semantic roles; create hierarchy with type, spacing, and borders | Future game artwork may have separately reviewed art direction |
| Centered oversized headline, badge, subhead, and two generic calls to action | Derive composition from the user's task and real content | A centered empty state when it improves comprehension |
| Exactly three identical feature cards or a generic bento grid | Choose layout from content relationships and responsive constraints | Three genuine objects may form three columns when that relationship is useful |
| Large uniform rounding on every surface/control | Default to 0 px; use 2 px only for a named geometric need | Platform clipping or a documented component affordance |
| Nested cards for visual interest | Budget one boundary per meaningful grouped object | Nested interactive domain objects whose semantics remain clear |
| Glassmorphism, translucent blur, glow borders, diffuse elevation | Use opaque fills, crisp borders, and an optional hard offset | Media overlays only after contrast and performance verification |
| Decorative pill eyebrows and sparkle/bolt icon tiles | Reserve chips/icons for recognizable semantics | A real status/filter chip or required AI-feature disclosure |
| Floating, pulsing, parallax, and reveal-on-scroll ornament | Animate state, causality, loading, or spatial continuity only | Behavior that cannot be understood as clearly without motion |
| Generic hype copy and fake metrics | Use domain terms, concrete actions, real states, and actual data | None |

### Pre-merge anti-template check

1. Does each container represent a real object or interaction boundary?
2. Does each color, icon, effect, and animation communicate a named purpose?
3. Does layout follow content and user task rather than a stock hero/card
   formula?
4. Could removing a decorative element improve comprehension without losing
   meaning? If yes, remove it.
5. Did a new exception update this document and pass contrast, semantics, and
   responsive checks?

## 8. Accessibility and responsive requirements

- Target WCAG 2.2 AA for web and equivalent Flutter platform guidance on
  mobile.
- Normal text reaches 4.5:1; large text reaches 3:1; meaningful non-text
  boundaries and states reach 3:1; focus is visibly distinguishable.
- Status, error, selection, and progress retain a color-independent cue.
- Harness and component tests cover representative labels, progress labels,
  and native checked/selected/toggled/enabled/value flags. Live-region behavior
  is implemented by the reusable error component and remains a required direct
  assertion when dynamic status components are added.
- Layout remains readable at the largest supported text scale and at narrow
  mobile widths.
- Controls remain semantic Material controls with accessible labels, not
  painted-pixel replacements.
- Keyboard access and focus order remain intact on web and desktop.
- Implementation uses the stricter 48×48 token and direct target assertions,
  which also exceed the iOS 44×44 guidance.

The committed theme harness exercises layout and rendering in light and dark
modes. Focused behavior, semantics, keyboard, and target tests use
representative fixtures where brightness does not change the platform
semantics. If an automated guideline cannot evaluate an unpainted or disabled
state, retain the direct token/component and rendered-state assertion and name
the scanner limitation in the test. Do not remove the contract to satisfy a
scanner limitation.

## 9. Contribution checklist

Before merging a new screen or component:

- [ ] Consume semantic theme roles instead of raw `BirbPalette` values.
- [ ] Use an existing spacing, radius, border, and motion token.
- [ ] Verify both light and dark modes.
- [ ] Test required contrast and a non-color cue.
- [ ] Test large text and a narrow width.
- [ ] Inspect keyboard focus and semantics.
- [ ] Run the anti-template check.
- [ ] Document any new token or justified exception before merge.

## 10. Code review components

The design system provides a bounded set of pull-request review components:
`BirbReviewStatusBadge`, `BirbChangedFileList`, `BirbDiffView`,
`BirbReviewThreadView`, and `BirbReviewComposer`. They render immutable host
presentation models and emit controlled callbacks. GitHub is a workflow
reference only: no provider DTO, HTTP call, authentication, Markdown or HTML
execution, persistence, or state-management framework enters this package.

### 10.1 Scoped monospace exception

Source code is the one authored typography exception to section 5's
platform-typeface rule. Code rows use `bodyMedium` size, height, and weight
with a monospace family resolved from the platform fallback list
`ui-monospace`, `SFMono-Regular`, `Menlo`, `Consolas`, `Roboto Mono`,
`Courier New`, `monospace`. No font asset is bundled and no remote font is
fetched, so an unavailable family degrades to the next entry. OS text scaling
is preserved; code text is never shrunk to fit. The exception applies to source
lines, hunk headings, and the numeric line-number cells, which must stay
column-aligned with the source beside them. It never applies to labels, comment
bodies, or a row's prose metadata: a stacked row's line description uses
ordinary platform typography.

A rune count only approximates display width, so snapshot preparation keeps the
several longest rows as candidates and lays out all of them to find the true
column width. Snapshot preparation therefore stays O(total source text) with a
bounded number of source layouts — plus one layout per hunk heading, re-paid on
a width or scale change — while row construction stays O(visible rows).
Font-metric or text-scale changes invalidate the measurement and it is
recomputed.

Tab stops and that candidate ranking count one Unicode code point as one
column. Fullwidth, combining, and multi-code-point emoji text renders and
copies correctly, but its alignment to the four-column grid is approximate.
Measuring several candidates rather than one is what keeps a wide-glyph row from
being clipped with no scroll extent left to reach it.

Tabs expand for display to the next four-column stop. `Copy source line`
always copies the original text with real tab characters, no line numbers, no
change sign, and no trailing newline; it remains available when commenting is
disabled. Native text selection copies what is displayed, which means the
spaces expanded from a tab. Both behaviors are documented in the package README
and here. The source column is one selection region that excludes line numbers
and change signs, so a selection may span rows and still yields displayed source
text only.

### 10.2 Diff row roles

| Element | Fill | Foreground | Boundary/cue |
| --- | --- | --- | --- |
| code row, context | `surface` | `onSurface` | Both line numbers; no sign fill |
| addition marker | semantic `success` | semantic `onSuccess` | Literal `+` glyph |
| deletion marker | semantic `error` (`ColorScheme.error`) | `onError` | Literal `−` glyph |
| selected row | `surfaceContainerHigh` | `onSurface` | Leading `Icons.arrow_right` in `onSurface` plus `selected` semantics |
| active row, region focused | Base row fill | Base row foreground | Semantic `focus` 2 px box |
| active row, region unfocused | Base row fill | Base row foreground | `outline` 1 px box |
| hunk heading | `surfaceContainerLow` | `onSurfaceVariant` | Top `outline` 1 px |
| file/thread boundary | `surface` | `onSurface` | `outline` 1 px, radius 0 |

A row that ends a file without a trailing newline appends the caller-supplied
no-final-newline marker to its line description, which is both announced and
visible in the stacked layout and in the action area.

Change markers are compact non-interactive cells, never full-row tinted
backgrounds, because a translucent red or green row fill would need an authored
alpha effect and would invalidate code contrast. Additions and deletions
therefore carry an explicit sign glyph, an accessible kind word, and a line
identity in addition to color. Selection never hides a sign, native text
selection, or the keyboard focus box. One boundary per meaningful grouped
object; no nested decorative cards.

### 10.3 Review status badge

| Status | Fill | Foreground | Icon |
| --- | --- | --- | --- |
| `pending` | semantic `warning` | semantic `onWarning` | `Icons.schedule` |
| `approved` | semantic `success` | semantic `onSuccess` | `Icons.check` |
| `changesRequested` | `ColorScheme.error` | `onError` | `Icons.close` |
| `commented` | semantic `info` | semantic `onInfo` | `Icons.chat_bubble_outline` |

Every badge pairs its icon with human-readable text, so status never depends on
color alone. The badge is presentation state; it implies nothing about
mergeability or authorization.

### 10.4 Geometry, targets, and layout

Code text is non-interactive and may be denser than 48 logical pixels so that a
diff stays readable. Every interactive review control keeps the 48×48 target
from section 5: file items, the diff action area, resolve/reopen, and the
composer buttons are ordinary themed Material buttons.

A diff row's line numbers and change sign never require horizontal scrolling.
The source column is the only horizontally scrolled region, it shares one
offset across rows, and that offset is reachable with `Left`/`Right` from the
diff navigation region as well as with the labeled horizontal scrollbar. Below
360 logical pixels of row width, above 1.5× effective code text scale, or
whenever an inline gutter would leave fewer than twelve columns of source, each
row stacks its metadata above its source text instead of shrinking text or
overflowing.

The horizontal offset is reachable four ways: `Left`/`Right` from the
navigation region, a horizontal drag anywhere over the source rows, the labelled
scrollbar below them — whose scrollable fills a full interaction target even
though the thumb is thin — and its scroll semantics actions. The row drag is
restricted to touch and stylus on purpose: a mouse or trackpad drag belongs to
the native text selection section 10.1 requires.

`BirbDiffView` is a bounded-height, finite-width widget; the host supplies
finite constraints. Loading, failure, and retry belong to the host around the
diff, not to asynchronous work inside it. Empty text, binary, and unavailable
content render distinct caller-overridable messages rather than an empty diff.

### 10.5 Keyboard contract

The diff exposes one focusable navigation region, then one stable action area,
and no per-row tab stops. While the navigation region owns focus:

- `Up`/`Down` move the active line and reveal it.
- `Home`/`End` move to the first and last line.
- `Left`/`Right` scroll the source column.
- `F2` reveals the active line, enters its native selectable source text, and
  places the caret at the start; native `Shift+Arrow` selection and the
  platform copy shortcut then operate on that text.
- `Escape` returns focus to the navigation region and preserves the active
  line identity.

A pointer tap or an assistive-technology activation on a row also makes it the
active line and gives the navigation region focus, so the next arrow key
continues from there. A host-supplied `selectedAnchor` does the same and reveals
its row. The active-line description is a live region, so that
change is announced. A row announces its kind and both line numbers once,
followed by its source text; the gutter repeats neither.

`Tab` advances from the navigation region to the action area and then out of
the diff; `Shift+Tab` reverses it. There is no focus trap. The same key list is
visible on screen, not only in semantics. If pointer scrolling unmounts the
row that owns focus, focus returns to the navigation region and the active line
identity is preserved.

### 10.6 Discussion and composition

`BirbReviewThreadView` renders author, timestamp, plain-text body, anchor
summary, and resolved or outdated labels with semantics. Bodies are plain text:
links and Markdown are never executed, and an HTML-like string appears
literally. All comments stay visible when a thread is resolved; collapsing is
deferred. Resolve and reopen report the intent to the host, which owns the
model; the widget never updates it optimistically. While a state change is
pending the action is disabled with a meaningful progress label, and a failure
stays visible in a scoped live region with retry through the same action.

`BirbReviewComposer` borrows the host's controller and focus node, never
disposes them, and never clears draft text. It uses the multiline
`BirbTextFormField` ledger with `minLines: 3` and `maxLines: 8`. `Enter`
inserts a newline; submission is only through the labeled button. Whitespace-
only drafts are rejected, and a valid draft is emitted untrimmed. While
submitting, text stays visible and read-only, which is semantically distinct
from disabled. A failure keeps the text and shows the error in the existing
live correction row. Hosts key controllers and pending operations by thread or
by new-discussion anchor including revision, so a late completion for one
draft never clears or appends to another.

### 10.7 Semantic role exposure

`BirbReviewStyle` is public so that hosts and contrast tests can enumerate
every foreground, background, boundary, and icon this section names, plus the
default English word for each enum value. It returns only `ColorScheme` and
`BirbSemanticColors` roles resolved from the ambient theme. It does not read the
private palette, construct a color, or transform one, and it adds no required
field to `BirbSemanticColors`.

Source-text transformation is not presentation, so it lives in `BirbSourceText`
rather than in the style table: that separation also keeps the one file the
design-source audit allows to name a typeface as small as its exemption.

## Deferred work

A manual/persisted theme preference, high-contrast themes, a licensed brand or
pixel-display font, golden infrastructure, product-specific streaming
components, and static analyzer integration are separate design decisions.
They are not exceptions to this contract and are not part of the initial
design-system implementation.

For the section 10 review components the following are also deferred and are
not exceptions to this contract: raw patch parsing, provider adapters and
authentication, side-by-side diffs, syntax highlighting, Markdown comment
bodies, editable suggestions, review submission and merge, complete
pull-request timelines, and persisted drafts. A selection may span rows today
(section 10.1); what stays deferred is selecting across the gutter, and any
selection surviving a scroll far enough to unmount its rows.
