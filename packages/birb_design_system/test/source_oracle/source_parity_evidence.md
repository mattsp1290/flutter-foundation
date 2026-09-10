# Birbparty source parity evidence

The temporary source oracle was rebuilt from Birbparty commit
`0a037dc0d696cf6ea09e006d9c7145b0ab9f8291` and removed after the parity gate
passed, as required by the extraction plan.

The source design contract from that commit (`ui/DESIGN.md`, Git blob
`120a3f798a1fce82d0db9347d9686afe06fd54fd`) is preserved and adapted at the
repository root in [`DESIGN.md`](../../../../DESIGN.md). The companion
[`design-contract-coverage.md`](../../../../docs/verification/design-contract-coverage.md)
maps its documented families to the committed implementation and tests.

- Oracle tree digest (`birbparty-source-oracle-v1`):
  `7c08acbd3ae681349d9acd617c037b1d9417713894bf825ebc4001a3de330cd1`
- Temporary component parity test digest:
  `bac69f76588ea7e1c9d46adb89a64dadad83842a4695c3010b46a023c36f8b2b`
- Historical command (temporary oracle; not runnable from this checkout):
  `flutter test --reporter compact packages/birb_design_system/test/source_oracle/component_source_oracle_parity_test.dart`
- Reconstruction inputs: the pinned Birbparty commit and source-file hashes
  recorded in this document.
- Result: both light and dark source-parity cases passed.

The temporary test compared every source-authored component-theme property
captured for app bars, cards, dialogs, dividers, all button families, selection
controls, sliders, chips, input decoration, menus, navigation, snackbars, and
tooltips. Widget-state properties were resolved for enabled, disabled, hover,
focus, press, selected, error, and combined states.

Independent expected-value, rendering, semantics, interaction, inventory,
narrow-width, and large-text tests remain in the committed suite. No copied
source implementation or oracle Dart library remains in the repository.

Source file SHA-256 values:

| Source file | SHA-256 |
| --- | --- |
| `birb_semantic_colors.dart` | `5e14ab7618e354156613962c1c5a19c0ae01829868647f877956ba468723322a` |
| `birb_text_form_field.dart` | `25ca9d577e31af1c557fda1db0aac3700ec6597183f1d19c588b5ba2d468c7d9` |
| `birb_theme.dart` | `2a94c09605094ef989193c67ee94228f19ac2b541b7f8ebc5aed2bdca915118e` |
| `birb_tokens.dart` | `f7bb76c637972534aeccd11a9477548da5d93bc0a3c569f837fab803f62ec612` |
| `design_system.dart` | `91ea9d86db6fa07b26f73e3eb2ae0579c1e2d24c5ba40af84f1699427275f901` |
| `src/birb_input_border.dart` | `5009b8a9845edc28087ca8398e35fae67adb065934942175542096f4e6cd6454` |
| `src/birb_palette.dart` | `6183a21ab11d3cf3651eba72997e8b32bd7592c150de4ec9028ce532ef284a95` |
