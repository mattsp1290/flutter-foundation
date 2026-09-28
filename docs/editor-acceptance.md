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
`b07edbeb47ab7d9171dc8103cad32503978f4ff6`, derived from 0.10.0.
Highlighter `re_highlight` is 0.0.3; native workers resolve `isolate_manager`
4.1.5+1 and `isolate_contactor` 4.1.0. These four MIT dependencies retain their
notices under [licenses](licenses/). Patch details and historical evidence are
in [engine qualification](editor-engine-qualification.md) and the fork's
`BIRB_PATCH.md`.

Standalone consumption pins the editor to B and the design system to exactly
A = `3cccfc448de0306b036f93deb4409280266baa9f`, both at
`https://github.com/mattsp1290/flutter-foundation.git`, with package paths
`packages/birb_code_editor` and `packages/birb_design_system`. The current verified candidate B is
`ffb6eebb69203ad48372b415623046e6f379a3a7`; release gates remain open.
Both [candidate cases](evidence/editor-acceptance/checkpoints/ffb6eeb/candidate-consumers.json)
passed before its push, and both [published cases](evidence/editor-acceptance/checkpoints/ffb6eeb/published-consumers.json)
passed afterward. This evidence commit is separate from B. Early checkpoint B =
`998653683742e5e16ef8de7e9577a2aee0d90178` passed both editor-only consumption
and coexistence with a direct design-system import: independent Pub resolution,
analysis, public-widget edit/undo smoke test and offline-assets release build.
These checks use an external temporary app and no overrides or sibling paths.
Repeat them if code or dependency pins change before final delivery.

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
| Exact source/history | Fork 166 tests; controller/engine tests including mixed separators, raw offsets, nested folds and 64 KiB line | Automated pass; final matrix pending |
| Recovery/input | Catalog macOS framework keyboard and composing deltas; immediate host recovery assertions | Pass; physical IME pending |
| Providers/UI | Completion keyboard acceptance, pointer/keyboard hover, diagnostic marker geometry/navigation, readonly toolbar and stale response tests | Automated pass; physical visual checks and hover retest pending |
| Narrow/scaled UI | 320×480 widget test with 200% text and reachable find/close | [32 current release captures and hover](evidence/editor-acceptance/checkpoints/ffb6eeb/visuals/provenance.json); source/history survive all states; physical inspection pending |
| Workers | Twenty production-view macOS cycles: 1 detached / 3 mounted isolates | [Stage-two pass](evidence/editor-qualification/production-native-workers-stage2.json) |
| Standalone dependency closure | Candidate/published `ffb6eeb`, exact A; editor-only and coexistence | Both cases pass resolution, analysis, public smoke and release build before and after push; release gates pending |
| macOS external native suite | B `ffb6eeb`: pointer focus, keyboard undo/redo, composing updates, system clipboard, readonly, theme/remount and focus exit | Framework suite pass; physical checks pending |
| Native CI | [Checkpoint `ffb6eeb`](evidence/editor-acceptance/checkpoints/ffb6eeb/native-ci.json), PR merge tree verified identical to branch head | Windows, macOS and Linux build/analyze/native suites pass; physical OS evidence pending |
| Browser assets and real input | [Current release matrix](evidence/editor-acceptance/checkpoints/ffb6eeb/browser-ci.json): root/nested paths × DPR 1/2; visible gutter before accessibility, actual typing after enabling it, recovery, readonly, completion/undo/redo; proxy rejects external origins | All four functional cases pass with fork `b07edbe`; historical cloud timing failed the original 50 ms limit; revised-budget CI pending |
| Performance | [100 measured edits after 20 warmups](evidence/editor-acceptance/performance/stage2-results.json), 64 KiB / 2,000 lines, local release Chrome on M4 Max / 64 GiB | DPR 1: p95 33.4 ms, ready 226.4 ms; DPR 2: p95 34.0 ms, ready 245.4 ms; both pass 50 ms / 3 s budgets |
| Review gauntlet | Seven stage-one findings fixed and pushed at `d630362`; pinned Cursor rubric `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` requested three Important fixes and one Suggestion | Both review checkpoints pushed; all eleven findings fixed and independently rechecked; local gates pass |

