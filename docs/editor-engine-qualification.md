# Native editor engine qualification

Status: executable W1 probes pass with the owned fork; the controller and
production view are implemented and W4 acceptance is in progress. This is not a release,
physical-IME certification or four-platform delivery claim.

## Production-view checkpoint

The W2 controller and W3 production view now replace the temporary catalog
probe. Provider completion, pointer/keyboard hover, diagnostic markers and
navigation, find/replace, selection toolbar and focus exit have automated
coverage. The catalog retains the legacy API alongside two independent native
editors and deterministic provider fixtures. The qualification-only widget is
now test support, not a public package export.

On 2026-09-27, the native input/composition/recovery test passed using the
production `BirbSourceEditor` with fork `e6f40f5`. The production worker probe
also passed all twenty cycles: one baseline isolate, three mounted, one after
every detach. [Production samples](evidence/editor-qualification/production-native-workers.json)
record the working-tree provenance. Neither result establishes physical IME or
screen-reader behavior. The portable workspace gate passed after updating its
design-contract scope assertion; a subsequent pointer-hover regression test
also passed. Final release visual/platform/performance evidence remains W4.

## Current owned candidate

W4's blocked-origin Chrome tests exposed two accessibility issues that the
earlier feasibility probe did not cover. The product view now supplies an
editable semantic field (the web engine needs it to create a DOM input when
accessibility is enabled). The pinned Flutter SDK's semantic input path omits
the `beforeinput` hook needed by delta mode. The owned fork therefore translates
full web editing values through its existing delta/pairing/composition pipeline
in exact-source mode; native input retains delta mode. Selection-only messages
cannot replace a multiline selection with unchanged base-line text. Two new
fork regression tests cover exact undo, pairing, deletion and composition.
Real ChromeDriver typing now passes with accessibility enabled, with local
release assets at both root and nested paths and pixel ratios 1 and 2. This
does not establish physical screen-reader or IME behavior.

The maintainer supplied `git@github.com:mattsp1290/re-editor.git` and confirmed
`~/git/re-editor` as the fork checkout. Foundation resolves the public HTTPS URL
at immutable commit `b07edbeb47ab7d9171dc8103cad32503978f4ff6`, branch
`birb/exact-source-0.10.0`; remote and local SHAs match. The fork starts at
upstream `0a2a7d832011431d123b1b9391a481171cb4b849`, whose library is identical
to the publisher archive. `BIRB_PATCH.md` in the fork records ownership,
regression tests, upgrade rules and removal conditions.

The bounded patch touches eight upstream source files and adds one private
exact-value helper. It retains source
separators in existing line/history values, groups nested transactions, includes
folded document tails in select-all, fixes upstream's paired-delete regression,
and cancels owned deferred timers. W2's controller probe also exposed selection
and folding creating history entries or discarding redo. Exact-source mode now
updates the current node's presentation state without branching source history.
All value mutations that join CR and LF now produce canonical logical lines
before history and notifications; that uncommon edit reparses the document and
expands folds, with exact undo recovery. Tests cover Enter, deletion and range
replacement, and assert logical line counts during randomized edits.
Review qualification added trailing transaction boundaries so later typing has
its own undo entry, corrected word-extension direction, and bounded forward word
navigation at trailing whitespace. Six new regressions cover these cases.
CPU profiling of the web fallback showed syntax and folding analysis blocking
the first edit frame. Web tasks now retain only their latest pending input and
run after a frame plus a 50 ms quiet period; disposal cancels pending work. The 166 native
tests and an additional Chrome analysis/lifecycle case pass. This uses the
existing web UI-thread fallback, not a browser worker bootstrap. Native isolates
are unchanged. Browser latency still requires its separate measured gate.
The renderer, input stack and history remain
the upstream implementations. `preserveLineBreaks: true` is an opt-in public
engine option; Foundation's internal adapter enables it and selects the first
existing separator as the Enter convention (LF for a document without one).

