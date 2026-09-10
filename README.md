# Flutter Foundation

Shared Flutter packages for Birb projects. This repository keeps visual design
and appearance preferences independent from any application, backend, or state
management framework.

## Packages

- `packages/birb_design_system`: semantic colors, design tokens, Material
  themes, accessible components, preview fixtures, and design-source audits.
- `packages/birb_appearance`: system/light/dark selection and namespaced local
  persistence through a small `Listenable` API.
- `examples/catalog`: web and macOS catalog used for package integration and
  visual verification.

The initial package version is `0.1.0`. Both packages use `publish_to: none`;
there is no pub.dev release.

Theme, component, and catalog changes follow the repository
[design contract](DESIGN.md).

## Toolchain

Use Flutter 3.47.1 and the bundled Dart 3.13.1 SDK. Run the complete portable
gate from the repository root:

```sh
./tool/verify.sh
```

The macOS runner is an additional local gate:

```sh
cd examples/catalog
flutter build macos
```

## Git dependencies

Consumers pin both package subpaths to the same immutable commit. Replace
`YOUR_COMMIT_SHA` with a reviewed commit from this repository.

```yaml
dependencies:
  birb_design_system:
    git:
      url: https://github.com/mattsp1290/flutter-foundation.git
      ref: YOUR_COMMIT_SHA
      path: packages/birb_design_system
  birb_appearance:
    git:
      url: https://github.com/mattsp1290/flutter-foundation.git
      ref: YOUR_COMMIT_SHA
      path: packages/birb_appearance
```

Applications should commit their own lockfiles. Roll back by restoring both the
previous manifest pin and application lockfile.
