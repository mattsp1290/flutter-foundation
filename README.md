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
there is no pub.dev artifact. Consumers resolve these packages only from the
Git repository.

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

Use the same immutable `YOUR_COMMIT_SHA` value for both subpaths. Mixing refs
can pair incompatible package contracts even when dependency resolution
succeeds.

## Usage

```dart
import 'package:birb_appearance/birb_appearance.dart';
import 'package:birb_design_system/birb_design_system.dart';

final appearance = AppearanceController(
  store: PreferencesAppearanceStore(applicationNamespace: 'my_application'),
);
await appearance.initialize();

AnimatedBuilder(
  animation: appearance,
  builder: (context, child) => MaterialApp(
    theme: BirbTheme.light,
    darkTheme: BirbTheme.dark,
    themeMode: appearance.themeMode,
    themeAnimationDuration: BirbDurations.instant,
    home: AppearanceSelector(controller: appearance),
  ),
);
```

The host owns the controller and calls `dispose`. The selector borrows it and
reports initialization, pending saves, failures, and retry through its public
UI contract.

## Catalog

The catalog integrates both public runtime barrels and the design-system
preview barrel. It contains every preview fixture plus appearance and
accessibility inspection sections.

```sh
cd examples/catalog
flutter run -d macos
flutter run -d macos --dart-define=BIRB_THEME_PREVIEW=light
flutter run -d macos --dart-define=BIRB_THEME_PREVIEW=dark
```

Forced preview modes do not rewrite the stored appearance. The in-app controls
can constrain the selected section to 320 logical pixels and scale its text to
200 percent. Repository tooling imports the separate audit barrel; application
runtime code does not.
