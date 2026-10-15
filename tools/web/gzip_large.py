"""20MB 넘는 파일을 gzip 으로 줄여 <이름>.gz 로 바꾼다 (Cloudflare 정적 파일 한 개 25 MiB 제한).
Worker(tools/web/cloudflare/src/index.js)가 원래 이름 요청에 .gz 를 압축 표시와 함께 내려준다.
"""
import gzip
import os
import sys

LIMIT = 20 * 1024 * 1024

pub = sys.argv[1]
for name in os.listdir(pub):
    p = os.path.join(pub, name)
    if os.path.isfile(p) and os.path.getsize(p) > LIMIT and not name.endswith(".gz"):
        with open(p, "rb") as f:
            data = f.read()
        with gzip.open(p + ".gz", "wb", compresslevel=9) as f:
            f.write(data)
        os.remove(p)
        print("gzip", name, len(data) // 1024, "KB ->", os.path.getsize(p + ".gz") // 1024, "KB")
