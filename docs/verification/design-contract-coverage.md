# Design contract coverage

The root [`DESIGN.md`](../../DESIGN.md) is the normative design contract for
the reusable package and catalog. It was adapted from `ui/DESIGN.md` at the
pinned Birbparty source commit
`0a037dc0d696cf6ea09e006d9c7145b0ab9f8291` (Git blob
`120a3f798a1fce82d0db9347d9686afe06fd54fd`). The semantic color tables,
component recipes, accessibility rules, and contribution checks remain part of
the contract. Repository-specific authority paths and verification wording are
adapted to this workspace.

The committed test suite provides the following implementation evidence:

| Contract area | Implementation | Primary evidence |
| --- | --- | --- |
| Primitive palette | `lib/src/foundation/birb_palette.dart` | `test/foundation/birb_palette_test.dart` |
| Semantic roles and assigned surfaces | `lib/src/color/birb_semantic_colors.dart` | `test/foundation/birb_semantic_colors_test.dart`, `test/theme/contrast_test.dart` |
| Spacing, borders, radii, targets, and motion | `lib/src/tokens/birb_tokens.dart` | `test/foundation/birb_tokens_test.dart` |
| Typography | `lib/src/theme/birb_typography.dart` | `test/theme/birb_typography_test.dart` |
| Complete light and dark color schemes | `lib/src/theme/birb_color_schemes.dart` | `test/theme/birb_color_schemes_test.dart`, `test/audit/color_scheme_roles_test.dart` |
| Theme assembly and global interaction roles | `lib/src/theme/birb_theme.dart` | `test/theme/birb_theme_test.dart`, `test/theme/public_theme_smoke_test.dart` |
| Filled, elevated, outlined, text, and icon buttons | `lib/src/theme/components/birb_button_themes.dart` | `test/theme/interactive_button_themes_test.dart` |
| Checkbox, radio, switch, slider, and chip | `lib/src/theme/components/birb_selection_themes.dart`, `lib/src/widgets/birb_filter_chip.dart` | `test/theme/selection_control_themes_test.dart` |
| App bar, card, dialog, divider, menu, navigation, snackbar, and tooltip | `lib/src/theme/components/birb_surface_themes.dart` | `test/theme/surface_themes_test.dart`, `test/theme/surface_render_test.dart` |
| Text input | `lib/src/theme/components/input_decoration_theme.dart`, `lib/src/widgets/birb_text_form_field.dart` | `test/theme/input_decoration_theme_test.dart`, `test/widgets/birb_text_form_field_test.dart` |
| Preview inventory and responsive fixtures | `lib/src/preview/birb_theme_harness.dart` | `test/preview/birb_theme_harness_test.dart` |
| Semantic-role consumption boundary | `lib/src/audit/design_system_audit.dart` | `test/audit/design_system_audit_test.dart` |

[`source_parity_evidence.md`](../../packages/birb_design_system/test/source_oracle/source_parity_evidence.md)
records the temporary source-oracle comparison. The contract test treats this
matrix and the current component and mechanism tables as closed inventories,
and verifies that every referenced implementation and evidence file exists.
