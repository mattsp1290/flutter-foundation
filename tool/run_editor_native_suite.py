#!/usr/bin/env python3
"""Build and drive the generated native fixture; require executed test evidence."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    # Keep both log decoding and console replay independent of the host code page.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, required=True)
    parser.add_argument("--platform", choices=("macos", "linux", "windows"), required=True)
    args = parser.parse_args()
    app = args.app.resolve()
    record = json.loads((app.parent / "pin-map.json").read_text())
    if record["platform"] != args.platform:
        raise RuntimeError("Fixture platform differs from pin map")
    for path in ("integration_test/editor_native_test.dart", "test_driver/integration_test.dart"):
        if not (app / path).is_file():
            raise RuntimeError(f"Missing required native suite: {path}")
    flutter = shutil.which("flutter")
    if not flutter:
        raise RuntimeError("Flutter is not on PATH")
    steps = [
        ("analyze", [flutter, "analyze"]),
        ("build", [flutter, "build", args.platform]),
        ("drive", [flutter, "drive", "-d", args.platform,
                   "--driver=test_driver/integration_test.dart",
                   "--target=integration_test/editor_native_test.dart"]),
    ]
    for name, command in steps:
        if name == "drive" and args.platform == "linux":
            command = ["xvfb-run", "-a", *command]
        print(f"Running editor {args.platform} {name}", flush=True)
        with (app.parent / f"{name}.log").open("w") as log:
            result = subprocess.run(command, cwd=app, stdout=log,
                                    stderr=subprocess.STDOUT, timeout=900)
        # Flutter writes UTF-8 even when Windows Python defaults to cp1252.
        output = (app.parent / f"{name}.log").read_text(encoding="utf-8", errors="replace")
        print(output, flush=True)
        if result.returncode:
            raise RuntimeError(f"Native {name} failed: {result.returncode}")
        if name == "drive" and "EDITOR_NATIVE_SUITE_PASS" not in output:
            raise RuntimeError("Driver exited without proof the native suite executed")
    (app.parent / "result.json").write_text(json.dumps({
        **record, "result": "pass", "evidence": "native framework input, not physical OS input",
    }, indent=2) + "\n")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Native editor verification failed: {error}", file=sys.stderr)
        sys.exit(1)
