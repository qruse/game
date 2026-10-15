param([Parameter(Mandatory=$true)][string]$InputImage,[Parameter(Mandatory=$true)][ValidateSet('smile','angry','sad','surprised','embarrassed')][string]$Expression,[ValidateSet('combat','casual')][string]$Outfit='combat')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S08Face {
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
    P(new float[]{394,187,405,211,429,226,451,239,445,262,417,268,396,253,384,234}),
    P(new float[]{467,150,480,166,507,182,536,185,553,188,555,217,541,236,513,237,488,240,464,218,464,198}),
    P(new float[]{402,267,429,260,451,253,478,243,514,239,550,229,560,251,557,283,537,310,509,333,495,340,466,328,442,311,421,288})
   };   var paths=new GraphicsPath[polygons.Length];for(int i=0;i<paths.Length;i++){paths[i]=new GraphicsPath();paths[i].AddPolygon(polygons[i]);}
   long changed=0,outside=0,alphaDiff=0;int mx0=1024,my0=1536,mx1=-1,my1=-1;
   for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++) {
    int j=(y*a.Width+x)*4;double weight=0;var p=new PointF(x+.5f,y+.5f);
    if(x>=380&&x<=562&&y>=148&&y<=342)for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(p)) {
     double d=1000;for(int n=0;n<polygons[k].Length;n++)d=Math.Min(d,Dist(p,polygons[k][n],polygons[k][(n+1)%polygons[k].Length]));
     weight=Math.Max(weight,Math.Min(1,d/4));
    }
    if(x>=530&&x<=551&&y>=246&&y<=276)weight=0; int m=(int)Math.Round(weight*255);for(int c=0;c<3;c++)mask[j+c]=(byte)m;mask[j+3]=255;diff[j+3]=255;
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
$id='C02_portrait_'+$Outfit+'_'+$Expression
$raw=Join-Path $root ('art/raw/'+$id+'_v1.png')
$final=Join-Path $root ('art/final/characters/C02_cecile/'+$id+'.png')
$qa=Join-Path $root ('art/raw/qa_S08_remaining/'+$id)
if(Test-Path -LiteralPath $final){Copy-Item -LiteralPath $final -Destination (Join-Path $qa "before_brow_endpoint_refinement.png") -ErrorAction Stop}
New-Item -ItemType Directory -Force -Path $qa | Out-Null
if(-not (Test-Path -LiteralPath $raw)){Copy-Item -LiteralPath $InputImage -Destination $raw}
$report=[S08Face]::Smile((Join-Path $root ('art/final/characters/C02_cecile/C02_portrait_'+$Outfit+'_neutral.png')),$raw,$final,$qa)
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report