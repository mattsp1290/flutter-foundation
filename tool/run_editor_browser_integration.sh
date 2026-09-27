#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
chrome=${CHROME_EXECUTABLE:-}
if [ -z "$chrome" ]; then
  if [ -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]; then
    chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  else
    chrome=$(command -v chromium 2>/dev/null || command -v google-chrome)
  fi
fi
command -v chromedriver >/dev/null
evidence=${EDITOR_BROWSER_EVIDENCE:-$(mktemp -d "${TMPDIR:-/tmp}/birb-editor-browser-evidence.XXXXXX")}
cd "$root/examples/catalog"
for base in / /editor-check/; do
  flutter build web --no-web-resources-cdn --base-href "$base" \
    --dart-define=BIRB_EDITOR_ACCEPTANCE=true
  case "$base" in /) case_name=root;; *) case_name=nested;; esac
  python3 "$root/tool/editor_browser_driver.py" --web-root build/web \
    --base-path "$base" --chrome "$chrome" --evidence "$evidence/$case_name"
done
python3 "$root/tool/editor_browser_driver.py" --web-root build/web \
  --base-path /editor-check/ --chrome "$chrome" --performance \
  --evidence "$evidence/performance"
printf 'Editor browser evidence: %s\n' "$evidence"
