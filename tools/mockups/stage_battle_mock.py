"""전투 방식 시안: '무대 전투' (사이드뷰 진형 + 주사위 배정 + 장면 오브젝트).
기존 그림(길드 배경, SD, 스탠딩)만으로 화면 구성을 확인하는 용도. 적은 아직 그림이 없어 실루엣으로 둔다.

사용: python tools/mockups/stage_battle_mock.py <출력.png>
"""
import sys

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

W, H = 1920, 1080
FONT = "C:/Windows/Fonts/malgun.ttf"
FONT_B = "C:/Windows/Fonts/malgunbd.ttf"
ART = "art/final"
GOLD = (214, 178, 96)
INK = (18, 15, 13)


def f(size, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, size)


def sd(path, h, flip=False, silhouette=False):
    im = Image.open(path).convert("RGBA")
    im = im.resize((h, h), Image.LANCZOS)
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if silhouette:
        a = im.getchannel("A")
        dark = Image.new("RGBA", im.size, (40, 22, 26, 255))
        dark.putalpha(a)
        glow = a.filter(ImageFilter.GaussianBlur(6)).point(lambda v: min(255, v * 2))
        rim = Image.new("RGBA", im.size, (190, 50, 45, 0))
        rim.putalpha(glow)
        im = Image.alpha_composite(rim, dark)
    return im


def place_feet(canvas, im, cx, feet_y):
    h = im.height
    canvas.alpha_composite(im, (int(cx - im.width / 2), int(feet_y - h * 487 / 512)))


def shadow(d, cx, y, rx, col=(0, 0, 0, 110)):
    d.ellipse([cx - rx, y - rx * 0.22, cx + rx, y + rx * 0.22], fill=col)


def d20(d, cx, cy, r, val, col, txt=(255, 255, 255), small=None):
    import math
    pts = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))) for a in range(-90, 270, 60)]
    d.polygon(pts, fill=col, outline=(250, 236, 200), width=3)
    tw = d.textlength(str(val), font=f(int(r * 0.9), True))
    d.text((cx - tw / 2, cy - r * 0.62), str(val), font=f(int(r * 0.9), True), fill=txt)
    if small:
        sw = d.textlength(small, font=f(18))
        d.text((cx - sw / 2, cy + r + 4), small, font=f(18), fill=(235, 225, 205))