The fork's 166 tests pass on Flutter 3.47.1. Its W1 baseline and current analyzer
both report the same 15 upstream diagnostics; this is not reported as a passing
fork analysis gate. Foundation's W1 workspace analysis passed. The original
16 engine/view/provider qualification tests still pass, covering exact source,
same-stack callback before queued reload, filtered fold/selection events,
multi-edit undo including selection, visible 64 KiB paragraphs, delta input,
detach and public paragraph geometry after scroll/wrap. A delayed provider
prototype rejects a stale response, positions completion/hover with exported
caret geometry, paints diagnostic range markers, exposes a semantic diagnostic
button and accepts a replacement that undoes exactly. Two simultaneous views
and twenty highlighted remounts return owned subscription counts to zero while
preserving host text/history/selection. Desktop widget variants
are simulated target-platform settings, not actual Linux/Windows execution.

Chrome 153.0.8010.53 / ChromeDriver 153.0.8010.52 loaded a local release build at
`/editor-check/` using `flutter build web --no-web-resources-cdn --base-href
/editor-check/`. Visible absolute digits and Go keyword/string/number/comment
styles appeared with no provider and without enabling accessibility mode.
WebDriver pointer and Command+A/typing actions changed the source to
`package typed`; the visible synchronous-recovery counter became 13 UTF-16
units. Browser logs had no errors; captured requests were all local assets.
This observation is not yet the W4 test that actively blocks external origins.
Screenshots: [initial rendering](evidence/editor-qualification/chrome-nested-base.png)
and [keyboard edit](evidence/editor-qualification/chrome-keyboard-edit.png).
These screenshots used the preceding timer-fix pin `9f1acb6`; the subsequent
pins change timer disposal and history bookkeeping, not rendering. Repeat
release evidence at delivery. Native worker/input evidence below was collected
at the preceding `5e6cf95` pin; rerun these probes before delivery.

`flutter build macos` and the native `editor_qualification_test.dart` driven
through `editor_qualification_driver.dart` pass. The test sends keyboard and
platform delta messages, observes exact host recovery before the next frame,
checks intermediate/committed composing text and undoes to prior exact source.
This is native framework-input evidence, not physical OS IME evidence. The
driver reports a foregrounding failure and missing native integration plugin
warning, but connects through the VM service and receives passing test results;
no foreground/manual claim is made.

The native worker-lifecycle probe observes three VM isolates while a highlighted
view is mounted and one after detach, returning to baseline on all twenty
cycles. Run `python3 tool/verify_editor_worker_lifecycle.py` to repeat this
measurement; it requires all samples and an actual increase while mounted.
The [recorded native samples](evidence/editor-qualification/native-workers.json)
contain counts and tool/platform versions, without VM-service credentials.

| Required W1 capability | Public hook and executable evidence | Outcome |
| --- | --- | --- |
| Exact load/edit/copy, CRLF/CR/mixed/Unicode, nested folds, 64 KiB | Fork `exact_source_test.dart`; Foundation `engine_qualification_test.dart` and 64 KiB paragraph test | Pass with owned patch |
| Synchronous source before recovery task, no fold/selection text event | `EngineAdapter` listener; adapter recovery test; native delta/composition callback test | Pass |
| Atomic edits and exact history/selection; raw folded offsets | `runRevocableOp`, `unfoldLineSelection`, per-line serialization; Foundation transaction and raw-offset probes | Pass with owned patch |
| Async completion, hover, diagnostic ranges/list, stale-result rejection | Exported `CodeIndicatorValueNotifier`/`CodeLineRenderParagraph`; bounded coordinator and product widget tests | Implemented and tested; final platform matrix remains W4 |
| Offline Go and visible absolute lines, nested asset path, long-line rendering | Explicit `langGo`/`CodeHighlightTheme`, `DefaultCodeLineNumber`; Chrome screenshots/network observation and 64 KiB view test | Pass for W1; W4 actively blocked-origin/performance matrix remains |
| Theme/remount/two-controller state and owned resource disposal | Repeated highlighted-view subscription test; native worker VM samples and detach/input tests | Pass with owned timer fixes |

