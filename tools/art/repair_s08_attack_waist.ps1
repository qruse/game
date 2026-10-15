param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S08Waist {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p){var b=new Bitmap(512,512,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,512,512),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static string Run(string original,string edit,string output,string qa){
  using(var a=new Bitmap(original))using(var e=new Bitmap(edit))using(var patch=new Bitmap(100,85,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(patch)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(e,new Rectangle(0,0,100,85));}
   var op=Read(a);var ep=Read(patch);var result=(byte[])op.Clone();var mask=new byte[op.Length];var diff=new byte[op.Length];long changed=0,outside=0,alphaChanges=0;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++){
    int j=(y*512+x)*4;double d1=Math.Sqrt(Math.Pow((x-237.0)/15,2)+Math.Pow((y-289.0)/18,2));double d2=Math.Sqrt(Math.Pow((x-358.0)/6,2)+Math.Pow((y-181.0)/7,2));
    double weight=Math.Max(0,Math.Min(1,(1-d1)*8));
    mask[j+3]=diff[j+3]=255;mask[j]=mask[j+1]=mask[j+2]=(byte)Math.Round(weight*255);
    if(weight>0){int k=((y-255)*100+x-190)*4;for(int c=0;c<3;c++)result[j+c]=(byte)Math.Round(op[j+c]+(ep[k+c]-op[j+c])*weight);}
    bool differs=false;for(int c=0;c<4;c++)if(result[j+c]!=op[j+c])differs=true;
    if(differs){changed++;diff[j+2]=255;if(weight==0)outside++;}if(result[j+3]!=op[j+3])alphaChanges++;
   }
   if(outside!=0||alphaChanges!=0)throw new Exception("Cheek mask invariants failed");
   using(var final=Make(result)){
    final.Save(output,ImageFormat.Png);
    foreach(string background in new[]{"checkerboard","dark","light"})using(var preview=new Bitmap(512,512))using(var g=Graphics.FromImage(preview)){
     g.Clear(background=="dark"?Color.FromArgb(27,31,36):Color.White);if(background=="checkerboard")for(int y=0;y<512;y+=16)for(int x=0;x<512;x+=16)g.FillRectangle((x/16+y/16)%2==0?Brushes.LightGray:Brushes.White,x,y,16,16);g.DrawImageUnscaled(final,0,0);preview.Save(Path.Combine(qa,background+".png"),ImageFormat.Png);
    }
   }
   using(var m=Make(mask))m.Save(Path.Combine(qa,"waist_mask.png"),ImageFormat.Png);using(var d=Make(diff))d.Save(Path.Combine(qa,"waist_rgba_diff.png"),ImageFormat.Png);
   return String.Format("{{\"changed_rgb_pixels\":{0},\"outside_waist_mask_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"method\":\"RGB-only waist hilt removal mask; all other RGBA and entire alpha channel identical\"}}",changed,outside,alphaChanges);
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S08_remaining/C02_sd_attack';$raw=Join-Path $root 'art/raw/C02_sd_attack_v2.png'


$report=[S08Waist]::Run((Join-Path $qa 'before_waist_edit.png'),$raw,(Join-Path $qa 'waist_edit_composite.png'),$qa)
Copy-Item -LiteralPath (Join-Path $qa 'waist_edit_composite.png') -Destination (Join-Path $root 'art/final/characters/C02_cecile/C02_sd_attack.png')
$utf8=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $qa 'waist_edit_verification.json'),$report,$utf8)
$report