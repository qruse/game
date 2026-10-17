"""마을·길드 운영 화면 UI 그림 (Claude 담당): 자원 아이콘, 길드 메뉴 아이콘, 장식 줄, 길드 문장 → art/src/ui/*.svg
tools/ui/render_ui.ps1 이 이 스크립트도 돌려 godot/ui/*.png 로 굽는다 (2배).
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "src", "ui")

INK = "#120d0a"
GOLD = "#c9a45c"
GOLD_HI = "#f0d79a"
GOLD_DK = "#7a5a2c"
CREAM = "#f3e6c8"
S = f'stroke="{INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"'
S2 = f'stroke="{INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"'


def svg(w, h, body, defs=""):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><defs>{defs}</defs>{body}</svg>'


def lg(gid, top, bot, x2=0, y2=1):
    return f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bot}"/></linearGradient>'


def icon(body, defs=""):
    return svg(64, 64, body, defs)


# ── 자원 아이콘 (작게 쓰이므로 굵고 단순하게) ──

RES = {
    "res_gold": icon(
        f'<circle cx="36" cy="40" r="18" fill="url(#c2)" {S}/>'
        f'<circle cx="28" cy="27" r="19" fill="url(#c1)" {S}/>'
        f'<circle cx="28" cy="27" r="13" fill="none" stroke="#8a6420" stroke-width="2.5"/>'
        f'<path d="M22 27 L28 19 L34 27 L28 35 Z" fill="#fff3c4" stroke="#8a6420" stroke-width="2"/>',
        lg("c1", "#ffe08a", "#c98d22") + lg("c2", "#e8b850", "#9a6a1a")),
    "res_wood": icon(
        f'<rect x="8" y="30" width="44" height="16" rx="8" fill="#8a5a2e" {S}/>'
        f'<rect x="14" y="14" width="44" height="16" rx="8" fill="#a06a36" {S}/>'
        f'<ellipse cx="16" cy="38" rx="6" ry="7" fill="#e3c08a" {S2}/><circle cx="16" cy="38" r="2.5" fill="none" stroke="#8a5a2e" stroke-width="1.5"/>'
        f'<ellipse cx="22" cy="22" rx="6" ry="7" fill="#efcf98" {S2}/><circle cx="22" cy="22" r="2.5" fill="none" stroke="#8a5a2e" stroke-width="1.5"/>'),
    "res_iron": icon(
        f'<path d="M6 46 L14 30 H50 L58 46 Z" fill="url(#i1)" {S}/>'
        f'<path d="M14 30 L20 18 H44 L50 30 Z" fill="url(#i2)" {S}/>'
        f'<line x1="22" y1="22" x2="40" y2="22" stroke="#ffffff" stroke-opacity="0.7" stroke-width="2.5" stroke-linecap="round"/>',
        lg("i1", "#8e9aa8", "#4c5663") + lg("i2", "#c5cfda", "#7d8a98")),
    "res_herb": icon(
        f'<path d="M32 58 C31 44 30 32 32 14" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
        f'<path d="M32 58 C31 44 30 32 32 14" fill="none" stroke="#4d7a2e" stroke-width="2.5" stroke-linecap="round"/>'
        f'<path d="M32 22 C20 20 12 12 12 6 C22 6 30 12 32 22 Z" fill="#7fbf4a" {S2}/>'
        f'<path d="M32 30 C44 28 54 20 54 12 C42 12 34 20 32 30 Z" fill="#6aae3c" {S2}/>'
        f'<path d="M31 42 C19 40 10 34 9 26 C20 26 29 32 31 42 Z" fill="#8fcd58" {S2}/>'),
    "res_fame": icon(
        f'<polygon points="32,5 39.5,22.5 58,24 44,36.5 48.5,55 32,45 15.5,55 20,36.5 6,24 24.5,22.5" fill="url(#f1)" {S}/>'
        f'<polygon points="32,15 36,25 46,26 38.5,32.5 41,43 32,37.5 23,43 25.5,32.5 18,26 28,25" fill="#fff4c8" fill-opacity="0.55"/>',
        lg("f1", "#ffe58f", "#d99a22")),
}


def rank(fill_top, fill_bot, mark):
    return icon(
        f'<path d="M12 8 H52 V30 C52 44 42 52 32 58 C22 52 12 44 12 30 Z" fill="url(#r)" {S}/>'
        f'<path d="M17 13 H47 V30 C47 41 39 47 32 52 C25 47 17 41 17 30 Z" fill="none" stroke="#ffffff" stroke-opacity="0.45" stroke-width="2"/>'
        + "".join(f'<polygon points="{x},{y - 6} {x + 5},{y} {x},{y + 6} {x - 5},{y}" fill="{INK}" fill-opacity="0.75"/>' for x, y in mark),
        lg("r", fill_top, fill_bot))


# 동패 · 은패 · 금패: 마름모 1 · 2 · 3개
RES["rank_0"] = rank("#e0a26a", "#8a5428", [(32, 30)])
RES["rank_1"] = rank("#eef2f6", "#8d99a6", [(25, 30), (39, 30)])
RES["rank_2"] = rank("#ffe28a", "#c48a1e", [(22, 26), (42, 26), (32, 38)])


# ── 길드 메뉴 아이콘 (64, 크림·금색 + 먹선) ──

MENU = {
    # 의뢰 게시판: 나무판 + 핀 꽂힌 종이 셋
    "m_board": icon(
        f'<rect x="6" y="8" width="52" height="42" rx="3" fill="#7a4e28" {S}/>'
        f'<rect x="10" y="12" width="44" height="34" rx="2" fill="#a06a36"/>'
        f'<line x1="18" y1="50" x2="16" y2="60" {S}/><line x1="46" y1="50" x2="48" y2="60" {S}/>'
        f'<rect x="13" y="15" width="16" height="20" fill="{CREAM}" {S2} transform="rotate(-5 21 25)"/>'
        f'<rect x="33" y="17" width="17" height="14" fill="#f8efd8" {S2} transform="rotate(4 41 24)"/>'
        f'<rect x="31" y="31" width="14" height="12" fill="{CREAM}" {S2} transform="rotate(-3 38 37)"/>'
        f'<circle cx="21" cy="16" r="2.6" fill="#c0392b" {S2}/><circle cx="41" cy="18" r="2.6" fill="#c0392b" {S2}/><circle cx="38" cy="32" r="2.6" fill="#c0392b" {S2}/>'
        f'<line x1="16" y1="22" x2="26" y2="21" stroke="{INK}" stroke-width="1.5"/><line x1="16" y1="26" x2="25" y2="25" stroke="{INK}" stroke-width="1.5"/>'),
    # 위탁 의뢰: 말린 두루마리 + 붉은 봉랍
    "m_jobs": icon(
        f'<rect x="10" y="14" width="44" height="34" rx="2" fill="{CREAM}" {S}/>'
        f'<rect x="6" y="10" width="10" height="42" rx="5" fill="#d9c49a" {S}/>'
        f'<rect x="48" y="10" width="10" height="42" rx="5" fill="#d9c49a" {S}/>'
        f'<line x1="20" y1="22" x2="44" y2="22" stroke="{INK}" stroke-width="2"/><line x1="20" y1="28" x2="40" y2="28" stroke="{INK}" stroke-width="2"/>'
        f'<circle cx="38" cy="40" r="8" fill="#b0302a" {S2}/><path d="M34 40 L38 36 L42 40 L38 44 Z" fill="#e8705f"/>'),
    # 스카우트실: 망원경
    "m_scout": icon(
        f'<path d="M8 44 L40 14 L50 24 L18 54 Z" fill="url(#sc)" {S}/>'
        f'<rect x="38" y="6" width="18" height="20" rx="3" fill="#7a4e28" {S} transform="rotate(45 47 16)"/>'
        f'<line x1="22" y1="32" x2="32" y2="42" stroke="{GOLD_DK}" stroke-width="3"/>'
        f'<circle cx="12" cy="50" r="5" fill="#8fc7e8" {S2}/>'
        f'<line x1="28" y1="50" x2="22" y2="60" {S}/><line x1="34" y1="44" x2="44" y2="60" {S}/>',
        lg("sc", GOLD_HI, GOLD_DK, 1, 1)),
    # 모험가 명부: 사람 셋
    "m_roster": icon(
        f'<circle cx="16" cy="24" r="7" fill="#a8b8c8" {S2}/><path d="M4 50 C4 38 28 38 28 50 Z" fill="#6f87a0" {S2}/>'
        f'<circle cx="48" cy="24" r="7" fill="#a8b8c8" {S2}/><path d="M36 50 C36 38 60 38 60 50 Z" fill="#6f87a0" {S2}/>'
        f'<circle cx="32" cy="20" r="9" fill="{CREAM}" {S}/><path d="M16 56 C16 38 48 38 48 56 Z" fill="{GOLD}" {S}/>'),
    # 재건 공사: 망치 + 판자
    "m_build": icon(
        f'<rect x="6" y="40" width="52" height="12" rx="2" fill="#a06a36" {S}/>'
        f'<line x1="14" y1="46" x2="50" y2="46" stroke="#7a4e28" stroke-width="2"/>'
        f'<rect x="28" y="12" width="7" height="30" rx="2" fill="#8a5a2e" {S} transform="rotate(-35 31 27)"/>'
        f'<rect x="20" y="6" width="26" height="12" rx="2" fill="url(#hm)" {S} transform="rotate(-35 33 12)"/>',
        lg("hm", "#c5cfda", "#5d6875")),
    # 연대기: 걸쇠 달린 책
    "m_book": icon(
        f'<rect x="12" y="6" width="40" height="52" rx="3" fill="#6b2a2a" {S}/>'
        f'<rect x="12" y="6" width="8" height="52" rx="2" fill="#4a1c1c" {S2}/>'
        f'<rect x="26" y="16" width="20" height="26" rx="2" fill="none" stroke="{GOLD}" stroke-width="2"/>'
        f'<polygon points="36,22 40,29 36,36 32,29" fill="{GOLD_HI}" {S2}/>'
        f'<rect x="46" y="26" width="10" height="10" rx="2" fill="{GOLD}" {S2}/>'),
    # 마을로: 지붕 있는 집
    "m_town": icon(
        f'<rect x="14" y="30" width="36" height="26" fill="{CREAM}" {S}/>'
        f'<path d="M6 32 L32 8 L58 32 Z" fill="#b5532e" {S}/>'
        f'<rect x="27" y="40" width="10" height="16" fill="#7a4e28" {S2}/>'
        f'<rect x="17" y="36" width="7" height="7" fill="#8fc7e8" {S2}/><rect x="40" y="36" width="7" height="7" fill="#8fc7e8" {S2}/>'),
    # 주말 장부: 펼친 장부 + 초승달
    "m_weekend": icon(
        f'<path d="M4 20 L30 24 V58 L4 54 Z" fill="{CREAM}" {S}/><path d="M60 20 L34 24 V58 L60 54 Z" fill="#f8efd8" {S}/>'
        f'<line x1="10" y1="32" x2="24" y2="34" stroke="{INK}" stroke-width="1.8"/><line x1="10" y1="40" x2="24" y2="42" stroke="{INK}" stroke-width="1.8"/>'
        f'<line x1="40" y1="34" x2="54" y2="32" stroke="{INK}" stroke-width="1.8"/><line x1="40" y1="42" x2="54" y2="40" stroke="{INK}" stroke-width="1.8"/>'
        f'<path d="M40 4 A10 10 0 1 0 52 18 A8 8 0 1 1 40 4 Z" fill="{GOLD_HI}" {S2}/>'),
    # 출발: 칼
    "m_depart": icon(
        f'<path d="M46 6 L58 6 L58 18 L26 50 L14 38 Z" fill="url(#sw)" {S}/>'
        f'<line x1="52" y1="12" x2="22" y2="42" stroke="#ffffff" stroke-opacity="0.7" stroke-width="2"/>'
        f'<rect x="6" y="36" width="24" height="7" rx="2" fill="{GOLD}" {S2} transform="rotate(45 18 40)"/>'
        f'<line x1="14" y1="48" x2="6" y2="56" stroke="#5a3418" stroke-width="7" stroke-linecap="round"/>'
        f'<line x1="14" y1="48" x2="6" y2="56" stroke="{INK}" stroke-width="2" stroke-linecap="round" fill="none"/>',
        lg("sw", "#eef2f6", "#8d99a6", 1, 1)),
}


def divider():
    """제목 아래 장식 줄 360×24"""
    body = (f'<line x1="10" y1="12" x2="160" y2="12" stroke="url(#l)" stroke-width="2"/>'
            f'<line x1="200" y1="12" x2="350" y2="12" stroke="url(#r)" stroke-width="2"/>'
            f'<polygon points="180,2 190,12 180,22 170,12" fill="{GOLD}" stroke="{INK}" stroke-width="1.5"/>'
            f'<polygon points="180,7 185,12 180,17 175,12" fill="{GOLD_HI}"/>'
            f'<circle cx="162" cy="12" r="2.5" fill="{GOLD}"/><circle cx="198" cy="12" r="2.5" fill="{GOLD}"/>')
    defs = (f'<linearGradient id="l" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{GOLD}" stop-opacity="0"/><stop offset="1" stop-color="{GOLD}"/></linearGradient>'
            f'<linearGradient id="r" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{GOLD}"/><stop offset="1" stop-color="{GOLD}" stop-opacity="0"/></linearGradient>')
    return svg(360, 24, body, defs)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    files = {k + ".svg": v for k, v in {**RES, **MENU}.items()}
    files["orn_divider.svg"] = divider()
    # 길드 문장 (tools/icons/emblem_harwell.py 가 그린 것)을 제목 화면용으로
    em = os.path.join(ROOT, "art", "src", "emblem", "emblem_harwell.svg")
    if os.path.exists(em):
        with open(em, encoding="utf-8") as f:
            files["emblem_harwell.svg"] = f.read().replace('width="1024" height="1024"', 'width="200" height="200"', 1)
    for name, text in files.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
            f.write(text)
    print("hub ui svg:", len(files))
