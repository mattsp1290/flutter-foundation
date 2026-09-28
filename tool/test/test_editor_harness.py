import argparse
from contextlib import redirect_stderr
import io
from pathlib import Path
import subprocess
import tempfile
import unittest

from tool import create_editor_native_harness as harness


class EditorHarnessTest(unittest.TestCase):
    def test_source_boundary_rejects_incomplete_and_conflicting_modes(self):
        parser = argparse.ArgumentParser()
        harness.add_source_arguments(parser)
        shared = ["--design-system-ref", "a" * 40]
        url = ["--editor-url", "https://example.com/editor.git"]
        ref = ["--editor-ref", "b" * 40]
        candidate = ["--candidate-root", "/tmp/editor-candidate"]
        for mode in ([], url, ref, candidate + url, candidate + ref, candidate + url + ref):
            with self.subTest(mode=mode), redirect_stderr(io.StringIO()):
                args = parser.parse_args(shared + mode)
                with self.assertRaises(SystemExit) as error:
                    harness.parse_editor_source(args, parser)
                self.assertEqual(error.exception.code, 2)
        self.assertEqual(
            harness.parse_editor_source(parser.parse_args(shared + candidate), parser),
            harness.CandidateSource(Path("/tmp/editor-candidate")))
        self.assertEqual(
            harness.parse_editor_source(parser.parse_args(shared + url + ref), parser),
            harness.PublishedSource("https://example.com/editor.git", "b" * 40))

    def test_resolved_refs_accept_pub_yaml_quoting(self):
        for quote in ('', '"', "'"):
            ref = 'fb37f2' + 'a' * 34
            lock = ('packages:\n  birb_code_editor:\n    description:\n'
                    f'      resolved-ref: {quote}{ref}{quote}\n'
                    '    source: git\n  unrelated:\n    source: hosted\n')
            self.assertEqual(harness.resolved_git_ref(lock, 'birb_code_editor'), ref)
            self.assertIsNone(harness.resolved_git_ref(lock, 'unrelated'))

    def test_export_contains_only_clean_committed_head(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            candidate = root / "input"
            candidate.mkdir()
            subprocess.run(["git", "init", "--quiet", str(candidate)], check=True)
            (candidate / ".gitignore").write_text("ignored\n")
            (candidate / "source").write_text("committed")
            subprocess.run(["git", "add", "."], cwd=candidate, check=True)
            subprocess.run(["git", "-c", "user.name=Test", "-c", "user.email=test@localhost",
                            "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "fixture"],
                           cwd=candidate, check=True)
            (candidate / "ignored").write_text("must not export")
            exported = root / "export"
            url, ref, original = harness.export_candidate(candidate, exported)
            self.assertEqual(url, exported.as_uri())
            self.assertEqual((exported / "source").read_text(), "committed")
            self.assertFalse((exported / "ignored").exists())
            self.assertEqual(len(ref), 40)
            self.assertEqual(len(original), 40)
            (candidate / "source").write_text("dirty")
            with self.assertRaisesRegex(RuntimeError, "clean committed"):
                harness.export_candidate(candidate, root / "rejected")
            self.assertFalse((root / "rejected").exists())

    def test_public_url_and_immutable_ref_validation(self):
        for value in ("main", "abc123", "a" * 39):
            with self.assertRaises(argparse.ArgumentTypeError):
                harness.sha(value)
        for value in ("file:///private/repo", "https://token@example.com/repo",
                      "git@example.com:repo", "../repo"):
            with self.assertRaises(argparse.ArgumentTypeError):
                harness.public_git_url(value)
        self.assertEqual(harness.sha("a" * 40), "a" * 40)

    def test_dependency_a_must_match_declared_pin(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            package = root / "packages/birb_code_editor"
            package.mkdir(parents=True)
            manifest = package / "pubspec.yaml"
            manifest.write_text("dependencies:\n  birb_design_system:\n    git:\n"
                                f"      url: {harness.DESIGN_URL}\n"
                                f"      ref: {'a' * 40}\n"
                                "      path: packages/birb_design_system\n")
            harness.inspect_manifest(root, "a" * 40)
            with self.assertRaisesRegex(RuntimeError, "differs"):
                harness.inspect_manifest(root, "b" * 40)
            with manifest.open("a") as output:
                output.write("dependency_overrides:\n  engine:\n    path: ../engine\n")
            with self.assertRaisesRegex(RuntimeError, "overrides"):
                harness.inspect_manifest(root, "a" * 40)


if __name__ == "__main__":
    unittest.main()