The selected completion row's foreground was corrected after browser inspection;
the new [completion screenshot](evidence/editor-acceptance/browser/nested/dpr-1/completion-popup.png)
includes the semantic foreground correction. The original
[dark browser screenshot](evidence/editor-qualification/production-chrome-dark.png)
is an early product checkpoint, not final acceptance.

The browser acceptance runner uses a fixture-only compile definition to expose
exact source code units in the catalog's semantics. Normal catalog builds do not
include that observation label. `./tool/run_editor_browser_integration.sh` builds
local assets for `/` and `/editor-check/`, runs both device pixel ratios, rejects
console errors, and records screenshots and requested paths. Its local proxy
denies all external origins, including a deliberate HTTPS probe. The command is
also part of the portable gate. The `Cmd` shortcut label avoids an otherwise
undeclared web fallback-font download for the platform command symbol.

The first portable CI attempt could not launch snap-based Chromium. CI now
installs Chrome for Testing and ChromeDriver together at 153.0.8010.52; that
portable job passed in run 36351633076. The Linux native run established:
the fixture wrote CRLF to the system clipboard and a direct `Clipboard.getData`
returned LF before editor input (run 36351633076, Linux job 108711306308).
On 2026-09-27 the maintainer accepted the clipboard API boundary: paste must
preserve exactly the text returned by Flutter, and copy passes exact source to
Flutter. OS transport may normalize it. The native suite records readback code
units, asserts pasted source/recovery equals that API value, then verifies undo
restores the original mixed separators. Loading, edits, snapshots, recovery and
undo retain exact-separator guarantees. This approved exception applies only to
OS clipboard transport, not internal editor serialization. The updated suite
still needs all three native runs. At checkpoint `636bf0a`, Linux and macOS
passed core input/state and API-boundary clipboard checks but failed an invalid
pairing assertion (multiline replacement was incorrectly expected to pair).
The corrected case uses native deletion followed by insertion and checks both
undo boundaries. Windows also exposed UTF-8 log decoding through cp1252; the
runner now explicitly reads Flutter logs as UTF-8. The complete macOS external
suite passed all four tests at `d630362`, including pairing and clipboard API
readback. Its cloud run `36355561347` failed before starting jobs because
`runner.temp` was referenced in job-level environment configuration. The fix
moves the value to the verification step; actionlint accepts the corrected
workflow. Run `36356469165` then passed the Linux and macOS native suites.
Windows compiled successfully but replaying the UTF-8 build log into the
cp1252 Python console raised `UnicodeEncodeError` before tests started. The
runner now configures both console streams as UTF-8. A portable regression
uses real cp1252 text streams and raw UTF-8 child bytes. Run `36357239753`
at `ffb6eeb` then passed all three native jobs, including Windows test execution.

