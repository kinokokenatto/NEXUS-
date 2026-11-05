# cython: language_level=3, embedsignature=True
"""NEXUS SUPER4.1 Cython core.

The browser-facing UI is retained as a static asset in web/index.html because
Cython cannot directly implement browser DOM/CSS/Canvas/WebAudio APIs. This
module provides a compiled local service and native implementations for
persistent state, encrypted backups, URL inspection, safe calculations and
Open-Meteo weather retrieval.
"""

import ast
import base64
import datetime as _dt
import ipaddress
import json
import math
import os
import pathlib
import secrets
import sqlite3
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

APP_NAME = "NEXUS SUPER4.1"
APP_VERSION = "4.1"
MAX_REQUEST_BYTES = 2 * 1024 * 1024
MAX_VALUE_BYTES = 7_500_000
PBKDF2_ITERATIONS = 310_000

_ROOT = pathlib.Path(__file__).resolve().parent
_WEB_ROOT = _ROOT / "web"
_DATA_ROOT = _ROOT / "data"
_DEFAULT_DB = _DATA_ROOT / "nexus.sqlite3"

# Representative forecast locations. Values are latitude, longitude and a
# Japanese label; weather is informational and is not an official warning.
PREFECTURES = {
    "hokkaido": (43.0642, 141.3469, "北海道・札幌"),
    "aomori": (40.8244, 140.7400, "青森県・青森"),
    "iwate": (39.7036, 141.1527, "岩手県・盛岡"),
    "miyagi": (38.2688, 140.8721, "宮城県・仙台"),
    "akita": (39.7186, 140.1024, "秋田県・秋田"),
    "yamagata": (38.2404, 140.3633, "山形県・山形"),
    "fukushima": (37.7503, 140.4676, "福島県・福島"),
    "ibaraki": (36.3418, 140.4468, "茨城県・水戸"),
    "tochigi": (36.5657, 139.8836, "栃木県・宇都宮"),
    "gunma": (36.3911, 139.0608, "群馬県・前橋"),
    "saitama": (35.8569, 139.6489, "埼玉県・さいたま"),
    "chiba": (35.6047, 140.1233, "千葉県・千葉"),
    "tokyo": (35.6895, 139.6917, "東京都・東京"),
    "kanagawa": (35.4478, 139.6425, "神奈川県・横浜"),
    "niigata": (37.9026, 139.0236, "新潟県・新潟"),
    "toyama": (36.6953, 137.2113, "富山県・富山"),
    "ishikawa": (36.5947, 136.6256, "石川県・金沢"),
    "fukui": (36.0652, 136.2216, "福井県・福井"),
    "yamanashi": (35.6642, 138.5684, "山梨県・甲府"),
    "nagano": (36.6513, 138.1810, "長野県・長野"),
    "gifu": (35.3912, 136.7223, "岐阜県・岐阜"),
    "shizuoka": (34.9769, 138.3831, "静岡県・静岡"),
    "aichi": (35.1802, 136.9066, "愛知県・名古屋"),
    "mie": (34.7303, 136.5086, "三重県・津"),
    "shiga": (35.0045, 135.8686, "滋賀県・大津"),
    "kyoto": (35.0210, 135.7556, "京都府・京都"),
    "osaka": (34.6863, 135.5200, "大阪府・大阪"),
    "hyogo": (34.6913, 135.1830, "兵庫県・神戸"),
    "nara": (34.6851, 135.8049, "奈良県・奈良"),
    "wakayama": (34.2260, 135.1675, "和歌山県・和歌山"),
    "tottori": (35.5039, 134.2377, "鳥取県・鳥取"),
    "shimane": (35.4723, 133.0505, "島根県・松江"),
    "okayama": (34.6618, 133.9344, "岡山県・岡山"),
    "hiroshima": (34.3963, 132.4596, "広島県・広島"),
    "yamaguchi": (34.1861, 131.4705, "山口県・山口"),
    "tokushima": (34.0658, 134.5593, "徳島県・徳島"),
    "kagawa": (34.3401, 134.0434, "香川県・高松"),
    "ehime": (33.8416, 132.7657, "愛媛県・松山"),
    "kochi": (33.5597, 133.5311, "高知県・高知"),
    "fukuoka": (33.5902, 130.4017, "福岡県・福岡"),
    "saga": (33.2494, 130.2988, "佐賀県・佐賀"),
    "nagasaki": (32.7448, 129.8737, "長崎県・長崎"),
    "kumamoto": (32.7898, 130.7417, "熊本県・熊本"),
    "oita": (33.2382, 131.6126, "大分県・大分"),
    "miyazaki": (31.9111, 131.4239, "宮崎県・宮崎"),
    "kagoshima": (31.5602, 130.5581, "鹿児島県・鹿児島"),
    "okinawa": (26.2124, 127.6809, "沖縄県・那覇"),
}


