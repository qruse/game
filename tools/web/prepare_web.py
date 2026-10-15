"""웹(모바일 브라우저) 빌드 준비.

1. 전투에 쓰는 그림을 art/final 에서 godot/art 로 복사한다 (웹에서는 godot 폴더 밖 파일을 못 읽는다)
2. 한글 글꼴을 godot/fonts 에 넣는다 (웹에는 시스템 글꼴이 없다)
   Noto Sans KR(OFL)에서 게임에 나오는 글자 + 자주 쓰는 한글 2,350자 + 기호만 남겨 크기를 줄인다

사용: python tools/web/prepare_web.py   (저장소 루트에서)
"""
import glob
import os
import shutil

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC_FONT = r"C:\Windows\Fonts\NotoSansKR-VF.ttf"


def copy_art() -> int:
    dst = os.path.join(ROOT, "godot", "art")
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    pats = [
        "art/final/characters/*/*_sd_*.png",
        "art/final/characters/*/*_cutin.png",
        "art/final/icons/skills/*.png",
        "art/final/backgrounds/battle/*.png",
    ]
    n = 0
    for pat in pats:
        for src in glob.glob(os.path.join(ROOT, pat)):
            rel = os.path.relpath(src, os.path.join(ROOT, "art", "final"))
            out = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            shutil.copy2(src, out)
            n += 1
    return n


def used_text() -> str:
    chars = set()
    for pat in ["godot/**/*.gd", "godot/**/*.txt", "godot/**/*.tscn"]:
        for p in glob.glob(os.path.join(ROOT, pat), recursive=True):
            with open(p, encoding="utf-8") as f:
                chars.update(f.read())
    # KS X 1001 한글 2,350자 (EUC-KR 로 표현되는 완성형)
    for cp in range(0xAC00, 0xD7A4):
        ch = chr(cp)
        try:
            ch.encode("euc-kr")
            chars.add(ch)
        except UnicodeEncodeError:
            pass
    chars.update(chr(c) for c in range(0x20, 0x7F))
    chars.update("·×→←↑↓…—–‘’“”★☆▼▲●○■□◆◇♪①②③④⑤%‰°±")
    return "".join(sorted(c for c in chars if c.isprintable()))


def make_font() -> str:
    out_dir = os.path.join(ROOT, "godot", "fonts")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "NotoSansKR-Game.ttf")
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    font = TTFont(SRC_FONT)
    sub = subset.Subsetter(opts)
    sub.populate(text=used_text())
    sub.subset(font)
    font.save(out)
    # OFL: 저작권 표시와 라이선스를 글꼴과 함께 배포한다
    name = TTFont(SRC_FONT)["name"]
    copy = name.getDebugName(0) or ""
    lic = name.getDebugName(13) or ""
    url = name.getDebugName(14) or "https://openfontlicense.org"
    with open(os.path.join(out_dir, "NotoSansKR-LICENSE.txt"), "w", encoding="utf-8") as f:
        f.write("NotoSansKR-Game.ttf is a subset of Noto Sans KR (variable).\n\n")
        f.write(copy + "\n\n" + lic + "\n\nLicense: SIL Open Font License 1.1 — " + url + "\n")
    return out


if __name__ == "__main__":
    print("art files:", copy_art())
    f = make_font()
    print("font:", f, os.path.getsize(f) // 1024, "KB")
