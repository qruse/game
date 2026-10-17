"""하웰 모험가 길드 문장 SVG.

파란 방패 위에 은빛 우물과 그 뒤로 교차한 두 검. 깃발·서코트·망토·간판에 쓰이는 기준 그림이다.
Codex 이미지 편집의 참조로 쓰도록 art/refs/emblem-harwell.png 로도 굽는다 (크롬 헤드리스).

사용: python tools/icons/emblem_harwell.py
"""
import os
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
SVG = ROOT / "art/src/emblem/emblem_harwell.svg"
PNG = ROOT / "art/refs/emblem-harwell.png"

BLUE, BLUE_D = "#2c56a8", "#1a3672"
SILVER, SILVER_D, SILVER_L = "#d9dde3", "#8e96a3", "#ffffff"
INK = "#14100c"
GOLD = "#c9a23a"

SHIELD = "M64 8 L116 8 L116 58 C116 92 92 112 64 122 C36 112 12 92 12 58 L12 8 Z"


def sword(angle: float) -> str:
    """칼끝이 위로 선 장검 하나를 (64,40) 기준으로 돌린다. 두 검은 우물 지붕 바로 위에서 교차한다."""
    return (
        f'<g transform="rotate({angle} 64 40)">'
        f'<polygon points="64,16 68,23 68,80 60,80 60,23" fill="{SILVER}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>'
        f'<line x1="64" y1="22" x2="64" y2="78" stroke="{SILVER_D}" stroke-width="2"/>'
        f'<rect x="51" y="80" width="26" height="6" rx="2" fill="{GOLD}" stroke="{INK}" stroke-width="2.5"/>'
        f'<rect x="61" y="86" width="6" height="11" fill="#5a3a22" stroke="{INK}" stroke-width="2"/>'
        f'<circle cx="64" cy="100" r="4" fill="{GOLD}" stroke="{INK}" stroke-width="2"/>'
        "</g>"
    )

def well() -> str:
    """돌 우물: 지붕, 두 기둥, 도르래와 두레박, 돌 벽."""
    p = [
        # 기둥
        f'<rect x="43" y="56" width="5" height="34" fill="{SILVER_D}" stroke="{INK}" stroke-width="2.5"/>',
        f'<rect x="80" y="56" width="5" height="34" fill="{SILVER_D}" stroke="{INK}" stroke-width="2.5"/>',
        # 지붕
        f'<polygon points="64,40 92,58 36,58" fill="{SILVER}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
        f'<line x1="46" y1="52" x2="82" y2="52" stroke="{SILVER_D}" stroke-width="2"/>',
        # 가로대와 두레박
        f'<line x1="48" y1="64" x2="80" y2="64" stroke="{INK}" stroke-width="3"/>',
        f'<line x1="64" y1="64" x2="64" y2="73" stroke="{INK}" stroke-width="2"/>',
        f'<path d="M58 73 L70 73 L68 82 L60 82 Z" fill="{SILVER}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>',
        # 돌 벽
        f'<path d="M36 86 L92 86 L90 104 C80 108 48 108 38 104 Z" fill="{SILVER}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
        f'<path d="M37 95 L91 95 M50 86 L50 95 M64 86 L64 95 M78 86 L78 95 M57 95 L57 106 M71 95 L71 106 M44 95 L44 104 M84 95 L84 104" '
        f'stroke="{SILVER_D}" stroke-width="2" fill="none"/>',
    ]
    return "".join(p)


def svg() -> str:
    return "".join([
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="1024" height="1024">',
        "<defs>"
        f'<linearGradient id="field" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{BLUE}"/><stop offset="1" stop-color="{BLUE_D}"/></linearGradient>'
        f'<clipPath id="sh"><path d="{SHIELD}"/></clipPath>'
        "</defs>",
        f'<path d="{SHIELD}" fill="url(#field)"/>',
        f'<path d="M64 14 L110 14 L110 58 C110 88 89 106 64 115 C39 106 18 88 18 58 L18 14 Z" fill="none" stroke="{SILVER}" stroke-width="2.5"/>',
        '<g clip-path="url(#sh)">',
        sword(-34), sword(34),
        '<g transform="translate(64 106) scale(0.8) translate(-64 -106)">', well(), '</g>',
        "</g>",
        f'<path d="{SHIELD}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>',
        "</svg>",
    ])


def bake_png() -> None:
    chrome = next(p for p in [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    ] if os.path.exists(p))
    with tempfile.TemporaryDirectory() as d:
        html = pathlib.Path(d) / "e.html"
        html.write_text(
            '<html><body style="margin:0;background:transparent">' + svg() + "</body></html>", encoding="utf-8")
        subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--default-background-color=00000000", "--window-size=1024,1024",
                        f"--user-data-dir={d}", f"--screenshot={PNG}", html.as_uri()], check=True)


if __name__ == "__main__":
    SVG.parent.mkdir(parents=True, exist_ok=True)
    SVG.write_text(svg(), encoding="utf-8")
    bake_png()
    print("svg:", SVG, "png:", PNG)
