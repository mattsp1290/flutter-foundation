# Birb code editor

This package is under development. Engine feasibility is qualified; the complete
editor UI and four-platform delivery gates are pending.
It does not replace the legacy design-system editor yet.

The temporary `BirbEditorQualification` export is solely a catalog probe and
has no stable API. The production view will replace it in W2/W3.

`BirbSourceEditor(controller: controller)` now provides the native view shell.
Supply finite width/height. It enforces one attached view per controller; detach
before disposing the controller. Sequential remounts preserve source, history,
selection and scroll. An optional focus node is borrowed and remains host-owned.
Different controllers support simultaneous independent editors. Readonly input
guards take effect before the next widget rebuild, and replaced engines reject
obsolete input until their old views detach.

The command menu exposes editing, clipboard, folding, wrap and font controls.
Find supports case/whole-word/regex search and literal replacement, with
replace-all as one undo transaction. Escape closes find first; otherwise it
enables Tab traversal. The next Tab or Shift+Tab leaves the whole editor. Use
the visible status control to restore indentation mode. Provider presentation,
selection toolbar, full accessibility/viewport checks and catalog migration
remain W3 work; the shell is not a completed product release.

## Host-owned document

Construct `BirbEditorController(documentId: 'document', source: exactSource)`.
The initial `snapshot` is available synchronously, without a mounted widget.
Dispose the controller after detaching its view. Never dispose or replace it
from a notification; schedule that work for a later event.

`addTextListener` receives a complete immutable snapshot synchronously after
each source transaction. `addListener` separately observes selection and
capability changes as well. Nested mutation returns `reentrant`. Subscriber
exceptions are reported through `FlutterError` using a source-free error;
later subscribers still run. The package does not log document contents.

Generation increases for source mutations and every explicit `replaceDocument`,
including an identical reload. Reload clears selection to offset zero, folds,
composition and history. Readonly remains host-controlled. Selection changes
do not increase generation. `applyEdits` checks expected identity/generation,
readonly and composition, validates the complete transaction, then applies it
as one engine undo entry. Failed validation changes neither source nor selection.

Offsets are raw UTF-16 units in the exact source. Ranges are half-open;
selection preserves directional base/extent. LF, CR and CRLF remain exact.
CRLF counts as two units; offsets between CR and LF or inside a surrogate pair
are rejected. `BirbSourceCoordinates` converts logical zero-based line/column
positions without consulting wrapping or folding.

Edits use original-source coordinates. Overlapping ranges and edits sharing a
start offset are rejected. Adjacent distinct ranges are allowed. Without an
explicit resulting selection, the caret follows the lowest-offset insertion.
A supplied resulting selection is validated against the entire resulting source.
If an insertion joins CR/LF or surrogate halves, its default caret moves to the
end of the joined unit. Adjacent edits are coalesced before engine application.
An engine mutation joining CR/LF reparses logical lines and expands folds;
undo restores the prior exact value and fold state.
No command acknowledges saves or owns storage.

## Language providers

`BirbEditorProvider` is a host-owned, transport-neutral interface for completion,
plain-text hover and diagnostics. Requests contain immutable document identity,
generation, source, raw position and independent request ID. The host translates
these coordinates to its transport. The editor never starts a language server,
opens links, executes completion commands or disposes the provider.

Responses exceeding any limit are rejected in full: 100 completion items,
100 additional edits per completion, 500 diagnostics, 16 KiB UTF-8 per display
message/label/detail/code, and 256 KiB UTF-8 across response strings (including
edit replacements). Hover is plain text with the same 16 KiB limit. Invalid
ranges, overlapping completion edits and invalid resulting selections are also
rejected. Collections presented by the coordinator are immutable.

Each provider channel permits one active logical request and one latest pending
request. The default timeout is five seconds, configurable to a positive duration.
Timed-out transport futures cannot publish later. Source/reload/provider/readonly
changes invalidate results; selection invalidates completion and hover. Detaching
the view closes its coordinator. Acceptance revalidates the document transaction.
Errors expose neutral status enums without source contents; retries are explicit.

## Current verification

Controller, coordinates, transaction validation and provider scheduling have
automated tests. The retained W1 probes cover the real engine and its geometry,
input pipeline, exact history and lifecycle. These tests are not physical OS
keyboard, IME, clipboard or accessibility certification. See the repository's
`docs/editor-engine-qualification.md` for evidence and remaining release gates.
