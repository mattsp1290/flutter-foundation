# Flutter Foundation agent guide

This repository is a Dart Pub workspace containing two reusable Flutter
packages and one catalog application.

## Repository map

- `packages/birb_design_system/`: design tokens, themes, components, preview
  fixtures, and source-audit APIs.
- `packages/birb_appearance/`: appearance storage, controller, and selector.
- `examples/catalog/`: web and macOS integration and visual verification app.
- `docs/`: source provenance, release evidence, and package guidance.
- `tool/`: repository validation entry points.
- `.agents/plans/`: implementation-plan inputs. Do not stage these files as
  implementation output unless a queue contract explicitly includes them.

## Toolchain and dependency rules

Use Flutter 3.47.1 and the Dart 3.13.1 binary bundled with that Flutter SDK.
Do not use a separately installed Dart executable for formatting or analysis.
The workspace has one root `pubspec.lock`; do not create or commit member
lockfiles or dependency overrides.

Packages must resolve without sibling checkout paths. Runtime package code must
not import from another package's `lib/src/`, example, test, or tool directory.

## Validation

Run the portable gate from the repository root:

```sh
./tool/verify.sh
```

For changes to generated macOS runner files, also run:

```sh
cd examples/catalog
flutter build macos
```

Format changed Dart files with the selected Flutter SDK's bundled Dart binary
before running the full gate.

## Generated files and visual work

The catalog `web/` and `macos/` runners originate from this pinned command:

```sh
flutter create --platforms=web,macos \
  --project-name=flutter_foundation_catalog \
  --org=homes.birb examples/catalog
```

Report generated runner changes separately from authored Dart and documentation.
Do not hand-edit generated plugin registrants or files below Flutter ephemeral,
Pub cache, `.dart_tool`, or build directories.

Theme and component changes require both automated coverage and the manual
light/dark, 320 logical pixel, 200 percent text, keyboard-focus, and overlay
inspection described by the root `DESIGN.md`.

Never stage `reviews/`, plan-loop state or locks, local settings, build output,
or unrelated working-tree changes.
