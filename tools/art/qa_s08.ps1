$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S08'
$b=[Drawing.Bitmap]::new(1064,580);$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::White)
for($y=44;$y -lt 556;$y+=16){for($x=20;$x -lt 1044;$x+=16){$brush=if((([int](($x-20)/16)+[int](($y-44)/16))%2) -eq 0){[Drawing.Brushes]::LightGray}else{[Drawing.Brushes]::White};$g.FillRectangle($brush,$x,$y,16,16)}}
$font=[Drawing.Font]::new('Arial',15);$i=0
foreach($id in @('C01','C02')){
 $dir=if($id -eq 'C01'){'C01_lina'}else{'C02_cecile'}
 $im=[Drawing.Bitmap]::FromFile((Join-Path $root ('art/final/characters/'+$dir+'/'+$id+'_sd_idle.png')))
 $g.DrawImageUnscaled($im,(20+$i*512),44);$g.DrawString(($id+' sd_idle'),$font,[Drawing.Brushes]::Black,(24+$i*512),10);$im.Dispose();$i++
}
$pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(220,80,80),1);$g.DrawLine($pen,20,531,1043,531)
$g.DrawString('Foot baseline y=487 (both); 1:1 pixels',$font,[Drawing.Brushes]::Black,20,556)
$b.Save((Join-Path $root 'art/raw/qa_S08_lina_sd_comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$b.Dispose();$font.Dispose();$pen.Dispose()
# Enlarged SD head and waist for scar/weapon placement QA; non-deliverable derivatives.
$im=[Drawing.Bitmap]::FromFile((Join-Path $root 'art/final/characters/C02_cecile/C02_sd_idle.png'))
foreach($item in @(@{name='face_3x';rect=[Drawing.Rectangle]::new(150,20,270,220);scale=3},@{name='daggers_3x';rect=[Drawing.Rectangle]::new(200,265,210,130);scale=3})){
 $b=[Drawing.Bitmap]::new(($item.rect.Width*$item.scale),($item.rect.Height*$item.scale));$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::White);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
 $g.DrawImage($im,[Drawing.Rectangle]::new(0,0,$b.Width,$b.Height),$item.rect,[Drawing.GraphicsUnit]::Pixel)
 $b.Save((Join-Path $qa ('sd/'+$item.name+'.png')),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$b.Dispose()
}
$im.Dispose()
# Standing portraits side by side at identical0.5 scale.
$b=[Drawing.Bitmap]::new(1064,820);$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::FromArgb(230,230,230));$font=[Drawing.Font]::new('Arial',15)
$i=0;foreach($id in @('C01','C02')){
 $dir=if($id -eq 'C01'){'C01_lina'}else{'C02_cecile'};$im=[Drawing.Bitmap]::FromFile((Join-Path $root ('art/final/characters/'+$dir+'/'+$id+'_portrait_combat_neutral.png')))
 $g.DrawImage($im,[Drawing.Rectangle]::new((20+$i*512),44,512,768));$g.DrawString(($id+' neutral; 50% scale'),$font,[Drawing.Brushes]::Black,(24+$i*512),10);$im.Dispose();$i++
}
$b.Save((Join-Path $qa 'lina_portrait_comparison.png'),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$b.Dispose();$font.Dispose()
'Final comparison and enlarged detail QA images saved.'
