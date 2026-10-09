import json
import threading
import urllib.error
import urllib.request
from http import HTTPStatus

import pytest

from maops_p5_app import SERVICE_NAME, __version__
from maops_p5_app.server import BUILD_ID_ENV, DEFAULT_BUILD_ID, make_server, route


def test_healthz_ok():
    assert route("GET", "/healthz") == (HTTPStatus.OK, {"status": "ok"})


def test_info_uses_default_build_id(monkeypatch):
    monkeypatch.delenv(BUILD_ID_ENV, raising=False)
    status, body = route("GET", "/info")
    assert status == HTTPStatus.OK
    assert body == {"service": SERVICE_NAME, "version": __version__, "build_id": DEFAULT_BUILD_ID}


def test_info_reads_build_id_from_env(monkeypatch):
    monkeypatch.setenv(BUILD_ID_ENV, "abc1234")
    assert route("GET", "/info")[1]["build_id"] == "abc1234"


def test_blank_build_id_falls_back_to_default(monkeypatch):
    monkeypatch.setenv(BUILD_ID_ENV, "   ")
    assert route("GET", "/info")[1]["build_id"] == DEFAULT_BUILD_ID


def test_unknown_path_is_404():
    assert route("GET", "/nope")[0] == HTTPStatus.NOT_FOUND


def test_non_get_is_405():
    assert route("POST", "/healthz")[0] == HTTPStatus.METHOD_NOT_ALLOWED


@pytest.fixture
def base_url():
    server = make_server("127.0.0.1", 0)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_address[1]}"
    server.shutdown()
    server.server_close()


def test_http_healthz_and_info(base_url):
    with urllib.request.urlopen(f"{base_url}/healthz") as resp:
        assert resp.status == 200
        assert resp.headers["Content-Type"] == "application/json"
        assert json.load(resp) == {"status": "ok"}
    with urllib.request.urlopen(f"{base_url}/info") as resp:
        assert json.load(resp)["service"] == SERVICE_NAME


def test_http_unknown_path_returns_404(base_url):
    with pytest.raises(urllib.error.HTTPError) as exc:
        urllib.request.urlopen(f"{base_url}/missing")
    assert exc.value.code == 404
