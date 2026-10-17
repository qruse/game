"""20MB 넘는 파일을 gzip 으로 줄여 R2 에 올릴 폴더로 옮긴다 (Cloudflare 정적 파일 한 개 25 MiB 제한).
<이름>.gz 는 tools/web/deploy_web.ps1 이 R2 버킷 project-d20-web 에 올리고,
Worker(tools/web/cloudflare/src/index.js)가 원래 이름 요청에 압축 표시와 함께 내려준다.

사용: python gzip_large.py <public 폴더> <R2 폴더>
"""
import gzip
import os
import shutil
import sys

LIMIT = 20 * 1024 * 1024

pub, r2 = sys.argv[1], sys.argv[2]
if os.path.isdir(r2):
    shutil.rmtree(r2)
os.makedirs(r2)
for name in os.listdir(pub):
    p = os.path.join(pub, name)
    if os.path.isfile(p) and os.path.getsize(p) > LIMIT:
        with open(p, "rb") as f:
            data = f.read()
        out = os.path.join(r2, name + ".gz")
        with gzip.open(out, "wb", compresslevel=9) as f:
            f.write(data)
        os.remove(p)
        print("R2", name, len(data) // 1024, "KB ->", os.path.getsize(out) // 1024, "KB")
