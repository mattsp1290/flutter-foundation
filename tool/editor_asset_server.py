"""Local asset server used as Chrome's proxy: every external origin is denied."""

import functools
import http.server
import threading
from urllib.parse import urlsplit


class AssetHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_CONNECT(self):
        self.server.blocked.append(self.path)
        self.send_error(403, "External origins are blocked by the editor fixture")

    def do_GET(self):
        url = urlsplit(self.path)
        if url.scheme:
            if url.scheme != "http" or url.hostname != "127.0.0.1" or url.port != self.server.server_port:
                self.server.blocked.append(f"{url.scheme}://{url.netloc}")
                self.send_error(403, "External origins are blocked by the editor fixture")
                return
            self.path = url.path + ("?" + url.query if url.query else "")
        self.server.requests.append(self.path)
        super().do_GET()


class EditorAssetServer:
    def __init__(self, directory):
        self.server = http.server.ThreadingHTTPServer(
            ("127.0.0.1", 0), functools.partial(AssetHandler, directory=str(directory)))
        self.server.blocked = []
        self.server.requests = []
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    @property
    def origin(self):
        return f"http://127.0.0.1:{self.server.server_port}"
