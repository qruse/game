$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S09'
New-Item -ItemType Directory -Force -Path $qa | Out-Null
$baseline=@(Get-ChildItem (Join-Path $root 'art/final'),(Join-Path $root 'art/refs') -Recurse -File | ForEach-Object { [ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} })
if(Test-Path (Join-Path $qa 'baseline_hashes.json')) { throw 'S09 baseline already exists; do not replace.' }
[IO.File]::WriteAllText((Join-Path $qa 'baseline_hashes.json'),($baseline|ConvertTo-Json -Depth 5),$utf8)
Copy-Item -LiteralPath (Join-Path $root 'art/manifest.csv') -Destination (Join-Path $qa 'manifest_before.csv')
$mp=Join-Path $root 'art/manifest.csv';$mt=[IO.File]::ReadAllText($mp)
$rows=@(Import-Csv -LiteralPath $mp -Encoding UTF8 | Where-Object step -eq 'S08')
if($rows.Count -ne 21) { throw 'S08 must have exactly 21 assets.' }
foreach($row in $rows) {
    if(-not(Test-Path -LiteralPath (Join-Path $root $row.output))) { throw "S08 missing PNG: $($row.id)" }
    if(-not(Test-Path -LiteralPath (Join-Path $root ($row.output -replace '\.png$','.prompt.txt')))) { throw "S08 missing prompt: $($row.id)" }
    $mt=[regex]::Replace($mt,'(?m)^'+[regex]::Escape($row.id)+',[^\r\n]*',{param($m)
        $r=$m.Value|ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
        $r.status='approved';$r.notes+='; 2026-10-15 사용자 S08 전체 승인 처리; PNG 및 prompt 보존'
        ($r|ConvertTo-Csv -NoTypeInformation)[1]
    })
}
[IO.File]::WriteAllText($mp,$mt,$utf8)
$sp=Join-Path $root 'art/steps/S08.md';$st=[IO.File]::ReadAllText($sp)
$st=$st.Replace('## 피드백',"## 피드백`n`n- 2026-10-15 사용자 승인")
$st+="`n`n## 승인 후 처리 · 2026-10-15`n`n사용자 승인에 따라 S08의 21개 manifest 행을 모두 approved로 기록했다. 기존 PNG와 .prompt.txt는 변경하지 않았다. 이 단계 파일에는 별도의 복사·파생 에셋 생성 지시가 없으므로 승인 상태와 기록만 반영했다. art/steps/README.md의 S08 상태를 승인으로 변경했다.`n"
[IO.File]::WriteAllText($sp,$st,$utf8)
$rp=Join-Path $root 'art/steps/README.md';$rt=[IO.File]::ReadAllText($rp)
$rt=$rt.Replace('| [S08](S08.md) | 세실 세트 | 21 | P1 | 검토 대기 |','| [S08](S08.md) | 세실 세트 | 21 | P1 | 승인 |')
$rt=$rt.Replace('| [S09](S09.md) | 아델하이트 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 대기 |','| [S09](S09.md) | 아델하이트 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 진행 중 |')
[IO.File]::WriteAllText($rp,$rt,$utf8)
$sp=Join-Path $root 'art/steps/S09.md';$st=[IO.File]::ReadAllText($sp)
$st=$st.Replace('(아직 없음)','- 2026-10-15 · 사용자 실행 지시: S08 승인 처리 후 S09 전투복·일상복 시트 2장만 제작. characters.md C03 원문 BODY/COMBAT/CASUAL 및 MUST KEEP 유지. 승인 리나·세실 네 시트의 화풍·배치 참조, 얼굴 복사 금지. 세 방향 소품 손·땋은 머리 좌우·안경 확인. 일상복은 전투복 얼굴·체형을 유지하고 노출 낮음·귀여움 담당. raw에 세 캐릭터 나란히 QA 대조. 실패 최대3회·국소 결함은 해당 부분만 마스크 편집. 검토 대기 후 정지·커밋/S10 금지.')
[IO.File]::WriteAllText($sp,$st,$utf8)
$guide=[IO.File]::ReadAllText((Join-Path $root 'art/style-guide.md'))
$chars=[IO.File]::ReadAllText((Join-Path $root 'art/characters.md'))
$style=[regex]::Match($guide,'(?s)## 2\. STYLE_BLOCK\s+```\s*(.*?)\s*```').Groups[1].Value
$negative=[regex]::Match($guide,'(?s)## 5\. NEGATIVE_BLOCK\s+```\s*(.*?)\s*```').Groups[1].Value
$c03=[regex]::Match($chars,'(?s)### C03 .*?(?=### C04)').Value
$body=[regex]::Match($c03,'- BODY: `([^`]+)`').Groups[1].Value
$format='Character reference sheet: full body front view, side view and back view of the same character side by side, neutral standing pose, plain flat light grey background, consistent design across all views.'
$common=@'
Use case: stylized-concept. Production character model sheet, landscape 1536x1024.
Match the attached approved Lina and Cecile reference sheets in clean line quality, restrained cel shading with soft highlights, fabric rendering, adult anime anatomy, three equal columns, head and foot alignment and figure scale. Images 1-5 are style/layout references only: do not copy either woman's facial identity, hair, armor, colors or clothes. Adelheid must be a distinct adult woman with a softly oval face, quieter narrow golden eyes, black bangs, small closed mouth and round iron wire spectacles; a bookish dry aloof look, cute rather than seductive. No text, labels, panels or annotations. Plain opaque light grey background. Leave small outer margins; show every staff tip, shoe, hand and book inside the canvas. FRONT at left, LEFT SIDE PROFILE facing canvas left at center, BACK at right. No horizontal mirroring. Back view glasses are visible as correctly wrapping thin iron temples above both ears, not eyes or lenses painted on the back of the head. Glasses lenses/rims unmistakable on front and left profile. No modern plastic glasses. The negative modern-eyewear rule does not prohibit the character's REQUIRED simple round iron wire spectacles.
Fixed anatomical layout: exactly ONE thick black braid originates at nape, passes OVER HER LEFT SHOULDER and hangs down her LEFT chest. Front: braid on viewer RIGHT. Left profile: braid visible on NEAR left shoulder/chest. Back: braid route on viewer LEFT of nape/left shoulder, tail continues in FRONT and is naturally partly occluded. Never place a second braid down the center back, never switch shoulders. Keep the same body, hair length, garment construction and held-object anatomy in all three views. Navy/charcoal and black silhouette should be distinct from Lina's crimson/brown and Cecile's green/silver.
'@
$combat=@'
Ankle-length modest DARK NAVY modified former novice nun robe, short matching shoulder cape, restrained pale linen high collar/cuffs, practical brown leather shoes. Head uncovered so black hair and glasses are visible. No armor, thief hood or modern witch costume. The torso is fully covered with natural loose fabric, no cleavage or slits. She holds ONE gnarled wooden staff vertically in her anatomical RIGHT hand and cradles ONE thick CLOSED dark leather grimoire bound visibly around its covers with an IRON CHAIN in her anatomical LEFT hand/forearm. Natural five-finger hands, thumb opposing grip; book supported from below. FRONT: staff and right hand on viewer LEFT, book and left hand on viewer RIGHT. LEFT profile: left book arm is near, staff right arm is far, wooden staff can be offset forward enough to remain visible. BACK: staff and right hand on viewer RIGHT, chain-bound book and left hand on viewer LEFT. Same staff knots, iron chain and book thickness in every view. Calm closed-mouth dry expression. No spell effects.
'@
$casual=@'
Image 1 is the newly made Adelheid COMBAT sheet and is the PRIMARY IDENTITY reference: preserve precisely her face shape, golden eyes, nose, bangs, adult age, body proportions, single braid shoulder, and round iron glasses. Remaining images are style/layout references only; never copy Lina or Cecile's face. Match the combat reference's three columns and figure height.
Low exposure, cozy cute adult reader. Oversized opaque CHARCOAL/DARK NAVY wool nightshirt with high modest neckline, very long sleeves covering the palms, hem reaching just below knees; thick opaque charcoal wool stockings fully cover legs above the hem so no bare-thigh gap, knitted muted slate-grey shawl. Relaxed drape; no corset, cleavage, bare shoulders, bare midriff, lingerie or seductive posing. Her ONE braid remains over anatomical LEFT shoulder, more loosely plaited and slightly messy with stray hairs, not unbraided loose hair or a second braid. Sleepy cozy closed-mouth expression, same person and adult physique as combat.
ONE candle in a simple small iron fingerloop holder is held in her anatomical RIGHT hand, visible fingertips emerging just enough from the long sleeve to hold it safely. ONE thick OPEN grimoire is supported by her anatomical LEFT hand/forearm; its SAME iron chain is loosened around the covers without crossing/closing the open pages. No writing on the pages. Preserve the wooden staff as the same recognizable gnarled staff resting on the floor on her anatomical RIGHT, lightly leaning against her outer RIGHT shoulder/upper arm; she does NOT need an extra hand to hold it. Staff stays on the right side in all views. FRONT: candle/right hand and leaning staff viewer LEFT; open book/left hand and braid viewer RIGHT. LEFT profile: near LEFT arm supports open book and near braid visible; far RIGHT candle hand and staff remain identifiable without extra arms. BACK: candle and resting staff viewer RIGHT, left book arm and braid shoulder viewer LEFT. Correct fingers, no merged candle/staff, no extra props. Candle small and clear of sleeves and hair, no environmental lighting effects. All views stand neutrally on the same baseline.
'@
foreach($outfit in @('combat','casual')) {
    $costume=[regex]::Match($c03,('- '+$outfit.ToUpper()+': `([^`]+)`')).Groups[1].Value
    $extra=if($outfit -eq 'combat') { $common+"`n"+$combat } else { $common+"`n"+$casual }
    $prompt=$style+"`n`n"+$format+"`n`n"+$body+"`n`n"+$costume+"`n`n"+$extra+"`n`n"+$negative
    if(-not $body -or -not $style -or -not $costume -or -not $negative) { throw 'Prompt block missing' }
    [IO.File]::WriteAllText((Join-Path $qa "C03_ref_$outfit.full-prompt.txt"),$prompt,$utf8)
}
"S08 approved assets: $($rows.Count). Existing PNG/prompt baseline: $($baseline.Count). S09 started and prompts assembled."
