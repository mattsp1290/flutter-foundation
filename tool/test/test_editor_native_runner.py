import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from tool import run_editor_native_suite as runner


class EditorNativeRunnerTest(unittest.TestCase):
    def test_utf8_flutter_output_can_be_replayed_with_windows_default_console(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            app = root / 'app'
            for name in ('integration_test/editor_native_test.dart',
                         'test_driver/integration_test.dart'):
                file = app / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.touch()
            (root / 'pin-map.json').write_text(json.dumps({'platform': 'windows'}))
            output = io.BytesIO()
            error_output = io.BytesIO()
            stdout = io.TextIOWrapper(output, encoding='cp1252')
            stderr = io.TextIOWrapper(error_output, encoding='cp1252')

            def flutter(command, *, cwd, stdout, stderr, timeout):
                # A child writes raw UTF-8, bypassing Python's text-file encoder.
                stdout.buffer.write('√ Built fixture\nEDITOR_NATIVE_SUITE_PASS\n'.encode('utf-8'))
                return subprocess.CompletedProcess(command, 0)

            with patch.object(sys, 'argv', ['runner', '--app', str(app), '--platform', 'windows']), \
                    patch.object(sys, 'stdout', stdout), patch.object(sys, 'stderr', stderr), \
                    patch.object(runner.shutil, 'which', return_value='flutter'), \
                    patch.object(runner.subprocess, 'run', side_effect=flutter):
                runner.main()
                stdout.flush()
            self.assertIn('√ Built fixture', output.getvalue().decode('utf-8'))
            self.assertEqual(json.loads((root / 'result.json').read_text())['result'], 'pass')
            stdout.close()
            stderr.close()


if __name__ == '__main__':
    unittest.main()
