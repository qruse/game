$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S10'
$baseline=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline.json')|ConvertFrom-Json
$changed=@($baseline|Where-Object{(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
if($changed.Count -ne 1 -or $changed[0].path -notlike '*C03_ref_casual.prompt.txt'){throw 'Unexpected existing art modification'}
$mp=Join-Path $root 'art/manifest.csv';$mt=[IO.File]::ReadAllText($mp)
foreach($kind in @('portrait','sd')){
 $id=if($kind -eq 'portrait'){'C03_portrait_combat_neutral'}else{'C03_sd_idle'}
 $format=if($kind -eq 'portrait'){'portrait_combat_neutral'}else{'sd_idle'}
 $refs=@('art/refs/C03_ref_combat.png','art/refs/style-anchor.png',"art/final/characters/C01_lina/C01_$format.png","art/final/characters/C02_cecile/C02_$format.png")
 $record="Model/tool: OpenAI built-in image_gen; exact backend model identifier not exposed and not inferred.`nGeneration date: 2026-10-15 (Asia/Seoul)`nMode: reference-guided new generation, transparent_background=true; no CLI/API fallback.`nReferences in exact attachment order:`n- "+($refs -join "`n- ")+"`n`nFULL GENERATION PROMPT (verbatim):`n"+[IO.File]::ReadAllText((Join-Path $qa "$kind.full-prompt.txt"))+"`nRaw generation: art/raw/${id}_v1.png, preserved byte-for-byte.`nPostprocessing: tools/art/finish_s10_asset.ps1; fully opaque interiors alpha255, native antialias retained within1px silhouette neighborhood, transparent RGB zeroed; no horizontal mirroring. Portrait 1024x1536 fixed position; SD uniformly trimmed/scaled to464px height on512x512, occupied y24..487 and foot baseline487.`nGeneration QA:`n"+[IO.File]::ReadAllText((Join-Path $qa "$kind/qa.json"))
 if($kind -eq 'portrait'){
  $record+="`nCalls: generation1 + local lower-staff edit1 =2; retries1; no full regeneration. Initial lower staff tip was cut by bottom canvas edge. Final shortened lower shaft ends inside canvas; fixed through narrow RGB-only mask x190..298,y1090..1535 with12px inward feather, original alpha preserved. Face/hair/glasses/braid/hands/book/cape and all outside-mask pixels identical.`nLOCAL EDIT PROMPT (verbatim):`n"+[IO.File]::ReadAllText((Join-Path $qa 'portrait.staff-edit-prompt.txt'))+"`nEdit attachment: art/raw/qa_S10/portrait/before_staff_edit.png (sole edit target). Raw result: art/raw/C03_portrait_combat_neutral_v2.png. tools/art/repair_s10_staff.ps1. Mask/difference and verification preserved:`n"+[IO.File]::ReadAllText((Join-Path $qa 'portrait/staff_edit_qa.json'))
 }else{$record+="`nCalls: generation1, retries0, local edits0.`n"}
 $record+="`nVisual QA: own Adelheid identity, golden eyes, round wire glasses; single black braid over anatomical LEFT shoulder (front viewer-right; right-facing3/4 far/face-side shoulder). Navy modified habit robe and short cape, RIGHT hand securely gripping wooden staff, LEFT hand/forearm supporting thick closed iron-chain grimoire. Calm closed-mouth nearly expressionless aloof face. All props inside frame, no text or watermark, no extra props. SD right-facing3/4, body/head scale compared directly to approved Lina and Cecile at1:1 with shared baseline. Checked light/dark/checker backgrounds and enlarged face/hands. COMBAT clause comparison in art/steps/S10.md. Status generated; S10 intermediate checkpoint awaiting user review; remaining19 not generated. No commit.`n"
 [IO.File]::WriteAllText((Join-Path $root "art/final/characters/C03_adelheid/$id.prompt.txt"),$record,$utf8)
 $joined=$refs -join ';'
 $mt=[regex]::Replace($mt,'(?m)^'+$id+',[^\r\n]*',{param($m)
  $r=$m.Value|ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
  if($r.status -ne 'todo'){throw 'Unexpected target status'}
  $r.status='generated';$r.refs=$joined
  $r.notes='2026-10-15 내장 image_gen; 승인C03전투복 및 승인리나·세실 동일형식 화풍구도비율 참조·얼굴복사금지; 안경·금안·왼어깨단일땋음·오른손지팡이·왼손쇠사슬마법서 확인; COMBAT대조맞음; raw·전체prompt·참조·QA보존; 내부알파255·가장자리반투명; S10중간확인2장만·검토대기·커밋없음'
  if($kind -eq 'portrait'){$r.notes+='; 생성1회+하단지팡이국소편집1회·재시도1; 마스크밖RGBA차이0·알파차이0; 1024x1536 정면무릎위·차분한냉소무표정'}else{$r.notes+='; 생성1회·재시도0; 512x512·발y487·높이464(y24..487)·오른쪽3/4; 리나세실1:1대조'}
  ($r|ConvertTo-Csv -NoTypeInformation)[1]
 })
}
[IO.File]::WriteAllText($mp,$mt,$utf8)
$rows=@(Import-Csv -LiteralPath $mp -Encoding UTF8)
$s10=@($rows|Where-Object step -eq 'S10')
if(@($s10|Where-Object status -eq 'generated').Count -ne 2 -or @($s10|Where-Object status -eq 'todo').Count -ne 19){throw 'S10 scope mismatch'}
if(@($rows|Where-Object {$_.step -eq 'S09' -and $_.status -eq 'approved'}).Count -ne 2){throw 'S09 not approved'}
$before=@(Import-Csv -LiteralPath (Join-Path $qa 'manifest_before.csv') -Encoding UTF8)
$diff=@();for($i=0;$i -lt $before.Count;$i++){
 if(($before[$i]|ConvertTo-Json -Compress) -ne ($rows[$i]|ConvertTo-Json -Compress)){
  if($rows[$i].id -notin @('C03_ref_combat','C03_ref_casual','C03_portrait_combat_neutral','C03_sd_idle')){throw 'Unexpected manifest difference'}
  $diff+=$rows[$i].id
 }
}
$p=Join-Path $root 'art/steps/README.md';$s=[IO.File]::ReadAllText($p)
$s=$s.Replace('| [S10](S10.md) | 아델하이트 세트 | 21 | P1 | 진행 중 |','| [S10](S10.md) | 아델하이트 세트 | 21 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($p,$s,$utf8)
$report=@'

## 중간 확인 보고 · 2026-10-15

[S10 보고]
만든 것 (generated):
- C03_portrait_combat_neutral → art/final/characters/C03_adelheid/C03_portrait_combat_neutral.png
- C03_sd_idle → art/final/characters/C03_adelheid/C03_sd_idle.png
- 내장 image_gen 사용. 각 PNG 옆 .prompt.txt에 전체 실제 프롬프트·참조 순서·날짜·모델 식별자 비공개 사실·후처리·QA 기록. raw 원본 보존.
- SD 1:1 나란히 대조: art/raw/qa_S10_lina_cecile_sd_comparison.png. 스탠딩 대조와 얼굴·안경·땋은 머리·손 확대: art/raw/qa_S10/.

재시도한 것: portrait 생성1회+하단 지팡이 국소편집1회(재시도1); SD 생성1회·재시도0. 스탠딩의 잘린 지팡이 아래끝만 화면 안으로 마무리했다. 마스크 밖 RGBA 차이0·전체 알파 차이0. QA3회 실패 id 없음.

스스로 본 문제: 두 이미지의 안경·금색 눈·왼어깨 단일 땋은 머리, 오른손 지팡이·왼팔 쇠사슬 마법서를 확대 확인했다. portrait는 정면·무릎 위·입 다문 차분한 냉소 표정이며 얼굴/의상 위치를 유지했다. SD는 오른쪽3/4·512×512·발y487·머리끝y24·높이464px, 리나·세실과 같은 배율로 비교했다. 로브가 다리를 덮어 동료보다 몸통이 넓게 보이는 차이는 의상 실루엣이다. 머리/몸 비율과 동일 인물 인상의 최종 판단은 사용자 검토 사항이다.

| COMBAT 블록 구절 | portrait | SD | 대조 근거 |
|---|---|---|---|
| wearing a modified dark navy nun's habit robe | 맞음 | 맞음 | 승인 시트의 짙은 남색 개조 수도복 로브 |
| with a short cape | 맞음 | 맞음 | 짧은 남색 어깨 케이프 |
| carrying a thick grimoire | 맞음 | 맞음 | 왼손·왼팔로 받친 두꺼운 닫힌 마법서 |
| bound with an iron chain | 맞음 | 맞음 | 책 표지를 두르는 쇠사슬 확인 |
| and a gnarled wooden staff | 맞음 | 맞음 | 오른손으로 쥔 옹이진 나무 지팡이, 양끝 캔버스 안 |

MUST KEEP 및 좌우: 검은 긴 단일 땋은 머리는 본인 왼어깨. 정면은 관찰자 오른쪽, 오른쪽3/4 SD는 얼굴 쪽 먼 어깨에서 앞으로 내려온다. 둥근 철테 안경 두 렌즈·금안 확인. 소품·장식은 승인 전투복 시트 기준, 일상복 물건이나 추가 무기 없음. 불투명 내부 alpha255, 가장자리1px 반투명 유지, 이진 알파 아님. 스탠딩1024×1536 위치 유지·좌우반전 없음.

확인 요청: 위2장의 얼굴/표정, 지팡이·책을 잡은 손, SD 머리/몸 비율과 크기를 확인할 차례다. S10 검토 대기. 나머지19장은 todo 유지. 커밋하지 않고 여기서 멈춤.
'@
[IO.File]::AppendAllText((Join-Path $root 'art/steps/S10.md'),$report,$utf8)
$verification=[ordered]@{date='2026-10-15';existing_pngs_unchanged=$true;existing_files_modified=@($changed|ForEach-Object{$_.path});casual_sha256=(Get-FileHash (Join-Path $root 'art/refs/C03_ref_casual.png')).Hash;manifest_changed_ids=$diff;S09_approved=2;S10_generated=2;S10_todo=19;comparison='art/raw/qa_S10_lina_cecile_sd_comparison.png';portrait_qa=(Get-Content -Raw (Join-Path $qa 'portrait/qa.json')|ConvertFrom-Json);staff_qa=(Get-Content -Raw (Join-Path $qa 'portrait/staff_edit_qa.json')|ConvertFrom-Json);sd_qa=(Get-Content -Raw (Join-Path $qa 'sd/qa.json')|ConvertFrom-Json);commit_performed=$false}
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($verification|ConvertTo-Json -Depth 6),$utf8)
$verification|ConvertTo-Json -Depth 6
