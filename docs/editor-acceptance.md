# Production editor acceptance

Status: implementation and verification are in progress. This is not a release
record or consumer unblock. Missing rows below block four-platform delivery.

## Pins and ownership

Flutter 3.47.1 uses bundled Dart 3.13.1. The editor owns its internal
`re_editor` adapter, view resources and provider request coordinator. Hosts own
`BirbEditorController`, borrowed focus nodes and language providers. Unmount the
view before disposing its controller. One view attaches per controller; two
independent controllers are supported. Recovery listeners receive exact source
in the same call stack as a committed mutation, before a queued reload/frame.

The qualified fork is `mattsp1290/re-editor` at
`e6f40f5a24db6a9ab9bb1a61a1837f9d6aa99375`, derived from 0.10.0.
Highlighter `re_highlight` is 0.0.3; native workers resolve `isolate_manager`
4.1.5+1 and `isolate_contactor` 4.1.0. These four MIT dependencies retain their
notices under [licenses](licenses/). Patch details and historical evidence are
in [engine qualification](editor-engine-qualification.md) and the fork's
`BIRB_PATCH.md`.

Standalone consumption pins the editor to B and the design system to exactly
A = `3cccfc448de0306b036f93deb4409280266baa9f`, both at
`https://github.com/mattsp1290/flutter-foundation.git`, with package paths
`packages/birb_code_editor` and `packages/birb_design_system`. B is not yet a
final delivery SHA. Early checkpoint B =
`998653683742e5e16ef8de7e9577a2aee0d90178` passed both editor-only consumption
and coexistence with a direct design-system import: independent Pub resolution,
analysis, public-widget edit/undo smoke test and offline-assets release build.
These checks use an external temporary app and no overrides or sibling paths.
They must be repeated at final B.

## Repeatable commands

Run the portable gate from the root with Chrome, ChromeDriver and `timeout` on
PATH:

```sh
./tool/verify.sh
python3 tool/verify_editor_worker_lifecycle.py
```

Generate a real external native fixture using a clean committed candidate:

```sh
python3 tool/create_editor_native_harness.py --platform macos \
  --output /tmp/birb-editor-native-check --candidate-root "$PWD" \
  --design-system-ref 3cccfc448de0306b036f93deb4409280266baa9f
python3 tool/run_editor_native_suite.py --platform macos \
  --app /tmp/birb-editor-native-check/app
```

Use `linux` or `windows` on those hosts (`python` on Windows). The generator
requires a new output directory outside the workspace, exports only committed
HEAD into an isolated Git repository, checks its declared dependency A, and
records both original and exported SHAs. Its file-Git URL is candidate evidence,
not published evidence. The runner requires build, analysis and successful
execution of the suite marker. Linux uses Xvfb. CI uploads the pin map and logs.
Generated runners stay outside the repository; entitlements are not weakened.

For published evidence, replace `--candidate-root` with
`--editor-url https://github.com/mattsp1290/flutter-foundation.git --editor-ref B`.
Verify both standalone dependency cases separately:

```sh
./tool/verify_editor_consumer.sh \
  --editor-url https://github.com/mattsp1290/flutter-foundation.git \
  --editor-ref FULL_IMMUTABLE_B_SHA \
  --design-system-ref 3cccfc448de0306b036f93deb4409280266baa9f \
  --evidence /tmp/editor-consumer-results.json
```

The consumer script cleans up only its owned temporary directories, including
their independent locks. For native inspection, retain the generated directory
until the run and evidence collection finish, then remove that owned directory.

## Current evidence and remaining gates

| Area | Evidence | Status |
| --- | --- | --- |
| Exact source/history | Fork 158 tests; controller/engine tests including mixed separators, raw offsets, nested folds and 64 KiB line | Automated pass; final matrix pending |
| Recovery/input | Catalog macOS framework keyboard and composing deltas; immediate host recovery assertions | Pass; physical IME pending |
| Providers/UI | Completion keyboard acceptance, pointer/keyboard hover, diagnostic marker geometry/navigation, readonly toolbar and stale response tests | Automated pass; final visual matrix pending |
| Narrow/scaled UI | 320×480 widget test with 200% text and reachable find/close | Pass for tested fixture; full preset matrix pending |
| Workers | Twenty production-view macOS cycles: 1 detached / 3 mounted isolates | [Recorded pass](evidence/editor-qualification/production-native-workers.json) |
| Standalone dependency closure | B `9986536`, exact A; editor-only and coexistence | Early published checkpoint pass; candidate/final B pending |
| macOS external native suite | B `9986536`: pointer focus, keyboard undo/redo, composing updates, system clipboard, readonly, theme/remount and focus exit | Framework suite pass; physical checks pending |
| Linux / Windows | Required desktop CI jobs authored | Not yet run |
| Browser assets and real input | Local nested-path visual inspection at B `9986536`; visible gutter/Go tokens and completion popup | Automated blocked-origin/root/high-DPI matrix pending |
| Performance | 64 KiB / 2,000-line fixture, 100 warmed edits, p95 ≤50 ms; cold ready ≤3 s | Not yet measured |
| Review gauntlet | Two independent reviews, fixes, then pinned Cursor maintainability rubric | Not yet run |

The selected completion row's foreground was corrected after browser inspection;
the final screenshot matrix must include that correction. The current
[dark browser screenshot](evidence/editor-qualification/production-chrome-dark.png)
is an early product checkpoint, not final acceptance.

## Physical release checklist

For Chrome/web and each native platform, run the generated fixture at the same
pin map (`flutter run -d macos|linux|windows` for native). Record operator, date,
OS, Flutter, browser where applicable, IME and screen-reader versions. Record
each scenario as pass/fail with notes; do not relabel framework-injected events
as physical OS results.

- Type, select with mouse and keyboard, undo/redo, indent/outdent, comment,
  fold/unfold, find/replace, and scroll on both axes.
- Copy to another application and paste back mixed separators and Unicode;
  inspect exact recovered source. Verify readonly permits copy/find and blocks
  paste, undo and provider acceptance.
- Use a real IME through intermediate composition and commit; undo, reload
  recovery immediately, and verify no committed text was lost.
- Check light/dark × four code presets at normal width, 320 logical pixels,
  and 200% text. Inspect overlays, focus boundary, contrast and 48px controls.
- Navigate source and diagnostics with the platform screen reader. Gutter
  digits must not be read twice. Verify completion/hover dismissal and Escape
  followed by Tab/Shift+Tab exits to surrounding controls.
- Switch theme, wrap and font size, resize, detach/remount and operate the
  second editor. Confirm source, history and selection remain correct.

All four physical platform records are missing. Do not fulfill Beans
`flutter-foundation-r-ikci` or claim consumer adoption until required evidence,
final published pin-map resolution and both review stages are complete. The
consumer separately verifies its real interview screen, persistence and gopls;
owner fixtures do not substitute for those checks.
