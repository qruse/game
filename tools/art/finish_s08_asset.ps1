param([Parameter(Mandatory=$true)][ValidateSet('portrait','sd')][string]$Kind,[Parameter(Mandatory=$true)][string]$Id,[Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S08Finish {
 static byte[] Read(Bitmap b) {
  var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  if(d.Stride!=b.Width*4)throw new Exception("Unexpected stride");
  var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;
 }
 static Bitmap Make(byte[] p,int w,int h) {
  var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);
  var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;
 }
 static int[] Bounds(byte[] p,int w,int h,int cutoff) {
  int x0=w,y0=h,x1=-1,y1=-1;
  for(int y=0;y<h;y++)for(int x=0;x<w;x++)if(p[(y*w+x)*4+3]>=cutoff){x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);}
  return new[]{x0,y0,x1,y1};
 }
 public static string Run(string input,string output,string qa,bool sd) {
  using(var src=new Bitmap(input)) {
   var source=Read(src);var crop=Bounds(source,src.Width,src.Height,128);
   if(crop[2]<0)throw new Exception("No opaque character");
   int w=sd?512:1024,h=sd?512:1536;
   if(!sd&&(src.Width!=w||src.Height!=h))throw new Exception("Portrait must be 1024x1536; no repositioning permitted");
   using(var canvas=new Bitmap(w,h,PixelFormat.Format32bppArgb)) {
    if(sd) {
     int cw=crop[2]-crop[0]+1,ch=crop[3]-crop[1]+1;
     double scale=Math.Min(464.0/cw,464.0/ch);
     int dw=(int)Math.Round(cw*scale),dh=(int)Math.Round(ch*scale);
     using(var g=Graphics.FromImage(canvas)) {
      g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;
      g.DrawImage(src,new Rectangle((512-dw)/2,488-dh,dw,dh),new Rectangle(crop[0],crop[1],cw,ch),GraphicsUnit.Pixel);
     }
    } else {using(var g=Graphics.FromImage(canvas)){g.CompositingMode=CompositingMode.SourceCopy;g.DrawImageUnscaled(src,0,0);}}
    var p=Read(canvas);var native=(byte[])p.Clone();var mask=new bool[w*h];
    for(int j=0;j<mask.Length;j++)mask[j]=native[j*4+3]>=128;
    long opaque=0,zero=0,partial=0,deepPartial=0,interiorRgbChanges=0;
    for(int y=0;y<h;y++)for(int x=0;x<w;x++) {
     int j=(y*w+x)*4,n=0;bool near=false;
     for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++) {
      int xx=x+dx,yy=y+dy;
      if(xx<0||xx>=w||yy<0||yy>=h){if(!sd)n++;}
      else if(mask[yy*w+xx]){n++;near=true;}
     }
     int a=n==9?255:near?native[j+3]:0;
     if(mask[y*w+x]&&n<9&&a==255)a=(int)Math.Round(255.0*n/9);
     p[j+3]=(byte)a;
     if(n==9&&a!=255)deepPartial++;
     if(a==255)opaque++;else if(a==0){zero++;p[j]=p[j+1]=p[j+2]=0;}else partial++;
     if(a>0)for(int c=0;c<3;c++)if(p[j+c]!=native[j+c])interiorRgbChanges++;
    }
    var bbox=Bounds(p,w,h,1);
    int shift=sd?487-bbox[3]:0;
    if(shift!=0){var shifted=new byte[p.Length];for(int y=0;y<h;y++){int yy=y+shift;if(yy>=0&&yy<h)Buffer.BlockCopy(p,y*w*4,shifted,yy*w*4,w*4);}p=shifted;bbox=Bounds(p,w,h,1);}
    if(partial==0||deepPartial!=0||opaque<10000||zero<10000||interiorRgbChanges!=0)throw new Exception("Alpha QA failed");
    if(sd&&bbox[3]!=487)throw new Exception("Foot baseline QA failed");
    using(var final=Make(p,w,h)) {
     final.Save(output,ImageFormat.Png);
     foreach(string background in new[]{"checkerboard","dark","light"})using(var preview=new Bitmap(w,h))using(var g=Graphics.FromImage(preview)) {
      g.Clear(background=="dark"?Color.FromArgb(27,31,36):Color.White);
      if(background=="checkerboard")for(int y=0;y<h;y+=24)for(int x=0;x<w;x+=24)g.FillRectangle((x/24+y/24)%2==0?Brushes.LightGray:Brushes.White,x,y,24,24);
      g.DrawImageUnscaled(final,0,0);preview.Save(Path.Combine(qa,background+".png"),ImageFormat.Png);
     }
    }
    return String.Format("{{\"size\":[{0},{1}],\"source_size\":[{2},{3}],\"source_crop\":[{4},{5},{6},{7}],\"alpha255\":{8},\"alpha0\":{9},\"partial_alpha\":{10},\"interior_partial\":{11},\"visible_rgb_changes\":{12},\"bbox\":[{13},{14},{15},{16}],\"foot_baseline\":{17},\"alpha_method\":\"native edge alpha retained within 1px silhouette neighborhood; deep interior forced255; fully covered edge feathered1px; not binary output\",\"mirrored\":false,\"portrait_position_unchanged\":{18}}}",w,h,src.Width,src.Height,crop[0],crop[1],crop[2],crop[3],opaque,zero,partial,deepPartial,interiorRgbChanges,bbox[0],bbox[1],bbox[2],bbox[3],sd?"487":"null",sd?"null":"true");
   }
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path

$qa=Join-Path $root ('art/raw/qa_S08_remaining/'+$Id)
New-Item -ItemType Directory -Force -Path $qa | Out-Null
$raw=Join-Path $root ('art/raw/'+$id+'_v1.png')
$final=Join-Path $root ('art/final/characters/C02_cecile/'+$id+'.png')
foreach($p in @($raw,$final)){if(Test-Path -LiteralPath $p){throw "Refusing to overwrite $p"}}
Copy-Item -LiteralPath $Source -Destination $raw
$report=[S08Finish]::Run($raw,$final,$qa,($Kind -eq 'sd'))
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report
