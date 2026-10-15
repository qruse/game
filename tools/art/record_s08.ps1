$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S08'
foreach($kind in @('portrait','sd')) {
 $id=if($kind -eq 'portrait'){'C02_portrait_combat_neutral'}else{'C02_sd_idle'}
 $lina=if($kind -eq 'portrait'){'C01_portrait_combat_neutral'}else{'C01_sd_idle'}
 $prompt=[IO.File]::ReadAllText((Join-Path $qa ($kind+'.full-prompt.txt')))
 $report=[IO.File]::ReadAllText((Join-Path $qa ($kind+'/qa.json')))
 $record="Model/tool: OpenAI built-in image_gen. Exact backend model identifier is not exposed by the tool; not inferred.`nGeneration date: 2026-10-15 (Asia/Seoul)`nMode: built-in generation, transparent_background=true; no CLI/API fallback.`nGeneration calls: 1; retries: 0; no local editing required (left-cheek scar present).`nReferences in attachment order:`n1. art/refs/C02_ref_combat.png - approved identity, clothing, scar and dagger placement`n2. art/refs/style-anchor.png - approved style only`n3. art/final/characters/C01_lina/$lina.png - approved style, composition and proportions only, not face identity`n`nFULL PROMPT (verbatim):`n$prompt`n`nRaw generation: art/raw/${id}_v1.png, original file retained byte-for-byte.`nPostprocessing: tools/art/finish_s08.ps1. Preserve character RGB, normalize deep interior alpha to255 and retain native antialias at silhouette boundary (1px neighborhood); no binary output alpha. Transparent background pixels RGB zeroed. No mirroring.`n"
 if($kind -eq 'portrait'){$record+="Canvas 1024x1536 retained; no scaling, cropping or repositioning. Face enlarged3x and anatomical LEFT-cheek crossed scar verified on viewer RIGHT. Closed-mouth calm playful smile; both hands and both belt-sheathed daggers visible.`n"}
 else{$record+="Transparent subject trimmed and uniformly resized to464px height to match Lina idle's y24..487 total height; placed on512x512, foot baseline last occupied row487. Right-facing3/4; anatomical LEFT-cheek scar belongs on FAR cheek (screen-right face edge), matching Lina's far-side left-temple ribbon logic. One sheathed dagger on each belt hip, both hands empty. Hair/bob shape differs from Lina while chibi head/body scale matches.`n"}
 if($kind -eq 'sd'){
  $record=$record.Replace('Generation calls: 1; retries: 0; no local editing required (left-cheek scar present).','Image calls: 3 (generation1 + local head-proportion edit1 + cheek correction1); retries:2. Initial SD prompt incorrectly described anatomical left cheek as near side; final cheek-only correction removes near-side scar and places it on far LEFT cheek. Historical prompts below retained verbatim; corrected anatomy supersedes their mistaken near-side instruction.')
  $record+="`nLOCAL HEAD EDIT (verbatim):`n"+[IO.File]::ReadAllText((Join-Path $qa 'sd.head-edit-prompt.txt'))+"`nEdit attachments in order: art/raw/qa_S08/sd/before_head_edit.png (target); art/final/characters/C01_lina/C01_sd_idle.png (proportion reference only).`nOriginal edit result retained byte-for-byte: art/raw/C02_sd_idle_v2.png. Selected output: head+upper-neck mask composite from edit over pre-edit normalized sprite; outside-mask RGBA difference0. Mask and difference PNG retained in art/raw/qa_S08/sd/. Final torso, cloak sides, hands, daggers, legs and boots outside the mask are pixel-identical. tools/art/repair_s08_head.ps1.`n"
  $record+="`nFINAL CHEEK CORRECTION (verbatim):`n"+[IO.File]::ReadAllText((Join-Path $qa 'sd.scar-edit-prompt.txt'))+"`nEdit attachments: art/raw/qa_S08/sd/scar_edit_target_5x.png (700x500 target crop from512 sprite at x255,y125,w140,h100, enlarged5x); art/refs/C02_ref_combat.png (anatomical scar side). Raw tool result: art/raw/C02_sd_idle_v3.png. Two feathered cheek RGB masks only; outside-mask RGBA difference0 and entire alpha channel difference0. Removal centered(295,186), correct far LEFT-cheek scar centered(358,181),512px coordinates. tools/art/repair_s08_scar.ps1. Final face enlarged3x and scar verified.`n"
 }
 $record+="QA JSON: $report`nQA previews: art/raw/qa_S08/$kind/. Comparison: art/raw/qa_S08_lina_sd_comparison.png. Status: generated, awaiting user approval; S08 intermediate checkpoint only.`n"
 [IO.File]::WriteAllText((Join-Path $root ('art/final/characters/C02_cecile/'+$id+'.prompt.txt')),$record,$utf8)
}
$p=Join-Path $root 'art/manifest.csv';$text=[IO.File]::ReadAllText($p)
foreach($id in @('C02_portrait_combat_neutral','C02_sd_idle')) {
 $text=[regex]::Replace($text,'(?m)^"?'+$id+'"?,[^\r\n]*',{param($m)
  $row=$m.Value | ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
  if($row.status -ne 'todo'){throw "Unexpected initial status $id"}
  $row.status='generated'
  $kind=if($id -eq 'C02_sd_idle'){'sd'}else{'portrait'}
  $lina=if($kind -eq 'sd'){'C01_sd_idle'}else{'C01_portrait_combat_neutral'}
  $row.refs+=';art/final/characters/C01_lina/'+$lina+'.png'
  $row.notes='2026-10-15 내장 image_gen 생성1회 재시도0; 승인 세실 전투복 시트 외형 및 승인 리나 화풍·구도 참조; 본인 왼쪽볼 흉터 확대확인; 양허리 단검 각1자루 수납·양손빈손; 내부알파255·가장자리1px 반투명; raw v1 및 전체 prompt·QA 보존; S08 중간확인 2장만 generated; 사용자 검토 대기'
  if($kind -eq 'sd'){$row.notes=$row.notes.Replace('생성1회 재시도0','생성1회 머리비율국소편집1회 볼좌우보정1회(총3회)').Replace('raw v1 및','raw v1/v2/v3 및');$row.notes+='; 머리·목 및 볼마스크밖 RGBA차이0·볼편집알파차이0; 흉터는 오른쪽3/4에서 먼쪽 본인왼쪽볼; 512x512 발기준선y487·전체높이464px(y24..487)·리나 SD 비율 비교'}else{$row.notes+='; 1024x1536 위치유지·정면 무릎위 대화용·입다문 차분한 미소·흉터관찰자오른쪽'}
  ($row | ConvertTo-Csv -NoTypeInformation)[1]
 }.GetNewClosure())
}
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/README.md';$text=[IO.File]::ReadAllText($p).Replace('| [S08](S08.md) | 세실 세트 | 21 | P1 | 진행 중 |','| [S08](S08.md) | 세실 세트 | 21 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/S08.md'
$report=@'

