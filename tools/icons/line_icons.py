"""흰 선 아이콘 (Claude 담당) → art/src/ui/i_*.svg. Godot 에서 modulate 로 색을 입힌다.
24×24 좌표, 선 1.7px. tools/ui/render_ui.ps1 이 2배(96px)로 굽는다.
시안: design/mockups/guild_desk_v5.html
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "src", "ui")
S = 'fill="none" stroke="#fff" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"'

ICONS = {
    "scroll": f'<path d="M6 4h11a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H7" {S}/><path d="M6 4a2 2 0 0 0-2 2v1h4V6a2 2 0 0 0-2-2zM7 20a2 2 0 0 1-2-2V7" {S}/><path d="M10 9h6M10 12.5h6M10 16h3" {S}/>',
    "scope": f'<path d="M3.5 14.5l11-7 2.5 4-11 7z" {S}/><path d="M15.5 6.5l3-2 2.5 4-3 2" {S}/><path d="M10 16l-2 5M12 15l3 6" {S}/>',
    "people": f'<circle cx="9" cy="8" r="3.2" {S}/><path d="M3 20c0-3.6 2.7-6 6-6s6 2.4 6 6" {S}/><path d="M15.5 5.2a3 3 0 0 1 0 5.6M17.5 14.3c2 .8 3.5 2.8 3.5 5.7" {S}/>',
    "hammer": f'<path d="M13 6l5 5M9.5 9.5L4 15a2 2 0 0 0 0 2.8l2.2 2.2a2 2 0 0 0 2.8 0l5.5-5.5" {S}/><path d="M11 4.5l3-1.5 7 7-1.5 3z" {S}/>',
    "book": f'<path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15H6.5A1.5 1.5 0 0 0 5 19.5z" {S}/><path d="M5 19.5A1.5 1.5 0 0 0 6.5 21H19v-3" {S}/><path d="M12 7l2 3-2 3-2-3z" {S}/>',
    "town": f'<path d="M3 11l9-7 9 7" {S}/><path d="M5.5 9.5V20h13V9.5" {S}/><path d="M10 20v-5h4v5" {S}/>',
    "map": f'<path d="M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2z" {S}/><path d="M9 4v14M15 6v14" {S}/>',
    "moon": f'<path d="M19.5 14.5A8 8 0 1 1 9.5 4.5a6.5 6.5 0 0 0 10 10z" {S}/>',
    "sword": f'<path d="M14.5 3.5H20.5V9.5L10 20l-6-6z" {S}/><path d="M5 13l6 6M3 21l3-3" {S}/>',
    "gear": f'<circle cx="12" cy="12" r="3" {S}/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1" {S}/>',
    "close": f'<path d="M5 5l14 14M19 5L5 19" {S}/>',
    "back": f'<path d="M15 4l-8 8 8 8" {S}/>',
    "check": f'<path d="M5 12.5l4.5 4.5L19 7.5" {S}/>',
    "plus": f'<path d="M12 5v14M5 12h14" {S}/>',
    "lock": f'<rect x="5" y="10.5" width="14" height="10" rx="1.5" {S}/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" {S}/>',
    "star": f'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8 6.8 19.6l1-5.8-4.3-4.1 5.9-.8z" {S}/>',
    "chat": f'<path d="M4 5h16v11H10l-4 3.5V16H4z" {S}/>',
    "shop": f'<path d="M4 9l1.5-5h13L20 9" {S}/><path d="M4 9h16v2.5a2.7 2.7 0 0 1-5.3 0 2.7 2.7 0 0 1-5.4 0A2.7 2.7 0 0 1 4 11.5z" {S}/><path d="M5.5 13.5V20h13v-6.5" {S}/>',
    "anvil": f'<path d="M3 7h13c0 3 2 4 5 4v1H15l-2 3h-6L5 12H3z" {S}/><path d="M7 15l-1.5 5h11L15 15" {S}/>',
    "mug": f'<path d="M5 6h10v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1z" {S}/><path d="M15 9h2.5A2.5 2.5 0 0 1 20 11.5v2a2.5 2.5 0 0 1-2.5 2.5H15" {S}/><path d="M8 10v6M11.5 10v6" {S}/>',
    "well": f'<path d="M4 10l8-5 8 5" {S}/><path d="M6 10v4M18 10v4M12 5v4" {S}/><path d="M4 14h16v6H4z" {S}/><path d="M4 17h16" {S}/>',
    "house": f'<path d="M4 20V9l8-5 8 5v11z" {S}/><path d="M9.5 20v-6h5v6" {S}/>',
    "ledger": f'<path d="M3 6c3-1.5 6-1.5 9 0v14c-3-1.5-6-1.5-9 0z" {S}/><path d="M21 6c-3-1.5-6-1.5-9 0v14c3-1.5 6-1.5 9 0z" {S}/>',
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for k, body in ICONS.items():
        with open(os.path.join(OUT, f"i_{k}.svg"), "w", encoding="utf-8") as f:
            f.write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="48" height="48">{body}</svg>')
    print("line icons:", len(ICONS))
