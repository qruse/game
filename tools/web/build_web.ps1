# Web build -> tools/web/cloudflare/public + build/web_r2 (then: tools/web/deploy_web.ps1)
# Run from the repository root:  powershell -ExecutionPolicy Bypass -File tools/web/build_web.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

python "$root\tools\web\prepare_web.py"
& $godot --headless --path "$root\godot" --import | Out-Null
$out = "$root\build\web"
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force $out | Out-Null
& $godot --headless --path "$root\godot" --export-release "Web" "$out\index.html"
if (-not (Test-Path "$out\index.wasm")) { throw "export failed" }

$pub = "$root\tools\web\cloudflare\public"
if (Test-Path $pub) { Remove-Item -Recurse -Force $pub }
Copy-Item -Recurse $out $pub
# Files over 20 MB go to R2 gzip-compressed (Cloudflare static file limit is 25 MiB)
python "$root\tools\web\gzip_large.py" "$pub" "$root\build\web_r2"
Get-ChildItem $pub, "$root\build\web_r2" | Select-Object Name, Length
