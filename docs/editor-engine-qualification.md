# Native editor engine qualification

Status: W1 incomplete; unpatched candidate fails exact-source fidelity.
W2–W4 and release/adoption are not authorized by passing individual probes.

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

## Proposed owned patch boundary; not implemented

Require a maintainer-selected fork location and owner before adopting a fork.
Candidate owner/location proposed for decision: `mattsp1290/re-editor`.
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

## Dependency and license boundary

The scaffold pins design system dependency A to
`3cccfc448de0306b036f93deb4409280266baa9f`, URL
`https://github.com/mattsp1290/flutter-foundation.git`, subpath
`packages/birb_design_system`. No editor delivery commit B exists yet and no
external dependency closure is claimed. There are no overrides or member
lockfiles. Runtime product source and an engine adapter are not implemented.

Notices in `docs/licenses/` preserve re_editor, re_highlight, isolate_manager
and isolate_contactor licenses from the exact resolved releases. They are
research/dependency notices, not a claim of owned fork publication.
