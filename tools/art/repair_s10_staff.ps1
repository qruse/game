param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class S10Staff {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static void Save(byte[] p,int w,int h,string path){using(var b=new Bitmap(w,h,PixelFormat.Format32bppArgb)){var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);b.Save(path,ImageFormat.Png);}}
 public static string Run(string before,string edit,string output,string maskPath,string diffPath){
  using(var a=new Bitmap(before))using(var e=new Bitmap(edit))using(var norm=new Bitmap(a.Width,a.Height,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(norm)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(e,new Rectangle(0,0,a.Width,a.Height));}
   int w=a.Width,h=a.Height;var orig=Read(a);var ep=Read(norm);var p=(byte[])orig.Clone();var mask=new byte[p.Length];var diff=new byte[p.Length];int changes=0,outside=0,alphadiff=0;
   for(int y=0;y<h;y++)for(int x=0;x<w;x++){
    double m=0;if(x>=190&&x<=298&&y>=1090)m=Math.Min(1.0,Math.Min(Math.Min((x-190)/12.0,(298-x)/12.0),(y-1090)/12.0));
    int j=(y*w+x)*4;mask[j]=mask[j+1]=mask[j+2]=(byte)Math.Round(m*255);mask[j+3]=255;
    if(m>0)for(int c=0;c<3;c++)p[j+c]=(byte)Math.Round(orig[j+c]*(1-m)+ep[j+c]*m);
    bool changed=false;for(int c=0;c<4;c++)if(p[j+c]!=orig[j+c])changed=true;
    if(changed){changes++;if(m==0)outside++;diff[j+2]=255;diff[j+3]=255;}
    if(p[j+3]!=orig[j+3])alphadiff++;
   }
   if(outside!=0||alphadiff!=0)throw new Exception("Local mask invariant failed");
   Save(p,w,h,output);Save(mask,w,h,maskPath);Save(diff,w,h,diffPath);
   return String.Format("{{\"changed_pixels\":{0},\"outside_mask_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"mask_bounds\":[190,1090,298,1535],\"method\":\"RGB-only lower staff strip, 12px inward feather, original alpha preserved\"}}",changes,outside,alphadiff);
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S10/portrait'
$raw=Join-Path $root 'art/raw/C03_portrait_combat_neutral_v2.png'
if(Test-Path $raw){throw 'Raw v2 already exists'}
Copy-Item -LiteralPath $Source -Destination $raw
$result=[S10Staff]::Run((Join-Path $qa 'before_staff_edit.png'),$raw,(Join-Path $root 'art/final/characters/C03_adelheid/C03_portrait_combat_neutral.png'),(Join-Path $qa 'staff_mask.png'),(Join-Path $qa 'staff_rgba_diff.png'))
[IO.File]::WriteAllText((Join-Path $qa 'staff_edit_qa.json'),$result,[Text.UTF8Encoding]::new($false))
$result
