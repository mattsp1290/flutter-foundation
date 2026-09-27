#!/usr/bin/env python3
"""Observe real macOS worker shutdown through the native fixture's VM service."""

import json
from collections import deque
from pathlib import Path
import re
import subprocess
import sys
import threading
import urllib.request


def main():
    root = Path(__file__).resolve().parent.parent
    command = [
        "flutter", "drive", "-d", "macos",
        "--driver=test_driver/editor_qualification_driver.dart",
        "--target=integration_test/editor_worker_test.dart",
    ]
    process = subprocess.Popen(
        command, cwd=root / "examples/catalog", stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True,
    )
    service_url = None
    samples = []
    output = deque(maxlen=100)
    watchdog = threading.Timer(240, process.terminate)
    watchdog.start()
    try:
        for line in process.stdout:
            output.append(line)
            match = re.search(r"Connecting to Flutter application at (http://\S+)", line)
            if match:
                service_url = match.group(1)
            phase = re.search(r"EDITOR_WORKERS (baseline|mounted|detached)(?: (\d+))?", line)
            if phase:
                if service_url is None:
                    raise RuntimeError("Worker sample arrived before the VM service URL")
                with urllib.request.urlopen(service_url + "getVM", timeout=5) as response:
                    count = len(json.load(response)["result"]["isolates"])
                sample = {"phase": phase.group(1), "cycle": phase.group(2), "isolates": count}
                samples.append(sample)
                print(json.dumps(sample), flush=True)
            elif "All tests passed" in line or "[E]" in line:
                print(line.rstrip(), flush=True)
        result = process.wait()
        if result:
            sys.stderr.write(''.join(output))
            raise RuntimeError(f"Native qualification exited {result}")
        baselines = [s["isolates"] for s in samples if s["phase"] == "baseline"]
        detached = [s["isolates"] for s in samples if s["phase"] == "detached"]
        mounted = [s["isolates"] for s in samples if s["phase"] == "mounted"]
        if len(baselines) != 1 or len(detached) != 20 or len(mounted) != 20:
            raise RuntimeError("Missing worker-lifecycle samples")
        baseline = baselines[0]
        if any(count != baseline for count in detached):
            raise RuntimeError("Detached worker count did not return to baseline")
        if not all(count > baseline for count in mounted):
            raise RuntimeError("Probe did not observe active highlight workers")
        print("PASS: 20 native mount/detach cycles returned to the VM isolate baseline")
    finally:
        watchdog.cancel()
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=10)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Worker lifecycle verification failed: {error}", file=sys.stderr)
        sys.exit(1)
