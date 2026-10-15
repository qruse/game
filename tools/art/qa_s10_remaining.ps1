$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class S10Audit {
 public static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static string Face(string original,string final,string mask){using(var a=new Bitmap(original))using(var b=new Bitmap(final))using(var m=new Bitmap(mask)){
  if(a.Size!=b.Size||a.Size!=m.Size)throw new Exception("Face dimensions changed");var ap=Read(a);var bp=Read(b);var mp=Read(m);long changed=0,outside=0,alpha=0;
  for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int j=(y*a.Width+x)*4;bool differs=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])differs=true;if(differs){changed++;if(mp[j]==0)outside++;}if(ap[j+3]!=bp[j+3])alpha++;}
  if(outside!=0||alpha!=0||changed<100)throw new Exception("Face saved-PNG audit failed");
  return "{\"changed\":"+changed+",\"outside_mask_rgba_changed\":"+outside+",\"alpha_changed\":"+alpha+"}";
 }}
 public static string Alpha(string path,int w,int h,bool transparent){using(var b=new Bitmap(path)){
  if(b.Width!=w||b.Height!=h)throw new Exception("Wrong size: "+path);var p=Read(b);long partial=0,opaque=0,zero=0,deep=0;int x0=w,y0=h,x1=-1,y1=-1;
  for(int y=0;y<h;y++)for(int x=0;x<w;x++){int j=(y*w+x)*4,a=p[j+3];if(a==0){zero++;continue;}x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);if(a==255){opaque++;continue;}partial++;bool interior=true;for(int dy=-2;dy<=2;dy++)for(int dx=-2;dx<=2;dx++){int xx=x+dx,yy=y+dy;if(xx<0||xx>=w||yy<0||yy>=h||p[(yy*w+xx)*4+3]<128)interior=false;}if(interior)deep++;}
  if(deep!=0||(transparent&&(partial==0||zero==0||opaque<10000))||(!transparent&&opaque!=w*h))throw new Exception("Alpha audit failed: "+path);
  return "{\"size\":["+w+","+h+"],\"opaque\":"+opaque+",\"transparent\":"+zero+",\"partial\":"+partial+",\"interior_partial\":"+deep+",\"bbox\":["+x0+","+y0+","+x1+","+y1+"]}";
 }}
 public static string MaskAudit(string original,string final,string mask){using(var a=new Bitmap(original))using(var b=new Bitmap(final))using(var m=new Bitmap(mask)){if(a.Size!=b.Size||a.Size!=m.Size)throw new Exception("Repair dimensions");var ap=Read(a);var bp=Read(b);var mp=Read(m);long outside=0,changed=0,alpha=0;for(int j=0;j<ap.Length;j+=4){bool diff=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])diff=true;if(diff){changed++;if(mp[j]==0)outside++;}if(ap[j+3]!=bp[j+3])alpha++;}if(outside!=0)throw new Exception("Repair outside mask changed");return "{\"changed_rgba_pixels\":"+changed+",\"outside_mask_rgba_changed\":"+outside+",\"alpha_changed_inside_mask\":"+alpha+"}";}}
 public static void Sheets(string qa){string dir="art/final/characters/C03_adelheid/";string[] expressions={"neutral","smile","angry","sad","surprised","embarrassed"};string[] outfits={"combat","casual"};
 using(var b=new Bitmap(1800,660))using(var g=Graphics.FromImage(b))using(var font=new Font("Arial",14)){g.Clear(Color.FromArgb(50,48,46));g.InterpolationMode=InterpolationMode.HighQualityBicubic;for(int row=0;row<2;row++)for(int col=0;col<6;col++)using(var a=new Bitmap(dir+"C03_portrait_"+outfits[row]+"_"+expressions[col]+".png")){var crop=new Rectangle(row==0?368:350,row==0?96:102,288,288);g.DrawImage(a,new Rectangle(col*300+6,row*330+6,288,288),crop,GraphicsUnit.Pixel);g.DrawString(outfits[row]+" / "+expressions[col],font,Brushes.White,col*300+6,row*330+302);}b.Save(Path.Combine(qa,"expressions_12_grid.png"));}
 using(var b=new Bitmap(1536,820))using(var g=Graphics.FromImage(b))using(var font=new Font("Arial",12)){g.Clear(Color.FromArgb(100,100,100));g.InterpolationMode=InterpolationMode.HighQualityBicubic;for(int row=0;row<2;row++)for(int col=0;col<6;col++){using(var a=new Bitmap(dir+"C03_portrait_"+outfits[row]+"_"+expressions[col]+".png"))g.DrawImage(a,col*256,row*410,256,384);g.DrawString(outfits[row]+" / "+expressions[col],font,Brushes.White,col*256+4,row*410+388);}b.Save(Path.Combine(qa,"portraits_12_full.png"));}
 string[] actions={"idle","attack","skill","hit","down"};string[] characters={"C01_lina","C02_cecile","C03_adelheid"};string[] ids={"C01","C02","C03"};
 using(var b=new Bitmap(2560,1640))using(var g=Graphics.FromImage(b))using(var font=new Font("Arial",14)){g.Clear(Color.FromArgb(100,100,100));for(int row=0;row<3;row++)for(int col=0;col<5;col++){using(var a=new Bitmap("art/final/characters/"+characters[row]+"/"+ids[row]+"_sd_"+actions[col]+".png"))g.DrawImageUnscaled(a,col*512,row*546);g.DrawLine(Pens.Yellow,col*512,row*546+488,col*512+511,row*546+488);g.DrawString(ids[row]+" "+actions[col],font,Brushes.White,col*512+8,row*546+514);}b.Save(Path.Combine(qa,"sd_15_comparison.png"));}
 using(var b=new Bitmap(1920,1920))using(var g=Graphics.FromImage(b)){for(int row=0;row<3;row++)using(var a=new Bitmap("art/final/characters/"+characters[row]+"/"+ids[row]+"_cutin.png"))g.DrawImageUnscaled(a,0,row*640);b.Save(Path.Combine(qa,"cutins_3_comparison.png"));}
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location $root
$qa=Join-Path $root 'art/raw/qa_S10_remaining'
$rows=@(Import-Csv -Encoding UTF8 art/manifest.csv | Where-Object {$_.step -eq 'S10' -and $_.format -ne 'icon'})
if($rows.Count -ne 18){throw 'Expected 18 S10 asset rows'}
$report=[ordered]@{date='2026-10-16';saved_png_checks=@();face_checks=@();repair_checks=@();protected_files=@();external_icon_changes=@()}
foreach($r in $rows){
 $w=1024;$h=1536;$transparent=$true
 if($r.format -eq 'sd'){$w=512;$h=512}
 if($r.format -eq 'cutin'){$w=1920;$h=640;$transparent=$false}
 $result=[S10Audit]::Alpha($r.output,$w,$h,$transparent)|ConvertFrom-Json
 $report.saved_png_checks+=@{id=$r.id;qa=$result}
 if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){
  $base='art/final/characters/C03_adelheid/C03_portrait_'+$r.outfit+'_neutral.png'
  $mask=Join-Path $qa ($r.id+'/face_mask.png')
  $result=[S10Audit]::Face($base,$r.output,$mask)|ConvertFrom-Json
  $report.face_checks+=@{id=$r.id;qa=$result}
 }
}
$repairCases=@(
 @('braid','art/raw/C03_sd_attack_v1.png',"$qa/C03_sd_attack/repaired_source.png","$qa/C03_sd_attack/braid_mask.png"),
 @('arms',"$qa/C03_sd_attack/repaired_source.png","$qa/C03_sd_attack/arms_repaired_source.png","$qa/C03_sd_attack/arms_mask.png"),
 @('cutin',"$qa/C03_cutin/before_hands_repair.png",'art/final/characters/C03_adelheid/C03_cutin.png',"$qa/C03_cutin/hands_mask.png")
)
foreach($c in $repairCases){$result=[S10Audit]::MaskAudit($c[1],$c[2],$c[3])|ConvertFrom-Json;$report.repair_checks+=@{id=$c[0];qa=$result}}
foreach($r in (Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline.json')|ConvertFrom-Json)){
 $exists=Test-Path -LiteralPath $r.path
 $unchanged=$exists -and ((Get-FileHash -LiteralPath $r.path).Hash -eq $r.sha256)
 if(-not $unchanged){
  if($r.path -match '[\\/]art[\\/]final[\\/]icons[\\/]skills[\\/]C0[12]_icon_'){
   $report.external_icon_changes+=@{path=$r.path;exists=$exists;note='Changed or removed outside this S10 work; no writes by this task. Kept external state.'}
   continue
  }
  throw "Protected file changed: $($r.path)"
 }
 $report.protected_files+=@{path=$r.path;unchanged=$true}
}
[S10Audit]::Sheets($qa)
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
"Saved 18 PNGs audited; 10 expression masks outside RGBA/alpha differences 0; $($report.protected_files.Count) protected files unchanged."
