param([Parameter(Mandatory=$true)][string]$InputImage,[Parameter(Mandatory=$true)][ValidateSet('smile','angry','sad','surprised','embarrassed')][string]$Expression)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S05Finish {
 static byte[] Read(Bitmap b) {
  var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  if(d.Stride!=b.Width*4)throw new Exception("Unexpected stride");
  byte[] p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;
 }
 static Bitmap Make(byte[] p,int w,int h) {
  var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);
  var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;
 }
 static void Preview(Bitmap b,string path) {
  using(var p=new Bitmap(b.Width,b.Height))using(var g=Graphics.FromImage(p)) {
   for(int y=0;y<b.Height;y+=24)for(int x=0;x<b.Width;x+=24)
    g.FillRectangle((x/24+y/24)%2==0?Brushes.LightGray:Brushes.White,x,y,24,24);
   g.DrawImageUnscaled(b,0,0);p.Save(path,ImageFormat.Png);
  }
 }
 static PointF[] P(float[] xy) {var p=new PointF[xy.Length/2];for(int i=0;i<p.Length;i++)p[i]=new PointF(xy[i*2],xy[i*2+1]);return p;}
 static double Dist(PointF p,PointF a,PointF b) {
  double dx=b.X-a.X,dy=b.Y-a.Y,t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));
  return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));
 }
 public static string Smile(string src,string edit,string output,string qa) {
  using(var a=new Bitmap(src))using(var b=new Bitmap(edit)) {
   if(a.Width!=1024||a.Height!=1536||a.Size!=b.Size)throw new Exception("Portrait size must remain 1024x1536");
   var original=Read(a);var ep=Read(b);var result=(byte[])original.Clone();
   var mask=new byte[original.Length];var diff=new byte[original.Length];
   // Face interior only: separate eye/brow masks avoid all overhanging hair strands.
   var polygons=new[]{
    P(new float[]{398,198,415,195,437,205,449,219,449,239,438,249,420,245,406,230}),
    P(new float[]{476,181,495,170,523,164,545,171,550,189,544,213,529,228,510,232,492,225,482,210}),
    P(new float[]{418,249,441,242,458,244,478,241,496,236,518,236,541,222,550,239,543,266,525,290,505,309,491,316,465,303,445,287,429,270})
   };
   var paths=new GraphicsPath[polygons.Length];for(int i=0;i<paths.Length;i++){paths[i]=new GraphicsPath();paths[i].AddPolygon(polygons[i]);}
   long changed=0,outside=0,alphaDiff=0;int mx0=1024,my0=1536,mx1=-1,my1=-1;
   for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++) {
    int j=(y*a.Width+x)*4;double weight=0;var p=new PointF(x+.5f,y+.5f);
    if(x>=395&&x<=552&&y>=160&&y<=318)for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(p)) {
     double d=1000;for(int n=0;n<polygons[k].Length;n++)d=Math.Min(d,Dist(p,polygons[k][n],polygons[k][(n+1)%polygons[k].Length]));
     weight=Math.Max(weight,Math.Min(1,d/4));
    }
    int m=(int)Math.Round(weight*255);for(int c=0;c<3;c++)mask[j+c]=(byte)m;mask[j+3]=255;diff[j+3]=255;
    bool differs=false;for(int c=0;c<3;c++){result[j+c]=(byte)Math.Round(original[j+c]+(ep[j+c]-original[j+c])*weight);if(result[j+c]!=original[j+c])differs=true;}
    if(differs){changed++;diff[j+2]=255;mx0=Math.Min(mx0,x);my0=Math.Min(my0,y);mx1=Math.Max(mx1,x);my1=Math.Max(my1,y);if(weight==0)outside++;}
    if(result[j+3]!=original[j+3])alphaDiff++;
   }
   if(outside!=0||alphaDiff!=0)throw new Exception("Outside-mask/alpha invariants failed");
   using(var r=Make(result,a.Width,a.Height)) {
    r.Save(output,ImageFormat.Png);Preview(r,Path.Combine(qa,"checkerboard.png"));
    using(var detail=r.Clone(new Rectangle(370,145,210,195),PixelFormat.Format32bppArgb))detail.Save(Path.Combine(qa,"face_detail.png"),ImageFormat.Png);
   }
   using(var m=Make(mask,a.Width,a.Height))m.Save(Path.Combine(qa,"face_mask.png"),ImageFormat.Png);
   using(var d=Make(diff,a.Width,a.Height))d.Save(Path.Combine(qa,"rgba_difference.png"),ImageFormat.Png);
   foreach(var p in paths)p.Dispose();
   return String.Format("{{\"width\":1024,\"height\":1536,\"changed_rgb_pixels\":{0},\"outside_face_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"changed_bbox_inclusive\":[{3},{4},{5},{6}],\"method\":\"guide 3.1.4: face interior mask composite; original RGBA retained outside mask\"}}",changed,outside,alphaDiff,mx0,my0,mx1,my1);
  }
 }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$id='C01_portrait_casual_'+$Expression
$raw=Join-Path $root ('art/raw/'+$id+'_v1.png')
$final=Join-Path $root ('art/final/characters/C01_lina/'+$id+'.png')
$qa=Join-Path $root ('art/raw/qa_S05_expressions/'+$Expression)
foreach($p in @($raw,$final)){if(Test-Path -LiteralPath $p){throw "Refusing overwrite: $p"}}
New-Item -ItemType Directory -Force -Path $qa | Out-Null
Copy-Item -LiteralPath $InputImage -Destination $raw
$report=[S05Finish]::Smile((Join-Path $root 'art/final/characters/C01_lina/C01_portrait_casual_neutral.png'),$raw,$final,$qa)
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report