$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class S15Verify {
 public static int[] Check(string filename) {
  using(var b=new Bitmap(filename)) {
   if(b.Width!=512||b.Height!=512)throw new Exception("Wrong dimensions: "+filename);
   var data=b.LockBits(new Rectangle(0,0,512,512),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   byte[] p=new byte[data.Stride*512];Marshal.Copy(data.Scan0,p,0,p.Length);b.UnlockBits(data);
   int x0=512,y0=512,x1=-1,y1=-1,opaque=0,zero=0,partial=0,deepPartial=0;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++){
    int a=p[y*data.Stride+x*4+3];
    if(a==0)zero++;else{if(a==255)opaque++;else partial++;x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
    if(a>0&&a<255&&x>1&&x<510&&y>1&&y<510){bool interior=true;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++)if(p[(y+dy)*data.Stride+(x+dx)*4+3]<128)interior=false;if(interior)deepPartial++;}
   }
   if(y1!=487||x0<8||x1>503||y0<0||opaque<10000||zero<10000||partial==0||deepPartial!=0)throw new Exception("Independent alpha/baseline QA failed: "+filename);
   return new[]{x0,y0,x1,y1,opaque,zero,partial,deepPartial};
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S15'
$baseline=Get-Content -Encoding UTF8 -Raw (Join-Path $qa 'sources_20261016.json') | ConvertFrom-Json
foreach($b in $baseline.baseline){if((Get-FileHash -LiteralPath $b.Path).Hash -ne $b.Hash){throw "Approved file changed: $($b.Path)"}}
$runs=Get-Content -Encoding UTF8 -Raw (Join-Path $qa 'runs_20261016.json') | ConvertFrom-Json
$results=@()
foreach($r in $runs) {
 $path=Join-Path $root $r.output
 $stats=[S15Verify]::Check($path)
 $sidecar=[IO.Path]::ChangeExtension($path,'.prompt.txt')
 if(!(Test-Path $sidecar)){throw "Missing prompt: $path"}
 $text=[IO.File]::ReadAllText($sidecar)
 foreach($required in @('Model:','2026-10-16','FULL ORIGINAL PROMPT','References','facing left')){if(!$text.Contains($required)){throw "Incomplete prompt record: $sidecar ($required)"}}
 if($r.id.StartsWith('E') -and !$text.Contains('crude and homely-looking grunt')){throw 'Missing grunt format text'}
 $results+=@{id=$r.id;size=@(512,512);bbox=@($stats[0..3]);alpha255=$stats[4];alpha0=$stats[5];partialAlpha=$stats[6];deepPartialAlpha=$stats[7];baseline=487;sha256=(Get-FileHash $path).Hash;prompt=([IO.Path]::ChangeExtension($r.output,'.prompt.txt'));raw=$r.raw}
}
if($results.Count -ne 9){throw 'Expected exactly 9 new deliverables'}
$manifest=Join-Path $root 'art/manifest.csv'
$content=[IO.File]::ReadAllText($manifest)
$oldApprovedLine=[regex]::Match($content,'(?m)^B01_sd_idle,[^\r\n]*').Value
$droppedBefore=@([regex]::Matches($content,'(?m)^E0[1-5]_sd_(attack|hit),[^\r\n]*') | ForEach-Object Value)
foreach($r in $runs) {
 $id=$r.id
 $note='2026-10-16 S15 9장 제작; built-in image_gen; 512x512 RGBA; 왼쪽3/4; 기준선y487; 내부알파255; 1:1동료/실루엣QA; raw v'+$r.version+'; prompt기록; 커밋없음'
 if($id.StartsWith('E')){$note+='; 저채도/최소장식/거친얼굴; idle만'}else{$note+='; 승인B01_idle 동일인물/체격 참조'}
 if($id -eq 'E02_sd_idle'){$note+='; 얼굴편집1회; 마스크밖RGBA차이0'}
 if($id -eq 'B01_sd_skill'){$note+='; 체격보정1회; 깊게굽힌무릎/양손머리위도끼'}
 if($id -eq 'B01_sd_down'){$note+='; 도끼위치보정1회; 무릎꿇은자세/접힌다리접지y487'}
 if($id -eq 'E01_sd_idle'){$note+='; 사용자요청재제작; 이전시안raw보존'}
 $pattern='(?m)^'+[regex]::Escape($id)+',[^\r\n]*'
 $line=[regex]::Match($content,$pattern).Value
 if(!$line){throw "Manifest row missing $id"}
 if($line.Contains(',approved,')){throw "Refusing approved row: $id"}
 $updated=[regex]::Replace($line,',todo,.*$',(',generated,"'+$note+'"'))
 if($updated -eq $line){throw "Expected todo row: $id"}
 $content=[regex]::Replace($content,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{param($match) $updated})
}
if([regex]::Match($content,'(?m)^B01_sd_idle,[^\r\n]*').Value -cne $oldApprovedLine){throw 'Approved B01 manifest row changed'}
$droppedAfter=@([regex]::Matches($content,'(?m)^E0[1-5]_sd_(attack|hit),[^\r\n]*') | ForEach-Object Value)
if(($droppedBefore -join "`n") -cne ($droppedAfter -join "`n")){throw 'Dropped grunt action rows changed'}
[IO.File]::WriteAllText($manifest,$content,$utf8)
$readme=Join-Path $root 'art/steps/README.md'
$text=[IO.File]::ReadAllText($readme).Replace('| 10 | P1 | 진행 중 |','| 10 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($readme,$text,$utf8)
$verification=@{date='2026-10-16';count=9;assets=$results;approvedHashesUnchanged=$true;approvedBossManifestUnchanged=$true;droppedRowsUnchanged=$true;faceOutsideMaskRgbaDiff=0;qaFailuresAtThreeAttempts=@();mode='built-in image_gen';commitPerformed=$false}
[IO.File]::WriteAllText((Join-Path $qa 'verification_remaining_20261016.json'),($verification | ConvertTo-Json -Depth 7),$utf8)
$step=Join-Path $root 'art/steps/S15.md'
$text=[IO.File]::ReadAllText($step)+"`n## 2026-10-16 추가 9장 제작 보고`n`n- 만든 것: E01~E05_sd_idle, B01_sd_attack/skill/hit/down. 각 art/final/enemies/<ID>/ 아래 PNG 및 .prompt.txt. manifest generated, S15 검토 대기.`n- 재시도: E01 사용자 요청 재제작. 이번 제작 중 E02 얼굴 수정 1회(얼굴 밖 RGBA 차이 0), B01 skill 체격 보정 1회, B01 down 도끼 위치 보정 1회. 3회 실패 없음.`n- QA: 9장 512x512 RGBA, 접지 기준선 y487, 안쪽 알파255, 외곽 반투명. 동료 3명과 잡몹 5종, 리나+보스 idle/4동작을 1:1로 비교. 밝음/어두움/체커/실루엣 8개 비교판.`n- 확인 요청: 5종 실루엣, 동료 대비 수수함, 보스 동작별 체격과 위압감. 자세에 따른 원근/접힌 다리 때문에 전체 bbox 높이는 달라짐. 보스 down은 발을 뒤로 접고 무릎으로 접지.`n- 상세: art/raw/qa_S15/QA_remaining_20261016.md 및 verification_remaining_20261016.json. remaining_* 비교판이 이번 9장 최종본, 기존 sd_comparison_*은 중간확인 당시 이력.`n- 승인 B01 idle PNG/prompt 및 리나 PNG SHA256 불변. 잡몹 dropped 행 불변. 커밋 없음. S16 진행 없음.`n"
[IO.File]::WriteAllText($step,$text,$utf8)
$results | ConvertTo-Json -Depth 4