class NexusStore:
    """SQLite-backed namespaced key/value storage for the Cython service."""

    def __init__(self, path=None):
        self.path = pathlib.Path(path) if path else _DEFAULT_DB
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._db = sqlite3.connect(str(self.path), check_same_thread=False)
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.execute("PRAGMA synchronous=FULL")
        self._db.execute("""CREATE TABLE IF NOT EXISTS kv (
            namespace TEXT NOT NULL,
            item_key TEXT NOT NULL,
            value_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY(namespace, item_key)
        )""")
        self._db.commit()

    def get(self, namespace, key, default=None):
        namespace, key = _clean_key(namespace), _clean_key(key)
        with self._lock:
            row = self._db.execute(
                "SELECT value_json FROM kv WHERE namespace=? AND item_key=?",
                (namespace, key),
            ).fetchone()
        if row is None:
            return default
        try:
            return json.loads(row[0])
        except (TypeError, ValueError):
            return default

    def put(self, namespace, key, value):
        namespace, key = _clean_key(namespace), _clean_key(key)
        encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        if len(encoded.encode("utf-8")) > MAX_VALUE_BYTES:
            raise ValueError("保存データが上限（約7.5 MB）を超えています")
        stamp = _dt.datetime.now(_dt.timezone.utc).isoformat()
        with self._lock:
            self._db.execute(
                "INSERT INTO kv(namespace,item_key,value_json,updated_at) VALUES(?,?,?,?) "
                "ON CONFLICT(namespace,item_key) DO UPDATE SET "
                "value_json=excluded.value_json, updated_at=excluded.updated_at",
                (namespace, key, encoded, stamp),
            )
            self._db.commit()
        return {"namespace": namespace, "key": key, "updated_at": stamp}

    def delete(self, namespace, key):
        namespace, key = _clean_key(namespace), _clean_key(key)
        with self._lock:
            cur = self._db.execute(
                "DELETE FROM kv WHERE namespace=? AND item_key=?", (namespace, key)
            )
            self._db.commit()
            return cur.rowcount > 0

    def keys(self, namespace=None):
        with self._lock:
            if namespace is None:
                rows = self._db.execute(
                    "SELECT namespace,item_key, length(value_json),updated_at FROM kv "
                    "ORDER BY namespace,item_key"
                ).fetchall()
            else:
                ns = _clean_key(namespace)
                rows = self._db.execute(
                    "SELECT namespace,item_key,length(value_json),updated_at FROM kv "
                    "WHERE namespace=? ORDER BY item_key", (ns,)
                ).fetchall()
        return [
            {"namespace": r[0], "key": r[1], "json_chars": r[2], "updated_at": r[3]}
            for r in rows
        ]

    def snapshot(self):
        with self._lock:
            rows = self._db.execute(
                "SELECT namespace,item_key,value_json FROM kv ORDER BY namespace,item_key"
            ).fetchall()
        data = {}
        for namespace, key, raw in rows:
            data.setdefault(namespace, {})[key] = json.loads(raw)
        return {
            "format": "NEXUS_CYTHON_SNAPSHOT",
            "version": 1,
            "application": APP_NAME,
            "exported_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
            "data": data,
        }

    def restore(self, payload):
        if not isinstance(payload, dict) or payload.get("format") != "NEXUS_CYTHON_SNAPSHOT":
            raise ValueError("未対応のスナップショット形式です")
        if payload.get("version") != 1 or not isinstance(payload.get("data"), dict):
            raise ValueError("スナップショットのバージョンまたはデータ形式が不正です")
        rows = []
        for ns, entries in payload["data"].items():
            ns = _clean_key(ns)
            if not isinstance(entries, dict):
                raise ValueError("保存領域のデータ形式が不正です")
            for key, value in entries.items():
                key = _clean_key(key)
                encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
                if len(encoded.encode("utf-8")) > MAX_VALUE_BYTES:
                    raise ValueError("復元データがサイズ上限を超えています")
                rows.append((ns, key, encoded, _dt.datetime.now(_dt.timezone.utc).isoformat()))
        with self._lock:
            cur = self._db.cursor()
            cur.execute("BEGIN IMMEDIATE")
            try:
                cur.execute("DELETE FROM kv")
                cur.executemany(
                    "INSERT INTO kv(namespace,item_key,value_json,updated_at) VALUES(?,?,?,?)",
                    rows,
                )
                self._db.commit()
            except Exception:
                self._db.rollback()
                raise
        return {"restored_keys": len(rows)}

    def metrics(self):
        rows = self.keys()
        try:
            size = self.path.stat().st_size
        except OSError:
            size = 0
        return {"key_count": len(rows), "database_bytes": size, "path": str(self.path)}

    def close(self):
        with self._lock:
            self._db.close()


