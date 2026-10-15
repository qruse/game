$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S10'
New-Item -ItemType Directory -Force -Path $qa | Out-Null
if(Test-Path (Join-Path $qa 'baseline.json')){throw 'Baseline already exists'}
$baseline=@(Get-ChildItem (Join-Path $root 'art/final'),(Join-Path $root 'art/refs') -Recurse -File | ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
[IO.File]::WriteAllText((Join-Path $qa 'baseline.json'),($baseline|ConvertTo-Json -Depth 4),$utf8)
Copy-Item (Join-Path $root 'art/manifest.csv') (Join-Path $qa 'manifest_before.csv')
$casual=Join-Path $root 'art/refs/C03_ref_casual.png'
$raw=Join-Path $root 'art/raw/C03_ref_casual_v4.png'
if((Get-FileHash $casual).Hash -ne (Get-FileHash $raw).Hash){throw 'Casual raw mismatch'}
$record=[IO.File]::ReadAllText((Join-Path $root 'art/refs/C03_ref_casual.prompt.txt'))
$actual=[IO.File]::ReadAllText((Join-Path $root 'art/raw/qa_S09_casual_redo/generation_prompt.txt')).Trim()
$recorded=[regex]::Match($record,'(?s)FULL GENERATION PROMPT \(verbatim\):\s*(.*?)\s*QA REPORT:').Groups[1].Value.Trim()
if($actual -cne $recorded){throw 'Casual prompt mismatch'}
$previous=[IO.File]::ReadAllText((Join-Path $root 'art/raw/qa_S09_casual_redo/new_prompt_record.txt'))
if($previous.Trim() -cne $record.Trim()){throw 'Casual archived record mismatch'}
$audit="`nProvenance audit - 2026-10-15:`nCurrent PNG and art/raw/C03_ref_casual_v4.png are byte-identical SHA256 F1BE5D28518B0435A22CFD9C8BAF96F379BAB6F5873377ECB845E4306CE3D8C4. FULL GENERATION PROMPT above exactly matches art/raw/qa_S09_casual_redo/generation_prompt.txt after trimming outer whitespace; the entire prior record matches new_prompt_record.txt. Both ordered reference paths and roles are recorded in that archived record. No missing prompt or references found; no inferred prompt text added. Backend model identifier remains unavailable and is not guessed. PNG untouched. User approved the second casual design unchanged on 2026-10-15.`n"
[IO.File]::AppendAllText((Join-Path $root 'art/refs/C03_ref_casual.prompt.txt'),$audit,$utf8)
[IO.File]::WriteAllText((Join-Path $qa 'casual_provenance_audit.txt'),$audit,$utf8)
$mp=Join-Path $root 'art/manifest.csv';$mt=[IO.File]::ReadAllText($mp)
foreach($id in @('C03_ref_combat','C03_ref_casual')){
 $mt=[regex]::Replace($mt,'(?m)^"?'+$id+'"?,[^\r\n]*',{param($m)
  $r=$m.Value|ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
  if($r.status -ne 'generated'){throw 'Unexpected S09 state'}
  $r.status='approved';$r.notes+='; 2026-10-15 사용자 S09 승인(일상복은 두 번째 시안 그대로); PNG 보존'
  ($r|ConvertTo-Csv -NoTypeInformation)[1]
 })
}
[IO.File]::WriteAllText($mp,$mt,$utf8)
$p=Join-Path $root 'art/steps/S09.md';$s=[IO.File]::ReadAllText($p)
$s=$s.Replace('## 피드백',"## 피드백`n`n- 2026-10-15 사용자 승인(일상복은 두 번째 시안 그대로)")
$s+="`n`n## 승인 후 처리 · 2026-10-15`n`nC03_ref_combat 및 C03_ref_casual을 manifest에서 approved로 기록하고 README의 S09를 승인으로 변경했다. 두 PNG는 바이트 그대로 보존했다. 일상복은 raw v4 및 당시 전체 프롬프트·참조 목록과 일치함을 확인하고 .prompt.txt에 대조 근거만 덧붙였다. 별도의 복사·파생 에셋 지시는 없어 추가 이미지를 만들지 않았다. 이전 완료 보고의 일상복 지팡이·쇠사슬 설명은 폐기된 첫 시안의 역사 기록이며, 승인 대상은 니트 잠옷·숄·털양말·실내화·촛불·평범한 책의 두 번째 시안이다.`n"
[IO.File]::WriteAllText($p,$s,$utf8)
$p=Join-Path $root 'art/steps/README.md';$s=[IO.File]::ReadAllText($p)
$s=$s.Replace('| [S09](S09.md) | 아델하이트 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 검토 대기 |','| [S09](S09.md) | 아델하이트 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 승인 |')
$s=$s.Replace('| [S10](S10.md) | 아델하이트 세트 | 21 | P1 | 대기 |','| [S10](S10.md) | 아델하이트 세트 | 21 | P1 | 진행 중 |')
[IO.File]::WriteAllText($p,$s,$utf8)
$p=Join-Path $root 'art/steps/S10.md';$s=[IO.File]::ReadAllText($p)
$s=$s.Replace('(아직 없음)','- 2026-10-15 사용자 지시: S09 승인 후 중간 확인 2장(C03_portrait_combat_neutral, C03_sd_idle)만 제작. 승인 C03 전투복을 인물·의상 기준으로, 승인 리나·세실의 동일 형식 이미지를 화풍·구도·비율 기준으로 참조하고 얼굴은 복사하지 않는다. portrait 정면 무릎 위·차분한 무표정에 가까운 냉소적 얼굴. SD 512×512·발 y487·오른쪽 3/4·기존 동료와 동일한 머리/몸 비율·크기, 지팡이와 마법서를 손에 든 전투 대기. 왼어깨 땋은 머리·안경 확인, COMBAT 대조표 및 raw 나란히 비교. 검토 대기에서 정지, 나머지19장·커밋 금지.')
[IO.File]::WriteAllText($p,$s,$utf8)
New-Item -ItemType Directory -Force -Path (Join-Path $root 'art/final/characters/C03_adelheid') | Out-Null
'Casual raw/prompt/record exact match; S09 approved; S10 started.'
