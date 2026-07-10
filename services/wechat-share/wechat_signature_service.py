#!/usr/bin/env python3
import hashlib
import json
import os
import time
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


APP_ID = os.environ.get("WECHAT_APP_ID", "").strip()
APP_SECRET = os.environ.get("WECHAT_APP_SECRET", "").strip()
ALLOWED_HOSTS = {
    host.strip().lower()
    for host in os.environ.get("WECHAT_ALLOWED_HOSTS", "www.mindevo.club,mindevo.club").split(",")
    if host.strip()
}
PORT = int(os.environ.get("WECHAT_SHARE_PORT", "8710"))

_access_token = {"value": "", "expires_at": 0}
_jsapi_ticket = {"value": "", "expires_at": 0}


def _json_response(handler, status, payload):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def _fetch_json(url):
    with urllib.request.urlopen(url, timeout=8) as response:
        return json.loads(response.read().decode("utf-8"))


def _get_access_token():
    now = int(time.time())
    if _access_token["value"] and _access_token["expires_at"] - 120 > now:
        return _access_token["value"]

    query = urllib.parse.urlencode(
        {
            "grant_type": "client_credential",
            "appid": APP_ID,
            "secret": APP_SECRET,
        }
    )
    data = _fetch_json(f"https://api.weixin.qq.com/cgi-bin/token?{query}")
    if "access_token" not in data:
        raise RuntimeError(f"WeChat access_token error: {data}")

    _access_token["value"] = data["access_token"]
    _access_token["expires_at"] = now + int(data.get("expires_in", 7200))
    return _access_token["value"]


def _get_jsapi_ticket():
    now = int(time.time())
    if _jsapi_ticket["value"] and _jsapi_ticket["expires_at"] - 120 > now:
        return _jsapi_ticket["value"]

    token = _get_access_token()
    query = urllib.parse.urlencode({"access_token": token, "type": "jsapi"})
    data = _fetch_json(f"https://api.weixin.qq.com/cgi-bin/ticket/getticket?{query}")
    if data.get("errcode") != 0 or "ticket" not in data:
        raise RuntimeError(f"WeChat jsapi_ticket error: {data}")

    _jsapi_ticket["value"] = data["ticket"]
    _jsapi_ticket["expires_at"] = now + int(data.get("expires_in", 7200))
    return _jsapi_ticket["value"]


def _normalize_share_url(raw_url):
    parsed = urllib.parse.urlparse(raw_url)
    if parsed.scheme != "https":
        raise ValueError("url must use https")
    if parsed.hostname is None or parsed.hostname.lower() not in ALLOWED_HOSTS:
        raise ValueError("url host is not allowed")

    # WeChat signs the current page URL without the fragment.
    return urllib.parse.urlunparse(
        (parsed.scheme, parsed.netloc, parsed.path or "/", parsed.params, parsed.query, "")
    )


def _make_signature(share_url):
    ticket = _get_jsapi_ticket()
    timestamp = str(int(time.time()))
    nonce = hashlib.sha1(f"{timestamp}:{share_url}:{os.urandom(8).hex()}".encode("utf-8")).hexdigest()[:16]
    sign_source = (
        f"jsapi_ticket={ticket}&noncestr={nonce}&timestamp={timestamp}&url={share_url}"
    )
    signature = hashlib.sha1(sign_source.encode("utf-8")).hexdigest()
    return {
        "appId": APP_ID,
        "timestamp": timestamp,
        "nonceStr": nonce,
        "signature": signature,
        "url": share_url,
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/health":
            return _json_response(
                self,
                200,
                {
                    "ok": True,
                    "configured": bool(APP_ID and APP_SECRET),
                    "allowedHosts": sorted(ALLOWED_HOSTS),
                },
            )

        if parsed.path != "/sign":
            return _json_response(self, 404, {"ok": False, "error": "not_found"})

        if not APP_ID or not APP_SECRET:
            return _json_response(self, 503, {"ok": False, "error": "wechat_not_configured"})

        params = urllib.parse.parse_qs(parsed.query)
        raw_url = params.get("url", [""])[0].strip()
        if not raw_url:
            return _json_response(self, 400, {"ok": False, "error": "missing_url"})

        try:
            share_url = _normalize_share_url(raw_url)
            return _json_response(self, 200, {"ok": True, **_make_signature(share_url)})
        except ValueError as exc:
            return _json_response(self, 400, {"ok": False, "error": str(exc)})
        except Exception:
            # Do not leak app secrets or upstream token details to browsers.
            return _json_response(self, 502, {"ok": False, "error": "wechat_upstream_error"})

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}", flush=True)


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"mindevo wechat share service listening on 127.0.0.1:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
