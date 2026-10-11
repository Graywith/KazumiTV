#!/usr/bin/env python3
"""Serve TV APKs from build/tv-updates to devices on the local network."""
import hashlib
import json
import re
from datetime import datetime, timezone
from functools import lru_cache
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent.parent / 'build' / 'tv-updates'
PATTERN = re.compile(r'kazumi-tv-(arm64-v8a|armeabi-v7a)-(\d+\.\d+\.\d+)\.apk$')


@lru_cache(maxsize=16)
def digest(path, size, modified):
    with open(path, 'rb') as stream:
        return 'sha256:' + hashlib.file_digest(stream, 'sha256').hexdigest()


def latest(abi):
    candidates = []
    for path in ROOT.glob('*.apk'):
        match = PATTERN.fullmatch(path.name)
        if match and match[1] == abi:
            candidates.append((tuple(map(int, match[2].split('.'))), path, match[2]))
    if not candidates:
        raise FileNotFoundError('No APK for this ABI')
    _, path, version = max(candidates)
    stat = path.stat()
    return {
        'package_id': 'io.github.graywith.kazumitv', 'abi': abi,
        'tag_name': version,
        'body': f'Kazumi TV {version} 本地测试更新',
        'published_at': datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        'assets': [{
            'name': path.name, 'browser_download_url': path.name,
            'size': stat.st_size,
            'digest': digest(str(path), stat.st_size, stat.st_mtime_ns),
        }],
    }


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        path = urlsplit(self.path).path
        match = re.fullmatch(r'/latest-(arm64-v8a|armeabi-v7a)\.json', path)
        if match:
            try:
                payload = json.dumps(latest(match[1]), ensure_ascii=False).encode()
            except FileNotFoundError:
                self.send_error(404, 'No APK published for this ABI')
                return
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        elif PATTERN.fullmatch(path.lstrip('/')):
            super().do_GET()
        else:
            self.send_error(404)


if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    print(f'TV update directory: {ROOT}', flush=True)
    print('LAN server on port 18080; use the Mac LAN IP on TV and emulator', flush=True)
    ThreadingHTTPServer(('0.0.0.0', 18080), Handler).serve_forever()
