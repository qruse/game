"""대화 화면 시안 (니케식 짧은 장면). 스탠딩 일러스트가 대사창에 가리지 않는지 확인용.

사용: python tools/mockups/dialogue_mock.py <스탠딩.png> <출력.png> [이름] [대사] [오른쪽 스탠딩.png]
배경 일러스트가 아직 없으면 어두운 그라데이션으로 대신한다.
"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
FONT = "C:/Windows/Fonts/malgun.ttf"
FONT_B = "C:/Windows/Fonts/malgunbd.ttf"


def background() -> Image.Image:
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(58 - 30 * t), int(46 - 24 * t), int(38 - 20 * t)))
    # 창문 빛 느낌의 흐린 사각형 (배경 일러스트 자리 표시)
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).rectangle([1300, 120, 1620, 560], fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    bg.paste((140, 110, 70), (0, 0), glow)
    ImageDraw.Draw(bg).text((40, 30), "배경: bg_guildhall_ruined 자리", font=ImageFont.truetype(FONT, 22), fill=(150, 130, 110))
    return bg


def place_portrait(bg: Image.Image, path: str, cx: int, dim: bool = False) -> None:
    p = Image.open(path).convert("RGBA")
    h = int(H * 1.05)  # 무릎 근처가 대사창 아래로 살짝 잘리게
    w = int(p.width * h / p.height)
    p = p.resize((w, h), Image.LANCZOS)
    if dim:
        dark = Image.new("RGBA", p.size, (0, 0, 0, 0))
        dark.putalpha(p.getchannel("A").point(lambda a: int(a * 0.45)))
        p = Image.alpha_composite(p, dark)
    bg.paste(p, (cx - w // 2, H - h + int(H * 0.05)), p)


def dialogue_box(img: Image.Image, name: str, line: str) -> None:
    box_top = int(H * 0.72)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for i in range(H - box_top):
        a = min(235, int(80 + 400 * i / (H - box_top)))
        d.line([(0, box_top + i), (W, box_top + i)], fill=(12, 10, 9, a))
    d.line([(160, box_top + 24), (W - 160, box_top + 24)], fill=(196, 160, 90, 200), width=2)
    img.paste(overlay, (0, 0), overlay)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([160, box_top - 6, 160 + 260, box_top + 48], radius=8, fill=(122, 30, 34))
    d.text((180, box_top - 2), name, font=ImageFont.truetype(FONT_B, 36), fill=(250, 240, 220))
    d.text((200, box_top + 70), line, font=ImageFont.truetype(FONT, 38), fill=(245, 238, 225), spacing=14)
    d.text((W - 240, H - 60), "▼ 다음", font=ImageFont.truetype(FONT, 24), fill=(196, 160, 90))
    small = ImageFont.truetype(FONT, 26)
    for i, label in enumerate(["자동", "건너뛰기", "기록"]):
        x = W - 520 + i * 165
        d.rounded_rectangle([x, 30, x + 150, 80], radius=24, fill=(20, 18, 16), outline=(196, 160, 90), width=2)
        tw = d.textlength(label, font=small)
        d.text((x + 75 - tw / 2, 40), label, font=small, fill=(240, 230, 210))


def main() -> None:
    src, out = sys.argv[1], sys.argv[2]
    name = sys.argv[3] if len(sys.argv) > 3 else "리나"
    line = sys.argv[4] if len(sys.argv) > 4 else "오늘부터 당신이 단장입니다.\n…열쇠가 좀 녹슬긴 했지만요!"
    right = sys.argv[5] if len(sys.argv) > 5 else ""
    bg_path = sys.argv[6] if len(sys.argv) > 6 else ""
    img = Image.open(bg_path).convert("RGB").resize((W, H)) if bg_path else background()
    if right:
        place_portrait(img, right, int(W * 0.70), dim=True)
        place_portrait(img, src, int(W * 0.30))
    else:
        place_portrait(img, src, int(W * 0.36))
    dialogue_box(img, name, line)
    img.save(out)
    print("saved", out)


if __name__ == "__main__":
    main()
