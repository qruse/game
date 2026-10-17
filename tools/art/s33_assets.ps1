param([ValidateSet('prepare','finish')][string]$Action='prepare',[string]$Id,[string]$Source,[int[]]$Face)
$ErrorActionPreference='Stop'
$OutputEncoding=[Console]::OutputEncoding=[Text.UTF8Encoding]::new()
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location $root
$utf8=[Text.UTF8Encoding]::new($false)
$session=Join-Path $root 'art/raw/S33_session'
$manifest=Join-Path $root 'art/manifest.csv'
$rows=Import-Csv -LiteralPath $manifest -Encoding utf8
function WriteUtf8($path,$value){[IO.File]::WriteAllText($path,$value,$utf8)}
if($Action -eq 'prepare'){
 New-Item -ItemType Directory -Force -Path $session | Out-Null
 $step=Join-Path $root 'art/steps/S33.md'
 $text=[IO.File]::ReadAllText($step)
 $feedback='- 2026-10-17 사용자 지시: 중간 확인 없이 전경→대장간→잡화점→촌장 집→N11 neutral/positive/negative→N12 neutral→N13 neutral 순서로 9장 모두 각 1회 생성. 전경은 하웰 문장 첨부, 여섯 장소 분리, 글자·라벨 없음. 실내는 전경 참조 없음. NPC 블록 원문·나이·개성 및 기존 스탠딩 형식 준수, N11 차분은 neutral 얼굴만 마스크 편집/합성. 자체 시각 검수·재생성·비교 시트 없이 기술 후처리(despill 포함)만 수행.'
 WriteUtf8 $step ($text.Replace('(아직 없음)',$feedback))
 $readme=Join-Path $root 'art/steps/README.md'
 WriteUtf8 $readme ([regex]::Replace([IO.File]::ReadAllText($readme),'(?m)^(\| \[S33\].*\| )[^|\r\n]+( \|)','$1진행 중$2'))
 $guide=[IO.File]::ReadAllText((Join-Path $root 'art/style-guide.md'))
 $chars=[IO.File]::ReadAllText((Join-Path $root 'art/characters.md'))
 $style=[regex]::Match($guide,'(?s)## 2\. STYLE_BLOCK\s*```\s*(.*?)```').Groups[1].Value.Trim()
 $negative=[regex]::Match($guide,'(?s)## 5\. NEGATIVE_BLOCK\s*```\s*(.*?)```').Groups[1].Value.Trim()
 $order=@('bg_town_harwell','bg_smithy','bg_general_store','bg_chief_house','N11_portrait_neutral','N11_portrait_positive','N11_portrait_negative','N12_portrait_neutral','N13_portrait_neutral')
 foreach($asset in $order){
  $row=$rows | Where-Object id -eq $asset
  if($row.status -ne 'todo'){throw "Expected todo: $asset"}
  if(Test-Path -LiteralPath $row.output){throw "Output exists: $($row.output)"}
  $refs=@('art/refs/style-anchor.png')
  if($asset -eq 'bg_town_harwell'){$refs+='art/refs/emblem-harwell.png'}
  $prompt="Use case: stylized-concept`nAsset: $asset; S33 game illustration.`n`n$style`n`n"
  if($row.format -eq 'bg_scene'){
   $prompt+='Background art only, no characters, painterly anime background, atmospheric lighting, wide 16:9 composition, leave the lower center area uncluttered because character portraits will stand there. Generate at 16:9 landscape, intended final canvas 1920x1080.'+"`n`n"+$row.extra+"`n`n"
   if($asset -eq 'bg_town_harwell'){
    $prompt+='Slightly elevated establishing view rather than an overhead map. Show all SIX destinations separately, with generous clear paths, air and visible gaps between the full building silhouettes; no overlapping destination facades or click areas. Spread the guild house, tavern, smithy, general store and chief house around the distinct well plaza, each with its own recognizable frontage. The guild house is a humble weathered timber structure with oak beams and plaster walls, NOT a palace, cathedral or monumental stone hall. Reference image 1: linework/rendering and medieval palette ONLY, do not copy the character, clothing or her cross motif. Reference image 2: EXACT Harwell guild heraldry for the torn blue guild banner ONLY: blue field, silver stone well, two crossed swords behind it. The emblem is the only permitted heraldic symbol. Do not add lantern heraldry. NO writing, lettering, labels, numbers, map pins, UI or borders.'
   }else{
    $prompt+='Independent eye-level interior composition. Material continuity only: humble frontier medieval oak beams, worn wood, plaster and modest stone, everyday practical furnishings. Reference image 1 is only a rendering/palette reference; do not depict its character or cross motif. No village panorama reference. No readable writing or labels, including on jars, ledgers and the village map; the map is a simple unlettered sketch.'
   }
  }else{
   $line=($chars -split '\r?\n' | Where-Object {$_ -match ('^\| '+$row.subject+' \|')}); $block=$line.Split([char]96)[1]
   if(!$block){throw "Missing verbatim NPC block $($row.subject)"}
   $prompt+='Dialogue standing portrait for a visual-novel style conversation screen: knee-up framing, character facing the viewer with the body angled slightly, eyes looking at the viewer, centered, the top of the head close to the top edge with a small margin, whole figure from head to knees inside the canvas, hands and props fully inside the canvas. Output 1024x1536 portrait PNG, genuinely transparent background, no backdrop, no ground shadow. One person only. Match existing NPC standing portrait format and comparable head scale.'+"`n`nNPC PROMPT from characters.md (verbatim):`n"+$block+"`n`n"
   if($asset -like '*_positive' -or $asset -like '*_negative'){
    $refs=@('art/final/npcs/N11_tobias/N11_portrait_neutral.png')
    $expression=if($asset -like '*_positive'){'friendly smile'}else{'displeased frown'}
    $prompt+="EDIT TARGET: input image 1 is the neutral Tobias portrait. Edit only the masked face area, eyebrows through chin, excluding the outer hair/beard silhouette, ears and clothing. Keep everything outside the face mask pixel-identical. Change the facial expression to: $expression. Keep facial identity, visibly late-60s age, wrinkles, hazel eyes and white facial hair. The accompanying face mask defines the only editable area. Do not redraw the body or shift any part of the image. Final output will composite only the masked face over the unchanged neutral original. Preserve transparency, camera, pose, staff, keys, clothing, silhouette and 1024x1536 canvas exactly."
   }else{
    $refs+='art/final/npcs/N01_martha/N01_portrait_neutral.png'
    $prompt+='Neutral expression override: calm closed mouth, quiet subtle smile or relaxed neutral expression. Personality descriptions of toothy/eager grins in the verbatim block are character references only; save expressive emotions for facial variants. Preserve ALL facial features, age, hair, markings, body type, costume and specified professional props in the verbatim block. Friendly village NPC: attractive and approachable at the stated real age, never a generic youthful anime companion. NOT a young girl; NOT a handsome young man. Do not make a grotesque enemy design. Reference 1 and reference 2 are STYLE, CANVAS, FIGURE/HEAD SCALE ONLY; do not copy their faces, hair, pose, clothing, props or color identity.'
    if($row.subject -eq 'N11'){$prompt+=' Clearly late 60s: deep but elegant laugh lines, crow feet, aged eyelids and forehead, bald crown, neat white fringe, bushy white brows and trimmed white beard; long oval mature face, warm shrewd hazel eyes, tall thin slightly stooped frame. Dignified, tidy, kindly mature handsomeness. Brown wool and moss green clothing exactly as written. Keep the carved-well staff entirely inside the canvas.'}
    if($row.subject -eq 'N12'){$prompt+=' Clearly mid 30s adult woman, mature square face and jaw, subtly aged smile lines, strong brows, sun-tanned skin, ash-blonde cropped hair and red headband; sturdy attractive broad-shouldered muscular silhouette, soot-marked cheek and small burn scar on HER left forearm. Work-worn practical leather and linen. Calm closed-mouth basic expression; no big toothy grin in this neutral variant. Keep shoulder hammer fully inside the canvas.'}
    if($row.subject -eq 'N13'){$prompt+=' Clearly mid 50s, gentle forehead creases and crow feet, round rosy-cheeked face, small bright shrewd eyes, large curled grey mustache, bald head under the small embroidered cap; short stocky plump silhouette. Tidy, likeable mature shopkeeper. Keep striped vest, measuring cord and wooden abacus distinct and fully visible. Calm closed-mouth salesman smile.'}
   }
  }
  $neg=$negative
  if($asset -eq 'bg_town_harwell'){$neg=$negative.Replace('signature, logo, UI','signature, UI'); $prompt+="`nThe required guild banner emblem is explicitly allowed; no unrelated logos.`n"}
  $prompt+="`n`n$neg"
  foreach($ref in $refs){if($ref -notlike '*N11_portrait_neutral*' -and !(Test-Path -LiteralPath $ref)){throw "Missing reference: $ref"}}
  $data=[ordered]@{id=$asset;prompt=$prompt;refs=$refs;output=$row.output;transparent=($row.format -eq 'portrait')}
  WriteUtf8 (Join-Path $session ($asset+'.json')) ($data | ConvertTo-Json -Depth 4)
 }
 Write-Output 'Prepared 9 prompts; S33 in progress.'
 exit
}