`CodeFindController` and revocable replacements are exercised by the fork's
upstream search tests. Provider UI uses exported paragraph geometry directly;
it need not force asynchronous providers through the upstream synchronous
`CodeAutocomplete` prompt builder. No separate text renderer or private runtime
import is required. Selection toolbar and search UI now compose the public engine.

`PATH="/tmp/birb-editor-tools:$PATH" ./tool/verify.sh` passes, including source and
boundary audits, workspace analysis, all package/example tests, mandatory
generic POST/SSE browser integration and both web builds. The temporary tools
directory contains the official ChromeDriver, while coreutils supplies timeout;
these are machine prerequisites, not repository artifacts. The harness now
serves through Flutter's `web-server` device before WebDriver launches Chrome,
avoiding the pinned SDK's `chrome` device startup deadlock. It supports the real
macOS executable path and `CHROME_EXECUTABLE`. The Benchy contract test now
distinguishes its writable composer from its readonly selectable caption.

The release JavaScript build passes; the tool's separate Wasm dry run warns
that the pinned isolate_contactor uses `dart:html`. No Wasm support is claimed.
Physical keyboard/clipboard/IME and screen-reader release checks on all selected
platforms remain W4 requirements, as do production provider coordination,
performance budgets and external package closure.

The source audit now distinguishes direct, unmodified forwarding from the
existing `BirbReviewStyle.codeTextStyle` token from authoring a new font. It still
rejects literal names, arbitrary styles, fallback-list modifications and color
exceptions; all 54 audit tests pass. The package boundary scan prunes generated
`.dart_tool`, `build` and Git metadata, while a separate disposable probe proves
source member lockfiles are still rejected. Existing generated validation
fixtures were not edited or removed.

## Original unpatched experiment (retained failure evidence)

## Reproduction on 2026-09-27

Baseline: `92948eaa1efa7cdcfe90681acc58d0f7e7233098`.
Working branch: `feature/production-code-editor`.

`./tool/verify_toolchain.sh` passes with Flutter 3.47.1, framework
`6655482ec06e547f90abf8ae7590466f4415978d`, Dart 3.13.1.
`flutter pub get` succeeds from the root workspace. Candidate versions:
re_editor 0.10.0, re_highlight 0.0.3, isolate_manager 4.1.5+1,
isolate_contactor 4.1.0. The one root lockfile records their archive hashes.

The downloaded publisher archive
<https://pub.dev/api/archives/re_editor-0.10.0.tar.gz> has SHA-256
`66671c4774a6b4c5254c9a53ab35a083e7e7da9ae371c519bcf491c70a2a4e56`,
matching the plan's research. All probes import the public package barrel.
Upstream source references below refer to this exact archive, not moving main.

Run `cd packages/birb_code_editor && flutter test`.

| Capability | Hook and executable probe | Result |
| --- | --- | --- |
| SDK compilation | Public `re_editor.dart` import in engine qualification tests | Pass |
| Homogeneous LF/CRLF/CR, tabs, Unicode, trailing empty line | `fromText`, `CodeLineOptions`, exact UTF-8 comparison | Pass |
| Full folded source and selection | `collapseChunk`, `text`, `selectAll`, `selectedText` | Pass for the tested single fold |
| Same-stack source delivery and undo/redo | Controller listener with `replaceSelection`, `undo`, `redo` | Pass for a programmatic engine edit; real input untested |
| Mixed separators | `fromText('a\r\nb\rc\n')`, exact UTF-8 comparison | **Fail:** returns `a\nb\nc\n` |
| Replacement separator identity | Different raw replacements compared as `CodeLineEditingValue`, including undo/redo | Both become the same value; separator information is lost |
| Atomic formatting/completion, raw offsets, IME | Not yet qualified | Missing |
| Provider range geometry, scroll/wrap, overlays | Not yet qualified | Missing |
| Offline Go grammar, workers, nested base path, 64 KiB rendering | Not yet qualified | Missing |
| View/worker disposal, remount, two controllers | Not yet qualified | Missing |
| Browser/native interactive qualification | Not yet qualified | Missing |

