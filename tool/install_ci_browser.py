#!/usr/bin/env python3
"""Install a matched, pinned Chrome for Testing pair on the Linux CI runner."""

import argparse
import os
from pathlib import Path
import subprocess
import urllib.request
import zipfile

VERSION = "153.0.8010.52"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    for name in ("chrome-linux64", "chromedriver-linux64"):
        archive = output / f"{name}.zip"
        url = f"https://storage.googleapis.com/chrome-for-testing-public/{VERSION}/linux64/{name}.zip"
        urllib.request.urlretrieve(url, archive)
        with zipfile.ZipFile(archive) as bundle:
            for entry in bundle.infolist():
                path = (output / entry.filename).resolve()
                if output not in path.parents:
                    raise RuntimeError("Browser archive contains an invalid path")
                bundle.extract(entry, output)
                if not entry.is_dir():
                    path.chmod((entry.external_attr >> 16) & 0o777 or 0o644)
        archive.unlink()
    chrome = output / "chrome-linux64/chrome"
    driver = output / "chromedriver-linux64/chromedriver"
    subprocess.run([str(chrome), "--version"], check=True)
    subprocess.run([str(driver), "--version"], check=True)
    with Path(os.environ["GITHUB_ENV"]).open("a") as environment:
        environment.write(f"CHROME_EXECUTABLE={chrome}\n")
    with Path(os.environ["GITHUB_PATH"]).open("a") as path:
        path.write(f"{driver.parent}\n")


if __name__ == "__main__":
    main()
