"""Stdlib-only HTTP server exposing /healthz and /info."""

import json
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from maops_p5_app import SERVICE_NAME, __version__

BUILD_ID_ENV = "APP_BUILD_ID"
DEFAULT_BUILD_ID = "local-dev"


def build_id() -> str:
    """Return the source/build identity, falling back to a safe local default."""
    return os.environ.get(BUILD_ID_ENV, "").strip() or DEFAULT_BUILD_ID


def route(method: str, path: str) -> tuple[HTTPStatus, dict]:
    """Resolve a request to a status and JSON payload, independent of the transport."""
    path = path.split("?", 1)[0]
    if method != "GET":
        return HTTPStatus.METHOD_NOT_ALLOWED, {"error": "method not allowed"}
    if path == "/healthz":
        return HTTPStatus.OK, {"status": "degraded"}
    if path == "/info":
        return HTTPStatus.OK, {
            "service": SERVICE_NAME,
            "version": __version__,
            "build_id": build_id(),
        }
    return HTTPStatus.NOT_FOUND, {"error": "not found"}


class Handler(BaseHTTPRequestHandler):
    server_version = f"{SERVICE_NAME}/{__version__}"
    sys_version = ""

    def _respond(self) -> None:
        status, payload = route(self.command, self.path)
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    do_GET = _respond
    do_POST = _respond
    do_PUT = _respond
    do_DELETE = _respond


def make_server(host: str, port: int) -> ThreadingHTTPServer:
    return ThreadingHTTPServer((host, port), Handler)


def main() -> None:
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8080"))
    server = make_server(host, port)
    print(f"{SERVICE_NAME} {__version__} ({build_id()}) listening on {host}:{port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
