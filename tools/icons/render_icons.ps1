# Skill icons: SVG generate -> PNG render (run from the repository root)
#   powershell -ExecutionPolicy Bypass -File tools/icons/render_icons.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
python "$root\tools\icons\skill_icons.py"
& $godot --headless --path "$root\godot" -s "$root\tools\icons\render_svg.gd"
