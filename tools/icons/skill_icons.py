"""스킬 아이콘 SVG 생성기 (Claude 담당, 2026-10-16~).

동료마다 4개: basic(기본 공격) / skill1 / skill2 / ult. 같은 틀·같은 선 굵기에 역할색만 바꾸고,
한 동료의 아이콘 4개는 주된 물체(실루엣)가 서로 달라야 한다 (art/AGENTS.md S04 규칙).

사용 (저장소 루트에서):
  python tools/icons/skill_icons.py          → art/src/icons/skills/*.svg
  godot --headless --path godot -s res://../tools/icons/render_svg.gd   → art/final/icons/skills/*.png (256px)
  (렌더는 tools/icons/render_icons.ps1 이 둘을 한 번에 한다)
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "src", "icons", "skills")

CREAM = "#f3e6c8"
INK = "#1b130d"
GOLD = "#e8b84a"
STEEL = "#d9dee6"
WOOD = "#7a4b2a"

ROLE = {"C01": "#a8323a", "C02": "#6247a8", "C03": "#2f63c4", "C04": "#c99a2e"}


def g(body, x=0, y=0, rot=0, s=1.0):
    return f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">{body}</g>'


def sword(x, y, rot=0, s=1.0):
    return g(
        f'<path d="M0 -46 L7 -36 L7 12 L-7 12 L-7 -36 Z" fill="{STEEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
        f'<line x1="0" y1="-33" x2="0" y2="8" stroke="#98a1ae" stroke-width="2"/>'
        f'<rect x="-19" y="10" width="38" height="8" rx="3" fill="{GOLD}" stroke="{INK}" stroke-width="3"/>'
        f'<rect x="-4" y="18" width="8" height="17" fill="{WOOD}" stroke="{INK}" stroke-width="3"/>'
        f'<circle cx="0" cy="38" r="5.5" fill="{GOLD}" stroke="{INK}" stroke-width="3"/>',
        x, y, rot, s)


def dagger(x, y, rot=0, s=1.0):
    return g(
        f'<path d="M0 -32 L5.5 -22 L5.5 4 L-5.5 4 L-5.5 -22 Z" fill="{STEEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
        f'<rect x="-13" y="3" width="26" height="6" rx="2.5" fill="{GOLD}" stroke="{INK}" stroke-width="3"/>'
        f'<rect x="-3" y="9" width="6" height="12" fill="{WOOD}" stroke="{INK}" stroke-width="3"/>'
        f'<circle cx="0" cy="24" r="4" fill="{GOLD}" stroke="{INK}" stroke-width="3"/>',
        x, y, rot, s)


def shield(x, y, color, rot=0, s=1.0):
    return g(
        f'<path d="M-28 -32 H28 V-6 C28 16 14 30 0 40 C-14 30 -28 16 -28 -6 Z" fill="{color}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
        f'<path d="M-21 -25 H21 V-6 C21 12 10 23 0 31 C-10 23 -21 12 -21 -6 Z" fill="none" stroke="{CREAM}" stroke-width="2"/>'
        f'<rect x="-4" y="-21" width="8" height="44" fill="{CREAM}"/><rect x="-16" y="-9" width="32" height="8" fill="{CREAM}"/>',
        x, y, rot, s)


def star(cx, cy, r_out, r_in, n, fill, stroke=INK, sw=3, rot=-90):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + 180 * i / n)
        pts.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'


def rays(cx, cy, n, r0, r1, color, opacity=0.4, width_deg=7):
    out = []
    for i in range(n):
        a = 360 * i / n
        a1, a2 = math.radians(a - width_deg), math.radians(a + width_deg)
        pts = [(cx + r0 * math.cos(math.radians(a)), cy + r0 * math.sin(math.radians(a))),
               (cx + r1 * math.cos(a1), cy + r1 * math.sin(a1)),
               (cx + r1 * math.cos(a2), cy + r1 * math.sin(a2))]
        out.append('<polygon points="%s" fill="%s" opacity="%s"/>' % (" ".join(f"{p[0]:.1f},{p[1]:.1f}" for p in pts), color, opacity))
    return "".join(out)


def stroke2(d, inner, w_out=12, w_in=6, cap="round"):
    """검은 테두리가 있는 굵은 선 (아래에 넓은 INK, 위에 색)"""
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{w_out}" stroke-linecap="{cap}" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="none" stroke="{inner}" stroke-width="{w_in}" stroke-linecap="{cap}" stroke-linejoin="round"/>')


# ── 동료별 상징 ─────────────────────────────────────

def lina(kind, role):
    if kind == "basic":  # 롱소드
        return star(94, 30, 14, 5, 4, CREAM, INK, 2.5) + sword(62, 66, 40, 1.25)
    if kind == "skill1":  # 방패 강타: 앞으로 내지르는 방패 + 충격선
        return (shield(56, 64, role, -12, 1.05)
                + stroke2("M92 38 L110 28", CREAM, 9, 4) + stroke2("M96 64 L116 64", CREAM, 9, 4) + stroke2("M92 90 L110 100", CREAM, 9, 4)
                + star(90, 64, 13, 6, 6, GOLD, INK, 2.5))
    if kind == "skill2":  # 도발: 외치는 느낌표 폭발
        return (star(64, 64, 50, 34, 12, role, INK, 3.5, -75)
                + f'<rect x="56" y="28" width="16" height="44" rx="7" fill="{CREAM}" stroke="{INK}" stroke-width="3.5"/>'
                + f'<circle cx="64" cy="88" r="8.5" fill="{CREAM}" stroke="{INK}" stroke-width="3.5"/>')
    # ult 기사의 맹세: 빛 속에 세운 검과 방패
    return rays(64, 62, 14, 6, 62, GOLD, 0.35) + sword(64, 54, 0, 1.1) + shield(64, 76, role, 0, 0.78)


def cecile(kind, role):
    if kind == "basic":  # 쌍단검
        return dagger(64, 66, -38, 1.35) + dagger(64, 66, 38, 1.35)
    if kind == "skill1":  # 기습: 그림자(초승달)에서 찌르는 단검
        return (f'<path d="M78 16 A46 46 0 1 0 112 86 A36 36 0 1 1 78 16 Z" fill="{role}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
                + dagger(70, 64, 135, 1.6))
    if kind == "skill2":  # 연막탄
        puffs = "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#b8b3c8" stroke="{INK}" stroke-width="3"/>'
                        for x, y, r in [(84, 86, 16), (98, 70, 13), (90, 54, 11), (34, 92, 12)])
        return (puffs
                + f'<circle cx="54" cy="74" r="23" fill="#2c2836" stroke="{INK}" stroke-width="3.5"/>'
                + f'<circle cx="46" cy="66" r="6" fill="#6b6680"/>'
                + stroke2("M66 56 Q74 44 80 40", "#c9a46a", 7, 3)
                + star(84, 36, 12, 5, 6, GOLD, INK, 2.5))
    # ult 그림자 난무: 세 줄기 베기
    slash = lambda d: f'<path d="{d}" fill="{CREAM}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
    return (f'<circle cx="64" cy="64" r="44" fill="{role}" opacity="0.45"/>'
            + slash("M14 50 Q60 60 112 22 Q70 72 14 50 Z") + slash("M12 82 Q62 88 114 58 Q72 104 12 82 Z")
            + slash("M22 108 Q64 112 104 90 Q70 124 22 108 Z")
            + star(98, 40, 9, 3, 4, "#ffffff", INK, 2) + star(30, 68, 7, 2.5, 4, "#ffffff", INK, 2))


def adelheid(kind, role):
    if kind == "basic":  # 마력탄
        return ('<defs><radialGradient id="orb" cx="40%" cy="38%" r="65%"><stop offset="0" stop-color="#e8f4ff"/>'
                f'<stop offset="0.45" stop-color="#8fc2ff"/><stop offset="1" stop-color="{role}"/></radialGradient></defs>'
                f'<ellipse cx="64" cy="66" rx="44" ry="14" fill="none" stroke="{CREAM}" stroke-width="3" opacity="0.7" transform="rotate(-20 64 66)"/>'
                f'<circle cx="64" cy="64" r="26" fill="url(#orb)" stroke="{INK}" stroke-width="3.5"/>'
                + star(80, 46, 12, 3.5, 4, "#ffffff", INK, 2))
    if kind == "skill1":  # 불꽃 화살
        return (f'<path d="M102 24 C82 28 60 36 40 62 C58 54 60 64 48 80 C74 70 96 50 102 24 Z" fill="#f07a2a" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                f'<path d="M96 32 C82 38 70 46 58 60 C70 56 70 62 62 72 C80 64 92 50 96 32 Z" fill="#ffd25a"/>'
                + stroke2("M28 100 L88 40", "#c9935a", 9, 4)
                + f'<polygon points="102,26 80,36 92,48" fill="{STEEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                + f'<polygon points="28,100 22,84 36,92" fill="{CREAM}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>'
                + f'<polygon points="28,100 44,106 36,92" fill="{CREAM}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>')
    if kind == "skill2":  # 서리 사슬
        links = "".join(
            f'<ellipse cx="{30 + i * 15}" cy="{98 - i * 15}" rx="12" ry="7" fill="none" stroke="{INK}" stroke-width="9" transform="rotate({-45 if i % 2 == 0 else 45} {30 + i * 15} {98 - i * 15})"/>'
            f'<ellipse cx="{30 + i * 15}" cy="{98 - i * 15}" rx="12" ry="7" fill="none" stroke="#c4e8ff" stroke-width="4" transform="rotate({-45 if i % 2 == 0 else 45} {30 + i * 15} {98 - i * 15})"/>'
            for i in range(4))
        flake = "".join(stroke2(f"M{88 + 18 * math.cos(math.radians(a)):.1f} {38 + 18 * math.sin(math.radians(a)):.1f} L{88 - 18 * math.cos(math.radians(a)):.1f} {38 - 18 * math.sin(math.radians(a)):.1f}", "#ffffff", 8, 4)
                        for a in (90, 30, 150))
        return links + flake
    # ult 금서 해방: 펼친 마법서와 솟는 빛
    return (rays(64, 50, 12, 4, 60, GOLD, 0.4)
            + f'<polygon points="64,92 20,80 20,44 64,56" fill="{CREAM}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            + f'<polygon points="64,92 108,80 108,44 64,56" fill="{CREAM}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            + f'<polygon points="64,92 20,80 20,86 64,98 108,86 108,80" fill="{role}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
            + "".join(f'<line x1="{28 + i * 0}" y1="{54 + i * 8}" x2="56" y2="{62 + i * 8}" stroke="#9c8a66" stroke-width="2.5"/>' for i in range(3))
            + "".join(f'<line x1="72" y1="{62 + i * 8}" x2="100" y2="{54 + i * 8}" stroke="#9c8a66" stroke-width="2.5"/>' for i in range(3))
            + star(64, 34, 10, 4, 4, "#ffffff", INK, 2))


def miriam(kind, role):
    if kind == "basic":  # 지팡이
        return (stroke2("M40 108 L82 36", "#a8743f", 12, 6)
                + rays(86, 30, 10, 14, 26, GOLD, 0.8, 9)
                + f'<circle cx="86" cy="30" r="12" fill="{GOLD}" stroke="{INK}" stroke-width="3.5"/>')
    if kind == "skill1":  # 치유의 손: 하트와 십자
        return (f'<circle cx="64" cy="64" r="46" fill="#9be08f" opacity="0.25"/>'
                + f'<path d="M64 102 C30 80 18 60 26 44 C34 28 56 30 64 46 C72 30 94 28 102 44 C110 60 98 80 64 102 Z" fill="#e8909c" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
                + f'<rect x="57" y="46" width="14" height="38" rx="3" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>'
                + f'<rect x="45" y="58" width="38" height="14" rx="3" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>')
    if kind == "skill2":  # 순례자의 축복: 가리비 조개
        ribs = "".join(f'<line x1="64" y1="98" x2="{64 + 40 * math.cos(math.radians(a)):.1f}" y2="{64 + 40 * math.sin(math.radians(a)):.1f}" stroke="{INK}" stroke-width="2.5"/>'
                       for a in range(-160, -15, 24))
        scallops = "".join(f'<circle cx="{64 + 40 * math.cos(math.radians(a)):.1f}" cy="{64 + 40 * math.sin(math.radians(a)):.1f}" r="7.5" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>'
                           for a in range(-172, -3, 24))
        return (rays(64, 50, 10, 30, 62, GOLD, 0.35)
                + scallops
                + f'<path d="M64 98 L24 66 A40 40 0 0 1 104 66 Z" fill="{CREAM}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
                + ribs
                + f'<rect x="52" y="94" width="24" height="12" rx="4" fill="{role}" stroke="{INK}" stroke-width="3"/>')
    # ult 빛의 기둥
    return ('<defs><linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6c8"/>'
            f'<stop offset="1" stop-color="{GOLD}" stop-opacity="0.6"/></linearGradient></defs>'
            f'<ellipse cx="64" cy="100" rx="40" ry="10" fill="{GOLD}" opacity="0.5" stroke="{INK}" stroke-width="3"/>'
            f'<path d="M46 10 H82 L78 100 H50 Z" fill="url(#beam)" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            + star(34, 40, 9, 3, 4, "#ffffff", INK, 2) + star(96, 56, 7, 2.5, 4, "#ffffff", INK, 2) + star(30, 76, 6, 2, 4, "#ffffff", INK, 2))


HEROES = {"C01": lina, "C02": cecile, "C03": adelheid, "C04": miriam}


def darken(hex_color, k):
    r, gg, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return "#%02x%02x%02x" % (int(r * k), int(gg * k), int(b * k))


def icon(hero, kind):
    role = ROLE[hero]
    top = darken(role, 0.62)
    ult = kind == "ult"
    basic = kind == "basic"
    border = GOLD if ult else ("#5c4a36" if basic else "#8a6a3a")
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">',
        '<defs>'
        f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="#120d0a"/></linearGradient>'
        '<radialGradient id="vig" cx="50%" cy="45%" r="70%"><stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.7"/></radialGradient>'
        '</defs>',
        '<rect x="4" y="4" width="120" height="120" rx="16" fill="url(#bg)"/>',
        '<rect x="4" y="4" width="120" height="120" rx="16" fill="url(#vig)"/>',
    ]
    if basic:
        parts.append('<rect x="4" y="4" width="120" height="120" rx="16" fill="#000" opacity="0.25"/>')
    parts.append(HEROES[hero](kind, role))
    parts.append(f'<rect x="4" y="4" width="120" height="120" rx="16" fill="none" stroke="{border}" stroke-width="{6 if ult else 5}"/>')
    if ult:
        parts.append('<rect x="10" y="10" width="108" height="108" rx="11" fill="none" stroke="#fff2b0" stroke-width="2"/>')
        for cx, cy in [(10, 10), (118, 10), (10, 118), (118, 118)]:
            parts.append(f'<polygon points="{cx},{cy - 7} {cx + 7},{cy} {cx},{cy + 7} {cx - 7},{cy}" fill="{GOLD}" stroke="{INK}" stroke-width="2"/>')
    elif not basic:
        parts.append(f'<rect x="10" y="10" width="108" height="108" rx="11" fill="none" stroke="{role}" stroke-width="2" opacity="0.9"/>')
    parts.append("</svg>")
    return "".join(parts)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for hero in HEROES:
        for kind in ["basic", "skill1", "skill2", "ult"]:
            with open(os.path.join(OUT, f"{hero}_icon_{kind}.svg"), "w", encoding="utf-8") as f:
                f.write(icon(hero, kind))
            n += 1
    print("svg:", n, OUT)