## 중간 확인 보고 · 2026-10-15

[S08 보고]
만든 것: 내장 image_gen으로 중간 확인용 2장만 제작, QA 통과 후 generated.
- C02_portrait_combat_neutral → art/final/characters/C02_cecile/C02_portrait_combat_neutral.png (1024×1536)
- C02_sd_idle → art/final/characters/C02_cecile/C02_sd_idle.png (512×512)
- 리나 SD 나란히 대조 → art/raw/qa_S08_lina_sd_comparison.png

재시도한 것: C02_sd_idle 국소 편집2회(생성 포함 총3회): ① 리나보다 작은 머리/몸 비율 보정 ② 가까운 오른쪽 볼의 잘못된 흉터를 제거하고 먼 왼쪽 볼로 이동. 각 마스크 밖 RGBA차이0, 볼 편집 전체 알파차이0 확인. portrait는 생성1회, 재시도0(흉터 보완 불필요). QA 3회 실패 id 없음.
스스로 본 문제: 명확한 QA 결함 없음. portrait는 입 다문 차분한 미소·정면 시선·무릎 위 구도·손/단검 캔버스 안 확인. SD는 오른쪽3/4·양허리 단검 수납·발끝y487·높이464px로 리나와 일치. 확대 얼굴과 어두운/밝은 배경에서 흉터·알파 가장자리 확인. 리나와 세실은 머리 모양과 장비 실루엣이 달라 대조 이미지에서 머리/몸 비율과 인상은 사용자 확인 필요.
확인 요청: 세실 외형 및 차분한 표정, 리나와 화풍/머리 크기 일치, SD 비율·단검 위치 확인 후 중간 확인 2장 승인 필요. S08 검토 대기. 나머지19장은 todo 유지, S09 미진행, 커밋 없음.

