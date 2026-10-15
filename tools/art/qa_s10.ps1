$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S10'
$font=[Drawing.Font]::new('Arial',20)
$board=[Drawing.Bitmap]::new(1536,568)
$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(230,230,230))
for($x=0;$x -lt 1536;$x+=24){for($y=56;$y -lt 568;$y+=24){if((($x/24)+[int](($y-56)/24))%2 -eq 0){$g.FillRectangle([Drawing.Brushes]::White,$x,$y,24,24)}}}
for($i=0;$i -lt 3;$i++){
 $folder=@('C01_lina','C02_cecile','C03_adelheid')[$i];$id=@('C01','C02','C03')[$i]
 $b=[Drawing.Bitmap]::FromFile((Join-Path $root "art/final/characters/$folder/${id}_sd_idle.png"))
 $g.DrawString(@('LINA - APPROVED','CECILE - APPROVED','ADELHEID - REVIEW')[$i],$font,[Drawing.Brushes]::Black,$i*512+10,12)
 $g.DrawImageUnscaled($b,$i*512,56);$b.Dispose()
}
$pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(150,220,70,70),1)
$g.DrawLine($pen,0,543,1535,543);$pen.Dispose()
$board.Save((Join-Path $root 'art/raw/qa_S10_lina_cecile_sd_comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$board.Dispose()
$board=[Drawing.Bitmap]::new(1536,824);$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(225,225,225))
for($i=0;$i -lt 3;$i++){
 $folder=@('C01_lina','C02_cecile','C03_adelheid')[$i];$id=@('C01','C02','C03')[$i]
 $b=[Drawing.Bitmap]::FromFile((Join-Path $root "art/final/characters/$folder/${id}_portrait_combat_neutral.png"))
 $g.DrawString("$id portrait",$font,[Drawing.Brushes]::Black,$i*512+10,10)
 $g.DrawImage($b,[Drawing.Rectangle]::new($i*512,56,512,768));$b.Dispose()
}
$board.Save((Join-Path $qa 'portrait_comparison.png'),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$board.Dispose()
$board=[Drawing.Bitmap]::new(1536,1024);$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(220,220,220))
$p=[Drawing.Bitmap]::FromFile((Join-Path $root 'art/final/characters/C03_adelheid/C03_portrait_combat_neutral.png'))
$s=[Drawing.Bitmap]::FromFile((Join-Path $root 'art/final/characters/C03_adelheid/C03_sd_idle.png'))
$g.DrawImage($p,[Drawing.Rectangle]::new(0,0,768,768),[Drawing.Rectangle]::new(240,0,600,600),[Drawing.GraphicsUnit]::Pixel)
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($s,[Drawing.Rectangle]::new(768,0,768,768),[Drawing.Rectangle]::new(120,0,300,300),[Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($s,[Drawing.Rectangle]::new(0,768,768,256),[Drawing.Rectangle]::new(50,240,450,150),[Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($p,[Drawing.Rectangle]::new(768,768,768,256),[Drawing.Rectangle]::new(0,700,1024,341),[Drawing.GraphicsUnit]::Pixel)
$p.Dispose();$s.Dispose();$g.Dispose();$font.Dispose()
$board.Save((Join-Path $qa 'face_braid_hands.png'),[Drawing.Imaging.ImageFormat]::Png);$board.Dispose()
'QA comparison and detail previews saved.'
