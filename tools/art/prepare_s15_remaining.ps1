$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class S15FacePatch {
 public static long Run(string original,string edit,string output) {
  using(var a=new Bitmap(original))using(var b=new Bitmap(edit))using(var path=new GraphicsPath()) {
   if(a.Size!=b.Size)throw new Exception("Face edit changed source dimensions");
   path.AddPolygon(new Point[]{new Point(494,297),new Point(539,321),new Point(582,238),new Point(632,299),new Point(684,314),new Point(712,360),new Point(713,395),new Point(680,406),new Point(530,418),new Point(499,395),new Point(494,344)});
   long outsideDiff=0;
   for(int y=230;y<425;y++)for(int x=485;x<725;x++)if(path.IsVisible(x,y))a.SetPixel(x,y,b.GetPixel(x,y));
   using(var src=new Bitmap(original))for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++)if(!path.IsVisible(x,y)&&a.GetPixel(x,y)!=src.GetPixel(x,y))outsideDiff++;
   if(outsideDiff!=0)throw new Exception("Face patch changed unmasked pixels");
   a.Save(output,ImageFormat.Png);return outsideDiff;
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$plan=Get-Content -Encoding UTF8 -Raw (Join-Path $root 'art/raw/qa_S15/plan_20261016.json') | ConvertFrom-Json
$runs=@()
foreach($p in $plan) {
 $id=$p.id
 $existing=@(Get-ChildItem (Join-Path $root 'art/raw') -File | Where-Object Name -Match ('^'+[regex]::Escape($id)+'_v(\d+)\.png$'))
 $v=1
 foreach($e in $existing){if($e.Name -match '_v(\d+)\.png$'){$v=[Math]::Max($v,[int]$Matches[1]+1)}}
 $source=$p.source
 $refs=@($p.refs)
 $history=''
 if($p.editSource) {
  $original=Join-Path $root ('art/raw/'+$id+'_v'+$v+'.png')
  if(Test-Path $original){throw "Raw exists: $original"}
  Copy-Item -LiteralPath $source -Destination $original
  [IO.File]::WriteAllText([IO.Path]::ChangeExtension($original,'.prompt.txt'),("Model: built-in image_gen (underlying model identifier not exposed)`nDate: 2026-10-16 Asia/Seoul`nReferences: "+($refs -join ';')+"`nFULL PROMPT`n"+$p.prompt),$utf8)
  $v++
  if($id -eq 'E02_sd_idle') {
   $modelEdit=Join-Path $root 'art/raw/E02_sd_idle_face_model_edit_v1.png'
   if(Test-Path $modelEdit){throw 'Face edit raw exists'}
   Copy-Item -LiteralPath $p.editSource -Destination $modelEdit
   [IO.File]::WriteAllText([IO.Path]::ChangeExtension($modelEdit,'.prompt.txt'),("Model: built-in image_gen`nDate: 2026-10-16 Asia/Seoul`nReference: "+$original+"`nFULL EDIT PROMPT`n"+$p.editPrompt),$utf8)
   $composite=Join-Path $root 'art/raw/E02_sd_idle_face_composite_v1.png'
   $outside=[S15FacePatch]::Run($original,$modelEdit,$composite)
   $source=$composite
   $history="`nLocal face edit composited with a polygon confined to exposed upper face. Outside-mask RGBA changed pixels: $outside. Body, bow, mask and hair retained from original.`nEdit source: art/raw/E02_sd_idle_face_model_edit_v1.png"
   [IO.File]::WriteAllText([IO.Path]::ChangeExtension($composite,'.prompt.txt'),("Deterministic composite of image_gen face edit`nDate: 2026-10-16 Asia/Seoul`n"+$history+"`nEDIT PROMPT`n"+$p.editPrompt),$utf8)
  } else { $source=$p.editSource; $history="`nPose correction reference: "+$original+'; art/final/enemies/B01/B01_sd_idle.png' }
 }
 & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'finish_s15_remaining_asset.ps1') -Id $id -Source $source -Version $v -MaxHeight $p.maxHeight
 if($LASTEXITCODE -ne 0){throw "Finalization failed: $id"}
 $raw='art/raw/'+$id+'_v'+$v+'.png'
 $output='art/final/enemies/'+$id.Split('_')[0]+'/'+$id+'.png'
 $record="Model: built-in image_gen; exact underlying model identifier not exposed`nDate: 2026-10-16 (Asia/Seoul)`nTool: image_gen.imagegen; transparent_background=true`nSource: $raw`nReferences in original attached order:`n"+($refs -join "`n")+"`nPostprocess: native transparency retained, uniform aspect-preserving resampling onto 512x512; max height "+$p.maxHeight+" / width 488; grounded silhouette y487; alpha255 interior with antialiased 1px edges; no mirror, no deformation.`n"+$history+"`nFULL ORIGINAL PROMPT`n"+$p.prompt
 if($p.editPrompt){$record+="`n`nFULL CORRECTION PROMPT`n"+$p.editPrompt}
 foreach($dest in @([IO.Path]::ChangeExtension((Join-Path $root $raw),'.prompt.txt'),[IO.Path]::ChangeExtension((Join-Path $root $output),'.prompt.txt'))){[IO.File]::WriteAllText($dest,$record,$utf8)}
 $runs+=@{id=$id;raw=$raw;output=$output;version=$v;edit=[bool]$p.editSource;maxHeight=$p.maxHeight}
 $qaFolder=Join-Path $root ('art/raw/qa_S15/'+$id)
 foreach($preview in Get-ChildItem $qaFolder -Filter '*.png') { [IO.File]::WriteAllText([IO.Path]::ChangeExtension($preview.FullName,'.prompt.txt'),("Deterministic QA preview; no model generation`nDate: 2026-10-16 Asia/Seoul`nSource: $output`n512px unscaled over "+$preview.BaseName+" background.`nFull source prompt: "+[IO.Path]::ChangeExtension($output,'.prompt.txt')),$utf8) }
}
[IO.File]::WriteAllText((Join-Path $root 'art/raw/qa_S15/runs_20261016.json'),($runs | ConvertTo-Json -Depth 4),$utf8)
