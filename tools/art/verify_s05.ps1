$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class VerifyS05 {
 static byte[] Read(string path,out int w,out int h){using(var b=new Bitmap(path)){w=b.Width;h=b.Height;var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);if(d.Stride!=w*4)throw new Exception("Unexpected stride");var p=new byte[w*h*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}}
 public static string Check(string neutral,string edited,string mask){int w,h,ew,eh,mw,mh;var a=Read(neutral,out w,out h);var b=Read(edited,out ew,out eh);var m=Read(mask,out mw,out mh);if(w!=1024||h!=1536||ew!=w||eh!=h||mw!=w||mh!=h)throw new Exception("Wrong dimensions");long changed=0,outside=0,alpha=0,zero=0,opaque=0,partial=0,interiorPartial=0;for(int y=0;y<h;y++)for(int x=0;x<w;x++){int i=(y*w+x)*4;bool differs=false;for(int c=0;c<4;c++)if(a[i+c]!=b[i+c])differs=true;if(differs){changed++;if(m[i]==0)outside++;}if(a[i+3]!=b[i+3])alpha++;int al=b[i+3];if(al==0)zero++;else if(al==255)opaque++;else{partial++;bool interior=true;for(int dy=-2;dy<=2;dy++)for(int dx=-2;dx<=2;dx++){int xx=x+dx,yy=y+dy;if(xx<0||xx>=w||yy<0||yy>=h||b[(yy*w+xx)*4+3]==0)interior=false;}if(interior)interiorPartial++;}}
 if(outside!=0||alpha!=0||changed==0||interiorPartial!=0)throw new Exception("Saved PNG invariant failed");return "{\"size\":[1024,1536],\"changed_rgba_pixels\":"+changed+",\"outside_face_rgba_changed_pixels\":"+outside+",\"alpha_changed_pixels\":"+alpha+",\"alpha0\":"+zero+",\"alpha255\":"+opaque+",\"partial_alpha\":"+partial+",\"partial_alpha_more_than_2px_from_transparency\":"+interiorPartial+"}";}
 public static void Sheets(string root,string qa){string dir=Path.Combine(root,"art/final/characters/C01_lina");string[] faces={"neutral","smile","angry","sad","surprised","embarrassed"};using(var b=new Bitmap(1440,560))using(var g=Graphics.FromImage(b))using(var font=new Font("Arial",14)){g.Clear(Color.FromArgb(45,35,30));for(int row=0;row<2;row++){string outfit=row==0?"combat":"casual";for(int i=0;i<6;i++)using(var a=new Bitmap(Path.Combine(dir,"C01_portrait_"+outfit+"_"+faces[i]+".png"))){g.DrawImage(a,new Rectangle(i*240,20+row*280,240,223),new Rectangle(370,145,210,195),GraphicsUnit.Pixel);g.DrawString(outfit+" "+faces[i],font,Brushes.White,i*240+4,250+row*280);}}b.Save(Path.Combine(qa,"combat_casual_expressions.png"),ImageFormat.Png);}
 using(var b=new Bitmap(1280,420))using(var g=Graphics.FromImage(b))using(var font=new Font("Arial",14)){g.Clear(Color.FromArgb(85,85,85));for(int i=1;i<6;i++)using(var a=new Bitmap(Path.Combine(dir,"C01_portrait_casual_"+faces[i]+".png"))){g.DrawImage(a,(i-1)*256,0,256,384);g.DrawString(faces[i],font,Brushes.White,(i-1)*256+5,390);}b.Save(Path.Combine(qa,"casual_full_contact.png"),ImageFormat.Png);}}
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$qa=Join-Path $root 'art/raw/qa_S05_expressions'
$neutral=Join-Path $root 'art/final/characters/C01_lina/C01_portrait_casual_neutral.png'
$checks=@()
foreach($e in @('smile','angry','sad','surprised','embarrassed')){
 $file=Join-Path $root ('art/final/characters/C01_lina/C01_portrait_casual_'+$e+'.png')
 $mask=Join-Path $qa ($e+'/face_mask.png')
 $check=[VerifyS05]::Check($neutral,$file,$mask)|ConvertFrom-Json
 $check|Add-Member -NotePropertyName id -NotePropertyValue ('C01_portrait_casual_'+$e)
 $check|Add-Member -NotePropertyName sha256 -NotePropertyValue (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
 $checks+=$check
}
$before=Get-Content -LiteralPath (Join-Path $qa 'before_hashes.json') -Encoding UTF8 -Raw|ConvertFrom-Json
$changed=@($before|Where-Object {!(Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256})
if($changed.Count -ne 0){throw 'Previously existing final/refs file changed'}
[VerifyS05]::Sheets($root,$qa)
$report=[ordered]@{date='2026-10-15';method='Independent reread of saved PNGs and masks; BGRA equality covers all four RGBA channels';existing_asset_files_checked=$before.Count;existing_asset_files_changed=$changed.Count;expressions=$checks}
[IO.File]::WriteAllText((Join-Path $qa 'verification.json'),($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$report|ConvertTo-Json -Depth 8
