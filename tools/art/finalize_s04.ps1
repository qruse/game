$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
$utf8=[Text.UTF8Encoding]::new($false)
$rows=@(Import-Csv art/manifest.csv -Encoding UTF8|Where-Object {$_.step -eq 'S04'})
if($rows.Count -ne 11){throw 'S04 row count'}
foreach($r in $rows){
 if(!(Test-Path -LiteralPath $r.output)){throw "Missing final $($r.id)"}
 $raw="art/raw/$($r.id)_v1"
 $record=[IO.File]::ReadAllText((Join-Path $PWD "$raw.prompt.txt"))
 $record+="`r`nTool parameters: referenced_image_paths were the absolute workspace paths corresponding to the ordered references above; transparent_background="+([string]($r.format -in @('portrait','sd'))).ToLower()+".`r`nOriginal output preserved: $raw.png`r`n"
 if($r.format -eq 'portrait'){
  $name=$r.id -replace '^C01_portrait_combat_',''
  $record+="Postprocessing: style-guide 3.1.4 fallback. Built-in tool has no explicit mask parameter. Reused the S03 fixed face-interior polygons excluding hair with inward 4px feather. Composited RGB only onto the approved neutral; retained original alpha and exact canvas/placement. Output 1024x1536.`r`nSaved-PNG independent QA: outside face mask RGBA difference=0; alpha difference=0. See art/raw/qa_S04/$name/face_mask.png and verification.json.`r`n"
 }elseif($r.id -eq 'C01_sd_down'){
  foreach($v in @(2,3)){$record+="`r`n----- Local repair call $v -----`r`n"+[IO.File]::ReadAllText((Join-Path $PWD "art/raw/C01_sd_down_v$v.prompt.txt"))}
  $record+="`r`nPostprocessing: fixed local masks composited v2 onto v1 (extra near-side braid + sword tip), then v3 shield tip onto masked v2. Independent saved-PNG outside-mask RGBA differences=0 for both edits. No whole-character regeneration. Total image calls 3; retries 2. Raw candidates and all masks/difference PNGs preserved.`r`nFinal finishing: uniform scale0.30 matching approx180px head width of approved idle, centered horizontally on 512x512, boot toe y487. Interior alpha255, only1px antialiased edge partial; zero partial deeper than2px. Kneeling surcoat hem reaches y488, one pixel below boot baseline; retained for review. See art/raw/qa_S04/verification.json.`r`n"
 }elseif($r.format -eq 'sd'){
  $record+="Postprocessing: native transparent alpha preserved as silhouette; transparent crop and uniform resize to512x512, foot baseline y487,24 transparent rows below. Set interior alpha255; retain inner1px antialiased silhouette edge rather than binary alpha. No horizontal flip. See art/raw/qa_S04/verification.json.`r`n"
 }elseif($r.format -eq 'cutin'){
  $record+="Postprocessing: original1536x1024; crop rectangle(x0,y128,w1536,h512) chosen after visual comparison to retain face/ribbon/sword grip/shield; high-quality resize to1920x640, opaque. Extreme close-up intentionally crops crown and long blade. No generated scene alteration.`r`n"
 }else{
  $record+="Postprocessing: square1254x1254 original resized to256x256 with high-quality bicubic. Opaque dark parchment vignette, no frame or text. Visual QA at48px in art/raw/qa_S04/icons_contact.png. Gameplay source: docs/05-combat.md section10 C01.`r`n"
 }
 $record+="`r`nStatus: generated; pending user review. Built-in image_gen only; no API/CLI image generation. Output: $($r.output)`r`n"
 $dest=Join-Path $PWD ([IO.Path]::ChangeExtension($r.output,'.prompt.txt'))
 if(Test-Path -LiteralPath $dest){throw "Prompt already exists: $dest"}
 [IO.File]::WriteAllText($dest,$record,$utf8)
}
$lines=[IO.File]::ReadAllLines((Join-Path $PWD 'art/manifest.csv'),[Text.Encoding]::UTF8)
for($i=0;$i -lt $lines.Length;$i++){
 if($lines[$i] -match '^([^,]+),S04,'){
  $id=$Matches[1];$note='2026-10-15 built-in image_gen; saved PNG QA pass; prompt and raw/qa_S04 preserved; user review pending'
  if($id -match 'portrait'){$note+='; face-only mask composite; outside-face RGBA diff0; alpha diff0'}
  if($id -match '^C01_sd_'){$note+='; approved idle and attack both referenced; face-side ribbon; 512x512; boot baseline y487; interior alpha255; soft edge'}
  if($id -eq 'C01_sd_down'){$note+='; calls3 retries2 local masked repairs only; outside-mask diff0; kneeling hem y488 is1px below boot for review; no unresolved 3-attempt design failure'}
  if($id -eq 'C01_cutin'){$note+='; 1920x640 crop x0 y128 w1536 h512'}
  if($id -match '^C01_icon_'){$note+='; 256x256; docs05 section10 C01 skill semantics; 48px visual QA'}
  $lines[$i]=[regex]::Replace($lines[$i],',(todo|generated),.*$',(",generated,$note"))
 }
}
[IO.File]::WriteAllLines((Join-Path $PWD 'art/manifest.csv'),$lines,$utf8)
$p=Join-Path $PWD 'art/steps/README.md';$s=[IO.File]::ReadAllText($p);$s=$s -replace '(\| \[S04\].*\| )진행 중( \|)','$1검토 대기$2';[IO.File]::WriteAllText($p,$s,$utf8)
$items=($rows|ForEach-Object {"- $($_.id) → $($_.output)"}) -join "`r`n"
$report=@"