def _clean_key(value):
    value = str(value).strip()
    if not value or len(value) > 160 or any(ord(c) < 32 for c in value):
        raise ValueError("キー名は1〜160文字で指定してください")
    return value


def _json_bytes(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def encrypt_backup(payload, passphrase):
    """Encrypt a JSON backup using PBKDF2-HMAC-SHA256 and AES-256-GCM."""
    if not isinstance(passphrase, str) or len(passphrase) < 10:
        raise ValueError("暗号化パスフレーズは10文字以上にしてください")
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    except ImportError as exc:
        raise RuntimeError("暗号化には cryptography パッケージが必要です") from exc
    salt, nonce = secrets.token_bytes(16), secrets.token_bytes(12)
    key = __import__("hashlib").pbkdf2_hmac(
        "sha256", passphrase.encode("utf-8"), salt, PBKDF2_ITERATIONS, dklen=32
    )
    ciphertext = AESGCM(key).encrypt(nonce, _json_bytes(payload), b"NEXUS_CYTHON_BACKUP_V1")
    return {
        "format": "NEXUS_CYTHON_ENCRYPTED_BACKUP",
        "version": 1,
        "cipher": "AES-256-GCM",
        "kdf": "PBKDF2-SHA-256",
        "iterations": PBKDF2_ITERATIONS,
        "salt": base64.b64encode(salt).decode("ascii"),
        "nonce": base64.b64encode(nonce).decode("ascii"),
        "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
    }


def decrypt_backup(envelope, passphrase):
    """Authenticate and decrypt an NEXUS Cython backup."""
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    if not isinstance(envelope, dict):
        raise ValueError("暗号化バックアップの形式が不正です")
    expected = ("NEXUS_CYTHON_ENCRYPTED_BACKUP", 1, "AES-256-GCM", "PBKDF2-SHA-256", PBKDF2_ITERATIONS)
    actual = (envelope.get("format"), envelope.get("version"), envelope.get("cipher"), envelope.get("kdf"), envelope.get("iterations"))
    if actual != expected:
        raise ValueError("未対応の暗号化形式です")
    try:
        salt = base64.b64decode(envelope["salt"], validate=True)
        nonce = base64.b64decode(envelope["nonce"], validate=True)
        ciphertext = base64.b64decode(envelope["ciphertext"], validate=True)
    except Exception as exc:
        raise ValueError("バックアップのバイナリ形式が不正です") from exc
    if len(salt) != 16 or len(nonce) != 12 or len(ciphertext) > 40 * 1024 * 1024:
        raise ValueError("バックアップのサイズまたは形式が不正です")
    key = __import__("hashlib").pbkdf2_hmac(
        "sha256", str(passphrase).encode("utf-8"), salt, PBKDF2_ITERATIONS, dklen=32
    )
    try:
        plain = AESGCM(key).decrypt(nonce, ciphertext, b"NEXUS_CYTHON_BACKUP_V1")
        return json.loads(plain.decode("utf-8"))
    except Exception as exc:
        raise ValueError("復号できません。パスフレーズまたはデータが正しくありません") from exc


_SHORTENERS = {
    "bit.ly", "t.co", "tinyurl.com", "goo.gl", "ow.ly", "is.gd",
    "buff.ly", "cutt.ly", "rebrand.ly", "t.ly", "lnkd.in", "shorturl.at",
}


def inspect_url(value):
    """Perform local syntactic/risk checks; this does not visit the URL."""
    if not isinstance(value, str) or not value.strip() or len(value) > 8192:
        raise ValueError("URLを1〜8192文字で指定してください")
    raw = value.strip()
    if any(ord(c) < 32 for c in raw):
        raise ValueError("URLに制御文字が含まれています")
    candidate = raw if "://" in raw else "https://" + raw
    parsed = urllib.parse.urlsplit(candidate)
    scheme = parsed.scheme.lower()
    if scheme not in ("http", "https"):
        return {"url": raw, "risk": "high", "safe_to_open": False, "findings": ["HTTP/HTTPS以外のスキームです"]}
    if not parsed.hostname:
        raise ValueError("ホスト名を解析できません")
    host = parsed.hostname.rstrip(".").lower()
    findings = []
    risk = "low"
    def flag(level, message):
        nonlocal risk
        findings.append(message)
        if ("low", "medium", "high").index(level) > ("low", "medium", "high").index(risk):
            risk = level
    if parsed.username is not None or parsed.password is not None:
        flag("high", "URLにユーザー名またはパスワードが含まれています")
    try:
        ascii_host = host.encode("idna").decode("ascii")
    except UnicodeError:
        ascii_host = host
        flag("high", "ドメイン名を正しくIDNA変換できません")
    if any(label.startswith("xn--") for label in ascii_host.split(".")):
        flag("medium", "国際化ドメイン（Punycode）です。表示名を慎重に確認してください")
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
        flag("medium", "IPアドレスを直接指定しています")
        if not ip.is_global:
            flag("high", "プライベート・予約済み・ローカルIPアドレスです")
    except ValueError:
        pass
    if host in _SHORTENERS:
        flag("medium", "短縮URLです。リンク先をこの検査では確認できません")
    if scheme == "http":
        flag("medium", "HTTPSではなく暗号化されないHTTPです")
    if len(host) > 180 or len(host.split(".")) < 2:
        flag("medium", "ホスト名の形式を確認してください")
    if not findings:
        findings.append("構文上の重大な問題は見つかりませんでした。安全性を保証するものではありません")
    return {
        "url": candidate,
        "scheme": scheme,
        "host": host,
        "ascii_host": ascii_host,
        "port": parsed.port,
        "path": parsed.path or "/",
        "risk": risk,
        "safe_to_open": risk == "low",
        "findings": findings,
        "checked_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "note": "ローカル構文検査のみです。サイトの内容・証明書・リダイレクト先は確認していません。",
    }


_ALLOWED_BINOPS = {
    ast.Add: lambda a, b: a + b,
    ast.Sub: lambda a, b: a - b,
    ast.Mult: lambda a, b: a * b,
    ast.Div: lambda a, b: a / b,
    ast.FloorDiv: lambda a, b: a // b,
    ast.Mod: lambda a, b: a % b,
    ast.Pow: lambda a, b: a ** b,
}
_ALLOWED_UNARY = {ast.UAdd: lambda a: +a, ast.USub: lambda a: -a}
_ALLOWED_FUNCS = {
    "abs": abs, "round": round, "sqrt": math.sqrt,
    "sin": math.sin, "cos": math.cos, "tan": math.tan,
    "log": math.log, "log10": math.log10,
    "floor": math.floor, "ceil": math.ceil,
}


def calculate(expression):
    """Evaluate a small arithmetic expression without eval/exec."""
    if not isinstance(expression, str) or not expression.strip() or len(expression) > 500:
        raise ValueError("計算式を1〜500文字で指定してください")
    try:
        root = ast.parse(expression, mode="eval").body
    except SyntaxError as exc:
        raise ValueError("計算式の構文が正しくありません") from exc

    def visit(node, depth=0):
        if depth > 40:
            raise ValueError("式が複雑すぎます")
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)) and not isinstance(node.value, bool):
            value = node.value
        elif isinstance(node, ast.BinOp) and type(node.op) in _ALLOWED_BINOPS:
            left, right = visit(node.left, depth + 1), visit(node.right, depth + 1)
            if isinstance(node.op, ast.Pow) and abs(right) > 1000:
                raise ValueError("累乗の指数が大きすぎます")
            value = _ALLOWED_BINOPS[type(node.op)](left, right)
        elif isinstance(node, ast.UnaryOp) and type(node.op) in _ALLOWED_UNARY:
            value = _ALLOWED_UNARY[type(node.op)](visit(node.operand, depth + 1))
        elif isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id in _ALLOWED_FUNCS and not node.keywords:
            args = [visit(a, depth + 1) for a in node.args]
            value = _ALLOWED_FUNCS[node.func.id](*args)
        else:
            raise ValueError("使用できない演算子または構文が含まれています")
        if isinstance(value, complex) or not math.isfinite(float(value)):
            raise ValueError("計算結果が有限の実数ではありません")
        if abs(value) > 1e100:
            raise ValueError("計算結果が大きすぎます")
        return value

    try:
        result = visit(root)
    except ZeroDivisionError as exc:
        raise ValueError("0で割ることはできません") from exc
    return {"expression": expression, "result": result}


