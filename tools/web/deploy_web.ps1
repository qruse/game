# Upload big files (build/web_r2/*.gz) to the R2 bucket, then deploy the Worker + static files.
# Run after build_web.ps1, from the repository root:  powershell -ExecutionPolicy Bypass -File tools/web/deploy_web.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$env:PATH = "$env:LOCALAPPDATA\node-portable\node-v24.20.0-win-x64;$env:PATH"
$bucket = "project-d20-web"

Push-Location "$root\tools\web\cloudflare"
try {
    foreach ($f in Get-ChildItem "$root\build\web_r2" -File) {
        & npx wrangler r2 object put "$bucket/$($f.Name)" --file $f.FullName --remote --content-encoding gzip
        if ($LASTEXITCODE -ne 0) { throw "R2 upload failed: $($f.Name)" }
    }
    & npx wrangler deploy
    if ($LASTEXITCODE -ne 0) { throw "wrangler deploy failed" }
} finally {
    Pop-Location
}