The failing test is retained as a release-blocking requirement, not replaced
with an assertion accepting normalization. The suite reports three passes and
one failure. `flutter analyze` and `git diff --check` pass.

`./tool/verify.sh` was attempted. Locked dependency resolution, toolchain,
formatting, source audit and AG-UI fixtures passed. The existing boundary audit
then failed on pre-existing ignored `.dart_tool/standalone-validation/` fixtures
for birb_appearance and birb_design_system containing member lockfiles and
override files. Those unrelated generated fixtures were left untouched. The
new qualification suite is wired into the gate after analysis; this run stopped
before reaching it. Even with the local fixture issue resolved, the new suite
blocks the gate on mixed-source fidelity. No successful full portable gate,
catalog integration or product implementation is claimed.

## Why a passive adapter is insufficient

In upstream `lib/src/code_line.dart:1174`, `textLines` replaces both CRLF and CR
with LF before splitting. `CodeLine` stores text and folded children, without
per-line separators. `CodeLine.asString` joins with one document-wide separator.
`lib/src/_code_line.dart:1753` uses the same normalization for replacements.
The private history cache at line 1971 records those normalized editing values.
Thus two different raw insertions can produce equal public editing values and
equal undo/redo results. A listener cannot infer which raw insertion occurred.

A separate source string plus normalized-text diff is therefore insufficient.
Intercepting every operation and maintaining separate undo metadata would need
additional qualification and risks the competing history engine prohibited by
the plan. This evidence does not claim every possible adapter is impossible;
it establishes why the straightforward passive mapping does not meet the gate.

## Original proposed patch boundary

The required maintainer-selected fork location and owner are now resolved above.
The original candidate owner/location was `mattsp1290/re-editor`.
Do not switch engines or weaken source fidelity.

Investigate per-line separator metadata retained in the existing engine value
and history. Likely upstream files are `code_line.dart` (model, parsing,
serialization, equality), `_code_line.dart` (range edits, splitting/joining,
indentation, clipboard, offsets), and `code_lines.dart` (serialization).
Audit every constructor/copy and folding path for metadata preservation.
Keep the existing renderer, input stack and history implementation. If this
cannot remain a bounded patch, return for a revised design instead of rewriting
them. Geometry and lifecycle may reveal additional blockers and remain unproven.

Before acceptance, tests must cover mixed separators after paste, IME, line
insert/delete/move, nested fold, copy, multi-edit transactions, undo/redo and
newline-only replacements with equal normalized text. Newline insertion uses
the selected convention; existing separators stay exact. The entire W1 matrix
must pass, including interactive checks. A hosted fork must retain upstream
licenses, use an immutable Git ref without overrides, record its diff from
0.10.0, and document ownership and upgrade/removal conditions. Upgrades rerun
the complete qualification suite; remove the patch only when upstream passes it.

## Historical dependency and license boundary (original scaffold)

The scaffold pins design system dependency A to
`3cccfc448de0306b036f93deb4409280266baa9f`, URL
`https://github.com/mattsp1290/flutter-foundation.git`, subpath
`packages/birb_design_system`. No editor delivery commit B exists yet and no
external dependency closure is claimed. There are no overrides or member
lockfiles. The qualification adapter/view exist; the public production contract
is not implemented.

Notices in `docs/licenses/` preserve re_editor, re_highlight, isolate_manager
and isolate_contactor licenses from the exact resolved releases. They are
research/dependency notices, not a claim of owned fork publication.
