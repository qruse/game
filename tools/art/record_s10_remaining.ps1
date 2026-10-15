$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location $root
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S10_remaining'
$verification=Get-Content -Raw -Encoding UTF8 "$qa/verification.json"|ConvertFrom-Json
if($verification.saved_png_checks.Count -ne 18 -or $verification.face_checks.Count -ne 10){throw 'Incomplete independent QA'}
$path=(Resolve-Path art/manifest.csv).Path
$text=[IO.File]::ReadAllText($path)
$rows=@(Import-Csv -Encoding UTF8 $path | Where-Object {$_.step -eq 'S10' -and $_.format -ne 'icon' -and $_.status -eq 'todo'})
if($rows.Count -ne 16){throw 'Expected exactly 16 new assets:11 portraits+4 SD+1cutin'}
foreach($r in $rows){
 $meta=Get-Content -Raw -Encoding UTF8 (Join-Path $qa ($r.id+'.json'))|ConvertFrom-Json
 foreach($reference in $meta.refs){if(-not(Test-Path -LiteralPath $reference)){throw "Missing ref $reference"}}
 $output=Join-Path $root $r.output
 if(-not(Test-Path -LiteralPath $output)){throw "Missing output $output"}
 $sidecar=[IO.Path]::ChangeExtension($output,'.prompt.txt')
 if(Test-Path $sidecar){throw "Refusing sidecar overwrite $sidecar"}
 $calls=if($r.id -eq 'C03_sd_attack'){3}elseif($r.id -eq 'C03_cutin'){2}else{1}
 $record="Model/tool: OpenAI built-in image_gen. Exact backend model identifier is not exposed; not inferred.`nGeneration date: 2026-10-16 (Asia/Seoul).`nNo CLI/API fallback. Image calls: $calls; retries/local model repairs: $($calls-1).`nReferences in actual attachment order:`n"
 for($i=0;$i -lt $meta.refs.Count;$i++){$record+="$($i+1). $($meta.refs[$i])`n"}
 $record+="`nFULL PROMPT (verbatim):`n$($meta.prompt)`n`nOriginal raw output: art/raw/$($r.id)_v1.png (preserved unmodified).`nDefault tool source: $($meta.source)`n"
 if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){
  $record+="`nPostprocessing: guide3.1.4 explicit face-mask composite. Neutral face crop: $($meta.source_crop -join ',') enlarged1024square for local expression editing; model result uniformly mapped back to that exact crop. Blend RGB through the stored exposed-face polygons with3px inward feather. Entire original neutral alpha channel and all RGBA outside the mask retained. Canvas1024x1536, body, props, clothing, head silhouette and hair outside mask never moved or mirrored. Crop and mask are QA/edit working files, not game assets. Outfit sheet and design inherited from the neutral target; actual attached reference list above is exact. Saved-PNG independent comparison is below.`n"
  $entry=@($verification.face_checks|Where-Object {$_.id -eq $r.id})[0]
  $record+="Face audit: $($entry.qa|ConvertTo-Json -Compress)`nMask, difference and detail evidence: art/raw/qa_S10_remaining/$($r.id)/`n"
 }elseif($r.format -eq 'portrait'){
  $record+="`nPostprocessing: preserve native1024x1536 RGB, position, framing and handedness. Normalize opaque interior alpha255; preserve soft native1px silhouette alpha; remove disconnected low-alpha halo. No movement, crop, mirror or stretch. Approved CASUAL sheet is primary outfit/prop authority: charcoal oversized knee-length nightshirt, sleeves covering fingers, cream knitted shawl, loosened single braid, thick knitted stockings. Ordinary open book in left sleeve and candle holder in right sleeve. No staff, chain-bound grimoire, weapon, combat cape or boots. House slippers belong to approved outfit but are below the knee-up crop and are not visible. Neutral is calm, mouth closed.`n"
 }elseif($r.format -eq 'sd'){
  $record+="`nPostprocessing: transparent trim, uniform resize to512square, horizontal centering and actual boot baseline487; no mirroring. Opaque interior alpha255; soft silhouette antialias retained1px, not binary. Head width compared at1:1 with approved C03 idle and Lina/Cecile same action. Anatomical right hand staff; left hand chained grimoire. Far left shoulder braid, round iron-rim glasses and golden eyes visually checked. No combat particle/effect asset rendered.`n"
  if($r.id -eq 'C03_sd_down'){$record+="Down uses uniform scale0.4 for same physical head size, avoiding filling464px height with kneeling sprite. Translate completed sprite down14px with no resampling to place visible boot at487; staff tip/hem may extend below baseline but remain inside canvas. foot_alignment.json confirms0clipped pixels.`n"}
 }else{
  $record+="`nPostprocessing: native2172x7243:1 banner uniformly resized1920x640, then full canvas alpha255. Matches approved Lina/Cecile cutin framing and subject scale. Abstract magical marks in integrated cutin art have no legible words. No standalone spell effect or skill icon generated.`n"
 }
 foreach($repairName in @('C03_sd_attack_braid_repair','C03_sd_attack_hands_repair','C03_cutin_hands_repair')){
  if(($r.id -eq 'C03_sd_attack' -and $repairName -like 'C03_sd_attack_*') -or ($r.id -eq 'C03_cutin' -and $repairName -like 'C03_cutin_*')){
   $repair=Get-Content -Raw -Encoding UTF8 (Join-Path $qa ($repairName+'.json'))|ConvertFrom-Json
   $record+="`nLOCAL EDIT: $repairName`nFull actual edit prompt:`n$($repair.prompt)`nActual attached references in order:`n$($repair.refs -join "`n")`n"
  }
 }
 if($r.id -eq 'C03_sd_attack'){$record+="Repair evidence: art/raw/qa_S10_remaining/C03_sd_attack/; original rawv1, braid edit rawv2, arm/prop edit rawv3 retained. Registered braid patch is a local RGB-only composite, outside-mask RGBA0 and alpha0. Final arm/prop correction uses stored local mask; excluded head/face/legs remain original. See repair QA JSON for actual masks and provenance.`n"}
 if($r.id -eq 'C03_cutin'){$record+="Repair evidence: art/raw/qa_S10_remaining/C03_cutin/; rawv1 and hand/prop edit rawv2 retained. Correct right-hand staff and left-hand open chained book. Moving the large foreground book requires a broad arms/props/costume/background integration mask; this is not a tiny hand-only patch. Register edited scene to original facial landmarks (scale1.08,translation[-15,-1]), then preserve original face/glasses core with elliptical mask feather. Braid follows same far-left shoulder orientation; its pixels are not claimed identical. Protected face landmark rectangle1060..1220,180..290 unchanged; outside stored integration mask RGBA0 independently verified. See repair QA JSON.`n"}
 $entry=@($verification.saved_png_checks|Where-Object {$_.id -eq $r.id})[0]
 $record+="`nIndependent saved PNG audit: $($entry.qa|ConvertTo-Json -Compress)`nQA evidence: art/raw/qa_S10_remaining/verification.json; expressions_12_grid.png; portraits_12_full.png; sd_15_comparison.png; cutins_3_comparison.png. $($verification.protected_files.Count) prior non-icon final/ref files SHA256 unchanged, including approved C03 checkpoint PNGs and prompts. Verification separately records12 C01/C02 icon PNG/prompt changes/removals made outside this task; this task did not write those files and did not revert external state.`nStatus: generated, awaiting user review of S10. Two checkpoint images remain approved and untouched. No commit; no S11; no skill icons.`n"
 [IO.File]::WriteAllText($sidecar,$record,$utf8)
 $r.refs=$meta.refs -join ';';$r.status='generated'
 $r.notes="2026-10-16 내장 image_gen ${calls}회·재시도$($calls-1); 원본raw·전체prompt·실제참조·독립QA보존; MUST KEEP 및 설정대조·손·안경·같은인물·노출낮음·알파검사; S10 검토 대기·커밋없음"
 if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){$r.notes+='; 얼굴마스크밖RGBA차이0·전체알파차이0'}
 if($r.format -eq 'sd'){$r.notes+=';512x512·오른쪽3/4·발y487·idle배율대조'}
 if($r.id -eq 'C03_sd_down'){$r.notes+=';무릎자세scale0.4·발정렬+14px·손실0'}
 if($r.id -eq 'C03_sd_attack'){$r.notes+=';땋은머리 및 손/소품 좌우 국소편집·외부픽셀보존'}
 if($r.id -eq 'C03_cutin'){$r.notes+=';1920x640·리나세실구도배율·손/소품좌우국소편집'}
 $replacement=($r|ConvertTo-Csv -NoTypeInformation)[1]
 $text=[regex]::Replace($text,'(?m)^"?'+[regex]::Escape($r.id)+'"?,[^\r\n]*',[Text.RegularExpressions.MatchEvaluator]{param($m)$replacement}.GetNewClosure())
}
[IO.File]::WriteAllText($path,$text,$utf8)
$p=(Resolve-Path art/steps/README.md).Path
$s=[IO.File]::ReadAllText($p).Replace('| [S10](S10.md) | 아델하이트 세트 | 18 | P1 | 진행 중 |','| [S10](S10.md) | 아델하이트 세트 | 18 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($p,$s,$utf8)
'16 new PNG prompt sidecars and generated manifest records saved; S10 review pending.'
