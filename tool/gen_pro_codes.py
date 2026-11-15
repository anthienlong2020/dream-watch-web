"""Tạo mã mở khoá bản Pro của Đồng hồ mộng mơ.

Chạy: python3 tool/gen_pro_codes.py 20   → in ra 20 mã dạng DW-XXXX-XXXX
Mỗi mã dùng được trên mọi máy (bản web chưa có máy chủ để khoá mã theo người dùng).
"""
import secrets
import sys

ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
SALT = 'DreamWatch2026|'


def fnv1a(s: str) -> int:
    h = 0x811C9DC5
    for c in s.encode('utf-16-le')[::2]:  # giống codeUnits của Dart với ký tự ASCII
        h ^= c
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def check(body: str) -> str:
    h = fnv1a(SALT + body)
    return ALPHABET[h % 32] + ALPHABET[(h >> 5) % 32]


def make() -> str:
    body = ''.join(secrets.choice(ALPHABET) for _ in range(6))
    full = body + check(body)
    return f'DW-{full[:4]}-{full[4:]}'


if __name__ == '__main__':
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    for _ in range(n):
        print(make())
