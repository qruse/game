$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$before=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'art/raw/qa_S06/existing_assets_before.json') | ConvertFrom-Json
$changed=@($before | Where-Object { -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 })
$rows=Import-Csv -Encoding UTF8 (Join-Path $root 'art/manifest.csv')
$assets=@()
foreach($row in @($rows | Where-Object step -eq 'S06')) {
    $path=Join-Path $root $row.output
    $img=[Drawing.Bitmap]::FromFile($path)
    $nonopaque=0
    for($y=0;$y -lt $img.Height;$y++) { for($x=0;$x -lt $img.Width;$x++) { if($img.GetPixel($x,$y).A -ne 255) { $nonopaque++ } } }
    $assets+=[pscustomobject]@{id=$row.id;status=$row.status;width=$img.Width;height=$img.Height;nonopaque_pixels=$nonopaque;prompt_exists=(Test-Path -LiteralPath ($path -replace '\.png$','.prompt.txt'));sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
    $img.Dispose()
}
$battle=[Drawing.Bitmap]::FromFile((Join-Path $root 'art/final/backgrounds/battle/bt_ch1_forest_clearing.png'))
$grid=[Drawing.Bitmap]::FromFile((Join-Path $root 'art/raw/qa_S06_grid.png'))
$gridDifferences=0; $outsideGridDifferences=0; $offLineDifferences=0
for($y=0;$y -lt 1080;$y++) { for($x=0;$x -lt 1920;$x++) {
    if($battle.GetPixel($x,$y).ToArgb() -ne $grid.GetPixel($x,$y).ToArgb()) {
        $gridDifferences++
        if($x -lt 400 -or $x -gt 1520 -or $y -lt 200 -or $y -gt 1000) { $outsideGridDifferences++ }
        elseif((($x-400)%160) -ne 0 -and (($y-200)%160) -ne 0) { $offLineDifferences++ }
    }
} }
$battle.Dispose(); $grid.Dispose()
$repair=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'art/raw/qa_S06/battle_bottom_repair.json') | ConvertFrom-Json
$result=[ordered]@{existing_assets_checked=$before.Count;existing_assets_changed=$changed.Count;assets=$assets;grid_difference_pixels=$gridDifferences;grid_outside_rectangle_diff=$outsideGridDifferences;grid_off_160px_lines_diff=$offLineDifferences;repair_outside_mask_RGBA_diff=$repair.outside_mask_RGBA_diff_pixels;S05_all_approved=(@($rows | Where-Object { $_.step -eq 'S05' -and $_.status -ne 'approved' }).Count -eq 0);S07_all_todo=(@($rows | Where-Object { $_.step -eq 'S07' -and $_.status -ne 'todo' }).Count -eq 0)}
[IO.File]::WriteAllText((Join-Path $root 'art/raw/qa_S06/verification.json'),($result | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 5
if($changed.Count -or $outsideGridDifferences -or $offLineDifferences -or $repair.outside_mask_RGBA_diff_pixels -or $gridDifferences -eq 0) { throw 'Preservation/grid verification failed.' }
foreach($a in $assets) { if($a.width -ne 1920 -or $a.height -ne 1080 -or $a.nonopaque_pixels -ne 0 -or -not $a.prompt_exists -or $a.status -ne 'generated') { throw 'Final asset verification failed.' } }
if(-not $result.S05_all_approved -or -not $result.S07_all_todo) { throw 'Step status verification failed.' }