$data=Get-Content -Raw -Encoding utf8 (Join-Path $session ($Id+'.json')) | ConvertFrom-Json
$row=$rows | Where-Object id -eq $Id
if($row.status -eq 'approved'){throw 'Approved asset is immutable'}
if(Test-Path -LiteralPath $row.output){throw 'Final output already exists'}
$version=1
while(Test-Path -LiteralPath ('art/raw/'+$Id+'_v'+$version+'.png')){$version++}
$raw='art/raw/'+$Id+'_v'+$version+'.png'
Copy-Item -LiteralPath $Source -Destination $raw
New-Item -ItemType Directory -Force -Path (Split-Path $row.output) | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public class S33Technical {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];for(int y=0;y<b.Height;y++)Marshal.Copy(IntPtr.Add(d.Scan0,y*d.Stride),p,y*b.Width*4,b.Width*4);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p,int w,int h){var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);for(int y=0;y<h;y++)Marshal.Copy(p,y*w*4,IntPtr.Add(d.Scan0,y*d.Stride),w*4);b.UnlockBits(d);return b;}
 public static void Run(string source,string target,bool portrait,string neutral,int[] face){
  int w=portrait?1024:1920,h=portrait?1536:1080;
  using(var src=new Bitmap(source))using(var canvas=new Bitmap(w,h,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(canvas)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(src,new Rectangle(0,0,w,h),new Rectangle(0,0,src.Width,src.Height),GraphicsUnit.Pixel);}
   var p=Read(canvas);
   if(portrait && String.IsNullOrEmpty(neutral)){
    // Preserve native edge alpha, force deep figure interiors fully opaque.
    var a=(byte[])p.Clone();
    for(int y=0;y<h;y++)for(int x=0;x<w;x++){
     int i=(y*w+x)*4; bool inside=true,near=false;
     for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx<0||xx>=w||yy<0||yy>=h){inside=false;continue;}int al=a[(yy*w+xx)*4+3];if(al<128)inside=false;if(al>=128)near=true;}
     p[i+3]=inside?(byte)255:near?a[i+3]:(byte)0;
     if(p[i+3]==0){p[i]=p[i+1]=p[i+2]=0;}
    }
    // tools/art/despill.py equivalent, radius 10, same RGB rule.
    a=(byte[])p.Clone();
    for(int y=0;y<h;y++)for(int x=0;x<w;x++){int i=(y*w+x)*4;if(a[i+3]==0)continue;int s=Math.Min(a[i+2],a[i])-a[i+1];if(s<=8)continue;bool near=false;for(int yy=Math.Max(0,y-10);yy<=Math.Min(h-1,y+10)&&!near;yy++)for(int xx=Math.Max(0,x-10);xx<=Math.Min(w-1,x+10);xx++)if(a[(yy*w+xx)*4+3]<250){near=true;break;}if(near){p[i]=(byte)(a[i]-s);p[i+2]=(byte)(a[i+2]-s);}}
    // tools/art/unmagenta_hair.py equivalent: local blonde donor mean near alpha edges.
    a=(byte[])p.Clone();
    for(int y=0;y<h;y++)for(int x=0;x<w;x++){
     int i=(y*w+x)*4,r=a[i+2],gg=a[i+1],b=a[i];if(a[i+3]==0||!((r-gg>40&&b>=gg-15)||(r-gg<10&&b<gg-40&&gg>80)))continue;
     bool near=false;for(int yy=Math.Max(0,y-16);yy<=Math.Min(h-1,y+16)&&!near;yy++)for(int xx=Math.Max(0,x-16);xx<=Math.Min(w-1,x+16);xx++)if(a[(yy*w+xx)*4+3]<250){near=true;break;}if(!near)continue;
     double sr=0,sg=0,sb=0,n=0;for(int yy=Math.Max(0,y-12);yy<=Math.Min(h-1,y+12);yy++)for(int xx=Math.Max(0,x-12);xx<=Math.Min(w-1,x+12);xx++){int j=(yy*w+xx)*4,dr=a[j+2],dg=a[j+1],db=a[j];if(a[j+3]>200&&dr-dg>=12&&dr-dg<=80&&db<dg-25){sr+=dr;sg+=dg;sb+=db;n++;}}
     if(n>5){sr/=n;sg/=n;sb/=n;double scale=(.299*r+.587*gg+.114*b)/Math.Max(1,.299*sr+.587*sg+.114*sb);p[i+2]=(byte)Math.Min(255,sr*scale);p[i+1]=(byte)Math.Min(255,sg*scale);p[i]=(byte)Math.Min(255,sb*scale);}
    }
   }
   if(!portrait){for(int i=3;i<p.Length;i+=4)p[i]=255;}
   if(!String.IsNullOrEmpty(neutral)){
    using(var basis=new Bitmap(neutral)){var q=Read(basis);if(face==null||face.Length!=4)throw new Exception("Face bounds required");
     for(int y=face[1];y<face[3];y++)for(int x=face[0];x<face[2];x++){
      // Elliptic face mask with 3px soft inner edge; neutral pixels elsewhere untouched.
      double cx=(face[0]+face[2])/2.0,cy=(face[1]+face[3])/2.0,rx=(face[2]-face[0])/2.0,ry=(face[3]-face[1])/2.0;
      double d=Math.Sqrt(Math.Pow((x-cx)/rx,2)+Math.Pow((y-cy)/ry,2));double t=Math.Min(1,Math.Max(0,(1-d)*Math.Min(rx,ry)/3));if(t<=0)continue;int i=(y*w+x)*4;for(int c=0;c<3;c++)q[i+c]=(byte)Math.Round(q[i+c]*(1-t)+p[i+c]*t);
     }p=q;
    }
   }
   using(var result=Make(p,w,h)){result.Save(target,ImageFormat.Png);}
  }
 }
}
'@
$neutral=$null
if($Id -eq 'N11_portrait_positive' -or $Id -eq 'N11_portrait_negative'){$neutral=(Join-Path $root 'art/final/npcs/N11_tobias/N11_portrait_neutral.png')}
[S33Technical]::Run((Join-Path $root $raw),(Join-Path $root $row.output),[bool]$data.transparent,$neutral,$Face)
$processing=if($neutral){'Elliptic face-mask-only composite over final neutral; all outside pixels and alpha copied from neutral.'}elseif($data.transparent){'1024x1536 canvas, no repositioning; native edge alpha; opaque interiors; despill.py RGB algorithm and unmagenta_hair.py blonde donor algorithm, equivalent C# execution (python unavailable).'}else{'1920x1080 RGB-opaque PNG, canvas resize only.'}
$record="Asset: $Id`nStep: S33`nDate: 2026-10-17 (Asia/Seoul)`nTool: built-in image_gen`nModel: identifier not exposed by built-in tool`nAttempts: 1; no retries`nTool options: transparent_background=$($data.transparent)`nRaw: $raw`nReferences (attachment order):`n$($data.refs -join "`n")`nPostprocessing: $processing`nFace bounds: $($Face -join ',')`n`nFULL PROMPT:`n$($data.prompt)`n"
WriteUtf8 ([IO.Path]::ChangeExtension((Join-Path $root $row.output),'.prompt.txt')) $record
$text=[IO.File]::ReadAllText($manifest)
$old=($text -split '\r?\n' | Where-Object {$_ -match ('^'+[regex]::Escape($Id)+',')})
$row.status='generated'
$row.refs=$data.refs -join ';'
$row.notes="2026-10-17 S33 built-in image_gen 1회; raw=$raw; $processing 자체 시각 검수·재생성·비교 시트 없음; 사용자·Claude 검토 대기"
$new=($row | ConvertTo-Csv -NoTypeInformation)[1]
WriteUtf8 $manifest ($text.Replace($old,$new))
$all=Import-Csv -LiteralPath $manifest -Encoding utf8 | Where-Object step -eq 'S33'
if(@($all | Where-Object status -ne 'generated').Count -eq 0){$readme=Join-Path $root 'art/steps/README.md';WriteUtf8 $readme ([regex]::Replace([IO.File]::ReadAllText($readme),'(?m)^(\| \[S33\].*\| )[^|\r\n]+( \|)','$1검토 대기$2'))}
$image=[Drawing.Image]::FromFile((Join-Path $root $row.output));Write-Output "$Id generated: $($image.Width)x$($image.Height) $($image.PixelFormat); $($row.output)";$image.Dispose()
