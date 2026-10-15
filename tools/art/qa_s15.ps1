$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S15'
$items=@(
 @('C01 - APPROVED','art/final/characters/C01_lina/C01_sd_idle.png'),
 @('C02 - APPROVED','art/final/characters/C02_cecile/C02_sd_idle.png'),
 @('C03 - APPROVED','art/final/characters/C03_adelheid/C03_sd_idle.png'),
 @('E01 - REVIEW','art/final/enemies/E01/E01_sd_idle.png'),
 @('B01 - REVIEW','art/final/enemies/B01/B01_sd_idle.png')
)
$font=[Drawing.Font]::new('Arial',18)
foreach($background in @('checkerboard','dark','light')) {
 $board=[Drawing.Bitmap]::new(2560,576)
 $g=[Drawing.Graphics]::FromImage($board)
 $g.Clear($(if($background -eq 'dark'){[Drawing.Color]::FromArgb(30,34,40)}else{[Drawing.Color]::FromArgb(240,240,240)}))
 if($background -eq 'checkerboard') {
  for($y=64;$y -lt 576;$y+=16){for($x=0;$x -lt 2560;$x+=16){if((($x/16)+[int](($y-64)/16))%2 -eq 0){$g.FillRectangle([Drawing.Brushes]::LightGray,$x,$y,16,16)}}}
 }
 for($i=0;$i -lt $items.Count;$i++) {
  $brush=if($background -eq 'dark'){[Drawing.Brushes]::White}else{[Drawing.Brushes]::Black}
  $g.DrawString($items[$i][0]+' | 512px 1:1',$font,$brush,$i*512+10,8)
  $b=[Drawing.Bitmap]::FromFile((Join-Path $root $items[$i][1]))
  if($b.Width -ne 512 -or $b.Height -ne 512){throw 'Comparison requires 512x512 sources'}
  $g.DrawImageUnscaled($b,$i*512,64)
  $b.Dispose()
 }
 $pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(160,210,80,80),1)
 $g.DrawLine($pen,0,551,2559,551)
 $pen.Dispose()
 $board.Save((Join-Path $qa ('sd_comparison_1to1_'+$background+'.png')),[Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$board.Dispose()
}
$font.Dispose()
'Saved 3 comparison boards: 5 sprites, unscaled, baseline local y487.'
