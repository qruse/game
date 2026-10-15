$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
Add-Type -AssemblyName System.Drawing
$source=Get-Content -Raw -Encoding UTF8 tools/art/verify_s03.ps1
$code=[regex]::Match($source,"(?s)-TypeDefinition @'\r?\n(.*?)\r?\n'@").Groups[1].Value
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $code
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class S04Verify {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static int Boot(string path){using(var b=new Bitmap(path)){var p=Read(b);int last=-1;for(int y=400;y<512;y++)for(int x=130;x<=168;x++)if(p[(y*512+x)*4+3]>0)last=Math.Max(last,y);if(last!=487)throw new Exception("Boot baseline failed");return last;}}
 public static string Mask(string before,string after,string mask){using(var a=new Bitmap(before))using(var b=new Bitmap(after))using(var m=new Bitmap(mask)){if(a.Size!=b.Size||a.Size!=m.Size)throw new Exception("Mask dimensions");var ap=Read(a);var bp=Read(b);var mp=Read(m);long outside=0,changed=0;for(int j=0;j<ap.Length;j+=4){bool d=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])d=true;if(d){changed++;if(mp[j]==0)outside++;}}if(outside!=0||changed==0)throw new Exception("Saved mask invariant failed");return "{\"changed_pixels\":"+changed+",\"outside_mask_rgba_difference\":"+outside+"}";}}
 public static void Opaque(string path){using(var b=new Bitmap(path)){var p=Read(b);for(int j=3;j<p.Length;j+=4)if(p[j]!=255)throw new Exception("Unexpected nonopaque pixel");}}
}
'@
$qa='art/raw/qa_S04'
$protected=Get-Content -Raw -Encoding UTF8 "$qa/protected_before.json" | ConvertFrom-Json
foreach($p in $protected){if((Get-FileHash -LiteralPath $p.Path -Algorithm SHA256).Hash -ne $p.Hash){throw "Protected asset changed $($p.Path)"}}
$report=[ordered]@{protected_files_unchanged=$true;protected_count=@($protected).Count;portraits=[ordered]@{};sd=[ordered]@{};other=[ordered]@{}}
$dir='art/final/characters/C01_lina'
foreach($name in @('angry','sad','surprised','embarrassed')){
 $id="C01_portrait_combat_$name"
 $report.portraits[$id]=[ordered]@{face=([S03Verify]::Face("$dir/C01_portrait_combat_neutral.png","$dir/$id.png","$qa/$name/face_mask.png")|ConvertFrom-Json);alpha=([S03Verify]::Alpha("$dir/$id.png",$false)|ConvertFrom-Json)}
}
foreach($name in @('skill','hit','down')){$id="C01_sd_$name";$report.sd[$id]=[S03Verify]::Alpha("$dir/$id.png",($name -ne 'down'))|ConvertFrom-Json}
$report.sd.C01_sd_down | Add-Member -NotePropertyName boot_toe_baseline -NotePropertyValue ([S04Verify]::Boot("$dir/C01_sd_down.png"))
$report.sd.C01_sd_down | Add-Member -NotePropertyName note -NotePropertyValue 'Boot toe y487; kneeling surcoat hem reaches y488 (1px below boot); no clipping. Foot baseline requirement verified separately from entire silhouette.'
$report['local_repairs']=[ordered]@{
 down_hair_sword=([S04Verify]::Mask('art/raw/C01_sd_down_v1.png','art/raw/C01_sd_down_masked_v2.png',"$qa/down_edit_mask.png")|ConvertFrom-Json)
 down_shield=([S04Verify]::Mask('art/raw/C01_sd_down_masked_v2.png','art/raw/C01_sd_down_masked_v3.png',"$qa/down_shield/down_edit_mask.png")|ConvertFrom-Json)
}
foreach($r in (Import-Csv art/manifest.csv -Encoding UTF8|Where-Object {$_.step -eq 'S04' -and $_.format -in @('cutin','icon')})){
 $b=[Drawing.Bitmap]::new((Join-Path $PWD $r.output));try{$expected=if($r.format -eq 'cutin'){@(1920,640)}else{@(256,256)};if($b.Width -ne $expected[0] -or $b.Height -ne $expected[1]){throw 'Dimensions failed'};$report.other[$r.id]=@{width=$b.Width;height=$b.Height;opaque=$true}}finally{$b.Dispose()};[S04Verify]::Opaque($r.output)
}
$json=$report|ConvertTo-Json -Depth 8
[IO.File]::WriteAllText((Join-Path $PWD "$qa/verification.json"),$json,[Text.UTF8Encoding]::new($false))
$json
