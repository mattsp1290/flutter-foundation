"""Small owned ChromeDriver session, using only Python's standard library."""

import base64
import json
from pathlib import Path
import socket
import subprocess
import time
import urllib.request


def wait_for(operation, timeout=15):
    deadline = time.monotonic() + timeout
    last_error = None
    while time.monotonic() < deadline:
        try:
            result = operation()
            if result:
                return result
        except (OSError, RuntimeError) as error:
            last_error = error
        time.sleep(.025)
    raise RuntimeError(f"Browser condition timed out: {last_error}")


class EditorWebDriver:
    def __init__(self, chrome, proxy, scale, output):
        self.chrome, self.proxy, self.scale, self.output = chrome, proxy, scale, output
        self.process = self.log = self.session = None

    def request(self, method, path, payload=None):
        data = None if payload is None else json.dumps(payload).encode()
        request = urllib.request.Request(self.url + path, data=data, method=method,
                                        headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=30) as response:
            value = json.load(response)["value"]
        if isinstance(value, dict) and "error" in value:
            raise RuntimeError(f"WebDriver {value['error']}: {value.get('message')}")
        return value

    def __enter__(self):
        with socket.socket() as available:
            available.bind(("127.0.0.1", 0))
            port = available.getsockname()[1]
        self.url = f"http://127.0.0.1:{port}"
        self.log = (self.output / "chromedriver.log").open("w")
        self.process = subprocess.Popen(["chromedriver", f"--port={port}"],
                                        stdout=self.log, stderr=subprocess.STDOUT)
        try:
            wait_for(lambda: self.request("GET", "/status"))
            result = self.request("POST", "/session", {"capabilities": {"alwaysMatch": {
                "browserName": "chrome", "goog:loggingPrefs": {"browser": "ALL"},
                "goog:chromeOptions": {"binary": self.chrome, "args": [
                    "--headless=new", "--no-sandbox", "--window-size=1280,1000",
                    "--disable-background-networking", "--disable-quic",
                    "--disable-component-update", f"--force-device-scale-factor={self.scale}",
                    f"--proxy-server={self.proxy}", "--proxy-bypass-list=<-loopback>",
                ]},
            }}})
            self.session = result["sessionId"]
            self.capabilities = result["capabilities"]
            self.url += "/session/" + self.session
            return self
        except BaseException:
            self.__exit__()
            raise

    def __exit__(self, *_):
        try:
            if self.session:
                self.request("DELETE", "")
        finally:
            if self.process:
                self.process.terminate()
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait()
            if self.log:
                self.log.close()

    def js(self, script, *arguments):
        return self.request("POST", "/execute/sync", {"script": script, "args": arguments})

    def frames(self):
        return self.request("POST", "/execute/async", {
            "script": "const done=arguments[0]; requestAnimationFrame(()=>requestAnimationFrame(()=>done(performance.now())));",
            "args": [],
        })

    def click(self, x, y):
        self.request("POST", "/actions", {"actions": [{"type": "pointer", "id": "mouse",
            "parameters": {"pointerType": "mouse"}, "actions": [
                {"type": "pointerMove", "duration": 0, "x": round(x), "y": round(y), "origin": "viewport"},
                {"type": "pointerDown", "button": 0}, {"type": "pointerUp", "button": 0},
            ]}]})

    def key(self, key, modifiers=()):
        actions = [{"type": "keyDown", "value": m} for m in modifiers]
        actions += [{"type": "keyDown", "value": key}, {"type": "keyUp", "value": key}]
        actions += [{"type": "keyUp", "value": m} for m in reversed(modifiers)]
        self.request("POST", "/actions", {"actions": [{"type": "key", "id": "keyboard", "actions": actions}]})

    def button(self, text):
        point = self.js("""
          const el=[...document.querySelectorAll('flt-semantics')].find(el =>
            ['button','checkbox'].includes(el.getAttribute('role')) &&
            (el.textContent===arguments[0] || el.getAttribute('aria-label')===arguments[0]));
          if (!el) return null;
          const r=el.getBoundingClientRect(); return [r.x+r.width/2,r.y+r.height/2];
        """, text)
        if not point:
            raise RuntimeError(f"Missing visible control: {text}")
        self.click(*point)
        self.frames()

    def screenshot(self, name):
        (self.output / name).write_bytes(base64.b64decode(self.request("GET", "/screenshot")))
