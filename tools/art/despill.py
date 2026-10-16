"""마젠타 배경을 지운 뒤 가장자리에 남는 보라색 테두리(spill)를 없앤다.

투명 경계 근처(반경 R 픽셀) 픽셀에서 min(R, B) - G 만큼의 마젠타 기운을 R, B 에서 뺀다.
사용: python tools/art/despill.py 파일.png [파일.png ...]   (제자리에서 고친다)
"""
import sys

import numpy as np
from PIL import Image, ImageFilter

R = 10


def despill(path: str) -> int:
    im = Image.open(path).convert("RGBA")
    a = np.array(im).astype(np.int16)
    alpha = a[..., 3]
    # 투명 경계에서 R 픽셀 안쪽까지
    hole = Image.fromarray((alpha < 250).astype(np.uint8) * 255)
    near = np.array(hole.filter(ImageFilter.MaxFilter(R * 2 + 1))) > 0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    spill = np.minimum(r, b) - g
    mask = near & (alpha > 0) & (spill > 8)
    s = np.where(mask, spill, 0)
    a[..., 0] = r - s
    a[..., 2] = b - s
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").save(path)
    return int(mask.sum())


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, "고친 픽셀", despill(p))
