# Changelog

## 0.1.0

- Scaffold the package in the Flutter Foundation workspace.
- Add code-review components: `BirbReviewStatusBadge`, `BirbChangedFileList`,
  `BirbDiffView`, `BirbReviewThreadView`, `BirbReviewComposer`, their
  presentation models, and `BirbReviewStyle`.
- Extend `BirbTextFormField` with `minLines`, `maxLines`, and `readOnly`,
  preserving the previous single-line, writable defaults.
- Export `BirbReviewHarness` from `design_system_preview.dart` as a simulated
  review host with deterministic fixtures.
