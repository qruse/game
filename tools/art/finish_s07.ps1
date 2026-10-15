param([Parameter(Mandatory=$true)][string]$CombatSource,[Parameter(Mandatory=$true)][string]$CasualSource)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$utf8=[Text.UTF8Encoding]::new($false)
$qa=Join-Path $root 'art/raw/qa_S07'
$records=@()
foreach($item in @(@{id='C02_ref_combat';source=$CombatSource},@{id='C02_ref_casual';source=$CasualSource})) {
    $id=$item.id
    $raw=Join-Path $root "art/raw/${id}_v1.png"
    $final=Join-Path $root "art/refs/${id}.png"
    if(-not (Test-Path -LiteralPath $raw)) { Copy-Item -LiteralPath $item.source -Destination $raw }
    if(Test-Path -LiteralPath $final) {
        if((Get-FileHash -LiteralPath $final).Hash -ne (Get-FileHash -LiteralPath $item.source).Hash) { throw "Preserve existing asset: $id" }
    } else { Copy-Item -LiteralPath $item.source -Destination $final }
    $bitmap=[Drawing.Bitmap]::FromFile($final)
    $nonopaque=0
    for($y=0;$y -lt $bitmap.Height;$y++) { for($x=0;$x -lt $bitmap.Width;$x++) { if($bitmap.GetPixel($x,$y).A -ne 255) { $nonopaque++ } } }
    $records+= [ordered]@{id=$id;width=$bitmap.Width;height=$bitmap.Height;nonopaque_pixels=$nonopaque;selected_png_preserved=((Get-FileHash $item.source).Hash -eq (Get-FileHash $final).Hash);raw="art/raw/${id}_v1.png";edit_raw="art/raw/${id}_v2.png";output="art/refs/${id}.png"}
    $bitmap.Dispose()
    if($nonopaque -ne 0) { throw "Reference sheet must have opaque grey backdrop: $id" }
    $refs=@('art/refs/style-anchor.png','art/refs/C01_ref_combat.png','art/refs/C01_ref_casual.png')
    if($id -eq 'C02_ref_casual') { $refs=@('art/refs/C02_ref_combat.png')+$refs }
    $prompt=[IO.File]::ReadAllText((Join-Path $qa "${id}.full-prompt.txt"))
    $editPrompt=[IO.File]::ReadAllText((Join-Path $qa "${id}.edit-prompt.txt"))
    if($id -eq 'C02_ref_casual') {
        $editPrompt+="`n`nFINAL LOCAL SCAR PASS (third and last image call):`n"+[IO.File]::ReadAllText((Join-Path $qa 'C02_ref_casual.scar-v3-prompt.txt'))+"`nEdit references in order: art/raw/qa_S07/C02_ref_casual_before_scar_v3.png; art/refs/C02_ref_combat.png (corrected scar).`nOriginal casual generation used the initial combat sheet, archived as art/raw/C02_ref_combat_v1.png. Third edit raw: art/raw/C02_ref_casual_v3.png.`n"
    }
    $editVerification=[IO.File]::ReadAllText((Join-Path $qa "${id}_repair_verification.txt"))
    $record="Model/tool: OpenAI built-in image_gen. Exact backend model identifier is not exposed by this tool; not inferred.`nGeneration date: 2026-10-15 (Asia/Seoul)`nMode: built-in generation with image references; no CLI/API fallback.`nReferences in attachment order:`n- "+($refs -join "`n- ")+"`n`nFULL PROMPT (verbatim):`n"+$prompt+"`n`nLOCAL EDIT PROMPT (verbatim):`n"+$editPrompt+"`nEdit reference: art/raw/${id}_v1.png (the generated refs file at time of edit).`n`nPostprocessing: original generation and edit preserved byte-for-byte in raw v1/v2. Tool has no mask argument: only specified repair mask regions from edit were composited over v1; all outside RGBA preserved. Native 1536x1024 opaque grey sheet retained; no resizing, background removal or mirroring. Verification: "+$editVerification+"`nQA derivatives saved separately. Status: generated, awaiting user approval.`n"
    if($id -eq 'C02_ref_casual') { $record=$record.Replace('Status: generated, awaiting user approval.','Status: todo (QA hold). Best candidate preserved after three image calls; front LEFT-cheek scar remains absent/indistinct. Further edits deferred to next session.') }
    [IO.File]::WriteAllText((Join-Path $root "art/refs/${id}.prompt.txt"),$record,$utf8)
}
# QA derivative: full approved Lina sheets beside the matching Cecile sheets.
$board=[Drawing.Bitmap]::new(2304,1648,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($board); $g.Clear([Drawing.Color]::FromArgb(235,235,235))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=[Drawing.Font]::new('Arial',22)
$cells=@(@{file='C01_ref_combat';x=0;y=0;label='LINA - COMBAT (approved)'},@{file='C02_ref_combat';x=1152;y=0;label='CECILE - COMBAT (review)'},@{file='C01_ref_casual';x=0;y=824;label='LINA - CASUAL (approved)'},@{file='C02_ref_casual';x=1152;y=824;label='CECILE - CASUAL (review)'})
foreach($cell in $cells) {
    $g.DrawString($cell.label,$font,[Drawing.Brushes]::Black,$cell.x+16,$cell.y+8)
    $im=[Drawing.Bitmap]::FromFile((Join-Path $root ('art/refs/'+$cell.file+'.png')))
    $g.DrawImage($im,[Drawing.Rectangle]::new($cell.x,$cell.y+56,1152,768))
    $im.Dispose()
}
$board.Save((Join-Path $root 'art/raw/qa_S07_lina_comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$board.Dispose()
# Same-character face and body comparison, front views only. No mirroring.
$board=[Drawing.Bitmap]::new(1800,1400,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($board);$g.Clear([Drawing.Color]::FromArgb(235,235,235));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for($i=0;$i -lt 2;$i++) {
    $name=@('C02_ref_combat','C02_ref_casual')[$i]
    $im=[Drawing.Bitmap]::FromFile((Join-Path $root "art/refs/$name.png"))
    $g.DrawString($name,$font,[Drawing.Brushes]::Black,$i*900+16,8)
    $g.DrawImage($im,[Drawing.Rectangle]::new($i*900,56,600,1200),[Drawing.Rectangle]::new(0,0,[int]($im.Width/3),$im.Height),[Drawing.GraphicsUnit]::Pixel)
    $g.DrawImage($im,[Drawing.Rectangle]::new($i*900+600,56,300,300),[Drawing.Rectangle]::new([int]($im.Width*0.08),0,[int]($im.Width*0.23),[int]($im.Height*0.345)),[Drawing.GraphicsUnit]::Pixel)
    $im.Dispose()
}
$board.Save((Join-Path $root 'art/raw/qa_S07_identity.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$board.Dispose();$font.Dispose()
$baseline=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline_hashes.json') | ConvertFrom-Json
$changed=@($baseline | Where-Object { (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 })
$result=[ordered]@{date='2026-10-15';assets=$records;existing_asset_count=@($baseline).Count;existing_assets_changed=$changed;comparison='art/raw/qa_S07_lina_comparison.png';identity='art/raw/qa_S07_identity.png'}
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($result | ConvertTo-Json -Depth 8),$utf8)
$result | ConvertTo-Json -Depth 8
if($changed.Count -ne 0) { throw 'Existing asset changed.' }
