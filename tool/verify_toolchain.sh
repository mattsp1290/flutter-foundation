#!/bin/sh
set -eu

flutter --version --machine | python3 -c '
import json
import sys

actual = json.load(sys.stdin)
expected = {
    "frameworkVersion": "3.47.1",
    "frameworkRevision": "6655482ec06e547f90abf8ae7590466f4415978d",
    "engineRevision": "5d531788691ec3404cac0cee66ead4007b177363",
    "dartSdkVersion": "3.13.1",
}

errors = []
for field, expected_value in expected.items():
    actual_value = actual.get(field)
    if actual_value != expected_value:
        errors.append(f"{field}: expected {expected_value}, got {actual_value}")

if errors:
    print("Pinned Flutter toolchain verification failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print(
    "Verified Flutter 3.47.1, framework "
    "6655482ec06e547f90abf8ae7590466f4415978d, and Dart 3.13.1."
)
'
