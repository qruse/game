param([Parameter(Mandatory=$true)][ValidateSet('combat','casual')][string]$Outfit,[Parameter(Mandatory=$true)][string]$EditSource,[switch]$ScarFinal)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$id="C02_ref_$Outfit"
$qa=Join-Path $root 'art/raw/qa_S07'
$v1=Join-Path $root "art/raw/${id}_v1.png"
$v2=Join-Path $root "art/raw/${id}_v2.png"
if($ScarFinal) {
    if($Outfit -ne 'casual') {throw 'Final scar pass is only for casual.'}
    $v1=Join-Path $qa 'C02_ref_casual_before_scar_v3.png'
    $v2=Join-Path $root "art/raw/${id}_v3.png"
}
if(Test-Path -LiteralPath $v2) {
    if((Get-FileHash -LiteralPath $v2).Hash -ne (Get-FileHash -LiteralPath $EditSource).Hash) {throw 'Preserve existing edit raw.'}
} else {Copy-Item -LiteralPath $EditSource -Destination $v2}
$serialized=if($Outfit -eq 'combat') { '333,124,42,43' } else { '333,124,42,43;1080,300,285,195' }
if($ScarFinal) { $serialized='333,124,42,43' }
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class S07Repair {
 public static string Run(string source,string edit,string final,string maskFile,string rectSpec) {
  using(var old=new Bitmap(source)) using(var generated=new Bitmap(edit)) using(var output=new Bitmap(old)) using(var mask=new Bitmap(old.Width,old.Height,PixelFormat.Format24bppRgb)) {
   if(old.Width!=generated.Width || old.Height!=generated.Height) throw new Exception("Edit dimensions changed.");
   using(var mg=Graphics.FromImage(mask)) mg.Clear(Color.Black);
   foreach(string spec in rectSpec.Split(';')) {
    string[] s=spec.Split(',');int rx=int.Parse(s[0]),ry=int.Parse(s[1]),rw=int.Parse(s[2]),rh=int.Parse(s[3]);
    for(int y=ry;y<ry+rh;y++) for(int x=rx;x<rx+rw;x++) {
     double a=Math.Min(1.0,Math.Min(Math.Min(x-rx,rx+rw-1-x),Math.Min(y-ry,ry+rh-1-y))/3.0);
     Color c=old.GetPixel(x,y),e=generated.GetPixel(x,y);
     output.SetPixel(x,y,Color.FromArgb(255,(int)Math.Round(c.R*(1-a)+e.R*a),(int)Math.Round(c.G*(1-a)+e.G*a),(int)Math.Round(c.B*(1-a)+e.B*a)));
     int v=(int)Math.Round(255*a);mask.SetPixel(x,y,Color.FromArgb(v,v,v));
    }
   }
   output.Save(final,ImageFormat.Png);mask.Save(maskFile,ImageFormat.Png);
   int outside=0,inside=0;
   for(int y=0;y<old.Height;y++) for(int x=0;x<old.Width;x++) if(old.GetPixel(x,y).ToArgb()!=output.GetPixel(x,y).ToArgb()) { if(mask.GetPixel(x,y).R==0)outside++;else inside++; }
   if(outside!=0)throw new Exception("Outside mask changed.");
   return "outside_mask_RGBA_diff_pixels="+outside+"; changed_inside_mask="+inside+"; mask_rectangles="+rectSpec;
  }
 }
}
'@
$selected=Join-Path $qa "${id}_repaired.png"
$mask=Join-Path $qa "${id}_repair_mask.png"
if($ScarFinal) { $selected=Join-Path $qa "${id}_repaired_v3.png"; $mask=Join-Path $qa "${id}_repair_mask_v3.png" }
$result=[S07Repair]::Run($v1,$v2,$selected,$mask,$serialized)
$log=Join-Path $qa "${id}_repair_verification.txt"
if($ScarFinal) { [IO.File]::AppendAllText($log,"`nFinal scar pass: "+$result,[Text.UTF8Encoding]::new($false)) }
else { [IO.File]::WriteAllText($log,$result,[Text.UTF8Encoding]::new($false)) }
Copy-Item -LiteralPath $selected -Destination (Join-Path $root "art/refs/${id}.png")
$result
