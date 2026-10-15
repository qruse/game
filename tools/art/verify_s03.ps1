$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class S03Verify {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);if(d.Stride!=b.Width*4)throw new Exception("Stride");var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static string Face(string neutral,string smile,string mask){using(var a=new Bitmap(neutral))using(var b=new Bitmap(smile))using(var m=new Bitmap(mask)){
  if(a.Size!=b.Size||a.Size!=m.Size)throw new Exception("Face dimensions differ");var ap=Read(a);var bp=Read(b);var mp=Read(m);long changed=0,outside=0,alpha=0;
  for(int j=0;j<ap.Length;j+=4){bool differs=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])differs=true;if(differs){changed++;if(mp[j]==0)outside++;}if(ap[j+3]!=bp[j+3])alpha++;}
  if(changed==0||outside!=0||alpha!=0)throw new Exception("Saved face invariants failed");return String.Format("{{\"saved_png_changed_rgba_pixels\":{0},\"saved_png_outside_mask_rgba_difference\":{1},\"saved_png_alpha_difference\":{2}}}",changed,outside,alpha);
 }}
 public static string Alpha(string path,bool sd){using(var b=new Bitmap(path)){
  if(sd&&(b.Width!=512||b.Height!=512))throw new Exception("SD dimensions");var p=Read(b);long zero=0,opaque=0,partial=0,deep=0;int miny=b.Height,maxy=-1;
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){int a=p[(y*b.Width+x)*4+3];if(a==0){zero++;continue;}miny=Math.Min(miny,y);maxy=Math.Max(maxy,y);if(a==255){opaque++;continue;}partial++;
   bool edge=false;for(int dy=-2;dy<=2;dy++)for(int dx=-2;dx<=2;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<b.Width&&yy>=0&&yy<b.Height&&p[(yy*b.Width+xx)*4+3]==0)edge=true;}
   if(!edge)deep++;
  }
  if(zero==0||partial==0||deep!=0||(sd&&maxy!=487))throw new Exception("Saved alpha or baseline failed");return String.Format("{{\"width\":{0},\"height\":{1},\"alpha0\":{2},\"alpha255\":{3},\"partial_alpha\":{4},\"partial_further_than_2px_from_zero\":{5},\"occupied_y_inclusive\":[{6},{7}]}}",b.Width,b.Height,zero,opaque,partial,deep,miny,maxy);
 }}
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location -LiteralPath $root
try {
 $qa='art/raw/qa_S03'
 $protected=Get-Content -LiteralPath "$qa/protected_hashes.json" -Raw -Encoding UTF8 | ConvertFrom-Json
 foreach($p in $protected){if((Get-FileHash -LiteralPath $p.path -Algorithm SHA256).Hash -ne $p.sha256){throw "Protected asset changed: $($p.path)"}}
 $base='art/final/characters/C01_lina'
 $face=[S03Verify]::Face("$base/C01_portrait_combat_neutral.png","$base/C01_portrait_combat_smile.png","$qa/smile/face_mask.png") | ConvertFrom-Json
 $report=[ordered]@{verification_scope='Saved PNG geometry/alpha and face invariants only; see design_qa for visual failures';protected_files_unchanged=$true;face=$face;design_qa=@{C01_portrait_combat_neutral='S01 approved reuse';C01_portrait_combat_smile='pass; generated';C01_sd_idle='pass on attempt3; generated';C01_sd_attack='FAIL on all3 attempts; anatomical braid/ribbon side wrong; review-only candidate; manifest todo'}}
 foreach($id in @('C01_portrait_combat_neutral','C01_portrait_combat_smile','C01_sd_idle','C01_sd_attack')){
  $report[$id]=[S03Verify]::Alpha("$base/$id.png",$id.StartsWith('C01_sd_')) | ConvertFrom-Json
  if(-not(Test-Path -LiteralPath "$base/$id.prompt.txt")){throw "Missing prompt: $id"}
 }
 $json=$report | ConvertTo-Json -Depth 5
 [IO.File]::WriteAllText((Join-Path (Get-Location) "$qa/verification.json"),$json,[Text.UTF8Encoding]::new($false))
 $json
} finally {Pop-Location}
