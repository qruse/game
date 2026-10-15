$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S09'
$utf8=[Text.UTF8Encoding]::new($false)
$records=@()
foreach($outfit in @('combat','casual')) {
 $id="C03_ref_$outfit";$png=Join-Path $root "art/refs/$id.png"
 $im=[Drawing.Bitmap]::FromFile($png);$nonopaque=0
 for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){if($im.GetPixel($x,$y).A -ne 255){$nonopaque++}}}
 if($im.Width -ne 1536 -or $im.Height -ne 1024 -or $nonopaque -ne 0){throw "Invalid sheet format: $id"}
 $records += [ordered]@{id=$id;width=$im.Width;height=$im.Height;nonopaque_pixels=$nonopaque;calls=$(if($outfit -eq 'combat'){1}else{2});output="art/refs/$id.png";sha256=(Get-FileHash $png).Hash}
 $im.Dispose()
 $refs=if($outfit -eq 'combat'){@('art/refs/style-anchor.png','art/refs/C01_ref_combat.png','art/refs/C01_ref_casual.png','art/refs/C02_ref_combat.png','art/refs/C02_ref_casual.png')}else{@('art/refs/C03_ref_combat.png','art/refs/style-anchor.png','art/refs/C01_ref_combat.png','art/refs/C02_ref_combat.png','art/refs/C02_ref_casual.png')}
 foreach($ref in $refs){if(-not(Test-Path (Join-Path $root $ref))){throw "Missing reference: $ref"}}
 $prompt=[IO.File]::ReadAllText((Join-Path $qa "$id.full-prompt.txt"))
 $record="Model/tool: OpenAI built-in image_gen. Exact backend model identifier is not exposed by this tool; not inferred.`nGeneration date: 2026-10-15 (Asia/Seoul)`nMode: built-in generation using local image references; no CLI/API fallback.`nReferences in exact attachment order:`n- "+($refs -join "`n- ")+"`n`nFULL GENERATION PROMPT (verbatim):`n"+$prompt+"`n`nRaw generation: art/raw/${id}_v1.png. Original 1536x1024 opaque grey reference-sheet format retained. No resize, background removal or horizontal flip.`n"
 if($outfit -eq 'casual') {
  $record+="`nLOCAL CLOTHING EDIT PROMPT (verbatim):`n"+[IO.File]::ReadAllText((Join-Path $qa "$id.edit-prompt.txt"))+"`nEdit reference: art/raw/C03_ref_casual_v1.png. Edit result: art/raw/C03_ref_casual_v2.png. Tool has no mask argument, so selected clothing pixels from this result were composited over v1 with tools/art/repair_s09_casual.ps1. Mask, difference image and selected result preserved in art/raw/qa_S09. Same model result reused while refining mask boundaries; no further image calls. Verification: "+[IO.File]::ReadAllText((Join-Path $qa 'C03_ref_casual_repair_verification.txt'))+"`nA request with six image references was rejected by tool validation before generation; corrected to five. Not a model QA attempt.`n"
 }
 $record+="`nQA: golden eyes and round iron glasses; one black braid over anatomical LEFT shoulder. FRONT staff/candle RIGHT hand on viewer LEFT, grimoire LEFT hand on viewer RIGHT; LEFT-profile near arm carries book; BACK staff/candle on viewer RIGHT, book/braid route viewer LEFT. Back glasses visible at temples/ear, no lenses painted on back of head. Combat navy robe and closed iron-chain book. Casual modest oversized charcoal wool nightshirt, thick opaque stockings, knitted shawl, candle and open iron-chain book. Staff preserved on anatomical RIGHT beside candle. Casual image uses combat as identity reference. No writing/watermark; all props inside canvas. Compare full sheets, faces and front silhouettes in art/raw/qa_S09. Status: generated, awaiting user approval.`n"
 [IO.File]::WriteAllText((Join-Path $root "art/refs/$id.prompt.txt"),$record,$utf8)
}
$font=[Drawing.Font]::new('Arial',22)
$board=[Drawing.Bitmap]::new(2304,1136,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(235,235,235));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for($row=0;$row -lt 2;$row++){for($col=0;$col -lt 3;$col++){
 $outfit=@('combat','casual')[$row];$id=@('C01','C02','C03')[$col];$name=@('LINA - APPROVED','CECILE - APPROVED','ADELHEID - REVIEW')[$col]
 $im=[Drawing.Bitmap]::FromFile((Join-Path $root "art/refs/${id}_ref_$outfit.png"))
 $g.DrawString("$name / $outfit",$font,[Drawing.Brushes]::Black,$col*768+12,$row*568+8)
 $g.DrawImage($im,[Drawing.Rectangle]::new($col*768,$row*568+56,768,512));$im.Dispose()
}}
$board.Save((Join-Path $root 'art/raw/qa_S09_lina_cecile_comparison.png'),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$board.Dispose()
# Front silhouettes/colors at a larger common scale, both outfits. Never mirror.
$board=[Drawing.Bitmap]::new(1536,2160,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(235,235,235));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for($row=0;$row -lt 2;$row++){for($col=0;$col -lt 3;$col++){
 $outfit=@('combat','casual')[$row];$id=@('C01','C02','C03')[$col]
 $im=[Drawing.Bitmap]::FromFile((Join-Path $root "art/refs/${id}_ref_$outfit.png"))
 $g.DrawString("$id / $outfit",$font,[Drawing.Brushes]::Black,$col*512+12,$row*1080+8)
 $g.DrawImage($im,[Drawing.Rectangle]::new($col*512,$row*1080+56,512,1024),[Drawing.Rectangle]::new(0,0,512,1024),[Drawing.GraphicsUnit]::Pixel);$im.Dispose()
}}
$board.Save((Join-Path $qa 'front_silhouette_color.png'),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$board.Dispose()
# Six enlarged heads: check identity and glasses in each view.
$board=[Drawing.Bitmap]::new(1536,864,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(235,235,235));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
for($row=0;$row -lt 2;$row++){
 $outfit=@('combat','casual')[$row];$im=[Drawing.Bitmap]::FromFile((Join-Path $root "art/refs/C03_ref_$outfit.png"))
 for($col=0;$col -lt 3;$col++){
  $rx=@(195,680,1140)[$col];$g.DrawString("$outfit / "+@('FRONT','LEFT','BACK')[$col],$font,[Drawing.Brushes]::Black,$col*512+12,$row*432+8)
  $g.DrawImage($im,[Drawing.Rectangle]::new($col*512,$row*432+56,480,360),[Drawing.Rectangle]::new($rx,15,240,180),[Drawing.GraphicsUnit]::Pixel)
 };$im.Dispose()
}
$board.Save((Join-Path $qa 'identity_glasses_6.png'),[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$board.Dispose();$font.Dispose()
$baseline=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline_hashes.json')|ConvertFrom-Json
$changed=@($baseline|Where-Object{(Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256})
if($changed.Count){throw 'An existing approved PNG or prompt changed.'}
$before=@(Import-Csv -Encoding UTF8 (Join-Path $qa 'manifest_before.csv'))
$manifest=Join-Path $root 'art/manifest.csv';$mt=[IO.File]::ReadAllText($manifest)
foreach($outfit in @('combat','casual')){
 $id="C03_ref_$outfit"
 $refs=if($outfit -eq 'combat'){'art/refs/style-anchor.png;art/refs/C01_ref_combat.png;art/refs/C01_ref_casual.png;art/refs/C02_ref_combat.png;art/refs/C02_ref_casual.png'}else{'art/refs/C03_ref_combat.png;art/refs/style-anchor.png;art/refs/C01_ref_combat.png;art/refs/C02_ref_combat.png;art/refs/C02_ref_casual.png'}
 $notes=if($outfit -eq 'combat'){'2026-10-15 내장 image_gen 생성1회·재시도0; 1536x1024 불투명 회색 원본 유지; C03 원문 BODY·COMBAT; 오른손지팡이·왼손쇠사슬마법서·왼어깨땋은머리 세방향 좌우 및 안경 QA 통과; raw·전체prompt·대조QA 보존; S09 사용자 검토 대기'}else{'2026-10-15 내장 image_gen 생성1회+의상국소편집1회(총2회·재시도1); C03 원문 BODY·CASUAL; 전투복 얼굴체형 참조; 낮은노출 모직잠옷·두꺼운스타킹·숄·촛불·펼친쇠사슬책; 마스크밖RGBA차이0·알파차이0; 동일편집출력으로 합성경계 보완(추가생성없음); 1536x1024; raw·전체prompt·대조QA 보존; S09 사용자 검토 대기'}
 $mt=[regex]::Replace($mt,'(?m)^'+$id+',[^\r\n]*',{param($m)
  $r=$m.Value|ConvertFrom-Csv -Header id,step,phase,format,subject,outfit,name_ko,extra,refs,output,status,notes
  $r.refs=$refs;$r.status='generated';$r.notes+='; '+$notes;($r|ConvertTo-Csv -NoTypeInformation)[1]
 })
}
[IO.File]::WriteAllText($manifest,$mt,$utf8)
$after=@(Import-Csv -Encoding UTF8 $manifest)
$diffs=@();for($i=0;$i -lt $before.Count;$i++){
 if(($before[$i]|ConvertTo-Json -Compress) -ne ($after[$i]|ConvertTo-Json -Compress)){
  if($after[$i].step -notin @('S08','S09')){throw "Unexpected manifest change: $($after[$i].id)"}
  $diffs+=$after[$i].id
 }
}
if(@($after|Where-Object{$_.step -eq 'S08' -and $_.status -eq 'approved'}).Count -ne 21){throw 'S08 approval incomplete'}
if(@($after|Where-Object{$_.step -eq 'S09' -and $_.status -eq 'generated'}).Count -ne 2){throw 'S09 completion incomplete'}
$verification=[ordered]@{date='2026-10-15';assets=$records;existing_files_count=@($baseline).Count;existing_files_changed=$changed;manifest_changed_ids=$diffs;S08_approved_count=21;S09_generated_count=2;S10_changed=$false;repair=[IO.File]::ReadAllText((Join-Path $qa 'C03_ref_casual_repair_verification.txt'));comparison='art/raw/qa_S09_lina_cecile_comparison.png';identity='art/raw/qa_S09/identity_glasses_6.png';silhouette='art/raw/qa_S09/front_silhouette_color.png'}
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($verification|ConvertTo-Json -Depth 8),$utf8)
$verification|ConvertTo-Json -Depth 8
