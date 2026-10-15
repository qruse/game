$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
$utf8=[Text.UTF8Encoding]::new($false)
$rows=Import-Csv art/manifest.csv -Encoding UTF8
$protected=@($rows | Where-Object {$_.status -eq 'approved' -or $_.step -eq 'S03'} | ForEach-Object {$_.output; [IO.Path]::ChangeExtension($_.output,'.prompt.txt')} | Where-Object {Test-Path -LiteralPath $_} | Select-Object -Unique)
New-Item -ItemType Directory -Force art/raw/qa_S04 | Out-Null
$protected | ForEach-Object {Get-FileHash -Algorithm SHA256 -LiteralPath $_} | Select-Object Path,Hash | ConvertTo-Json | Set-Content -Encoding UTF8 art/raw/qa_S04/protected_before.json
$lines=[IO.File]::ReadAllLines((Join-Path $PWD 'art/manifest.csv'),[Text.Encoding]::UTF8)
for($i=0;$i -lt $lines.Length;$i++){if($lines[$i] -match '^C01_(portrait_combat_(neutral|smile)|sd_(idle|attack)),S03,'){$lines[$i]=$lines[$i] -replace ',(todo|generated|approved),',',approved,'}}
[IO.File]::WriteAllLines((Join-Path $PWD 'art/manifest.csv'),$lines,$utf8)
$p=Join-Path $PWD 'art/steps/README.md';$s=[IO.File]::ReadAllText($p);$s=$s -replace '(\| \[S03\].*\| )검토 대기( \|)','$1승인$2';$s=$s -replace '(\| \[S04\].*\| )대기( \|)','$1진행 중$2';[IO.File]::WriteAllText($p,$s,$utf8)
[IO.File]::AppendAllText((Join-Path $PWD 'art/steps/S03.md'),"`r`n## 승인 후 처리 완료 · 2026-10-15`r`n`r`n사용자 S03 승인에 따라 manifest 4행 approved, README S03 승인. 승인 PNG 및 프롬프트는 변경하지 않음. S03에서 확인된 SD 리본 좌우 문제의 공통 규칙은 AGENTS.md 공통 규칙 표, characters.md에 이미 반영되어 있으며 style-guide.md에도 추가함. 화면 목업은 별도 Claude 담당 작업으로 미수행 기록을 유지함.`r`n",$utf8)
[IO.File]::AppendAllText((Join-Path $PWD 'art/style-guide.md'),"`r`n### S03 승인 후 공통 적용 · 2026-10-15`r`n`r`n- 동작 SD는 승인된 sd_idle과 sd_attack을 함께 참조한다. 리나가 오른쪽을 보는 3/4 시점에서는 붉은 리본과 작은 땋은 머리가 얼굴 쪽(먼 쪽) 관자놀이에 있어야 한다. 뒤통수 쪽이면 잘못된 위치다.`r`n- 일부만 틀렸으면 해당 영역만 마스크 편집하고 마스크 밖 RGBA 차이 0을 검사한다. 최대 3회 안에 해결되지 않으면 최선 시안을 보존하고 보고한다.`r`n",$utf8)
[IO.File]::AppendAllText((Join-Path $PWD 'art/steps/S04.md'),"`r`n## 작업 지시 · 2026-10-15`r`n`r`n사용자 지시: S03 승인 후 S04 11장만 진행. 표정 4종은 승인 neutral 얼굴 마스크 편집 및 얼굴 밖 픽셀 차이 0 검사. SD 3종은 승인 idle·attack 모두 참조, 얼굴 쪽 관자놀이 리본, 512×512 및 발끝 y487 동일. 컷인·아이콘 FORMAT 준수, 아이콘은 docs/05-combat.md 10절 C01 방패 강타·도발·기사의 맹세. 일부 오류는 국소 마스크 편집, 최대 3회 실패 시 최선 시안 보존 및 보고. 최종 검토 대기, S04 승인·S05 진행·commit/push 금지.`r`n",$utf8)
$style=[IO.File]::ReadAllText((Join-Path $PWD 'art/style-guide.md'))
$chars=[IO.File]::ReadAllText((Join-Path $PWD 'art/characters.md'))
$styleBlock=[regex]::Match($style,'(?s)## 2\. STYLE_BLOCK\s*```\s*(.*?)\s*```').Groups[1].Value
$negative=[regex]::Match($style,'(?s)## 5\. NEGATIVE_BLOCK\s*```\s*(.*?)\s*```').Groups[1].Value
$body=[regex]::Match($chars,'- BODY: `([^`]+)`').Groups[1].Value
$combat=[regex]::Match($chars,'- COMBAT: `([^`]+)`').Groups[1].Value
$assets=@()
foreach($row in ($rows|Where-Object {$_.step -eq 'S04'})) {
 $format=[regex]::Match($style,('\| `'+$row.format+'` \| [^\r\n]*?\| `([^`]+)`')).Groups[1].Value
 $refs=@('art/refs/style-anchor.png','art/refs/C01_ref_combat.png')
 $extra=$row.extra
 if($row.format -eq 'portrait'){$refs=@($row.refs)+$refs;$extra+="`nEdit target is Image 1, the approved neutral. Edit ONLY the face interior (eyebrows, eyes, cheeks and mouth). Preserve all hair including every overhanging bang, ribbon, ears, jaw silhouette, pose, body, clothes, weapons, canvas and background exactly. Keep face coordinates identical, output 1024x1536. No head movement. The final will use a fixed face-only mask composited onto the approved original."}
 if($row.format -eq 'sd'){$refs+=@('art/final/characters/C01_lina/C01_sd_idle.png','art/final/characters/C01_lina/C01_sd_attack.png');$extra+="`nMatch the approved SD references: 2.5-head proportions, same large head and short body, facing RIGHT. Ribbon and small braid at the FACE-SIDE far temple, screen-right edge of the head, NEVER the near back-of-head screen-left. Longsword right hand, shield strapped to left forearm using inner handle. Retain gold CROSS FLEURY, white frilled hem. Entire body and weapons fully inside square with generous margins. Feet at bottom. No shadow, aura, particles or ground. Actual transparent background overrides magenta. Head size at final 512 should be about 180px, comparable to idle (not a tiny head).";if($row.id -eq 'C01_sd_skill'){$extra+="`nSignature skill SHIELD BASH: pushing the left forearm shield strongly forward toward screen-right, sword in right hand held back. Determined face. A compact braced pose."};if($row.id -eq 'C01_sd_down'){$extra+="`nExhausted kneeling pose, torso upright enough to read, one boot sole/toe resting at ground baseline, eyes tired. Keep sword gripped in right hand and shield attached to left forearm. Not lying flat."}}
 if($row.format -eq 'cutin'){$extra+="`nKnight's Oath is defensive: heroic resolve, sheltering allies and intercepting damage. Keep all important action inside the central horizontal one-third-height band of the 1536x1024 image so it can crop to 3:1. Face, crossed raised sword and heater shield should remain readable together. Chestnut hair, pale violet eyes, red ribbon on anatomical left face-side temple. Cinematic golden oath light, crimson and dark medieval background, no text. Opaque image."}
 if($row.format -eq 'icon'){
  $extra+="`nThis is an abstract skill symbol, not a portrait: do not depict Lina's face or entire body. Use her white heater shield with a single red chevron. Exactly one bold integrated symbol, high contrast at 48px. Opaque dark parchment vignette. No UI frame or text."
  if($row.id -eq 'C01_icon_skill1'){$extra+="`nSHIELD BASH: one white red-chevron heater shield driving rightward into a single bright ochre impact burst, forceful shove/pushback. Steel rim and dynamic diagonal."}
  if($row.id -eq 'C01_icon_skill2'){$extra+="`nTAUNT: one raised white red-chevron shield seen frontally, encircled by a few bold crimson challenge rays directed outward, aggressive provoking signal. Clearly different from the impact shield bash."}
  if($row.id -eq 'C01_icon_ult'){$extra+="`nKNIGHT'S OATH: defensive damage interception for adjacent allies and damage reduction, NOT an offensive ultimate. One golden longsword crossed behind a protective white red-chevron shield beneath a radiant gold protective oath arc. The shield is dominant, warm sheltering glow."}
 }
 $prompt="$styleBlock`n`n$format`n`n$body`n$combat`n`n$extra`n`n$negative"
 foreach($ref in $refs){if(!(Test-Path -LiteralPath $ref)){throw "Missing reference $ref"}}
 if(!$format -or !$styleBlock -or !$body){throw 'Prompt parsing failed'}
 $raw='art/raw/'+$row.id+'_v1.png';if(Test-Path -LiteralPath $raw){throw "Existing raw: $raw"}
 $record="Tool: built-in image_gen.imagegen (underlying model identifier not exposed)`r`nDate: 2026-10-15`r`nReferences (ordered):`r`n"+($refs -join "`r`n")+"`r`n`r`nFull actual prompt:`r`n$prompt`r`n"
 [IO.File]::WriteAllText((Join-Path $PWD ($raw -replace '\.png$','.prompt.txt')),$record,$utf8)
 $assets+=@{id=$row.id;format=$row.format;output=$row.output;raw=$raw;refs=$refs;prompt=$prompt}
}
if($assets.Count -ne 11){throw "Expected 11 assets, got $($assets.Count); check manifest step column"}
$assets|ConvertTo-Json -Depth 6