## 진행 기록 · 2026-10-15

[S04 보고]
만든 것: 아래 11장 모두 generated. 내장 image_gen 사용, 각 최종 PNG 옆 .prompt.txt에 전체 실제 프롬프트·도구/날짜·참조·후처리 기록.
$items

재시도한 것: C01_sd_down만 재시도 2회(총 3회). v1의 반대쪽 추가 땋은 머리 및 검 끝을 v2 국소 마스크로 수정, v3에서 방패 끝만 올림. 두 편집 모두 저장 PNG 마스크 밖 RGBA 차이 0. 나머지 10장은 각 1회, 재시도 0. QA 3회 실패로 남은 id 없음.
스스로 본 문제: down의 무릎 자세 치맛단은 y488로 부츠 기준선 y487보다 1px 내려옴. 발끝 기준선은 동일하며 이 미세 차이는 최종 시안에 보존. 컷인은 극근접 구도로 머리 꼭대기와 검날 일부가 크롭됨. 게임 화면 목업 검사는 Claude 담당으로 미수행.
확인 요청: 표정 6종 차이, SD 5동작 크기·리본·down 치맛단, 컷인 구도, 아이콘 48px 가독성 검토. S04 검토 대기에서 멈춤. S04 승인 처리·S05 진행·git commit/push 없음.

### QA 근거

- 표정 4종: 승인 neutral의 얼굴 내부 고정 마스크만 합성. 1024×1536 및 위치 유지. 독립 재읽기 결과 얼굴 밖 RGBA 차이 0, 알파 차이 0. 마스크·차이·얼굴 확대: art/raw/qa_S04/angry, sad, surprised, embarrassed.
- SD 3종: 최초 생성에 style-anchor·전투복 레퍼런스·승인 C01_sd_idle·C01_sd_attack 모두 첨부. 512×512, 얼굴 쪽 관자놀이 리본, 오른손 검·왼팔 방패, 내부 알파255 및 가장자리1~2px만 반투명 확인. skill/hit 전체 최하단 y487, down 부츠 y487 및 치맛단 y488.
- 컷인 1920×640, 아이콘 각256×256 불투명. 아이콘은 docs/05-combat.md 10절 C01의 방패 강타(밀치기), 도발, 기사의 맹세(아군 피해 대신 받기·피해 감소)에 대응. 48px 축소 비교 완료.
- 승인/S03 PNG·프롬프트 14파일 SHA256 불변. 독립 수치 보고: art/raw/qa_S04/verification.json. 비교 시트: expressions_contact.png, sd_contact.png, icons_contact.png. 원본·실패 시안·국소 편집 후보 전부 art/raw/에 보존.
- 재현 및 검증 도구: tools/art/finish_s03.ps1, finish_s04.ps1, verify_s04.ps1. S03 승인 후 공통 SD 규칙은 style-guide.md에 반영 완료.
"@
[IO.File]::AppendAllText((Join-Path $PWD 'art/steps/S04.md'),$report,$utf8)
@{generated=@($rows.id);final_prompt_count=11;readme='S03 승인 / S04 검토 대기 / S05 대기'}|ConvertTo-Json
