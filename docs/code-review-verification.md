# Code review component verification

Evidence for the code-review components added to `packages/birb_design_system`
and demonstrated by `examples/catalog`.

## Environment

- Implementation revision: `7be9b5b0137b0273dee43054b018c9236805389b`,
  with review fixes applied on top (see the second commit on this branch)
- Base revision: `70e73faa9aec8d7b21da333a942e09af1c2698db`
- Flutter `3.47.1`, stable channel; bundled Dart `3.13.1`
- Host: macOS (darwin 25.6.0), Apple silicon
- Recorded: 2026-09-10

## Automated gate

`./tool/verify.sh` from the repository root, exit code `0`:

| Step | Result |
| --- | --- |
| Resolve locked workspace dependencies | pass |
| Verify pinned Flutter toolchain | pass |
| Check Dart formatting | pass |
| Audit design-system source | pass |
| Analyze workspace | pass, no issues |
| Test `birb_design_system` | pass, 331 tests |
| Test `birb_appearance` | pass, 1 test |
| Test catalog | pass, 5 tests |
| Build catalog web runner | pass, `✓ Built build/web` |

`flutter build macos` from `examples/catalog` also succeeded and produced no
change to the generated runner files (`git status` clean apart from the
untracked planning inputs under `.agents/`).

### Second review round — the gauntlet

The branch was then put through a second dual review at
`d63606e`. Both reviewers again returned `REQUEST_CHANGES`. The
significant finding was a regression introduced by the first round's own fix:
the horizontal-drag `GestureDetector` added to make the source pannable sat
inside the `SelectionArea` and won the gesture arena, removing drag-to-select
for every pointer. The recognizer is now restricted to touch and stylus and is
only installed when there is something to scroll, and a test drives a mouse drag
and asserts the platform copy shortcut returns the selection.

Also fixed in that round: the composer's activation guard could deadlock (a host
reporting the same error twice could never submit again, with the button still
enabled) and was simultaneously defeated by any host passing an inline callback
— it is now bounded to one frame and disables the action while it holds; a
host-driven `selectedAnchor` moved the active line without revealing it; the
harness kept single-slot errors after its pending state went per-key, so
starting any second request erased an unread failure; the scrollbar reserved a
48-pixel target but only 12 pixels of it responded; a stacked row rendered its
prose metadata in the monospace code style, contradicting section 10.1; and the
bidi rule written for file paths also rejected legitimate bidi-isolated author
names. Documentation claims that did not hold — the scrollbar hit area, the
monospace scope, the contrast coverage, "rename metadata" among the tested
behaviours, and a self-contradiction about cross-row selection — were corrected
rather than left standing.

### First review round

Two independent reviewers examined the first commit and both returned
`REQUEST_CHANGES`. Their reports stay local under the ignored `reviews/`
directory, as this repository requires. Both independently found, and verified with probe tests, that
`ExcludeSemantics` was stripping the tap action from changed-file items and diff
rows, so assistive technology could read the review but not operate it. That and
the other accepted findings — a stacked-layout scroll extent that clipped the
end of the widest line, a thread failure shown on every thread, a submission
that discarded a concurrent one, an unreachable load-failure branch, a dead
`hasNoFinalNewline` field, a missing hunk-heading boundary, a monospace fallback
resolved in the wrong order, and label classes without value equality — are
fixed in the follow-up commit, each with a regression test that fails without
the fix.

### What the automated tests prove

- **Models.** Defensive list copies, legal empty states, duplicate identities,
  illegal numbering/kind combinations, and exact anchor construction for added,
  deleted, and context lines.
- **Style.** Every foreground/background pair the review widgets paint —
  including the four painted outside `BirbReviewStyle` (the thread's error row
  and state labels, and the diff header and action area) — reaches 4.5:1, and
  every boundary and focus cue reaches 3:1, in both themes. The style resolves
  only existing `ColorScheme` and `BirbSemanticColors` roles; a set difference
  against the allowed roles is asserted, though because this theme maps several
  roles onto the same palette primitive that assertion compares colour values,
  not role identity. The ban on constructing a `Color` at all is enforced by
  `check_design_system.dart`, which also now scopes the monospace `fontFamily`
  exception to `birb_review_style.dart`.
- **Diff.** Signs, old/new numbers, hunk headings, the rename header and its
  overridable label, non-colour selected semantics, distinct
  empty/binary/unavailable messages, exact anchors per line kind, identity
  replacement clearing obsolete state and resetting owned scroll positions, and
  a same-identity content change keeping the reader's active line.
