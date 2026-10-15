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
public static class S08Scar {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p){var b=new Bitmap(512,512,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,512,512),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static string Run(string original,string edit,string output,string qa){
  using(var a=new Bitmap(original))using(var e=new Bitmap(edit))using(var patch=new Bitmap(140,100,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(patch)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(e,new Rectangle(0,0,140,100));}
   var op=Read(a);var ep=Read(patch);var result=(byte[])op.Clone();var mask=new byte[op.Length];var diff=new byte[op.Length];long changed=0,outside=0,alphaChanges=0;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++){
    int j=(y*512+x)*4;double d1=Math.Sqrt(Math.Pow((x-295.0)/12,2)+Math.Pow((y-186.0)/11,2));double d2=Math.Sqrt(Math.Pow((x-358.0)/6,2)+Math.Pow((y-181.0)/7,2));
    double weight=Math.Max(Math.Max(0,Math.Min(1,(1-d1)*5)),Math.Max(0,Math.Min(1,(1-d2)*4)));
    mask[j+3]=diff[j+3]=255;mask[j]=mask[j+1]=mask[j+2]=(byte)Math.Round(weight*255);
    if(weight>0){int k=((y-125)*140+x-255)*4;for(int c=0;c<3;c++)result[j+c]=(byte)Math.Round(op[j+c]+(ep[k+c]-op[j+c])*weight);}
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
   using(var m=Make(mask))m.Save(Path.Combine(qa,"cheek_mask.png"),ImageFormat.Png);using(var d=Make(diff))d.Save(Path.Combine(qa,"cheek_rgba_diff.png"),ImageFormat.Png);
   return String.Format("{{\"changed_rgb_pixels\":{0},\"outside_cheek_mask_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"removed_wrong_near_right_cheek\":[295,186],\"correct_far_left_cheek\":[358,181],\"method\":\"RGB-only two cheek masks; all other RGBA and entire alpha channel identical\"}}",changed,outside,alphaChanges);
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S08/sd';$raw=Join-Path $root 'art/raw/C02_sd_idle_v3.png'
if(Test-Path -LiteralPath $raw){throw 'Raw v3 exists'}
Copy-Item -LiteralPath $Source -Destination $raw
$report=[S08Scar]::Run((Join-Path $qa 'before_scar_edit.png'),$raw,(Join-Path $qa 'scar_edit_composite.png'),$qa)
Copy-Item -LiteralPath (Join-Path $qa 'scar_edit_composite.png') -Destination (Join-Path $root 'art/final/characters/C02_cecile/C02_sd_idle.png')
$utf8=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $qa 'scar_edit_verification.json'),$report,$utf8)
$finalQa=Get-Content -Raw -Encoding UTF8 (Join-Path $qa 'head_edit_verification.json') | ConvertFrom-Json
$finalQa | Add-Member -NotePropertyName scar_edit -NotePropertyValue ($report | ConvertFrom-Json)
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),($finalQa | ConvertTo-Json -Depth 5),$utf8)
$report
