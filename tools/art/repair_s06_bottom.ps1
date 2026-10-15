param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$final=Join-Path $root 'art/final/backgrounds/battle/bt_ch1_forest_clearing.png'
$backup=Join-Path $root 'art/raw/qa_S06/battle_before_bottom_edit.png'
if(Test-Path -LiteralPath $backup) { throw 'Preserve existing repair history.' }
Copy-Item -LiteralPath $final -Destination $backup
$raw=Join-Path $root 'art/raw/bt_ch1_forest_clearing_v2.png'
if(Test-Path -LiteralPath $raw) { throw 'Preserve raw versions.' }
Copy-Item -LiteralPath $Source -Destination $raw
$original=[Drawing.Bitmap]::FromFile($backup)
$native=[Drawing.Bitmap]::FromFile($raw)
$edit=[Drawing.Bitmap]::new(1920,1080,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($edit)
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$attributes=[Drawing.Imaging.ImageAttributes]::new()
$attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
$g.DrawImage($native,[Drawing.Rectangle]::new(0,0,1920,1080),0,0,$native.Width,$native.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)
$attributes.Dispose(); $g.Dispose(); $native.Dispose()
$out=[Drawing.Bitmap]::new($original)
$mask=[Drawing.Bitmap]::new(1920,1080,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$mg=[Drawing.Graphics]::FromImage($mask); $mg.Clear([Drawing.Color]::Black); $mg.Dispose()
for($y=900;$y -lt 1080;$y++) {
    $a=[Math]::Min(1.0,($y-900)/40.0)
    $v=[int][Math]::Round(255*$a)
    for($x=0;$x -lt 1920;$x++) {
        $c=$original.GetPixel($x,$y); $e=$edit.GetPixel($x,$y)
        $r=[int][Math]::Round($c.R*(1-$a)+$e.R*$a)
        $green=[int][Math]::Round($c.G*(1-$a)+$e.G*$a)
        $b=[int][Math]::Round($c.B*(1-$a)+$e.B*$a)
        $out.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,$r,$green,$b))
        $mask.SetPixel($x,$y,[Drawing.Color]::FromArgb($v,$v,$v))
    }
}
$out.Save($final,[Drawing.Imaging.ImageFormat]::Png)
$mask.Save((Join-Path $root 'art/raw/qa_S06/battle_bottom_mask.png'),[Drawing.Imaging.ImageFormat]::Png)
$out.Dispose(); $edit.Dispose(); $mask.Dispose()
$saved=[Drawing.Bitmap]::FromFile($final)
$outsideDiff=0; $nonopaque=0
for($y=0;$y -lt 1080;$y++) { for($x=0;$x -lt 1920;$x++) {
    $c=$saved.GetPixel($x,$y)
    if($c.A -ne 255) { $nonopaque++ }
    if($y -le 900 -and $c.ToArgb() -ne $original.GetPixel($x,$y).ToArgb()) { $outsideDiff++ }
} }
$grid=[Drawing.Bitmap]::new($saved)
$g=[Drawing.Graphics]::FromImage($grid)
$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::None
$pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(120,80,225,255),1)
for($x=400;$x -le 1520;$x+=160) { $g.DrawLine($pen,$x,200,$x,1000) }
for($y=200;$y -le 1000;$y+=160) { $g.DrawLine($pen,400,$y,1520,$y) }
$grid.Save((Join-Path $root 'art/raw/qa_S06_grid.png'),[Drawing.Imaging.ImageFormat]::Png)
$pen.Dispose(); $g.Dispose(); $grid.Dispose(); $saved.Dispose(); $original.Dispose()
$result=[ordered]@{id='bt_ch1_forest_clearing';edit_calls=1;total_calls=2;raw_edit=$raw;backup=$backup;mask='art/raw/qa_S06/battle_bottom_mask.png';mask_region='y901..1079; feather y901..939; everything y0..900 preserved';outside_mask_RGBA_diff_pixels=$outsideDiff;nonopaque_pixels=$nonopaque;sha256=(Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash}
[IO.File]::WriteAllText((Join-Path $root 'art/raw/qa_S06/battle_bottom_repair.json'),($result | ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 4
if($outsideDiff -ne 0 -or $nonopaque -ne 0) { throw 'Repair verification failed.' }
