$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S08'
New-Item -ItemType Directory -Force -Path $qa,(Join-Path $root 'art/final/characters/C02_cecile') | Out-Null
$baseline=@(Get-ChildItem (Join-Path $root 'art/final'),(Join-Path $root 'art/refs') -File -Recurse | ForEach-Object { @{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} })
[IO.File]::WriteAllText((Join-Path $qa 'baseline_hashes.json'),($baseline | ConvertTo-Json -Depth 4),$utf8)
Copy-Item -LiteralPath (Join-Path $root 'art/manifest.csv') -Destination (Join-Path $qa 'manifest_before.csv')
$p=Join-Path $root 'art/manifest.csv';$text=[IO.File]::ReadAllText($p)
foreach($id in @('C02_ref_combat','C02_ref_casual')) {
 $text=[regex]::Replace($text,'(?m)^"?'+$id+'"?,[^\r\n]*',{param($m)
  $row=$m.Value | ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
  if($row.status -ne 'generated'){throw "Unexpected status: $id"}
  $row.status='approved';$row.notes+='; 2026-10-15 사용자 S07 승인; 승인된 시트를 해당 의상 후속 이미지 참조로 사용'
  ($row | ConvertTo-Csv -NoTypeInformation)[1]
 }.GetNewClosure())
}
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/S07.md';$text=[IO.File]::ReadAllText($p)
$text=$text.Replace('## 피드백',"## 피드백`n`n- 2026-10-15 사용자 승인")
$text+="`n## 승인 후 처리 · 2026-10-15`n`n- 사용자 S07 승인에 따라 C02_ref_combat·C02_ref_casual manifest status를 approved로 변경.`n- 두 승인 PNG와 prompt는 변경하지 않고 유지. 이후 전투복은 art/refs/C02_ref_combat.png, 일상복은 art/refs/C02_ref_casual.png를 참조.`n- README S07=승인. 이전 완료 보고의 QA 보류는 뒤이은 볼 국소 편집으로 해결된 이력이며, 최종본 사용자 승인을 기록함.`n"
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/README.md';$text=[IO.File]::ReadAllText($p)
$text=$text.Replace('| [S07](S07.md) | 세실 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 검토 대기 |','| [S07](S07.md) | 세실 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 승인 |')
$text=$text.Replace('| [S08](S08.md) | 세실 세트 | 21 | P1 | 대기 |','| [S08](S08.md) | 세실 세트 | 21 | P1 | 진행 중 |')
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/S08.md';$text=[IO.File]::ReadAllText($p)
$text=$text.Replace('(아직 없음)','- 2026-10-15 · 사용자 실행 지시: S07 승인 후 중간 확인용 C02_portrait_combat_neutral·C02_sd_idle 2장만 제작. 승인 세실 전투복 시트로 외형을, 승인 리나 portrait/sd_idle로 화풍·구도·비율을 맞추되 리나 얼굴 복사 금지. portrait 정면·무릎 위·입 다문 차분한 장난스러운 미소. 본인 왼쪽 볼 흉터 확대 확인(정면 관찰자 오른쪽), 누락 시 볼만 마스크 편집 및 밖 픽셀 불변 검증. SD 512×512·발 기준선 y487·오른쪽 3/4·리나와 같은 머리/몸 비율 및 크기·시트와 같은 양허리 쌍단검. 내부 알파255·가장자리1~2px 반투명. raw에 리나 SD 나란히 대조 QA. 완료 후 S08 검토 대기. 나머지 19장 및 커밋 금지.')
[IO.File]::WriteAllText($p,$text,$utf8)
$guide=[IO.File]::ReadAllText((Join-Path $root 'art/style-guide.md'))
$chars=[IO.File]::ReadAllText((Join-Path $root 'art/characters.md'))
$style=[regex]::Match($guide,'(?s)## 2\. STYLE_BLOCK\s*```\s*(.*?)```').Groups[1].Value.Trim()
$negative=[regex]::Match($guide,'(?s)## 5\. NEGATIVE_BLOCK\s*```\s*(.*?)```').Groups[1].Value.Trim()
$cecile=[regex]::Match($chars,'(?s)### C02 .*?(?=### C03)').Value
$body=[regex]::Match($cecile,'- BODY: `([^`]+)`').Groups[1].Value
$combat=[regex]::Match($cecile,'- COMBAT: `([^`]+)`').Groups[1].Value
foreach($kind in @('portrait','sd')) {
 $format=[regex]::Match($guide,'(?m)^\| `'+$kind+'` \|[^\r\n]*?`([^`]+)`').Groups[1].Value
 if(-not $format -or -not $style -or -not $body -or -not $combat -or -not $negative){throw 'Missing prompt block'}
 $extra=if($kind -eq 'portrait') {
 'Neutral calm expression that still shows the character''s personality. Use a quiet, slightly mischievous CLOSED-MOUTH smile, relaxed brows. Her face, short silver-grey bob and green eyes must be Cecile from input 1, not Lina. The small crossed scar is on her anatomical LEFT cheek: viewer RIGHT in this front-facing portrait. Show it clearly without exaggerating its size. Dialogue standing portrait: face looks directly at viewer, only torso subtly angled, arms resting naturally, both empty gloved hands and both sheathed belt daggers wholly visible. Exactly one dagger sheathed on each hip, same orientation and belt attachments as the sheet; right-thigh strap on viewer left. Head-to-knee crop, small head margin and comparable head scale to approved Lina portrait. No feet. No mirroring. One character, no reference panels. Follow approved Lina portrait''s polished rendering and knee-up composition without its background, weapons, face or hairstyle.'
 } else {
 'Pose: relaxed ready combat stance. Match input 3 approved Lina sd_idle EXACTLY in chibi head-to-body ratio, head diameter and total on-canvas character height: approximately 2.5 heads tall, not a tall 3-head figure. Full body right-facing THREE-QUARTER view, including both boots. Cecile''s silver-grey bob, green eyes and face from input 1, not Lina. Hood down. Small crossed scar on anatomical LEFT cheek, the nearer visible cheek in this right-facing 3/4 view. Hands relaxed and EMPTY, both daggers remain SHEATHED, one at each belt hip as the sheet: nearer left-hip dagger visible beside left hand, far right-hip dagger visible at other waist in perspective. Do not hold or draw extra daggers. Right thigh strap on far right leg. Dark green cloak, brown leather vest and linen shirt, dark breeches, fingerless gloves, soft brown boots as approved sheet. Match Lina''s outline weight, material rendering and chibi scale; no sword, shield, ribbon, long brown hair or red surcoat. Centered with ample clear margins, feet at same level, no ground shadow, one character only.'
 }
 $prompt=$style+"`n`n"+$format+"`n`n"+$body+"`n`n"+$combat+"`n`n"+$extra+"`n`n"+$negative+"`n`nUse case: stylized-concept. Input 1: approved Cecile combat reference sheet, sole identity/clothing source. Input 2: approved style-anchor, style only. Input 3: approved Lina matching-format result, style/composition/proportion only, NEVER identity. Transparency override: create REAL transparent background, no magenta or other opaque backdrop; character interiors fully opaque alpha255, antialias only at silhouette edge."
 [IO.File]::WriteAllText((Join-Path $qa ($kind+'.full-prompt.txt')),$prompt,$utf8)
}
'S07 approved; S08 in progress; prompt blocks assembled verbatim.'
