# Flutter Foundation catalog

The catalog is the integration and visual-inspection host for
`birb_design_system` and `birb_appearance`.

Run the persisted appearance mode or force a deterministic preview:

```sh
flutter run -d macos
flutter run -d macos --dart-define=BIRB_THEME_PREVIEW=light
flutter run -d macos --dart-define=BIRB_THEME_PREVIEW=dark
```

The appearance store owns the namespace `flutter_foundation_catalog`. Forced
preview modes leave that preference unchanged. The preview toolbar applies a
320-logical-pixel viewport and 200-percent text scale to each catalog section.

Run the catalog checks from the repository root with `./tool/verify.sh`. The
additional macOS build gate is `flutter build macos` from this directory.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
