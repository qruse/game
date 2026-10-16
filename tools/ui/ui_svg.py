"""전투 UI 그림 (Claude 담당): 9-slice 틀, 버튼, 상태 아이콘, 운명 주사위. SVG → godot/ui/*.png
사용: powershell -ExecutionPolicy Bypass -File tools/ui/render_ui.ps1
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "src", "ui")

GOLD = "#c9a45c"
GOLD_HI = "#f0d79a"
GOLD_DK = "#7a5a2c"
INK = "#120d0a"


def svg(w, h, body, defs=""):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><defs>{defs}</defs>{body}</svg>'


def grad(gid, top, bot):
    return f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bot}"/></linearGradient>'


def corner_orn(x, y, sx, sy, col):
    """모서리 장식: 작은 마름모 + 짧은 덩굴선 (sx, sy 로 방향)"""
    d = f"M{x + sx * 4} {y + sy * 16} Q{x + sx * 4} {y + sy * 4} {x + sx * 16} {y + sy * 4}"
    return (f'<path d="{d}" fill="none" stroke="{col}" stroke-width="2" stroke-linecap="round"/>'
            f'<polygon points="{x + sx * 9},{y + sy * 5} {x + sx * 13},{y + sy * 9} {x + sx * 9},{y + sy * 13} {x + sx * 5},{y + sy * 9}" fill="{col}"/>')


def panel(top="#241b15", bot="#120e0b", border=GOLD_DK, inner=GOLD, alpha=0.94):
    """큰 판넬: 96×96, 9-slice 여백 30"""
    W = 96
    body = (f'<rect x="1.5" y="1.5" width="93" height="93" rx="9" fill="url(#g)" fill-opacity="{alpha}" stroke="{INK}" stroke-width="3"/>'
            f'<rect x="3.5" y="3.5" width="89" height="89" rx="8" fill="none" stroke="{border}" stroke-width="2.5"/>'
            f'<rect x="8.5" y="8.5" width="79" height="79" rx="5" fill="none" stroke="{inner}" stroke-width="1" stroke-opacity="0.55"/>'
            + corner_orn(6, 6, 1, 1, inner) + corner_orn(90, 6, -1, 1, inner) + corner_orn(6, 90, 1, -1, inner) + corner_orn(90, 90, -1, -1, inner))
    return svg(W, W, body, grad("g", top, bot))


def button(kind):
    """버튼: 64×64, 9-slice 여백 18"""
    styles = {
        "normal": ("#3b2d21", "#1f1712", GOLD_DK, GOLD, 0.0),
        "hover": ("#4d3a29", "#281e16", GOLD, GOLD_HI, 0.15),
        "pressed": ("#1c1510", "#33261b", GOLD_HI, GOLD_HI, 0.0),
        "disabled": ("#2a2622", "#1a1715", "#45403a", "#55504a", 0.0),
        "gold": ("#6b4e1e", "#2e210f", GOLD_HI, "#fff0c0", 0.25),
        "gold_hover": ("#86622a", "#3a2a14", "#fff0c0", "#ffffff", 0.35),
        "env": ("#253a24", "#121b11", "#5f7d3c", "#a8d07a", 0.1),
        "env_hover": ("#30502e", "#162214", "#a8d07a", "#d8f0b0", 0.2),
    }
    top, bot, border, line, glow = styles[kind]
    body = (f'<rect x="1.5" y="1.5" width="61" height="61" rx="7" fill="url(#g)" stroke="{INK}" stroke-width="3"/>'
            f'<rect x="3.5" y="3.5" width="57" height="57" rx="6" fill="none" stroke="{border}" stroke-width="2"/>'
            f'<line x1="10" y1="7" x2="54" y2="7" stroke="{line}" stroke-width="1.5" stroke-opacity="0.6" stroke-linecap="round"/>')
    if glow:
        body += f'<rect x="5" y="5" width="54" height="54" rx="5" fill="url(#hl)" opacity="{glow}"/>'
    defs = grad("g", top, bot) + '<radialGradient id="hl" cx="50%" cy="0%" r="90%"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>'
    return svg(64, 64, body, defs)


def chip(col):
    """작은 이름표·차례 칩 배경: 48×24, 9-slice 여백 10"""
    return svg(48, 24, f'<rect x="1" y="1" width="46" height="22" rx="11" fill="{col}" stroke="{INK}" stroke-width="2"/>'
                       f'<rect x="3" y="3" width="42" height="18" rx="9" fill="none" stroke="#ffffff" stroke-opacity="0.25" stroke-width="1"/>')


def d20(fill, edge, face_hi):
    """운명 주사위 아이콘 64×64: 정이십면체를 정면에서 본 모양"""
    cx, cy, r = 32, 33, 28
    hexp = [(cx + r * math.cos(math.radians(-90 + 60 * i)), cy + r * math.sin(math.radians(-90 + 60 * i))) for i in range(6)]
    tri = [(cx + r * 0.62 * math.cos(math.radians(-90 + 120 * i)), cy + r * 0.62 * math.sin(math.radians(-90 + 120 * i))) for i in range(3)]
    P = lambda pts: " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    body = f'<polygon points="{P(hexp)}" fill="{fill}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
    # 바깥 면 6개를 번갈아 밝게
    for i in range(6):
        a, b = hexp[i], hexp[(i + 1) % 6]
        t = tri[((i + 1) // 2) % 3]
        body += f'<polygon points="{P([a, b, t])}" fill="#ffffff" fill-opacity="{0.10 if i % 2 == 0 else 0.0}" stroke="{edge}" stroke-width="1.2" stroke-linejoin="round"/>'
    body += f'<polygon points="{P(tri)}" fill="{face_hi}" stroke="{edge}" stroke-width="1.5" stroke-linejoin="round"/>'
    body += f'<text x="{cx}" y="{cy + 6}" font-size="15" font-weight="bold" text-anchor="middle" fill="{INK}" font-family="sans-serif">20</text>'
    return svg(64, 64, body)


# 상태 아이콘 48×48: 색 동그라미 + 흰 기호
def status(col, glyph):
    return svg(48, 48, f'<circle cx="24" cy="24" r="21" fill="{col}" stroke="{INK}" stroke-width="3"/>'
                       f'<circle cx="24" cy="24" r="17" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5"/>' + glyph)


W = 'fill="#fff" stroke="#120d0a" stroke-width="2" stroke-linejoin="round"'
STATUS = {
    "stun": status("#7a4fb0", f'<polygon points="24,9 27.5,19 38,19 29.5,25.5 33,36 24,29.5 15,36 18.5,25.5 10,19 20.5,19" {W}/>'),
    "burn": status("#c4521f", f'<path d="M24 38 C14 36 13 26 19 20 C19 26 23 26 22 18 C28 21 34 28 31 34 C30 36 27 38 24 38 Z" {W}/>'),
    "taunt": status("#a8323a", f'<rect x="21" y="10" width="6" height="18" rx="3" {W}/><circle cx="24" cy="35" r="3.5" {W}/>'),
    "guard": status("#3d6aa8", f'<path d="M14 12 H34 V22 C34 31 28 36 24 39 C20 36 14 31 14 22 Z" {W}/>'),
    "stealth": status("#3a3550", f'<path d="M9 25 Q24 12 39 25 Q24 36 9 25 Z" {W}/><line x1="12" y1="36" x2="36" y2="14" stroke="#120d0a" stroke-width="4"/><line x1="12" y1="36" x2="36" y2="14" stroke="#fff" stroke-width="2"/>'),
    "bless": status("#c99a2e", f'<polygon points="24,9 27,21 39,24 27,27 24,39 21,27 9,24 21,21" {W}/>'),
    "oath": status("#b8862e", f'<polygon points="24,8 27,12 27,30 21,30 21,12" {W}/><rect x="15" y="29" width="18" height="4" rx="1.5" {W}/><rect x="22" y="33" width="4" height="7" {W}/>'),
    "smoke": status("#6d6a78", f'<circle cx="18" cy="27" r="7" {W}/><circle cx="28" cy="22" r="8" {W}/><circle cx="30" cy="31" r="6" {W}/>'),
    "cover": status("#6b5233", f'<rect x="12" y="14" width="7" height="22" {W}/><rect x="21" y="14" width="7" height="22" {W}/><rect x="30" y="14" width="7" height="22" {W}/>'),
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    files = {
        "panel.svg": panel(),
        "panel_light.svg": panel("#2e241b", "#1a140f", GOLD_DK, GOLD, 0.97),
        "chip_ally.svg": chip("#2d4f7c"),
        "chip_enemy.svg": chip("#7a2622"),
        "chip_down.svg": chip("#3a3a3a"),
        "fate_on.svg": d20("#7d4fc4", "#3d2066", "#c9a8f5"),
        "fate_off.svg": d20("#2c2833", "#45404d", "#3a3540"),
        "fate_lock.svg": d20("#d9a83a", "#6b4e1e", "#fff0c0"),
    }
    for k in ["normal", "hover", "pressed", "disabled", "gold", "gold_hover", "env", "env_hover"]:
        files[f"btn_{k}.svg"] = button(k)
    for k, v in STATUS.items():
        files[f"st_{k}.svg"] = v
    for name, text in files.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
            f.write(text)
    print("svg:", len(files))
