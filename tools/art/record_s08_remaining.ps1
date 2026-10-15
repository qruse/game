$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location $root
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S08_remaining'
$manifest=(Resolve-Path art/manifest.csv).Path
$before=[IO.File]::ReadAllText($manifest)
$rows=@(Import-Csv -Encoding UTF8 $manifest|Where-Object {$_.step -eq 'S08' -and $_.status -eq 'todo'})
if($rows.Count -ne 19){throw 'Expected exactly19 remaining todo rows'}
$verification=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'verification.json')|ConvertFrom-Json
foreach($r in $rows){
 $meta=Get-Content -Raw -Encoding UTF8 (Join-Path $qa ($r.id+'.json'))|ConvertFrom-Json
 foreach($ref in $meta.refs){if(-not(Test-Path -LiteralPath $ref)){throw "Missing ref: $ref"}}
 $output=Join-Path $root $r.output
 $sidecar=[IO.Path]::ChangeExtension($output,'.prompt.txt')
 if(Test-Path -LiteralPath $sidecar){throw "Refusing sidecar overwrite: $sidecar"}
 $calls=if($r.id -eq 'C02_sd_attack'){2}else{1}
 $mode=if($r.id -match 'portrait_.*_(smile|angry|sad|surprised|embarrassed)$'){'built-in local expression edit; guide3.1.4 strict face-interior composite'}else{'built-in generation'}
 $content="Model/tool: OpenAI built-in image_gen. Exact backend model identifier is not exposed; not inferred.`nGeneration date: 2026-10-15 (Asia/Seoul)`nMode: $mode. No CLI/API fallback.`nImage calls: $calls. Model retries: $($calls-1).`nReferences in attachment order:`n"
 for($i=0;$i -lt $meta.refs.Count;$i++){$content+="$($i+1). $($meta.refs[$i])`n"}
 $content+="`nFULL PROMPT (verbatim):`n$($meta.prompt)`n`nRaw generation/edit result: art/raw/$($r.id)_v1.png (byte-for-byte original retained).`nDefault generated source: $($meta.source)`n"
 if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){
  $content+="Postprocessing: tools/art/finish_s08_face.ps1. Original neutral canvas1024x1536 and RGBA preserved. Three face-interior polygons cover eyebrows/eyes and lower face; forehead/brow endpoints included so no neutral eyebrow remnants remain. Four-pixel feather inward. Protected scar patch x530..551,y246..276 excluded from mask. ONLY RGB blended from tool edit; entire original alpha channel retained. No head/body/hair silhouette repositioning or mirroring. Same edit output reused for mask-boundary refinements; no extra model calls. Independent saved-PNG audit checks ALL RGBA outside stored face_mask.png and ALL alpha pixels, not merely bounds. Outside-mask changes0, alpha changes0, scar-patch changes0.`n"
  $entry=@($verification.face_checks|Where-Object {$_.id -eq $r.id})[0]
  $content+="Independent face QA: $($entry.qa|ConvertTo-Json -Compress)`nMask/difference/detail/checkerboard: art/raw/qa_S08_remaining/$($r.id)/`n"
 }elseif($r.format -eq 'portrait'){
  $content+="Postprocessing: tools/art/finish_s08_asset.ps1. Keep native1024x1536 RGB and subject position, normalize deep interior alpha255, retain/feather only silhouette antialias1px, zero transparent RGB. No crop, move, stretch or mirror. Casual neutral QA passed BEFORE making casual expressions: matching face/build/head size to approved combat neutral; clear small X scar on HER LEFT cheek (viewer RIGHT), both hands and apple enlarged and inspected. Front-facing knee-up composition, calm closed mouth, small midriff, left hip pouch (viewer RIGHT).`n"
 }elseif($r.format -eq 'sd'){
  $content+="Postprocessing: tools/art/finish_s08_asset.ps1. Trim transparent bounds, uniform resize to fit464px, center horizontally on512square, boot baseline y487. Normalize deep interior alpha255 and preserve soft1px antialias. No mirroring. Reference idle is the USER-CONFIRMED reverse-grip dagger revision; both anatomical sides, far LEFT-cheek X scar and hand grips inspected. Face remains right-facing3/4; near RIGHT cheek unmarked. No rendered smoke or combat effect on SD.`n"
  if($r.id -eq 'C02_sd_attack'){
   $repair=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'C02_sd_attack_waist_repair.json')|ConvertFrom-Json
   $content+="`nLOCAL WAIST REPAIR (call2, model retry1): remove duplicate belt dagger hilt, leave empty scabbard; preserve both held reverse-grip daggers. Full edit prompt:`n$($repair.prompt)`nRepair references in order: $($repair.refs -join '; ')`nRaw repair: art/raw/C02_sd_attack_v2.png. Crop target:512sprite rectangle x190,y255,w100,h85 enlarged6x. Tool output uniformly mapped back to100x85 and RGB blended ONLY through elliptical waist mask centered(237,289),radii(15,18),1px feather. Original full alpha retained.831 RGB pixels changed; outside-mask RGBA0, alpha0. tools/art/repair_s08_attack_waist.ps1. Before image, waist mask and difference preserved in QA directory.`n"
  }
  if($r.id -eq 'C02_sd_skill'){$content+="Skill hand assignment: near anatomical RIGHT hand holds small dark round smoke bead; far anatomical LEFT hand holds dagger in reverse grip. Right dagger sheathed, left scabbard empty. Exactly two daggers total. No smoke, vapor or trails.`n"}
  if($r.id -eq 'C02_sd_down'){$content+="Down alignment exception: lowest visible pixels are dagger tips rather than boots. After standard finishing, translate entire sprite DOWN16px with no resampling or pixel loss; boot sole independently scanned in x70..110 moves y471 to y487. Full final occupied bounds y216..503, all daggers remain inside canvas. Head stays at same physical approximate scale, body fallen sideways and low. foot_alignment.json documents actual FOOT baseline; dagger tips extend below baseline. No arbitrary enlargement to fill full height.`n"}
 }else{
  $content+="Postprocessing: tools/art/finish_s04.ps1 $($r.format) resize using high-quality bicubic; opaque output matching approved Lina format. No mirroring.`n"
  if($r.format -eq 'cutin'){$content+="Native result2048x683 is already3:1; crop x0,y0,w2048,h682 then resize1920x640. Both hands, both real dagger blades, left-cheek X scar, dynamic dash and ghost afterimages remain visible. Same banner format as approved Lina cutin.`n"}else{$content+="Native1254x1254 uniformly resized256x256. Single blade+back silhouette / round orb+lobed smoke / X-shaped crossed daggers distinguish the three skills.64px color and grayscale inspection recorded in icons_3_64px.png.`n"}
 }
 $entry=@($verification.saved_png_checks|Where-Object {$_.id -eq $r.id})[0]
 $content+="`nSaved PNG QA: $($entry.qa|ConvertTo-Json -Compress)`nQA evidence: art/raw/qa_S08_remaining/verification.json; expressions_12_grid.png; portraits_12_full.png; sd_5_actions.png; icons_3_64px.png. Existing60 final/ref files including approved two PNGs/prompts remain SHA256-identical.`nStatus: generated, awaiting human review of S08; not approved by assistant. No commit, no S09.`n"
 [IO.File]::WriteAllText($sidecar,$content,$utf8)
 $r.status='generated'
 $r.refs=$meta.refs -join ';'
 if($r.id -match '_smile$'){$r.extra='EDIT (face mask only): mischievous tomboy toothy grin, upper teeth visible.'}
 if($r.id -eq 'C02_sd_down'){$r.extra='Pose: fallen on side, exhausted, right-facing3/4, both reverse-grip daggers; foot baseline487.'}
 if($r.id -eq 'C02_sd_skill'){$r.extra='Pose: preparing to throw a small smoke bead held in right hand, NO rendered smoke; left reverse-grip dagger.'}
 $r.notes="2026-10-15 내장 image_gen ${calls}회·모델재시도$($calls-1); raw·전체 prompt·참조·QA 보존; 저장PNG 재읽기 QA 통과; S08 사용자 검토 대기"
 if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){$r.notes+='; 얼굴마스크밖 RGBA차이0·알파차이0·흉터패치차이0; 눈썹끝 합성범위 보완(동일원본)'}
 if($r.id -eq 'C02_sd_attack'){$r.notes+='; 허리 중복단검 손잡이 국소편집1회·마스크밖차이0·알파차이0'}
 if($r.id -eq 'C02_sd_down'){$r.notes+='; 옆으로쓰러짐·발끝y487·단검끝y503 캔버스안'}
 $replacement=($r|ConvertTo-Csv -NoTypeInformation)[1]
 $before=[regex]::Replace($before,'(?m)^"?'+[regex]::Escape($r.id)+'"?,[^\r\n]*',[Text.RegularExpressions.MatchEvaluator]{param($m) $replacement}.GetNewClosure())
}
[IO.File]::WriteAllText($manifest,$before,$utf8)
$p=(Resolve-Path art/steps/README.md).Path
$t=[IO.File]::ReadAllText($p).Replace('| [S08](S08.md) | 세실 세트 | 21 | P1 | 진행 중 |','| [S08](S08.md) | 세실 세트 | 21 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($p,$t,$utf8)
$p=(Resolve-Path art/steps/S08.md).Path
$t=[IO.File]::ReadAllText($p)
$t+="`n## 나머지 19장 완료 보고 · 2026-10-15`n`n[S08 보고]`n만든 것: 내장 image_gen으로19장 제작·QA 통과·generated. 승인된 C02_portrait_combat_neutral 및 역수 수정 C02_sd_idle은 PNG/prompt 변경 없이 approved 기록.`n"
foreach($r in $rows){$t+="- $($r.id) → $($r.output)`n"}
$t+="`n재시도한 것: C02_sd_attack 생성1+허리 중복 손잡이 국소편집1=총2회(재시도1), 마스크밖 RGBA차이0·알파차이0. 나머지18장 각1회·모델재시도0. 표정10종 눈썹끝 마스크 합성범위 보완은 동일 모델출력 재사용이며 추가 생성 없음. QA3회 실패 id 없음.`n스스로 본 문제: 미해결 QA 결함 없음. down은 실제 발끝y487로 맞췄으며 단검끝은y503까지 내려오나512캔버스 안이다. 쓰러진 몸은 세로로 확대하지 않고 낮은 가로 자세로 유지. 표정은 피부 내부만 편집하고 흉터 원본패치 보존. 컷인 원본은2048x683로 도구가 직접3:1을 반환해2048x682크롭→1920x640. 아이콘3종64px·회색조에서도 단검/구슬/X 실루엣 구분 확인.`n확인 요청: 표정12장 그리드의 감정강도·동일인물, SD5동작의 크기·흉터 쪽·쌍단검 손과 자세, 컷인 돌진/잔상, 아이콘64px식별 최종 사용자 확인. S08검토대기. S09미진행·커밋없음.`n`n### QA 및 기록`n`n- 비교: art/raw/qa_S08_remaining/expressions_12_grid.png (얼굴12장), portraits_12_full.png (전체구도12장), sd_5_actions.png (동일512캔버스·발기준선), icons_3_64px.png (256·64px컬러/회색조).`n- verification.json: 저장PNG21장 크기·알파 독립 재읽기, 표정10장 얼굴마스크밖RGBA차이0·전체알파차이0·흉터패치차이0. 기존 final/refs60개 파일 SHA256 모두불변.`n- 일상복neutral은 표정생성 전 얼굴·흉터·손/사과·노출·구도·투명도 확대 QA 통과. 흉터 누락없음.`n- SD4장은 승인된 역수idle을 참조. 오른쪽3/4 먼 본인왼쪽볼 흉터, 가까운볼 무표식. attack/hit/down양손역수; skill오른손구슬·왼손역수단검·오른단검만수납. skill연기효과없음.`n- 각final옆19개.prompt.txt에 도구·모델식별자비공개 사실·날짜·전체프롬프트·참조순서·raw·후처리·QA 기록. 승인두장prompt도 보존.`n"
[IO.File]::WriteAllText($p,$t,$utf8)
"Recorded19 generated assets and prompts; S08 review pending."