- **Keyboard.** Tab reaches the navigation region, then the action area, then
  leaves the diff; arrows, `Home`, and `End` move the active line; `Left`/
  `Right` scroll the source. A keyboard-only path reaches a tab-containing line,
  presses `F2`, selects a substring with `Shift+Arrow`, copies with the platform
  shortcut, presses `Escape`, and tabs out — asserted with commenting both
  enabled and disabled, and with the clipboard read from the actual
  `Clipboard.setData` platform message rather than a callback.
- **Copy boundary.** `Copy source line` copies the original text with real tabs
  and Unicode and without decoration, in both commenting modes; native selection
  copies the displayed, tab-expanded text. A mouse drag across a row selects
  source and copies it with the platform shortcut without panning the column,
  while a touch drag pans it — the two gestures are asserted separately.
- **Bounded construction.** A 10,000-line snapshot containing a 2,000-character
  line builds fewer than 200 source rows at an 800×600 viewport, and keyboard
  `End` reaches line 10,000 and emits its exact anchor without tester scrolling
  or controller jumps. Focus recovery after pointer scrolling unmounts the
  focused row is covered separately. No wall-clock threshold is asserted.
- **Composer.** Whitespace-only rejection, exact untrimmed multiline emission,
  two activations before a host rebuild submitting once, pending read-only
  state, recoverable error and retry, host-controlled clearing, borrowed
  controller/focus replacement, and disposal without touching the caller's
  objects.
- **Harness.** The full workflow (file → anchor → draft → failure → retry →
  success → resolve → reopen), a pending submission leaving another draft
  untouched, a completion for a replaced revision reported as stale rather than
  attached, and unmounting with a submission pending throwing nothing.
- **Responsive.** Light and dark × 320/800 logical width × 1.0/2.0 text scale
  render the harness with no Flutter overflow exception, the diff present, and
  the controls at or above the 48 logical pixel target.

## Manual inspection

Run from `examples/catalog`:

```sh
flutter build macos --debug
open build/macos/Build/Products/Debug/flutter_foundation_catalog.app
```

| Check | Environment | Outcome |
| --- | --- | --- |
| Light theme rendering | macOS, 1400×1000 | Pass. Flat fills, square corners, aligned monospace gutter, `+`/`−` markers on `success`/`error`, tabs expanded to four columns, `<b>not parsed</b>` shown literally. |
| Dark theme rendering | macOS, 1400×1000 | Pass. Status legend shows `warning`/`success`/`error`/`info` correctly; code stays `onSurface` on `surface`. |
| Theme switch | macOS | Pass, no transition animation. |
| Keyboard traversal into the catalog chips | macOS | Pass. `Tab` reaches each chip; `Space` activates. Dark mode was selected by keyboard alone for the recorded screenshot. |
| 320 logical pixel width | macOS, window resized to 320 points | Pass. Chips and controls wrap, file paths wrap without hiding their suffix, each diff row stacks its metadata above the source, the source column keeps its own horizontal scrollbar, and no overflow banner appears. |
| Keyboard traversal into the diff at 320 points | macOS | Pass. `Tab` reaches the navigation region and then the action area, scrolling each into view. |
| Horizontal source scrolling | macOS | Pass. The labelled strip below the rows scrolls the source column only; line numbers and signs stay in place. |

### Pending checks

These are recorded as **not yet performed** and must not be read as passing:

- `flutter run -d chrome` interactive inspection: web-specific text selection,
  the browser context menu, and clipboard behaviour under a real browser.
- 200 percent OS text scale driven from macOS system settings rather than a
  `MediaQuery` override.
- VoiceOver announcement review for diff rows, thread state labels, and the
  live regions.
- Physical-device inspection (iOS/Android); the components are not claimed to
  be verified there.

The bird emoji in the modified-file fixture falls back to a non-monospace glyph
in the macOS monospace stack. That is expected font fallback for an emoji, not a
layout defect: the row height and the gutter alignment are unaffected because
the row extent is fixed from the measured line height.

## Limitations recorded from the inspection

- The diff's action area and keyboard help occupy a scrollable region capped at
  35 percent of the available height. That cap binds well before 320 logical
  pixels: in a diff about 500 logical pixels tall the third action button is
  already partly below the fold. Everything stays reachable by scrolling that
  region, but hosts should give the diff more height where they can.
- A hunk heading wraps at narrow widths and can be several lines tall. The
  active line is revealed after a snapshot is prepared so a tall heading never
  hides it.
- No performance SLA is claimed for large diffs. The measured property is that
  snapshot preparation is O(total source text) with a single text layout for the
  widest line, and that row construction is O(visible rows).
