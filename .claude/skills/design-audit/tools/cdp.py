"""Minimal Chrome DevTools Protocol client and headless browser launcher.

Standard library only. No Playwright, no Puppeteer, no PIL, matching the
convention in .github/render-modes.py and .github/season-probe.py.

Set $CHROME to a Chromium binary to override the search. On a Mac with no
Google Chrome, Microsoft Edge is the expected browser; see probe.py --help.
"""
import base64
import json
import os
import pathlib
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import time
import urllib.request


class WS:
    def __init__(self, url, timeout=60):
        if not url.startswith("ws://"):
            raise ValueError(url)
        hostport, path = url[5:].split("/", 1)
        host, port = hostport.split(":")
        self.sock = socket.create_connection((host, int(port)), timeout=timeout)
        key = base64.b64encode(os.urandom(16)).decode()
        request = (
            f"GET /{path} HTTP/1.1\r\nHost: {hostport}\r\nUpgrade: websocket\r\n"
            f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(request.encode())
        buf = b""
        while b"\r\n\r\n" not in buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ConnectionError("websocket handshake closed")
            buf += chunk
        head, self.buf = buf.split(b"\r\n\r\n", 1)
        if b"101" not in head.split(b"\r\n")[0]:
            raise RuntimeError(head[:300].decode("latin-1"))

    def _read(self, n):
        while len(self.buf) < n:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("socket closed")
            self.buf += chunk
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def send(self, text):
        payload = text.encode()
        header = bytearray([0x81])
        n = len(payload)
        if n < 126:
            header.append(0x80 | n)
        elif n < 65536:
            header.append(0x80 | 126)
            header += struct.pack(">H", n)
        else:
            header.append(0x80 | 127)
            header += struct.pack(">Q", n)
        mask = os.urandom(4)
        header += mask
        self.sock.sendall(bytes(header) + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))

    def recv(self):
        b1, b2 = self._read(2)
        opcode = b1 & 0x0F
        n = b2 & 0x7F
        if n == 126:
            n = struct.unpack(">H", self._read(2))[0]
        elif n == 127:
            n = struct.unpack(">Q", self._read(8))[0]
        data = self._read(n)
        if opcode == 0x8:
            raise ConnectionError("close frame")
        if opcode == 0x9:
            return self.recv()
        return data.decode("utf-8", "replace")


class CDP:
    def __init__(self, ws_url):
        self.ws = WS(ws_url)
        self.next_id = 0

    def call(self, method, **params):
        self.next_id += 1
        message_id = self.next_id
        self.ws.send(json.dumps({"id": message_id, "method": method, "params": params}))
        while True:
            message = json.loads(self.ws.recv())
            if message.get("id") == message_id:
                if "error" in message:
                    raise RuntimeError(f"{method}: {message['error']}")
                return message.get("result", {})

    def wait_event(self, name, timeout=120):
        deadline = time.time() + timeout
        while time.time() < deadline:
            message = json.loads(self.ws.recv())
            if message.get("method") == name:
                return message.get("params", {})
        raise TimeoutError(name)

    def evaluate(self, expression, await_promise=False):
        result = self.call(
            "Runtime.evaluate",
            expression=expression,
            returnByValue=True,
            awaitPromise=await_promise,
            userGesture=True,
        )
        if result.get("exceptionDetails"):
            raise RuntimeError(json.dumps(result["exceptionDetails"])[:1200])
        return result["result"].get("value")

    def json(self, expression, await_promise=False):
        return json.loads(self.evaluate(expression, await_promise=await_promise))

    def load(self, url, width=1280, height=900, media="screen", features=None,
             wait_fonts=True, settle=0.6, scroll_top=True):
        self.call("Emulation.setDeviceMetricsOverride", width=width, height=height,
                  deviceScaleFactor=1, mobile=False)
        params = {"media": media}
        if features is not None:
            params["features"] = features
        self.call("Emulation.setEmulatedMedia", **params)
        self.call("Page.navigate", url=url)
        self.wait_event("Page.loadEventFired")
        if wait_fonts:
            self.evaluate(
                "new Promise(r => { if (document.fonts) document.fonts.ready.then(r); else r(); })",
                await_promise=True,
            )
        time.sleep(settle)
        if scroll_top:
            self.evaluate("window.scrollTo(0, 0)")


def find_browser():
    if env := os.environ.get("CHROME"):
        return env
    for name in ("google-chrome", "google-chrome-stable", "chromium",
                 "chromium-browser", "microsoft-edge", "brave-browser"):
        if found := shutil.which(name):
            return found
    candidates = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    ]
    for path in candidates:
        if pathlib.Path(path).exists():
            return path
    sys.exit("No Chromium found. Set $CHROME to the binary (Edge works).")


class Browser:
    """Launches headless Chromium on a private profile and serves new pages."""

    def __init__(self, port=9222):
        self.port = port
        self.profile = tempfile.mkdtemp(prefix="da-probe-")
        self.binary = find_browser()
        self.process = subprocess.Popen(
            [self.binary, "--headless=new", "--disable-gpu", "--no-first-run",
             "--no-default-browser-check", f"--remote-debugging-port={port}",
             f"--user-data-dir={self.profile}", "about:blank"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        deadline = time.time() + 30
        while time.time() < deadline:
            try:
                urllib.request.urlopen(f"http://127.0.0.1:{port}/json/version", timeout=1)
                return
            except Exception:
                time.sleep(0.25)
        self.close()
        sys.exit("browser did not open a debugging port")

    def page(self):
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/json/new?about:blank", method="PUT"
        )
        target = json.load(urllib.request.urlopen(request))
        cdp = CDP(target["webSocketDebuggerUrl"])
        cdp.call("Page.enable")
        cdp.call("Runtime.enable")
        cdp.call("Network.enable")
        return cdp

    def close(self):
        self.process.terminate()
        try:
            self.process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.process.kill()
        shutil.rmtree(self.profile, ignore_errors=True)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()