def get_weather(prefecture="hyogo"):
    key = str(prefecture).lower().strip()
    if key not in PREFECTURES:
        raise ValueError("都道府県コードが正しくありません")
    lat, lon, label = PREFECTURES[key]
    params = urllib.parse.urlencode({
        "latitude": lat, "longitude": lon,
        "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m",
        "hourly": "precipitation,temperature_2m",
        "past_hours": 24, "forecast_hours": 24,
        "timezone": "Asia/Tokyo",
    })
    request = urllib.request.Request(
        "https://api.open-meteo.com/v1/forecast?" + params,
        headers={"User-Agent": "NEXUS-SUPER4.1-Cython/4.1", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            raw = response.read(1_500_001)
            if len(raw) > 1_500_000:
                raise ValueError("天気APIの応答が大きすぎます")
            data = json.loads(raw.decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise RuntimeError("天気情報を取得できませんでした: " + str(exc)) from exc
    return {"prefecture": key, "location": label, "latitude": lat, "longitude": lon, "source": "Open-Meteo", "data": data}


def _response_bytes(value):
    return _json_bytes(value)


class _Handler(BaseHTTPRequestHandler):
    server_version = "NEXUS-Cython/4.1"
    sys_version = ""

    def log_message(self, fmt, *args):
        print("[NEXUS] " + (fmt % args))

    def _send(self, status, payload, content_type="application/json; charset=utf-8"):
        body = payload if isinstance(payload, bytes) else _response_bytes(payload)
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            raise ValueError("Content-Lengthが不正です")
        if size < 0 or size > MAX_REQUEST_BYTES:
            raise ValueError("リクエストの上限は2 MiBです")
        raw = self.rfile.read(size) if size else b"{}"
        try:
            value = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError) as exc:
            raise ValueError("JSON形式が正しくありません") from exc
        if not isinstance(value, dict):
            raise ValueError("JSONオブジェクトを送信してください")
        return value

    def _error(self, status, message):
        self._send(status, {"ok": False, "error": str(message)})

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        path = parsed.path
        if path in ("/", "/index.html"):
            target = _WEB_ROOT / "index.html"
            try:
                body = target.read_bytes()
            except OSError:
                return self._error(404, "web/index.htmlが見つかりません")
            return self._send(200, body, "text/html; charset=utf-8")
        if path == "/api/health":
            return self._send(200, {"ok": True, "application": APP_NAME, "version": APP_VERSION, "engine": "Cython", "metrics": self.server.store.metrics()})
        if path == "/api/state":
            return self._send(200, {"ok": True, "items": self.server.store.keys()})
        if path.startswith("/api/state/"):
            parts = [urllib.parse.unquote(x) for x in path[len("/api/state/"):].split("/") if x]
            if len(parts) == 1:
                return self._send(200, {"ok": True, "items": self.server.store.keys(parts[0])})
            if len(parts) == 2:
                value = self.server.store.get(parts[0], parts[1], None)
                return self._send(200, {"ok": True, "found": value is not None, "value": value})
            return self._error(400, "URLは/api/state/{namespace}/{key}です")
        if path == "/api/snapshot":
            return self._send(200, self.server.store.snapshot())
        if path == "/api/weather":
            query = urllib.parse.parse_qs(parsed.query)
            prefecture = (query.get("prefecture") or ["hyogo"])[0]
            try:
                return self._send(200, {"ok": True, **get_weather(prefecture)})
            except ValueError as exc:
                return self._error(400, exc)
            except Exception as exc:
                return self._error(502, exc)
        return self._error(404, "指定されたAPIはありません")

    def do_PUT(self):
        parsed = urllib.parse.urlsplit(self.path)
        parts = [urllib.parse.unquote(x) for x in parsed.path[len("/api/state/"):].split("/") if x] if parsed.path.startswith("/api/state/") else []
        if len(parts) != 2:
            return self._error(404, "保存先は/api/state/{namespace}/{key}です")
        try:
            body = self._read_json()
            if "value" not in body:
                raise ValueError("valueフィールドが必要です")
            result = self.server.store.put(parts[0], parts[1], body["value"])
            return self._send(200, {"ok": True, **result})
        except ValueError as exc:
            return self._error(400, exc)

    def do_DELETE(self):
        parsed = urllib.parse.urlsplit(self.path)
        parts = [urllib.parse.unquote(x) for x in parsed.path[len("/api/state/"):].split("/") if x] if parsed.path.startswith("/api/state/") else []
        if len(parts) != 2:
            return self._error(404, "削除先は/api/state/{namespace}/{key}です")
        try:
            return self._send(200, {"ok": True, "deleted": self.server.store.delete(parts[0], parts[1])})
        except ValueError as exc:
            return self._error(400, exc)

    def do_POST(self):
        parsed = urllib.parse.urlsplit(self.path)
        try:
            body = self._read_json()
            if parsed.path == "/api/url-check":
                return self._send(200, {"ok": True, **inspect_url(body.get("url", ""))})
            if parsed.path == "/api/calculate":
                return self._send(200, {"ok": True, **calculate(body.get("expression", ""))})
            if parsed.path == "/api/backup/encrypt":
                if "payload" not in body:
                    raise ValueError("payloadフィールドが必要です")
                return self._send(200, {"ok": True, "backup": encrypt_backup(body["payload"], body.get("passphrase", ""))})
            if parsed.path == "/api/backup/decrypt":
                return self._send(200, {"ok": True, "payload": decrypt_backup(body.get("backup"), body.get("passphrase", ""))})
            if parsed.path == "/api/snapshot/restore":
                return self._send(200, {"ok": True, **self.server.store.restore(body.get("snapshot"))})
            return self._error(404, "指定されたAPIはありません")
        except ValueError as exc:
            return self._error(400, exc)
        except Exception as exc:
            return self._error(500, exc)


class _Server(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(self, address, handler, store):
        self.store = store
        super().__init__(address, handler)


def serve(host="127.0.0.1", port=8765, database=None, open_browser=True):
    """Start the local NEXUS UI and Cython API service."""
    if host not in ("127.0.0.1", "localhost", "::1"):
        raise ValueError("安全のため、サーバーはローカル端末内（loopback）でのみ起動できます")
    store = NexusStore(database)
    server = _Server((host, int(port)), _Handler, store)
    url = "http://%s:%d/" % (host, server.server_address[1])
    print("=" * 58)
    print(" NEXUS SUPER4.1 — Cython Edition")
    print(" URL: " + url)
    print(" API: " + url + "api/health")
    print(" DB : " + str(store.path))
    print(" Stop: Ctrl+C")
    print("=" * 58)
    if open_browser:
        try:
            import webbrowser
            threading.Timer(0.7, lambda: webbrowser.open(url)).start()
        except Exception:
            pass
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        print("\nNEXUSを終了します")
    finally:
        server.server_close()
        store.close()


if __name__ == "__main__":
    serve()
