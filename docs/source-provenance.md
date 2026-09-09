# Source provenance

## Foundation repository

- Repository: `https://github.com/mattsp1290/flutter-foundation`
- Initial revision: `58ae3e233829910e5929707fcf57ec67f879dad1`
- Maintainer and rights decision owner: Matt Spurlin
- Destination license: MIT, copyright 2026 Matt Spurlin
- Rights decision: Matt explicitly approved distributing the recorded
  Birbparty design-system Dart source and `ui/DESIGN.md` under this repository's
  MIT license on `2026-09-08T22:29:02Z`.

Stop extraction if a source segment at the recorded revision has a different
author or separate license until its rights holder gives an explicit decision.

## Birbparty design source

- Repository: `git@github.com:birbparty/birbparty.git`
- Revision: `0a037dc0d696cf6ea09e006d9c7145b0ab9f8291`
- Git author for the listed design history: Matt Spurlin
- Contract: `ui/DESIGN.md`
- Tests: `ui/test/design_system/`
- Audit and preview sources: `ui/tool/check_design_system.dart`,
  `ui/tool/theme_harness.dart`, and `ui/tool/theme_preview.dart`
- Runtime source:
  - `ui/lib/design_system/design_system.dart`
  - `ui/lib/design_system/birb_theme.dart`
  - `ui/lib/design_system/birb_semantic_colors.dart`
  - `ui/lib/design_system/birb_tokens.dart`
  - `ui/lib/design_system/birb_text_form_field.dart`
  - `ui/lib/design_system/src/birb_input_border.dart`
  - `ui/lib/design_system/src/birb_palette.dart`

No Birbparty source is copied by the workspace-scaffolding change.

## Toolchain and dependency pins

- Flutter: `3.47.1`, stable channel
- Flutter framework revision:
  `6655482ec06e547f90abf8ae7590466f4415978d`
- Flutter engine revision: `5d531788691ec3404cac0cee66ead4007b177363`
- Dart: `3.13.1`
- macOS arm64 archive:
  `https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.47.1-stable.zip`
- Official archive SHA-256:
  `38c9ffe0af4a71e4600f4fda310f0e895757550926128e28aa57782ea97538fa`
- CI Flutter action: `subosito/flutter-action` commit
  `1a449444c387b1966244ae4d4f8c696479add0b2` (release `v2.23.0`)
- CI checkout action: `actions/checkout` commit
  `11bd71901bbe5b1630ceea73d27597364c9af683` (release `v4.2.2`)
- Appearance persistence: `shared_preferences` `2.5.5`, whose published SDK
  floor is Dart 3.9 and whose public API includes `SharedPreferencesAsync`.

The official Flutter macOS release manifest supplied the archive path, revision,
Dart version, architecture, and SHA-256. The root Pub lockfile records the exact
hosted dependency graph used by this workspace.
