"""design/mockups/*.html 시안을 Chrome 으로 1600×900 PNG 로 굽는다.
사용: python design/mockups/render.py [이름 ...]   (이름 없으면 전부)
"""
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
CHROME = next(p for p in [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
] if pathlib.Path(p).exists())

names = sys.argv[1:] or [p.stem for p in HERE.glob("*.html")]
with tempfile.TemporaryDirectory() as d:
    for n in names:
        html = HERE / f"{n}.html"
        png = HERE / f"{n}.png"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        f"--user-data-dir={d}", "--window-size=1600,900", "--virtual-time-budget=3000",
                        f"--screenshot={png}", html.as_uri()], check=True, capture_output=True)
        print("png:", png.name)
