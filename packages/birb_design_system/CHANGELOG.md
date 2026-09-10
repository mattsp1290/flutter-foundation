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
- Keep the tap action on changed-file items and diff rows so assistive
  technology can operate them, and announce the active line as a live region.
- Restrict the source pan gesture to touch and stylus so mouse and trackpad
  drag-to-select keeps working, and make the scrollbar's whole reserved target
  draggable.
- Bound the composer's activation guard to one frame and disable the action
  while it holds, so it can neither deadlock nor be reopened by an unrelated
  rebuild.
