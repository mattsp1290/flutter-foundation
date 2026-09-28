#!/usr/bin/env python3
"""Resolve, analyze, test and build both supported standalone editor pin maps."""

import argparse
import json
from pathlib import Path
import subprocess
import tempfile

import create_editor_native_harness as harness


SMOKE = """
import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:birb_editor_platform_check/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('standalone public editor import, render, edit and undo', (tester) async {
    await tester.pumpWidget(const EditorFixture());
    await tester.pump();
    final host = tester.state<EditorFixtureState>(find.byType(EditorFixture));
    expect(find.byType(BirbSourceEditor), findsNWidgets(2));
    expect(host.controller.snapshot.source, fixtureSource);
    expect(host.controller.applyEdits(
      expectedDocumentId: host.controller.snapshot.documentId,
      expectedGeneration: host.controller.snapshot.generation,
      edits: [const BirbEditorEdit(range: TextRange.collapsed(0), text: '// smoke\\r\\n')],
    ), BirbEditorEditResult.applied);
    expect(host.recovered, '// smoke\\r\\n$fixtureSource');
    host.controller.undo();
    expect(host.recovered, fixtureSource);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    harness.add_source_arguments(parser)
    # Consumer cases always build web; native execution is a separate gate.
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    source = harness.parse_editor_source(args, parser)
    flutter = harness.flutter_sdk()
    records = []
    with tempfile.TemporaryDirectory(prefix="birb-editor-consumers-") as temporary:
        for editor_only in (True, False):
            output = Path(temporary) / ("editor-only" if editor_only else "coexistence")
            app = harness.generate(source=source, target_platform="web",
                                   output=output, design_system_ref=args.design_system_ref,
                                   editor_only=editor_only)
            (app / "test").mkdir()
            (app / "test/editor_smoke_test.dart").write_text(SMOKE)
            for command in ([flutter, "analyze"],
                            [flutter, "test", "test/editor_smoke_test.dart"],
                            [flutter, "build", "web", "--no-web-resources-cdn"]):
                subprocess.run(command, cwd=app, check=True, timeout=600)
            record = json.loads((output / "pin-map.json").read_text())
            record.update(result="pass", checks=["resolve", "analyze", "widget-smoke", "release-web-build"])
            records.append(record)
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(records, indent=2) + "\n")
    print(f"Both isolated consumer cases passed; evidence: {args.evidence}")


if __name__ == "__main__":
    main()
