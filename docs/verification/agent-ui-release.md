# Agent UI release evidence

Canonical AG-UI dependency: `https://github.com/mattsp1290/ag-ui.git`,
`sdks/community/dart`, `691ab5e3846ad5957d1b04a9237167f5496c6232`.

F1 is `3f29e39177f9201dfb503643a3fe4c21fb755989`; F2 is
`b27b7ff6273a2e65e4267f078a86e281323400ce`. Both are reachable from the
feature branch. F1 was resolved, analyzed, and tested by a clean Git consumer
with Flutter 3.47.1 / bundled Dart 3.13.1. Browser acceptance requires Chrome
and Chromedriver and is not evidence of iOS, Android, Rook, or Benchy delivery.

F3 is `7ddc4edfa3e1732c1114797fdc88e89976b47dfb` and composes the published
F1/F2 descriptors with the unchanged public Birb design-system API.
