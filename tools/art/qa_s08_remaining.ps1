$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class S08Audit {
 public static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static string Face(string original,string final,string mask){using(var a=new Bitmap(original))using(var b=new Bitmap(final))using(var m=new Bitmap(mask)){
  if(a.Size!=b.Size||a.Size!=m.Size)throw new Exception("Face dimensions changed");var ap=Read(a);var bp=Read(b);var mp=Read(m);long changed=0,outside=0,alpha=0,scar=0;
  for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int j=(y*a.Width+x)*4;bool differs=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])differs=true;if(differs){changed++;if(mp[j]==0)outside++;if(x>=530&&x<=551&&y>=246&&y<=276)scar++;}if(ap[j+3]!=bp[j+3])alpha++;}
  if(outside!=0||alpha!=0||scar!=0||changed<100)throw new Exception("Face saved-PNG audit failed");
  return "{\"changed\":"+changed+",\"outside_mask_rgba_changed\":"+outside+",\"alpha_changed\":"+alpha+",\"protected_scar_patch_changed\":"+scar+"}";
 }}
 public static string Alpha(string path,int w,int h,bool transparent){using(var b=new Bitmap(path)){
  if(b.Width!=w||b.Height!=h)throw new Exception("Wrong size: "+path);var p=Read(b);long partial=0,opaque=0,zero=0,deep=0;int x0=w,y0=h,x1=-1,y1=-1;
  for(int y=0;y<h;y++)for(int x=0;x<w;x++){int j=(y*w+x)*4,a=p[j+3];if(a==0){zero++;continue;}x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);if(a==255){opaque++;continue;}partial++;bool interior=true;for(int dy=-2;dy<=2;dy++)for(int dx=-2;dx<=2;dx++){int xx=x+dx,yy=y+dy;if(xx<0||xx>=w||yy<0||yy>=h||p[(yy*w+xx)*4+3]<128)interior=false;}if(interior)deep++;}
  if(deep!=0||(transparent&&(partial==0||zero==0||opaque<10000))||(!transparent&&opaque!=w*h))throw new Exception("Alpha audit failed: "+path);
  return "{\"size\":["+w+","+h+"],\"opaque\":"+opaque+",\"transparent\":"+zero+",\"partial\":"+partial+",\"interior_partial\":"+deep+",\"bbox\":["+x0+","+y0+","+x1+","+y1+"]}";
 }}
 public static void Sheets(string qa){string dir="art/final/characters/C02_cecile/";string[] faces={"neutral","smile","angry","sad","surprised","embarrassed"};string[] outfits={"combat","casual"};
  using(var b=new Bitmap(6*300,2*280))using(var g=Graphics.FromImage(b))using(var f=new Font("Arial",14)){g.Clear(Color.FromArgb(50,48,46));g.InterpolationMode=InterpolationMode.HighQualityBicubic;for(int r=0;r<2;r++)for(int i=0;i<6;i++)using(var a=new Bitmap(dir+"C02_portrait_"+outfits[r]+"_"+faces[i]+".png")){g.DrawImage(a,new Rectangle(i*300+12,r*280+8,276,230),new Rectangle(365,135,265,225),GraphicsUnit.Pixel);g.DrawString(outfits[r]+" / "+faces[i],f,Brushes.White,i*300+10,r*280+250);}b.Save(Path.Combine(qa,"expressions_12_grid.png"));}
  using(var b=new Bitmap(6*256,2*410))using(var g=Graphics.FromImage(b))using(var f=new Font("Arial",12)){g.Clear(Color.FromArgb(90,90,90));g.InterpolationMode=InterpolationMode.HighQualityBicubic;for(int r=0;r<2;r++)for(int i=0;i<6;i++)using(var a=new Bitmap(dir+"C02_portrait_"+outfits[r]+"_"+faces[i]+".png")){g.DrawImage(a,i*256,r*410,256,384);g.DrawString(outfits[r]+" / "+faces[i],f,Brushes.White,i*256+5,r*410+388);}b.Save(Path.Combine(qa,"portraits_12_full.png"));}
  string[] sds={"idle","attack","skill","hit","down"};using(var b=new Bitmap(5*512,560))using(var g=Graphics.FromImage(b))using(var f=new Font("Arial",16)){g.Clear(Color.FromArgb(85,85,85));for(int i=0;i<5;i++){using(var a=new Bitmap(dir+"C02_sd_"+sds[i]+".png"))g.DrawImageUnscaled(a,i*512,0);g.DrawLine(Pens.Yellow,i*512,488,(i+1)*512-1,488);g.DrawString(sds[i]+" / foot y487",f,Brushes.White,i*512+10,520);}b.Save(Path.Combine(qa,"sd_5_actions.png"));}
  string[] icons={"skill1","skill2","ult"};using(var b=new Bitmap(3*290,380))using(var g=Graphics.FromImage(b))using(var f=new Font("Arial",14)){g.Clear(Color.FromArgb(45,35,30));g.InterpolationMode=InterpolationMode.HighQualityBicubic;for(int i=0;i<3;i++){using(var a=new Bitmap("art/final/icons/skills/C02_icon_"+icons[i]+".png")){g.DrawImageUnscaled(a,i*290+16,8);g.DrawImage(a,i*290+16,280,64,64);using(var gray=new Bitmap(64,64))using(var gg=Graphics.FromImage(gray)){var cm=new ColorMatrix(new float[][]{new float[]{.299f,.299f,.299f,0,0},new float[]{.587f,.587f,.587f,0,0},new float[]{.114f,.114f,.114f,0,0},new float[]{0,0,0,1,0},new float[]{0,0,0,0,1}});using(var ia=new ImageAttributes()){ia.SetColorMatrix(cm);gg.InterpolationMode=InterpolationMode.HighQualityBicubic;gg.DrawImage(a,new Rectangle(0,0,64,64),0,0,256,256,GraphicsUnit.Pixel,ia);}gray.Save(Path.Combine(qa,"C02_icon_"+icons[i]+"_64_gray.png"));g.DrawImageUnscaled(gray,i*290+104,280);}}g.DrawString(icons[i]+"  64px / gray",f,Brushes.White,i*290+16,352);}b.Save(Path.Combine(qa,"icons_3_64px.png"));}
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location $root
$qa=Join-Path $root 'art/raw/qa_S08_remaining'
$rows=@(Import-Csv -Encoding UTF8 art/manifest.csv | Where-Object {$_.step -eq 'S08'})
if($rows.Count -ne 21){throw 'Expected21 rows'}
$report=[ordered]@{date='2026-10-15';saved_png_checks=@();face_checks=@();protected_files=@()}
foreach($r in $rows){$w=1024;$h=1536;$transparent=$true;if($r.format -eq 'sd'){$w=512;$h=512};if($r.format -eq 'cutin'){$w=1920;$h=640;$transparent=$false};if($r.format -eq 'icon'){$w=256;$h=256;$transparent=$false};$result=[S08Audit]::Alpha($r.output,$w,$h,$transparent)|ConvertFrom-Json;$report.saved_png_checks+=@{id=$r.id;qa=$result};if($r.format -eq 'portrait' -and $r.id -notmatch '_neutral$'){$base='art/final/characters/C02_cecile/C02_portrait_'+$r.outfit+'_neutral.png';$mask=Join-Path $qa ($r.id+'/face_mask.png');$result=[S08Audit]::Face($base,$r.output,$mask)|ConvertFrom-Json;$report.face_checks+=@{id=$r.id;qa=$result}}}
foreach($r in (Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'baseline_hashes.json')|ConvertFrom-Json)){$hash=(Get-FileHash -LiteralPath $r.path).Hash;if($hash -ne $r.sha256){throw "Protected file changed: $($r.path)"};$report.protected_files+=@{path=$r.path;unchanged=$true}}
[S08Audit]::Sheets($qa)
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
"Saved21 PNGs audited;10 face masks outside/alpha/scar differences0; $($report.protected_files.Count) existing files unchanged; comparison sheets saved."
