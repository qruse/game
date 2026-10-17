# Battle UI images: SVG generate -> PNG render into godot/ui (run from the repository root)
#   powershell -ExecutionPolicy Bypass -File tools/ui/render_ui.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
python "$root\tools\ui\ui_svg.py"
python "$root\tools\icons\hub_ui.py"
& $godot --headless --path "$root\godot" -s "$root\tools\ui\render_ui.gd"
& $godot --headless --path "$root\godot" --import | Out-Null
