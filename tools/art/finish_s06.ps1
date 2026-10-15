param(
    [Parameter(Mandatory=$true)][string]$Id,
    [Parameter(Mandatory=$true)][string]$Source
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$row = Import-Csv -Encoding UTF8 (Join-Path $root 'art/manifest.csv') | Where-Object id -eq $Id
if ($row.step -ne 'S06' -or $row.status -eq 'approved') { throw 'Only unapproved S06 assets may be processed.' }
$final = Join-Path $root $row.output
if (Test-Path -LiteralPath $final) { throw "Existing final must be preserved: $final" }
$version = 1
do { $raw = Join-Path $root "art/raw/${Id}_v$version.png"; $version++ } while (Test-Path -LiteralPath $raw)
Copy-Item -LiteralPath $Source -Destination $raw
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($final)) | Out-Null
$src = [Drawing.Bitmap]::FromFile($raw)
$nativeSize = @($src.Width, $src.Height)
$dst = [Drawing.Bitmap]::new(1920, 1080, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [Drawing.Graphics]::FromImage($dst)
$g.Clear([Drawing.Color]::Black)
$g.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$attributes = [Drawing.Imaging.ImageAttributes]::new()
$attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
$g.DrawImage($src, [Drawing.Rectangle]::new(0,0,1920,1080),0,0,$src.Width,$src.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)
$attributes.Dispose(); $g.Dispose(); $src.Dispose()
$dst.Save($final,[Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose()
$gridPath = $null
if ($Id -eq 'bt_ch1_forest_clearing') {
    $saved = [Drawing.Bitmap]::FromFile($final)
    $grid = [Drawing.Bitmap]::new($saved)
    $g = [Drawing.Graphics]::FromImage($grid)
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::None
    $pen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(120,80,225,255),1)
    for ($x=400; $x -le 1520; $x+=160) { $g.DrawLine($pen,$x,200,$x,1000) }
    for ($y=200; $y -le 1000; $y+=160) { $g.DrawLine($pen,400,$y,1520,$y) }
    $gridPath = Join-Path $root 'art/raw/qa_S06_grid.png'
    $grid.Save($gridPath,[Drawing.Imaging.ImageFormat]::Png)
    $pen.Dispose(); $g.Dispose(); $grid.Dispose(); $saved.Dispose()
}
$check = [Drawing.Bitmap]::FromFile($final)
$transparentPixels = 0
for($y=0;$y -lt $check.Height;$y++) { for($x=0;$x -lt $check.Width;$x++) { if($check.GetPixel($x,$y).A -ne 255) { $transparentPixels++ } } }
$result = [ordered]@{ id=$Id; native_size=$nativeSize; raw=$raw; final=$final; final_size=@($check.Width,$check.Height); nonopaque_pixels=$transparentPixels; sha256=(Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash; grid=$gridPath; postprocess='Full-frame HighQualityBicubic resize to 1920x1080; opaque RGB; no crop or background removal. Grid only on separate QA copy.' }
$check.Dispose()
$enc = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $root "art/raw/qa_S06/${Id}_technical.json"),($result | ConvertTo-Json -Depth 5),$enc)
$result | ConvertTo-Json -Depth 5
