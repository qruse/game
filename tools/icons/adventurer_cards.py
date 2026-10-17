"""모험가 인력풀 카드 SVG (일러스트 없이 Claude가 그리는 카드).

등급(F·D·C·B·A·S)마다 테두리 색과 장식만 바꾸고, 가운데에는 얼굴 대신 직업 문장을 넣는다.
게임에서는 같은 틀에 이름·직업·실력·특기·특성·몫을 코드로 채운다. 여기서는 등급별 견본 6장과 미리보기를 굽는다.

사용: python tools/icons/adventurer_cards.py
"""
import os
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "art/src/ui/cards"
PREVIEW = ROOT / "art/src/ui/cards/preview.png"

INK = "#1b130d"
PARCH, PARCH_D = "#f3e6c8", "#dcc79c"
GRADE = {  # 테두리, 밝은 테두리, 인장
    "F": ("#6f675d", "#a59d90", "#7d7468"),
    "D": ("#7a4a2c", "#c08a5c", "#8a5a3a"),
    "C": ("#3f6a3c", "#8fbf7f", "#4f7a4a"),
    "B": ("#2f5d9a", "#8db4ea", "#3d6aa8"),
    "A": ("#6a3c98", "#c49be8", "#7b4aa8"),
    "S": ("#a9812f", "#ffe9a6", "#c9a45c"),
}

ICON = {  # 120x120 안의 흰 실루엣, 가운데 (60,60)
    "전사": '<polygon points="56,14 64,14 64,78 60,86 56,78"/><rect x="42" y="78" width="36" height="7" rx="2"/><rect x="57" y="85" width="6" height="16"/><circle cx="60" cy="105" r="5"/>',
    "궁수": '<path d="M38 16 Q86 60 38 104" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round"/><line x1="38" y1="16" x2="38" y2="104" stroke="#fff" stroke-width="2.5"/><line x1="32" y1="60" x2="96" y2="60" stroke="#fff" stroke-width="5"/><polygon points="96,52 110,60 96,68"/><polygon points="30,52 40,60 30,68"/>',
    "마법사": '<rect x="56" y="40" width="8" height="70" rx="3"/><circle cx="60" cy="30" r="13"/><path d="M60 4 L63 13 L72 13 L65 18 L68 27 L60 21 L52 27 L55 18 L48 13 L57 13 Z" transform="translate(30 -2) scale(0.6)"/><path d="M60 4 L63 13 L72 13 L65 18 L68 27 L60 21 L52 27 L55 18 L48 13 L57 13 Z" transform="translate(-6 10) scale(0.45)"/><rect x="48" y="58" width="24" height="6" rx="3"/>',
    "도적": '<g transform="rotate(-35 60 60)"><polygon points="56,14 64,14 64,66 60,72 56,66" transform="rotate(180 60 60)"/><rect x="46" y="44" width="28" height="6" rx="2"/><rect x="57" y="18" width="6" height="26"/><circle cx="60" cy="15" r="5"/></g><g transform="rotate(35 60 60)"><polygon points="56,14 64,14 64,66 60,72 56,66" transform="rotate(180 60 60)"/><rect x="46" y="44" width="28" height="6" rx="2"/><rect x="57" y="18" width="6" height="26"/><circle cx="60" cy="15" r="5"/></g>',
    "수호자": '<path d="M60 12 L96 24 L96 58 C96 84 78 100 60 108 C42 100 24 84 24 58 L24 24 Z"/><path d="M60 26 L60 94 M38 50 L82 50" stroke="#2a2a2a" stroke-width="7" opacity="0.35"/>',
    "사제": '<circle cx="60" cy="60" r="18"/><g stroke="#fff" stroke-width="6" stroke-linecap="round"><line x1="60" y1="16" x2="60" y2="30"/><line x1="60" y1="90" x2="60" y2="104"/><line x1="16" y1="60" x2="30" y2="60"/><line x1="90" y1="60" x2="104" y2="60"/><line x1="29" y1="29" x2="39" y2="39"/><line x1="81" y1="81" x2="91" y2="91"/><line x1="91" y1="29" x2="81" y2="39"/><line x1="39" y1="81" x2="29" y2="91"/></g>',
    "견습": '<path d="M40 52 Q40 38 60 38 Q80 38 80 52 L84 98 Q60 108 36 98 Z"/><path d="M50 38 Q60 22 70 38" fill="none" stroke="#fff" stroke-width="6"/><rect x="88" y="20" width="6" height="86" rx="3" transform="rotate(8 91 63)"/>',
}

SAMPLES = [
    # 등급, 이름, 직업, 실력, 특기, 특성, 몫
    ("S", "세라핀", "궁수", 92, ["토벌", "정찰"], "백발백중 · 토벌 성공률 +15%", 35),
    ("A", "오르반", "수호자", 78, ["호위", "토벌"], "철벽 · 실패해도 다치지 않는다", 30),
    ("B", "미라", "마법사", 64, ["조사", "토벌"], "책벌레 · 조사 보상 재료 +1", 25),
    ("C", "텁", "도적", 48, ["정찰", "운반"], "손버릇 · 가끔 금화를 더 챙겨 온다", 20),
    ("D", "콘라드", "전사", 33, ["토벌"], "허세 · 토벌 성공률 −5%", 15),
    ("F", "피트", "견습", 15, ["운반", "채집"], "성실함 · 성공 3번이면 승급 시험", 10),
]

