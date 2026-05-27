#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import subprocess
import threading
import time
from dataclasses import dataclass, asdict
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse


ROOT = Path(__file__).resolve().parents[2]
WEB_DIR = ROOT / "bench" / "web"
RESULTS_PATH = ROOT / "bench" / "results" / "summary.json"
TARGET_DIR = "/private/tmp/la-benchmark-web"


@dataclass
class RunState:
    running: bool = False
    started_at: str = ""
    finished_at: str = ""
    last_exit_code: int | None = None
    last_stdout: str = ""
    last_stderr: str = ""
    last_command: list[str] | None = None


STATE = RunState()
LAST_RESULTS_PAYLOAD: dict | None = None
LOCK = threading.Lock()


def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def run_benchmarks(include_rust: bool, smoke: bool) -> None:
    process = subprocess.run(
        ["just", "bench-smoke" if smoke else "bench"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        env={
            **os.environ,
            "BENCH_FLAGS": " ".join(
                part
                for part in [
                    f"--target-dir {TARGET_DIR}",
                    "--include-rust" if include_rust else "",
                ]
                if part
            ),
        },
    )
    with LOCK:
        STATE.running = False
        STATE.finished_at = now_iso()
        STATE.last_exit_code = process.returncode
        STATE.last_stdout = process.stdout[-12000:]
        STATE.last_stderr = process.stderr[-12000:]


def start_run(include_rust: bool, smoke: bool) -> bool:
    with LOCK:
        if STATE.running:
            return False
        STATE.running = True
        STATE.started_at = now_iso()
        STATE.finished_at = ""
        STATE.last_exit_code = None
        STATE.last_stdout = ""
        STATE.last_stderr = ""
        STATE.last_command = [
            "just",
            "bench-smoke" if smoke else "bench",
        ]
    thread = threading.Thread(target=run_benchmarks, args=(include_rust, smoke), daemon=True)
    thread.start()
    return True


class BenchmarkHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/status":
            self.respond_json(asdict(STATE))
            return
        if parsed.path == "/api/results":
            if RESULTS_PATH.exists():
                try:
                    payload = json.loads(RESULTS_PATH.read_text(encoding="utf-8"))
                except (json.JSONDecodeError, OSError):
                    global LAST_RESULTS_PAYLOAD
                    if LAST_RESULTS_PAYLOAD is not None:
                        self.respond_json(LAST_RESULTS_PAYLOAD)
                    else:
                        self.respond_json(
                            {"mode": "steady_state", "rows": [], "status": "warming"},
                            status=HTTPStatus.SERVICE_UNAVAILABLE,
                        )
                    return
                LAST_RESULTS_PAYLOAD = payload
                self.respond_json(payload)
            else:
                self.respond_json(
                    {"mode": "steady_state", "rows": [], "status": "empty"},
                    status=HTTPStatus.NOT_FOUND,
                )
            return
        super().do_GET()

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path != "/api/run":
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8") if length else ""
        params = parse_qs(body)
        include_rust = params.get("include_rust", ["true"])[0] != "false"
        smoke = params.get("smoke", ["false"])[0] == "true"
        accepted = start_run(include_rust, smoke)
        status = HTTPStatus.ACCEPTED if accepted else HTTPStatus.CONFLICT
        self.respond_json(
            {
                "accepted": accepted,
                "running": STATE.running,
                "include_rust": include_rust,
                "smoke": smoke,
            },
            status=status,
        )

    def respond_json(self, payload: dict, status: HTTPStatus = HTTPStatus.OK) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    port = int(os.environ.get("BENCH_WEB_PORT", "8123"))
    server = ThreadingHTTPServer(("127.0.0.1", port), BenchmarkHandler)
    print(f"benchmark web on http://127.0.0.1:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
