$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S15'
$utf8=[Text.UTF8Encoding]::new($false)
$allies=@(
 @{label='C01 approved';path='art/final/characters/C01_lina/C01_sd_idle.png'},
 @{label='C02 approved';path='art/final/characters/C02_cecile/C02_sd_idle.png'},
 @{label='C03 approved';path='art/final/characters/C03_adelheid/C03_sd_idle.png'}
)
$grunts=@($allies)
foreach($s in @('E01','E02','E03','E04','E05')){$grunts+=@{label=($s+' idle');path=('art/final/enemies/'+$s+'/'+$s+'_sd_idle.png')}}
$boss=@($allies[0])
foreach($pose in @('idle','attack','skill','hit','down')){$boss+=@{label=('B01 '+$pose);path=('art/final/enemies/B01/B01_sd_'+$pose+'.png')}}
$font=[Drawing.Font]::new('Arial',17)
foreach($group in @(@{name='grunts';items=$grunts},@{name='boss';items=$boss})) {
 $items=$group.items
 $width=512*$items.Count
 foreach($background in @('checkerboard','dark','light','silhouette')) {
  $board=[Drawing.Bitmap]::new($width,576)
  $g=[Drawing.Graphics]::FromImage($board)
  $g.Clear($(if($background -eq 'dark'){[Drawing.Color]::FromArgb(29,33,40)}else{[Drawing.Color]::FromArgb(242,242,242)}))
  if($background -eq 'checkerboard'){for($y=64;$y -lt 576;$y+=16){for($x=0;$x -lt $width;$x+=16){if((($x/16)+(($y-64)/16))%2 -eq 0){$g.FillRectangle([Drawing.Brushes]::LightGray,$x,$y,16,16)}}}}
  for($i=0;$i -lt $items.Count;$i++) {
   $brush=if($background -eq 'dark'){[Drawing.Brushes]::White}else{[Drawing.Brushes]::Black}
   $g.DrawString($items[$i].label+' | 512px 1:1',$font,$brush,$i*512+10,8)
   $b=[Drawing.Bitmap]::FromFile((Join-Path $root $items[$i].path))
   if($b.Width -ne 512 -or $b.Height -ne 512){throw 'Comparison requires 512x512 inputs'}
   if($background -eq 'silhouette'){
    $sil=[Drawing.Bitmap]::new(512,512)
    for($y=0;$y -lt 512;$y++){for($x=0;$x -lt 512;$x++){$a=$b.GetPixel($x,$y).A;if($a -gt 0){$sil.SetPixel($x,$y,[Drawing.Color]::FromArgb($a,32,32,32))}}}
    $g.DrawImageUnscaled($sil,$i*512,64);$sil.Dispose()
   }else{$g.DrawImageUnscaled($b,$i*512,64)}
   $b.Dispose()
  }
  $pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(170,204,70,70),1)
  $g.DrawLine($pen,0,551,$width-1,551);$pen.Dispose()
  $dest=Join-Path $qa ('remaining_'+$group.name+'_1to1_'+$background+'.png')
  $board.Save($dest,[Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose();$board.Dispose()
  $record="Deterministic QA composition; no new image generation`nDate: 2026-10-16 Asia/Seoul`nAll sprites drawn unscaled at 512px, local baseline y487 (board y551).`nBackground: $background`nSource PNG list:`n"+(@($items | ForEach-Object {$_.path}) -join "`n")+"`nEach asset has its own full image_gen prompt sidecar. Silhouette mode replaces visible RGB with solid dark while preserving source alpha."
  [IO.File]::WriteAllText([IO.Path]::ChangeExtension($dest,'.prompt.txt'),$record,$utf8)
  Write-Output $dest
 }
}
$font.Dispose()
