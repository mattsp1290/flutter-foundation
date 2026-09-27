#!/usr/bin/env python3
"""Generate an isolated editor consumer using immutable Git dependencies."""

import argparse
from dataclasses import dataclass
import io
import json
import platform
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent.parent
DESIGN_URL = "https://github.com/mattsp1290/flutter-foundation.git"


def run(command, cwd=None, capture=False):
    return subprocess.run(command, cwd=cwd, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def sha(value):
    if not re.fullmatch(r"[0-9a-f]{40}", value):
        raise argparse.ArgumentTypeError("An immutable full Git SHA is required")
    return value


def public_git_url(value):
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise argparse.ArgumentTypeError("Use a credential-free public HTTPS Git URL")
    return value


def flutter_sdk():
    executable = shutil.which("flutter")
    if not executable:
        raise RuntimeError("Flutter is not on PATH")
    version = json.loads(run([executable, "--version", "--machine"], capture=True))
    if version["frameworkVersion"] != "3.47.1" or version["dartSdkVersion"] != "3.13.1":
        raise RuntimeError("Flutter 3.47.1 and its bundled Dart 3.13.1 are required")
    return executable


def export_candidate(candidate, destination):
    candidate = candidate.resolve()
    top = Path(run(["git", "rev-parse", "--show-toplevel"], candidate, True).strip())
    if top != candidate:
        raise RuntimeError("Candidate root must be the Git repository root")
    if run(["git", "status", "--porcelain"], candidate, True).strip():
        raise RuntimeError("Candidate export requires a clean committed checkout")
    original = run(["git", "rev-parse", "HEAD"], candidate, True).strip()
    archive = subprocess.check_output(["git", "archive", "HEAD"], cwd=candidate)
    destination.mkdir()
    # Only Git-tracked HEAD is exported; no checkout paths or ignored files.
    with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
        bundle.extractall(destination, filter="data")
    run(["git", "init", "--quiet"], destination)
    run(["git", "add", "."], destination)
    run(["git", "-c", "user.name=Editor verification", "-c",
         "user.email=editor-verification@localhost", "-c", "commit.gpgsign=false",
         "commit", "--quiet", "-m", "Isolated candidate snapshot"], destination)
    exported = run(["git", "rev-parse", "HEAD"], destination, True).strip()
    return destination.as_uri(), exported, original


def inspect_manifest(repository, design_ref):
    manifest = (repository / "packages/birb_code_editor/pubspec.yaml").read_text()
    if "dependency_overrides:" in manifest:
        raise RuntimeError("Editor declares dependency overrides")
    design = re.search(r"  birb_design_system:\n(.*?)(?=\n\S|\n  \w|\Z)",
                       manifest, re.S)
    if not design or not all(value in design.group(1) for value in
                             (DESIGN_URL, design_ref, "packages/birb_design_system")):
        raise RuntimeError("Requested design-system pin differs from editor dependency A")
    for path in re.findall(r"^\s*path:\s*(\S+)", manifest, re.M):
        if path != "packages/birb_design_system":
            raise RuntimeError("Unexpected local or Git subpath dependency")


def resolved_git_ref(lock, package):
    section = re.search(r"^  " + re.escape(package) + r":\n(.*?)(?=^  \w|\Z)", lock, re.M | re.S)
    if not section or "source: git" not in section.group(1):
        return None
    ref = re.search(r'''^\s+resolved-ref:\s*["']?([0-9a-f]{40})["']?\s*$''',
                    section.group(1), re.M)
    return ref.group(1) if ref else None


@dataclass(frozen=True)
class CandidateSource:
    root: Path


@dataclass(frozen=True)
class PublishedSource:
    url: str
    ref: str


def parse_editor_source(args, argument_parser):
    if args.candidate_root is not None:
        if args.editor_url is not None or args.editor_ref is not None:
            argument_parser.error("Choose candidate-root OR both editor-url and editor-ref")
        return CandidateSource(args.candidate_root)
    if args.editor_url is None or args.editor_ref is None:
        argument_parser.error("Published checks require both editor-url and editor-ref")
    return PublishedSource(args.editor_url, args.editor_ref)


def generate(*, source: CandidateSource | PublishedSource, target_platform: str,
             output: Path, design_system_ref: str, editor_only: bool = False):
    flutter = flutter_sdk()
    output = output.expanduser().resolve()
    if output.exists():
        raise RuntimeError("Output must be a new owned directory")
    if output == ROOT or ROOT in output.parents:
        raise RuntimeError("Output must be outside the workspace")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.mkdir()
    # Snapshot must remain beside the app while file-Git resolution is in use.
    if isinstance(source, CandidateSource):
        url, ref, original = export_candidate(source.root, output / "candidate")
        manifest_root = output / "candidate"
        mode = "candidate"
    else:
        url, ref, original = source.url, source.ref, None
        mode = "published"
        manifest_root = output / "manifest-check"
        run(["git", "init", "--quiet", str(manifest_root)])
        run(["git", "fetch", "--quiet", "--depth=1", url, ref], manifest_root)
        run(["git", "checkout", "--quiet", "--detach", "FETCH_HEAD"], manifest_root)
    inspect_manifest(manifest_root, design_system_ref)
    app = output / "app"
    run([flutter, "create", "--platforms=" + target_platform, "--project-name",
         "birb_editor_platform_check", "--no-pub", str(app)])
    dependencies = {
        "flutter": {"sdk": "flutter"},
        "birb_code_editor": {"git": {"url": url, "ref": ref,
                                     "path": "packages/birb_code_editor"}},
    }
    if not editor_only:
        dependencies["birb_design_system"] = {"git": {
            "url": DESIGN_URL, "ref": design_system_ref,
            "path": "packages/birb_design_system"}}
    manifest = {
        "name": "birb_editor_platform_check", "publish_to": "none",
        "environment": {"sdk": ">=3.13.1 <4.0.0"},
        "dependencies": dependencies,
        "dev_dependencies": {"flutter_test": {"sdk": "flutter"},
                             "integration_test": {"sdk": "flutter"},
                             "flutter_lints": "^6.0.0"},
        "flutter": {"uses-material-design": True},
    }
    # JSON is valid YAML and avoids platform-specific quoting of file Git URLs.
    (app / "pubspec.yaml").write_text(json.dumps(manifest, indent=2) + "\n")
    shutil.rmtree(app / "test")
    templates = ROOT / "tool/editor_fixtures"
    for template, target in (
        ("native_main.dart.template", "lib/main.dart"),
        ("native_editor_test.dart.template", "integration_test/editor_native_test.dart"),
        ("native_driver.dart.template", "test_driver/integration_test.dart"),
    ):
        destination = app / target
        destination.parent.mkdir(exist_ok=True)
        content = (templates / template).read_text()
        content = content.replace("// DESIGN_IMPORT", "" if editor_only else
                                  "import 'package:birb_design_system/birb_design_system.dart';")
        content = content.replace("/* DESIGN_THEME */", "" if editor_only else
                                  "theme: BirbTheme.light, darkTheme: BirbTheme.dark,")
        destination.write_text(content)
    run([flutter, "pub", "get"], app)
    lock = (app / "pubspec.lock").read_text()
    if re.search(r"source: path\b", lock) or "dependency_overrides" in manifest:
        raise RuntimeError("Consumer resolved a path dependency or override")
    for package, expected in (("birb_code_editor", ref),
                              ("birb_design_system", design_system_ref)):
        if resolved_git_ref(lock, package) != expected:
            raise RuntimeError(f"Unexpected resolved ref for {package}")
    record = {"mode": mode, "platform": target_platform, "editor_only": editor_only,
              "host": platform.platform(), "flutter": "3.47.1", "dart": "3.13.1",
              "editor_url": url, "editor_ref": ref, "candidate_original_ref": original,
              "design_system_url": DESIGN_URL, "design_system_ref": design_system_ref}
    (output / "pin-map.json").write_text(json.dumps(record, indent=2) + "\n")
    if mode == "published":
        shutil.rmtree(manifest_root)
    print(json.dumps({"generated_app": str(app), **record}, indent=2))
    return app


def add_source_arguments(result):
    result.add_argument("--candidate-root", type=Path)
    result.add_argument("--editor-url", type=public_git_url)
    result.add_argument("--editor-ref", type=sha)
    result.add_argument("--design-system-ref", type=sha, required=True)


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--platform", choices=("macos", "linux", "windows", "web"), required=True)
    result.add_argument("--output", type=Path, required=True)
    result.add_argument("--editor-only", action="store_true")
    add_source_arguments(result)
    return result


if __name__ == "__main__":
    argument_parser = parser()
    arguments = argument_parser.parse_args()
    generate(source=parse_editor_source(arguments, argument_parser),
             target_platform=arguments.platform, output=arguments.output,
             design_system_ref=arguments.design_system_ref,
             editor_only=arguments.editor_only)