### QA 근거

- STYLE/FORMAT/BODY/COMBAT/extra/NEGATIVE 순으로 영어 프롬프트 조립, BODY와 COMBAT 원문 유지. neutral 감정·투명 배경 우선 규칙을 추가 지시로 명시.
- 첨부 순서: 승인 C02_ref_combat, 승인 style-anchor, 승인 리나 해당 형식 이미지. 리나 얼굴/머리/의상은 복사하지 않음.
- portrait 본인 왼쪽 볼=관찰자 오른쪽의 작은 교차 흉터를 3배 확대 확인. SD 오른쪽3/4에서는 왼쪽 볼이 먼 쪽(작은 눈 아래 얼굴 오른쪽 가장자리)임을 리나 왼쪽 리본과 대조해 확인. 초기 프롬프트의 가까운 왼쪽 볼 지시는 잘못이었고 최종 볼 국소 편집으로 먼 왼쪽 볼에만 흉터가 있도록 수정. 쌍단검은 양허리 각각1자루 수납으로 승인 시트와 일치; 두 손은 빈손.
- portrait 원본1024×1536 위치·RGB 유지. SD는 균일 축소·512×512 정렬, 마지막 발 픽셀y487, 아래24행 투명. 좌우반전 없음.
- 내부알파255, 안쪽 반투명0, 가장자리1px 부근에만 부드러운 알파 유지. 0/255 이진 출력 아님. 밝은/어두운/체커 배경 QA 보존.
- portrait raw v1 및 SD raw v1/v2/v3 원본 덮어쓰기 없이 저장. SD 머리·목 및 두 볼 마스크/RGBA 차이 이미지 보존, 각 마스크 밖 차이0 및 볼 편집 전체 알파차이0. 각 final 옆 .prompt.txt에 날짜·도구·백엔드 모델 식별자 비공개 사실·전체 생성/편집 프롬프트·참조 순서·후처리·QA 수치 기록.
- art/raw/qa_S08/verification.json에서 기존 final/refs PNG·prompt SHA256 불변, manifest 변경이 S07 승인2행+S08 generated2행뿐인지 검증. 나머지 S08 19행 todo 및 파일 미생성 확인.
'@
[IO.File]::AppendAllText($p,$report+"`n",$utf8)
$baseline=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline_hashes.json') | ConvertFrom-Json
$changedAssets=@($baseline | Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$before=Import-Csv (Join-Path $qa 'manifest_before.csv');$after=Import-Csv (Join-Path $root 'art/manifest.csv');$changedRows=@()
for($i=0;$i -lt $before.Count;$i++){if(($before[$i] | ConvertTo-Json -Compress) -ne ($after[$i] | ConvertTo-Json -Compress)){$changedRows+=$after[$i].id}}
$expected=@('C02_ref_combat','C02_ref_casual','C02_portrait_combat_neutral','C02_sd_idle')
if($changedAssets.Count -ne 0 -or $changedRows.Count -ne 4 -or @($changedRows | Where-Object {$_ -notin $expected}).Count){throw 'Unexpected file/manifest change'}
$remaining=@($after | Where-Object {$_.step -eq 'S08' -and $_.id -notin @('C02_portrait_combat_neutral','C02_sd_idle')})
if($remaining.Count -ne 19 -or @($remaining | Where-Object {$_.status -ne 'todo' -or (Test-Path -LiteralPath (Join-Path $root $_.output))}).Count){throw 'Remaining19 must stay untouched'}
foreach($id in @('C02_ref_combat','C02_ref_casual')){if(($after | Where-Object id -eq $id).status -ne 'approved'){throw 'S07 approval missing'}}
$verification=[ordered]@{date='2026-10-15';existing_asset_count=@($baseline).Count;existing_assets_changed=$changedAssets;manifest_changed_ids=$changedRows;S07='approved';S08='intermediate review pending';generated=@('C02_portrait_combat_neutral','C02_sd_idle');remaining19='todo; no output files';commit_performed=$false;portrait=(Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'portrait/qa.json') | ConvertFrom-Json);sd=(Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'sd/qa.json') | ConvertFrom-Json)}
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($verification | ConvertTo-Json -Depth 8),$utf8)
$verification | ConvertTo-Json -Depth 8