def main(out):
    bg = Image.open(f"{ART}/backgrounds/scene/bg_guildhall_ruined.png").convert("RGB").resize((W, H))
    bg = ImageEnhance.Brightness(bg).enhance(0.62)
    c = bg.convert("RGBA")
    d = ImageDraw.Draw(c)

    # 무대 바닥 띠 (앞줄/뒷줄)
    feet_front, feet_back = 760, 690
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    od.rectangle([0, 640, W, 800], fill=(0, 0, 0, 70))
    c.alpha_composite(ov)
    d = ImageDraw.Draw(c)

    # 장면 오브젝트(핫스팟): 2층 난간
    hx, hy = 860, 250
    d.ellipse([hx - 34, hy - 34, hx + 34, hy + 34], outline=GOLD, width=4)
    d.ellipse([hx - 10, hy - 10, hx + 10, hy + 10], fill=GOLD)
    d.rounded_rectangle([hx + 44, hy - 30, hx + 470, hy + 34], radius=10, fill=(20, 16, 12, 225), outline=GOLD, width=2)
    d.text((hx + 60, hy - 24), "낡은 난간을 무너뜨린다 · 힘 13", font=f(26, True), fill=(250, 235, 200))

    # 아군 (왼쪽): 뒷줄 아델하이트, 앞줄 리나·세실
    allies = [
        ("C03_adelheid/C03_sd_idle.png", 250, feet_back, 400),
        ("C02_cecile/C02_sd_idle.png", 470, feet_front, 430),
        ("C01_lina/C01_sd_idle.png", 700, feet_front, 450),
    ]
    for p, cx, fy, sz in allies:
        shadow(d, cx, fy, sz * 0.22)
        place_feet(c, sd(f"{ART}/characters/{p}", sz), cx, fy)
    d = ImageDraw.Draw(c)

    # 적 (오른쪽): 실루엣 자리
    enemies = [
        (1230, feet_front, 440, "도적", "공격 → 리나", 0),
        (1450, feet_front, 440, "도적", "공격 → 세실", 60),
        (1690, feet_back, 400, "도적 궁수", "조준 → 아델하이트", 0),
    ]
    for cx, fy, sz, name, intent, lift in enemies:
        shadow(d, cx, fy, sz * 0.22)
        place_feet(c, sd(f"{ART}/characters/C02_cecile/C02_sd_idle.png", sz, flip=True, silhouette=True), cx, fy)
        d = ImageDraw.Draw(c)
        top = fy - sz * 0.92 - lift
        tw = d.textlength(intent, font=f(22, True))
        d.rounded_rectangle([cx - tw / 2 - 14, top - 46, cx + tw / 2 + 14, top - 6], radius=8, fill=(120, 26, 30, 235))
        d.text((cx - tw / 2, top - 42), intent, font=f(22, True), fill=(255, 235, 225))
        nw = d.textlength(name, font=f(22))
        d.text((cx - nw / 2, fy + 20), name, font=f(22), fill=(240, 220, 210))
        d.rectangle([cx - 70, fy + 52, cx + 70, fy + 60], fill=(60, 20, 20))
        d.rectangle([cx - 70, fy + 52, cx + 40, fy + 60], fill=(210, 70, 60))

    # 줄 표시
    d.text((70, 600), "뒷줄", font=f(22), fill=(200, 190, 170))
    d.text((70, 675), "앞줄", font=f(22), fill=(200, 190, 170))

    # 아래 HUD
    hud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hud)
    for i in range(300):
        hd.line([(0, 780 + i), (W, 780 + i)], fill=(10, 8, 7, min(240, 60 + i * 2)))
    c.alpha_composite(hud)
    d = ImageDraw.Draw(c)

    cards = [
        ("C01_lina/C01_portrait_combat_neutral.png", "리나", 22, 22, "", (150, 34, 36)),
        ("C02_cecile/C02_portrait_combat_neutral.png", "세실", 16, 16, "17", (46, 92, 58)),
        ("C03_adelheid/C03_portrait_combat_neutral.png", "아델하이트", 9, 12, "", (44, 52, 96)),
    ]
    for i, (p, name, hp, mhp, die, col) in enumerate(cards):
        x0, y0, cw, ch = 40 + i * 300, 820, 280, 240
        por = Image.open(f"{ART}/characters/{p}").convert("RGBA")
        crop = por.crop((int(por.width * 0.18), int(por.height * 0.02), int(por.width * 0.82), int(por.height * 0.02 + por.width * 0.64 * ch / cw)))
        crop = crop.resize((cw, ch), Image.LANCZOS)
        card = Image.new("RGBA", (cw, ch), col + (255,))
        card.alpha_composite(crop)
        mask = Image.new("L", (cw, ch), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, cw - 1, ch - 1], radius=14, fill=255)
        c.paste(card, (x0, y0), mask)
        d = ImageDraw.Draw(c)
        d.rounded_rectangle([x0, y0, x0 + cw, y0 + ch], radius=14, outline=GOLD if i == 1 else (120, 100, 70), width=4 if i == 1 else 2)
        d.rectangle([x0, y0 + ch - 58, x0 + cw, y0 + ch], fill=(0, 0, 0, 170))
        d.text((x0 + 12, y0 + ch - 56), name, font=f(24, True), fill=(250, 240, 220))
        d.rectangle([x0 + 12, y0 + ch - 20, x0 + cw - 12, y0 + ch - 10], fill=(50, 30, 30))
        d.rectangle([x0 + 12, y0 + ch - 20, x0 + 12 + (cw - 24) * hp / mhp, y0 + ch - 10], fill=(90, 200, 100))
        d.text((x0 + cw - 80, y0 + ch - 54), f"{hp}/{mhp}", font=f(20), fill=(230, 230, 220))
        if die:
            d20(d, x0 + cw - 40, y0 + 42, 30, die, (170, 120, 40))

    # 주사위 쟁반 (이번 라운드 굴림 + 운명 주사위)
    tx, ty = 960, 860
    d.rounded_rectangle([tx, ty - 20, tx + 470, ty + 190], radius=18, fill=(58, 40, 26, 235), outline=GOLD, width=3)
    d.text((tx + 18, ty - 12), "이번 라운드 주사위 · 동료에게 끌어다 놓기", font=f(20), fill=(240, 220, 180))
    d20(d, tx + 70, ty + 80, 42, 9, (110, 80, 50))
    d20(d, tx + 175, ty + 80, 42, 4, (110, 80, 50))
    d.line([tx + 245, ty + 30, tx + 245, ty + 160], fill=(150, 120, 80), width=2)
    d20(d, tx + 330, ty + 80, 42, 18, (96, 50, 120), small="운명")
    d20(d, tx + 420, ty + 80, 32, "", (60, 50, 60), small="비어 있음")

    # 행동 (선택한 동료: 세실, 17 배정)
    ax = 1470
    d.text((ax, 830), "세실 · 17 배정됨", font=f(24, True), fill=(250, 235, 200))
    for j, (lab, sub) in enumerate([("기습", "도적 1 · 명중 95%"), ("연막탄", "궁수 시야 차단"), ("난간으로 밀기", "앞줄 → 장면 오브젝트")]):
        y = 872 + j * 66
        d.rounded_rectangle([ax, y, ax + 410, y + 56], radius=10, fill=(32, 26, 20), outline=GOLD if j == 0 else (110, 90, 60), width=2)
        d.text((ax + 16, y + 12), lab, font=f(24, True), fill=(250, 240, 220))
        d.text((ax + 190, y + 16), sub, font=f(19), fill=(210, 200, 180))

    # 상단
    d.text((40, 24), "라운드 2", font=f(34, True), fill=(250, 240, 220))
    d.text((240, 34), "3라운드 끝: 궁수가 살아 있으면 나팔 → 증원", font=f(24), fill=(255, 170, 100))
    d.rounded_rectangle([1600, 20, 1880, 70], radius=24, fill=(20, 18, 16), outline=GOLD, width=2)
    d.text((1660, 28), "라운드 진행 ▶", font=f(24), fill=(240, 230, 210))

    c.convert("RGB").save(out)
    print("saved", out)


if __name__ == "__main__":
    main(sys.argv[1])
