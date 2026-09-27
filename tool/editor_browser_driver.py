#!/usr/bin/env python3
"""Exercise visible release editor input through real ChromeDriver actions."""

import argparse
import json
from pathlib import Path
import platform
import shutil
import tempfile

from editor_asset_server import EditorAssetServer
from editor_webdriver import EditorWebDriver, wait_for


OBSERVATION = """
const text=[...document.querySelectorAll('flt-semantics')].map(el =>
  el.getAttribute('aria-label') || el.textContent).find(text => text.startsWith('Editor observation '));
return text ? JSON.parse(text.slice(19)) : null;
"""


def observation(driver):
    return driver.js(OBSERVATION)


def expect_source(driver, source):
    expected = list(source.encode("utf-16-le"))
    units = [expected[i] + 256 * expected[i + 1] for i in range(0, len(expected), 2)]
    return wait_for(lambda: (value := observation(driver)) and value["units"] == units and value)


def focus_source(driver):
    rect = driver.js("""
      const input=document.querySelector('[data-semantics-role="text-field"][aria-label="Go source code"]');
      if (input) { const r=input.getBoundingClientRect(); return [r.x,r.y-96,r.width,r.height]; }
      const el=document.querySelector('flt-semantics[aria-label="Go source code"]');
      if (!el) return null;
      const r=el.getBoundingClientRect(); return [r.x,r.y,r.width,r.height];
    """)
    if not rect:
        raise RuntimeError("Rendered source region is missing")
    driver.click(rect[0] + 110, rect[1] + 112)


def run_case(driver, server, base_path):
    origin = server.origin
    driver.request("POST", "/url", {"url": origin + base_path})
    wait_for(lambda: driver.js("return !!document.querySelector('flt-semantics-placeholder');"))
    # Fixed catalog navigation hit target at the enforced 1280px viewport.
    started = driver.js("return performance.now();")
    driver.click(48, 208)
    driver.frames()
    driver.screenshot("gutter-before-accessibility.png")
    driver.js("document.querySelector('flt-semantics-placeholder').click();")
    initial = wait_for(lambda: observation(driver))
    ready_ms = driver.js("return performance.now();") - started
    assert initial["length"] == 82, initial
    modifier = "\ue03d" if driver.capabilities["platformName"] == "mac" else "\ue009"
    focus_source(driver)
    driver.key("a", (modifier,))
    for character in "package browser":
        driver.key(character)
        driver.frames()
    edited = expect_source(driver, "package browser")
    driver.frames()
    driver.screenshot("keyboard-edit.png")
    driver.button("Reload recovered source")
    expect_source(driver, "package browser")
    driver.button("Read only")
    focus_source(driver)
    driver.key("z")
    expect_source(driver, "package browser")
    driver.button("Read only")
    driver.button("Empty source")
    expect_source(driver, "")
    driver.button("Reload recovered source")
    expect_source(driver, "")
    focus_source(driver)
    driver.key(" ", ("\ue009",))
    wait_for(lambda: driver.js("return !!document.querySelector('[aria-label=Completions]');"))
    driver.screenshot("completion-popup.png")
    driver.key("\ue007")
    expect_source(driver, "println")
    driver.button("Undo")
    expect_source(driver, "")
    driver.button("Redo")
    expect_source(driver, "println")
    # Prove the proxy rejects an external origin; no host Internet fetch occurs.
    blocked = driver.request("POST", "/execute/async", {
        "script": "const done=arguments[0]; fetch('https://editor-external.invalid/probe').then(()=>done(false),()=>done(true));",
        "args": [],
    })
    if not blocked or not any("editor-external.invalid" in value for value in server.server.blocked):
        raise RuntimeError("External-origin blocking was not observed")
    errors = [entry for entry in driver.request("POST", "/log", {"type": "browser"})
              if entry["level"] == "SEVERE" and "editor-external.invalid" not in entry["message"]]
    if errors:
        raise RuntimeError(f"Browser errors: {errors}")
    return {"editor_ready_ms_including_driver_and_semantics": ready_ms,
            "edited_generation": edited["generation"], "external_origin_probe": "blocked",
            "checks": ["visible-input", "same-source-recovery", "empty-recovery", "readonly",
                       "completion", "undo", "redo", "offline-assets"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--web-root", type=Path, required=True)
    parser.add_argument("--base-path", choices=("/", "/editor-check/"), required=True)
    parser.add_argument("--chrome", required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    args.evidence.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory(prefix="birb-editor-browser-") as temporary:
        site = Path(temporary) / "site"
        target = site if args.base_path == "/" else site / "editor-check"
        shutil.copytree(args.web_root, target)
        with EditorAssetServer(site) as server:
            for scale in (1, 2):
                output = args.evidence / f"dpr-{scale}"
                output.mkdir(exist_ok=True)
                with EditorWebDriver(args.chrome, server.origin, scale, output) as driver:
                    try:
                        record = run_case(driver, server, args.base_path)
                    except Exception:
                        (output / 'failure-browser.json').write_text(json.dumps(driver.request('POST', '/log', {'type': 'browser'}), indent=2) + '\n')
                        driver.screenshot('failure.png')
                        (output / 'failure-semantics.json').write_text(json.dumps(driver.js(
                            "return {labels:[...document.querySelectorAll('[aria-label]')].map(el=>el.getAttribute('aria-label')), active:document.activeElement.outerHTML, inputs:[...document.querySelectorAll('input,textarea')].map(el=>el.outerHTML), text:document.body.innerText};"
                        ), indent=2) + '\n')
                        raise
                    records.append({**record, "base_path": args.base_path, "device_pixel_ratio": scale,
                                    "browser": driver.capabilities["browserVersion"],
                                    "host": platform.platform(), "result": "pass"})
                    for stale in ('failure.png', 'failure-semantics.json', 'failure-browser.json'):
                        (output / stale).unlink(missing_ok=True)
            (args.evidence / "asset-requests.json").write_text(json.dumps(server.server.requests, indent=2) + "\n")
    (args.evidence / "results.json").write_text(json.dumps(records, indent=2) + "\n")
    print(json.dumps(records, indent=2))


if __name__ == "__main__":
    main()