The performance timer runs inside the browser: real `keydown` starts it, and a
`requestAnimationFrame` after the source/recovery frame ends it. WebDriver
transport time is excluded; no controller text assignment is the measured edit.
The cold timer starts after Flutter startup, before opening the editor. The
fixture exposes only length/generation for large source to avoid copying a
64 KiB observation into every status update. Twenty wheel actions preserve the
source and generation; the screenshot reaches absolute line 101 without a
document reload. The portable browser gate also enforces these budgets. Its cloud run at
`636bf0a` failed at p95 78.1 ms (cold ready 1,571 ms); this failure is retained,
not waived. A local 4× CPU-throttled diagnostic reproduced 79.9 ms and identified
web UI-thread syntax/fold analysis before paint. The fork now coalesces that
work after the source frame and a short quiet period. [Throttled diagnostic records](evidence/editor-acceptance/performance/review-profile.json)
show 65.8 ms after scheduling changes; this is an improvement, not a 50 ms
acceptance pass. A subsequent [local stage-two release run](evidence/editor-acceptance/performance/stage2-results.json)
passes at p95 33.4/34.0 ms and ready 226.4/245.4 ms for DPR 1/2. Updated cloud
performance qualification remains required. [Cloud checkpoint `3ba3755`](evidence/editor-acceptance/checkpoints/3ba3755/performance.json)
passes DPR 1 at 49.6 ms but fails DPR 2 at 98.5 ms; cold readiness is 1,357.1 ms.
Chrome reports software WebGL fallback on the runner. Forcing SwiftShader on
the same local Mac reproduces a 66.0 ms DPR 2 p95, versus 34.0 ms with normal
rendering. A separate CPU profile is mostly main-thread idle, pointing to the
rendering path rather than another source-serialization bottleneck. This is
diagnostic evidence collected against the original 50 ms limit. The next
cloud run
at `ffb6eeb` varied further: DPR 1 failed at 66.0 ms, so DPR 2 was not reached;
all four functional browser cases still passed. A disposable local test of
Flutter’s [CPU-only CanvasKit mode](https://docs.flutter.dev/platform-integration/web/initialization)
with SwiftShader also failed at 67.0 ms.
Normal local Chrome reports the Apple M4 Max Metal renderer. No renderer
changes have been applied to the product or acceptance gate. The scroll
gate also requires the observed source viewport offset to increase, in addition to preserving the document.

## Revised performance budget

The maintainer authorized relaxing the 50 ms limit after the cloud failures.
The enforced p95 key-to-visible-edit budget is now **100 ms**, retaining the
software-rendered CI environment, both DPR 1/2 cases, 20 warmups and 100 measured
edits on the 64 KiB / 2,000-line fixture. Cold readiness remains **3 seconds**.
This supersedes the 50 ms performance requirement in the original W4 plan;
it does not change functional, source-integrity or physical acceptance criteria.

The bounded revision covers recorded cloud p95 measurements of 66.0, 79.5 and
98.5 ms. The latest original-budget failure was
[run 36358121167](https://github.com/mattsp1290/flutter-foundation/actions/runs/36358121167)
at 79.5 ms with readiness 1,192.6 ms. Historical failures above remain failures
under their original budget, and local hardware timings remain separately
identified. New performance records include both enforced budgets. A fresh
cloud run must qualify this change; the threshold change itself is not a pass.

## Physical release checklist

For Chrome/web and each native platform, run the generated fixture at the same
pin map (`flutter run -d macos|linux|windows` for native). Record operator, date,
OS, Flutter, browser where applicable, IME and screen-reader versions. Record
each scenario as pass/fail with notes; do not relabel framework-injected events
as physical OS results.

- Type, select with mouse and keyboard, undo/redo, indent/outdent, comment,
  fold/unfold, find/replace, and scroll on both axes.
- Copy to another application and paste back mixed separators and Unicode;
  compare recovered source with the clipboard API value and record any OS
  normalization. Verify readonly permits copy/find and blocks
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

The maintainer reported that hover information made the code section unusable
at checkpoint `636bf0a`. The follow-up makes short hover cards fit their content
and dismisses hover on source clicks, wheel input, pointer movement to another
source position, or leaving the surface. Widget regressions cover compact size,
click dismissal and leaving the surface. Physical recheck is pending.

All four complete physical platform records are missing. The maintainer has volunteered
for macOS and Chrome; Linux and Windows still need operators. Do not fulfill Beans
`flutter-foundation-r-ikci` or claim consumer adoption until required evidence,
final published pin-map resolution and both review stages are complete. The
consumer separately verifies its real interview screen, persistence and gopls;
owner fixtures do not substitute for those checks.
