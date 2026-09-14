# Agent UI release evidence

Canonical AG-UI dependency: `https://github.com/mattsp1290/ag-ui.git`,
`sdks/community/dart`, `691ab5e3846ad5957d1b04a9237167f5496c6232`.

F1 is `3f29e39177f9201dfb503643a3fe4c21fb755989`; F2 is
`b27b7ff6273a2e65e4267f078a86e281323400ce`. Both are reachable from the
feature branch. F1 was resolved, analyzed, and tested by a clean Git consumer
with Flutter 3.47.1 / bundled Dart 3.13.1. Browser acceptance requires Chrome
and Chromedriver and is not evidence of iOS, Android, Rook, or Benchy delivery.

F3 started at `7ddc4edfa3e1732c1114797fdc88e89976b47dfb` and composes the
published F1/F2 descriptors with the unchanged public Birb design-system API.
The current branch also contains its follow-up source-reference and design-audit
fixes. The final release commit is recorded only after the final root gate and
fresh full-tuple consumer complete; no pub.dev release is claimed.

Local evidence uses Flutter 3.47.1 and its bundled Dart 3.13.1. It includes
static-fixture hash/privacy/bounds/lifecycle tests, package and example tests,
the generic web build, and the required local browser POST/SSE runner. CI
installs ChromeDriver rather than treating missing browser capability as a skip.
Manual inspection remains required for light/dark, 320 logical pixels, 200%
text, keyboard focus, overlays, and status/error semantics. Android/iOS,
physical Rook iPhone 12/AYN Thor, Eino cutover, and Benchy production migration
are explicitly outside this repository's evidence.
