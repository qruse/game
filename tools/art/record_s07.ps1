$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$p=Join-Path $root 'art/manifest.csv'
$text=[IO.File]::ReadAllText($p)
foreach($outfit in @('combat','casual')) {
    $id="C02_ref_$outfit"
    $refs=if($outfit -eq 'combat') { 'art/refs/style-anchor.png;art/refs/C01_ref_combat.png;art/refs/C01_ref_casual.png' } else { 'art/refs/style-anchor.png;art/refs/C02_ref_combat.png;art/refs/C01_ref_combat.png;art/refs/C01_ref_casual.png' }
    $notes=if($outfit -eq 'combat') {'2026-10-15 내장 image_gen 총2회 국소편집1회; 정면 왼쪽볼 흉터 보완; 마스크밖 RGBA차이0; 세방향 쌍단검 양허리 수납 양손빈손; 1536x1024 불투명 회색 시트; raw v1/v2 및 전체 prompt 보존; 사용자 검토 대기'} else {'2026-10-15 QA 보류 총3회 한도 도달; 내장 image_gen 생성1회 국소편집2회 후에도 정면 왼쪽볼 흉터가 명확하지 않음; 최선 시안 refs에 보존하되 QA 미통과로 todo 유지; 후면 왼쪽 주머니와 앞매듭 구조는 해결; 각 마스크밖 RGBA차이0; 전투복 v1을 얼굴체형 기준 참조; 중간노출 준수; 1536x1024 불투명 회색 시트; raw v1/v2/v3 및 전체 prompt 보존; 다음 세션 정면 볼 국소편집 필요; 사용자 검토 대기'}
    $text=[regex]::Replace($text,'(?m)^'+$id+',[^\r\n]*',{param($m) $row=$m.Value | ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes; if($row.status -ne 'todo') { throw 'Unexpected initial status.' }; $row.refs=$refs; $row.status=if($outfit -eq 'combat'){'generated'}else{'todo'}; $row.notes+='; '+$notes; (($row | ConvertTo-Csv -NoTypeInformation)[1])}.GetNewClosure())
}
[IO.File]::WriteAllText($p,$text,$utf8)
$p=Join-Path $root 'art/steps/README.md'
$text=[IO.File]::ReadAllText($p).Replace('| [S07](S07.md) | 세실 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 진행 중 |','| [S07](S07.md) | 세실 레퍼런스 시트 (전투복·일상복) | 2 | P1 | 검토 대기 |')
[IO.File]::WriteAllText($p,$text,$utf8)
$before=Import-Csv (Join-Path $root 'art/raw/qa_S07/manifest_before.csv')
$after=Import-Csv (Join-Path $root 'art/manifest.csv')
$changed=@()
for($i=0;$i -lt $before.Count;$i++) {
    if(($before[$i] | ConvertTo-Json -Compress) -ne ($after[$i] | ConvertTo-Json -Compress)) { $changed+=$after[$i].id }
}
$expected=@('bg_guildhall_ruined','bt_ch1_forest_clearing','C02_ref_combat','C02_ref_casual')
if(@($changed | Where-Object {$_ -notin $expected}).Count -or $changed.Count -ne 4) {throw 'Unexpected manifest changes.'}
foreach($s06 in @('bg_guildhall_ruined','bt_ch1_forest_clearing')) {if(($after | Where-Object id -eq $s06).status -ne 'approved') {throw 'S06 approval missing.'}}
if(@($after | Where-Object { $_.step -eq 'S08' -and $_.status -ne 'todo' }).Count) {throw 'S08 must remain todo.'}
[IO.File]::WriteAllText((Join-Path $root 'art/raw/qa_S07/manifest_verification.json'),([ordered]@{changed_ids=$changed;changed_count=$changed.Count;S06='approved';S07_combat='generated';S07_casual='todo - QA hold after 3 calls; front scar unresolved';S08='todo';commit_performed=$false} | ConvertTo-Json -Depth 4),$utf8)
'Manifest verified: only S06 approval and two S07 rows changed. Combat generated; casual todo with QA hold. S08 remains todo.'
