"""밝은 머리(금발 등) 가장자리에 남은 마젠타 섞임을 주변 머리색으로 덮는다.

크로마키 마젠타가 금발 가장자리에 섞이면 장밋빛(예: 212,130,130)이 남는다. despill.py 는 min(R,B)-G 만 보므로 이걸 못 잡는다.
투명 경계 근처(반경 16px)에서 색이 머리답지 않은 픽셀(장밋빛, 또는 지나치게 연두빛)을
주변 '정상 금발' 픽셀의 평균색으로 바꾸고 밝기만 원래 픽셀에 맞춘다. 얼굴 홍조·입술은 안쪽이라 건드리지 않는다.

사용: python tools/art/unmagenta_hair.py 파일.png [파일.png ...]   (제자리에서 고친다)
"""
import sys

import numpy as np
from PIL import Image, ImageFilter

RADIUS = 16
LOCAL = 12  # 주변 평균을 낼 반경


def _box(x: np.ndarray, r: int) -> np.ndarray:
    """누적합으로 (2r+1)^2 상자 합"""
    p = np.pad(x, r, mode="constant")
    c = p.cumsum(0).cumsum(1)
    c = np.pad(c, ((1, 0), (1, 0)))
    n = 2 * r + 1
    return c[n:, n:] - c[:-n, n:] - c[n:, :-n] + c[:-n, :-n]


def fix(path: str) -> int:
    im = Image.open(path).convert("RGBA")
    a = np.array(im).astype(np.float32)
    alpha = a[..., 3]
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    hole = Image.fromarray((alpha < 250).astype(np.uint8) * 255)
    near = np.array(hole.filter(ImageFilter.MaxFilter(RADIUS * 2 + 1))) > 0
    good = (alpha > 200) & (r - g >= 12) & (r - g <= 80) & (b < g - 25)
    pink = (r - g > 40) & (b >= g - 15)
    lime = (r - g < 10) & (b < g - 40) & (g > 80)
    bad = near & (alpha > 0) & (pink | lime)
    cnt = _box(good.astype(np.float32), LOCAL)
    ok = bad & (cnt > 5)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    mean = [_box(np.where(good, ch, 0.0), LOCAL) / np.maximum(cnt, 1) for ch in (r, g, b)]
    mlum = 0.299 * mean[0] + 0.587 * mean[1] + 0.114 * mean[2]
    scale = lum / np.maximum(mlum, 1)
    for i in range(3):
        a[..., i] = np.where(ok, mean[i] * scale, a[..., i])
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").save(path)
    return int(ok.sum())


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, "고친 픽셀", fix(p))
