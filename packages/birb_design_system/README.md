# birb_design_system

Shared semantic tokens, Material themes, accessible components, preview
fixtures, and design-source audits for Birb Flutter applications.

Version `0.1.0` is under development. The package is consumed through an
immutable Git commit and the `packages/birb_design_system` subpath.

## Code review components

The package provides a bounded set of pull-request review widgets. They render
immutable host presentation models and emit controlled callbacks. GitHub is a
workflow reference only: there is no provider DTO, HTTP call, authentication,
Markdown or HTML execution, persistence, or state-management dependency.
`DESIGN.md` section 10 is the authority for their roles, geometry, and keyboard
contracts.

| API | Responsibility |
| --- | --- |
| `BirbReviewStatusBadge` | Review status as an icon plus text |
| `BirbChangedFileList` | Controlled changed-file navigation |
| `BirbDiffView` | A bounded unified diff with line anchors |
| `BirbReviewThreadView` | One host-controlled conversation |
| `BirbReviewComposer` | A multiline reply editor with host-owned async state |
| `BirbReviewStyle` | The semantic roles, icons, and code style they paint |
| `BirbSourceText` | Tab expansion for displayed source |

Models (`BirbReviewFile`, `BirbDiffHunk`, `BirbDiffLine`, `BirbDiffSnapshot`,
`BirbDiffAnchor`, `BirbReviewComment`, `BirbReviewThread`) validate their
invariants on construction and copy their lists defensively. Construct them from
already-normalized data:

```dart
final snapshot = BirbDiffSnapshot(
  file: BirbReviewFile(
    id: 'file-1',
    path: 'lib/main.dart',
    change: BirbReviewFileChange.modified,
    additions: 1,
    deletions: 1,
  ),
  revisionId: 'abc123',
  hunks: <BirbDiffHunk>[
    BirbDiffHunk(
      id: 'hunk-1',
      heading: '@@ -1,2 +1,2 @@',
      lines: <BirbDiffLine>[
        BirbDiffLine(
          id: 'l1',
          kind: BirbDiffLineKind.deletion,
          text: '\tprint("old");',
          oldNumber: 1,
        ),
        BirbDiffLine(
          id: 'l2',
          kind: BirbDiffLineKind.addition,
          text: '\tprint("new");',
          newNumber: 1,
        ),
      ],
    ),
  ],
);

SizedBox(
  height: 320,
  child: BirbDiffView(
    snapshot: snapshot,
    selectedAnchor: selectedAnchor,
    onCommentRequested: (anchor) => setState(() => selectedAnchor = anchor),
  ),
);
```

### Host responsibilities

- **Normalize input.** Hosts turn a provider's patch into hunks and lines with
  their own numbering. No widget parses a patch or reconstructs a position.
- **Give the diff finite constraints.** `BirbDiffView` needs a bounded height
  and width — a `SizedBox`, or an `Expanded` inside a bounded layout. It asserts
  this in debug mode.
- **Own asynchronous state.** Loading, failure, and retry live around the diff.
  Resolve and reopen report an intent; the widget never changes the model it was
  given. The composer takes `isSubmitting` and `errorText` from the host and must
  see a rebuild with pending state as soon as a submission is accepted.
- **Own controllers and drafts.** `BirbReviewComposer` borrows its
  `TextEditingController` and `FocusNode`, never disposes them, and never clears
  draft text. Key them by thread — or by new-discussion anchor including the
  revision — so a late completion can only affect the draft it belongs to.
- **Supply display text.** Every label has an English default and an override.
  Timestamps arrive as host-formatted strings; there is no localization
  dependency. The label classes compare by value, so building them inside
  `build()` is safe.
- **Expect the models to throw.** Validation uses `throw ArgumentError`, not
  `assert`, so it applies in release too. Rejected: blank or multi-line display
  text; a non-positive line number; a numbering/kind mismatch (a context line
  needs both numbers, an addition only a new one, a deletion only an old one);
  a duplicate hunk, line, or comment id within one snapshot or thread; hunks on
  binary or unavailable content; and a bidirectional control in a path, or an
  unterminated bidi override in an author or timestamp. `BirbDiffSnapshot.anchorFor`
  throws for a line the snapshot does not contain; use
  `BirbDiffSnapshot.contains` to test an anchor first. `BirbDiffLine.text` is
  deliberately exempt: source renders verbatim so a reviewer can see a
  Trojan-Source sequence. Normalize a provider payload before constructing.
- **Replace the snapshot rather than re-keying the widget.** Changing
  `snapshot.file.id` or `revisionId` restarts the active line, drops any open
  source selection, and replaces both owned scroll controllers. A change to the
  same file and revision keeps the reader's active line.

### Copy and selection

`Copy source line` always copies the original source: real tab characters,
Unicode intact, no line numbers, no change sign, no trailing newline. It stays
available when commenting is disabled — read-only means no discussion mutations,
not no copy controls.

Native text selection copies what is displayed, which means the spaces a tab
expanded into (four display columns). The source column is one selection region;
line numbers and change signs are excluded from it, so a selection that spans
rows still yields source text only.

### Keyboard

The diff exposes one focusable navigation region, then one stable action area,
and no per-row tab stops. `Up`/`Down` move the active line, `Home`/`End` jump to
the first and last, `Left`/`Right` scroll the source, `F2` enters the active
line's native selectable text with the caret at the start, and `Escape` returns
to the navigation region with the active line preserved. The same list is
visible on screen.

A row is also activatable by pointer and by assistive technology; either takes
the navigation region's focus, so the next arrow key continues from there. The
active-line description is a live region. The source column additionally pans
with a horizontal drag and through the labelled scrollbar's scroll actions.

### Limitations

Unified diffs only — side-by-side layout is deferred, as are raw patch parsing,
provider adapters and authentication, syntax highlighting, Markdown comment
bodies, cross-row continuous selection, editable suggestions, review submission
and merge, complete pull-request timelines, and persisted drafts. Comment bodies
are plain text; an HTML-like string appears literally. Large snapshots build
lazily — snapshot preparation is O(total source text) with a bounded number of
source layouts plus one per hunk heading, and row construction is O(visible
rows) — but no arbitrary repository size is claimed.

Tab stops count one Unicode code point as one display column, so fullwidth,
combining, and multi-code-point emoji source renders and copies correctly but
does not align exactly to the four-column grid. The column width itself is
measured, not estimated: the longest rows by code point are all laid out, so a
wide-glyph line is not clipped.

A drag over the source rows pans the column for touch and stylus only. A mouse
or trackpad drag selects text instead; those pointers reach the offset through
the scrollbar, `Left`/`Right`, or the scroll semantics actions.

### Preview

`package:birb_design_system/design_system_preview.dart` exports
`BirbReviewHarness`, a runnable simulated review with deterministic fixtures. It
has no service dependency, sends nothing, and says so on screen. The catalog at
`examples/catalog` hosts it beside `BirbThemeHarness`.
