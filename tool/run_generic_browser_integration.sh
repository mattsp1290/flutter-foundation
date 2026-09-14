#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
flutter_bin=${FLUTTER_BIN:-flutter}
flutter_root=$($flutter_bin --version --machine | sed -n \
  's/^[[:space:]]*"flutterRoot":[[:space:]]*"\([^"]*\)",*$/\1/p')
[ -n "$flutter_root" ] || { echo 'unable to locate Flutter SDK root' >&2; exit 1; }
dart_bin="$flutter_root/bin/cache/dart-sdk/bin/dart"
[ -x "$dart_bin" ] || { echo 'Flutter bundled Dart is unavailable' >&2; exit 1; }
command -v chromedriver >/dev/null
chromium_bin=$(command -v chromium 2>/dev/null || command -v google-chrome)
command -v timeout >/dev/null

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/generic-ag-ui.XXXXXX")
ready_file="$temp_dir/server-address"
server_pid=''
driver_pid=''
cleanup() {
  for pid in "$driver_pid" "$server_pid"; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  mv "$temp_dir" "${TMPDIR:-/tmp}/generic-ag-ui-last-run" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

"$dart_bin" "$root/tool/generic_fixture_server.dart" --ready-file "$ready_file" &
server_pid=$!
attempt=0
while [ ! -s "$ready_file" ]; do
  attempt=$((attempt + 1))
  [ "$attempt" -lt 100 ] || { echo 'fixture server did not become ready' >&2; exit 1; }
  kill -0 "$server_pid" 2>/dev/null || { echo 'fixture server exited early' >&2; exit 1; }
  sleep 0.1
done
address=$(cat "$ready_file")

chromedriver --port=4444 >"$temp_dir/chromedriver.log" 2>&1 &
driver_pid=$!
sleep 1
kill -0 "$driver_pid" 2>/dev/null || { cat "$temp_dir/chromedriver.log" >&2; exit 1; }

cd "$root/examples/generic_ag_ui"
if ! timeout 600 "$flutter_bin" drive -d chrome --headless \
  --chrome-binary="$chromium_bin" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/session_flow_test.dart \
  --dart-define="AG_UI_ENDPOINT=http://$address/generic/run"; then
  cat "$temp_dir/chromedriver.log" >&2
  exit 1
fi