FONT = "font-family=\"'Noto Serif KR','Nanum Myeongjo','Malgun Gothic',serif\""


def card(g, name, cls, power, tags, trait, share):
    edge, hi, seal = GRADE[g]
    s = g == "S"
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 340" width="240" height="340">',
         "<defs>"
         f'<linearGradient id="pa{g}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{PARCH}"/><stop offset="1" stop-color="{PARCH_D}"/></linearGradient>'
         f'<radialGradient id="md{g}" cx="50%" cy="40%" r="60%"><stop offset="0" stop-color="{hi}"/><stop offset="1" stop-color="{edge}"/></radialGradient>'
         "</defs>"]
    if s:  # S급만 뒤에서 빛이 번진다
        p.append(f'<rect x="0" y="0" width="240" height="340" rx="18" fill="{hi}" opacity="0.55"/>')
    p.append(f'<rect x="6" y="6" width="228" height="328" rx="14" fill="url(#pa{g})" stroke="{edge}" stroke-width="8"/>')
    p.append(f'<rect x="14" y="14" width="212" height="312" rx="9" fill="none" stroke="{hi}" stroke-width="2"/>')
    if g in "ABS":  # 상위 등급은 네 귀퉁이 장식
        for cx, cy in [(14, 14), (226, 14), (14, 326), (226, 326)]:
            p.append(f'<polygon points="{cx},{cy - 8} {cx + 8},{cy} {cx},{cy + 8} {cx - 8},{cy}" fill="{hi}" stroke="{INK}" stroke-width="1.5"/>')
    # 직업 문장 메달
    p.append(f'<circle cx="120" cy="104" r="62" fill="url(#md{g})" stroke="{INK}" stroke-width="3"/>')
    p.append(f'<circle cx="120" cy="104" r="54" fill="none" stroke="{hi}" stroke-width="2" opacity="0.8"/>')
    p.append(f'<g transform="translate(78 62) scale(0.7)" fill="#fff" stroke="none">{ICON[cls]}</g>')
    # 등급 밀랍 인장
    p.append(f'<circle cx="44" cy="46" r="26" fill="{seal}" stroke="{INK}" stroke-width="3"/>')
    p.append(f'<circle cx="44" cy="46" r="20" fill="none" stroke="{hi}" stroke-width="1.5"/>')
    p.append(f'<text x="44" y="57" font-size="30" font-weight="bold" text-anchor="middle" fill="#fff" stroke="{INK}" stroke-width="1" {FONT}>{g}</text>')
    # 실력
    p.append(f'<rect x="168" y="28" width="52" height="36" rx="6" fill="{INK}" opacity="0.85"/>')
    p.append(f'<text x="194" y="41" font-size="10" text-anchor="middle" fill="{PARCH}" {FONT}>실력</text>')
    p.append(f'<text x="194" y="59" font-size="18" font-weight="bold" text-anchor="middle" fill="#fff" {FONT}>{power}</text>')
    # 이름 리본
    p.append(f'<path d="M22 178 L218 178 L208 192 L218 206 L22 206 L32 192 Z" fill="{edge}" stroke="{INK}" stroke-width="2.5"/>')
    p.append(f'<text x="120" y="198" font-size="17" font-weight="bold" text-anchor="middle" fill="#fff" {FONT}>{name}</text>')
    p.append(f'<text x="120" y="226" font-size="13" text-anchor="middle" fill="{INK}" {FONT}>{cls}</text>')
    # 특기 태그
    w = 54
    x0 = 120 - (len(tags) * w + (len(tags) - 1) * 8) / 2
    for i, t in enumerate(tags):
        x = x0 + i * (w + 8)
        p.append(f'<rect x="{x}" y="236" width="{w}" height="22" rx="11" fill="{seal}" stroke="{INK}" stroke-width="1.5"/>')
        p.append(f'<text x="{x + w / 2}" y="252" font-size="12" text-anchor="middle" fill="#fff" {FONT}>{t}</text>')
    # 특성
    p.append(f'<line x1="30" y1="270" x2="210" y2="270" stroke="{edge}" stroke-width="1.5" stroke-dasharray="4 3"/>')
    p.append(f'<text x="120" y="290" font-size="11.5" text-anchor="middle" fill="{INK}" {FONT}>{trait}</text>')
    # 몫
    p.append(f'<text x="120" y="314" font-size="11" text-anchor="middle" fill="{edge}" font-weight="bold" {FONT}>보수 몫 {share}%</text>')
    p.append("</svg>")
    return "".join(p)


def chrome() -> str:
    return next(p for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
                            r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"] if os.path.exists(p))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    svgs = []
    for row in SAMPLES:
        svg = card(*row)
        (OUT / f"card_sample_{row[0]}.svg").write_text(svg, encoding="utf-8")
        svgs.append(svg)
    with tempfile.TemporaryDirectory() as d:
        html = pathlib.Path(d) / "p.html"
        html.write_text('<html><body style="margin:0;padding:20px;background:#3a2c20;display:flex;gap:16px">'
                        + "".join(svgs) + "</body></html>", encoding="utf-8")
        subprocess.run([chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars", "--window-size=1560,380",
                        f"--user-data-dir={d}", f"--screenshot={PREVIEW}", html.as_uri()], check=True)
    print("cards:", len(svgs), "preview:", PREVIEW)
