"""세력 인장 (봉랍 도장) SVG — Claude 담당 (docs/06-factions.md: 세력 인장 4개, 코드 SVG).
봉랍 가장자리는 울퉁불퉁한 원, 문양은 밝은 선·어두운 선을 어긋나게 겹쳐 눌린 자국처럼 보이게 한다 (필터 없이: Godot SVG 변환기로도 같은 그림).
art/src/ui/seal_*.svg 로 쓰고 tools/ui/render_ui.ps1 이 godot/ui/seal_*.png 로 굽는다.
사용: python tools/icons/faction_seals.py
"""
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "src", "ui")

# 세력: (밝은 색, 기본 색, 어두운 색)
WAX = {
    "crown": ("#e0645a", "#a8342a", "#5e1510"),   # 왕관 (왕국과 영주)
    "dawn": ("#7aa2e8", "#2f5fb8", "#16306a"),    # 새벽빛 교회
    "scales": ("#7fb36a", "#3f7a3a", "#1d3f1a"),  # 금저울 상회
    "rat": ("#a3a3a8", "#5d5d63", "#2a2a2e"),     # 회색 쥐
}


def blob(seed, cx=50, cy=50, r=44):
    """녹은 봉랍 가장자리: 반지름이 조금씩 흔들리는 닫힌 곡선"""
    rnd = random.Random(seed)
    n = 22
    pts = []
    for i in range(n):
        a = math.tau * i / n
        rr = r * (1 + 0.035 * math.sin(a * 3 + seed) + rnd.uniform(-0.03, 0.03))
        if rnd.random() < 0.18:
            rr *= 1.06  # 흘러나온 자국
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    # 부드러운 닫힌 곡선 (중점 이차 베지어)
    d = ""
    for i in range(n):
        p0, p1 = pts[i], pts[(i + 1) % n]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        d += (f"M{mx:.1f} {my:.1f}" if i == 0 else f" Q{p0[0]:.1f} {p0[1]:.1f} {mx:.1f} {my:.1f}")
    p0 = pts[0]
    m = ((pts[-1][0] + p0[0]) / 2, (pts[-1][1] + p0[1]) / 2)
    d += f" Q{pts[-1][0]:.1f} {pts[-1][1]:.1f} {m[0]:.1f} {m[1]:.1f}"
    first = ((pts[0][0] + pts[1][0]) / 2, (pts[0][1] + pts[1][1]) / 2)
    d += f" Q{p0[0]:.1f} {p0[1]:.1f} {first[0]:.1f} {first[1]:.1f} Z"
    return d


# 문양 (100×100 좌표, 가운데 50,50, 반지름 24 안쪽). 채움 도형 하나의 path d
EMBLEM = {
    "crown": "M30 62 L70 62 L70 55 L30 55 Z M30 53 L27 34 L39 44 L50 28 L61 44 L73 34 L70 53 Z",
    "dawn": "M27 60 L73 60 L73 57 L27 57 Z M36 55 A14 14 0 0 1 64 55 Z"
            " M48.5 30 L51.5 30 L51.5 39 L48.5 39 Z M33 36 L35.2 34 L40.8 40.8 L38.6 42.8 Z M67 36 L64.8 34 L59.2 40.8 L61.4 42.8 Z"
            " M26 47 L27 44.2 L35.2 47.2 L34.2 50 Z M74 47 L73 44.2 L64.8 47.2 L65.8 50 Z",
    "scales": "M48.5 30 L51.5 30 L51.5 66 L48.5 66 Z M40 66 L60 66 L60 70 L40 70 Z M28 36 L72 36 L72 39 L28 39 Z"
              " M30 39 L31.6 39 L25 54 L23.4 54 Z M30.8 39 L32.4 39 L39 54 L37.4 54 Z M22 54 L40 54 A9 6 0 0 1 22 54 Z"
              " M68.4 39 L70 39 L76.6 54 L75 54 Z M67.6 39 L69.2 39 L62.6 54 L61 54 Z M60 54 L78 54 A9 6 0 0 1 60 54 Z",
    "rat": "M27 59 C25 47 38 39 52 41 C61 42 67 46 72 51 L79 55 L72 58 C66 61 58 62 50 62 L34 62 C30 62 27 61 27 59 Z"
           " M53 41 A6.5 6.5 0 1 1 66 41 A6.5 6.5 0 1 1 53 41 Z"
           " M29 60 C19 60 17 70 25 72 C31 73 36 70 41 68 L40 65.6 C35 68 31 70 26 69 C21.5 67.5 23 62.6 30 62.6 Z",
}


def seal(key, small=False):
    """small: 작게 쓸 때 (44px 안팎) 테를 빼고 문양을 키운다"""
    hi, base, dk = WAX[key]
    seed = sum(map(ord, key))
    e = EMBLEM[key]
    k = ' transform="translate(50 50) scale(1.3) translate(-50 -50)"' if small else ''
    body = (
        # 그림자
        f'<path d="{blob(seed, 51.5, 53, 44)}" fill="#000" fill-opacity=".35"/>'
        # 봉랍
        f'<path d="{blob(seed)}" fill="url(#w)"/>'
        # 눌린 테 (도장 가장자리, 작은 것은 뺀다)
        + ("" if small else
           f'<circle cx="50" cy="50" r="31" fill="{dk}" fill-opacity=".18"/>'
           f'<circle cx="50.8" cy="50.8" r="30" fill="none" stroke="{hi}" stroke-opacity=".55" stroke-width="2"/>'
           f'<circle cx="49.4" cy="49.4" r="30" fill="none" stroke="{dk}" stroke-opacity=".7" stroke-width="2"/>')
        # 문양: 밝은 자국(오른쪽 아래) + 어두운 자국(왼쪽 위) + 바닥
        + f'<g{k}><path d="{e}" fill="{hi}" fill-opacity=".75" transform="translate(1 1)"/>'
        f'<path d="{e}" fill="{dk}" fill-opacity=".85" transform="translate(-.8 -.8)"/>'
        f'<path d="{e}" fill="url(#d)"/></g>'
        # 윗면 광택
        f'<ellipse cx="38" cy="30" rx="16" ry="8" fill="#fff" fill-opacity=".16" transform="rotate(-30 38 30)"/>'
    )
    defs = (f'<radialGradient id="w" cx="38%" cy="32%" r="75%"><stop offset="0" stop-color="{hi}"/><stop offset=".55" stop-color="{base}"/><stop offset="1" stop-color="{dk}"/></radialGradient>'
            f'<linearGradient id="d" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{dk}"/><stop offset="1" stop-color="{base}"/></linearGradient>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><defs>{defs}</defs>{body}</svg>'


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for k in WAX:
        with open(os.path.join(OUT, f"seal_{k}.svg"), "w", encoding="utf-8") as f:
            f.write(seal(k))
        with open(os.path.join(OUT, f"seal_{k}_s.svg"), "w", encoding="utf-8") as f:
            f.write(seal(k, True))
    print("seals:", len(WAX) * 2)
