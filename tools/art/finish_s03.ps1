param(
 [Parameter(Mandatory=$true)][ValidateSet('smile','sd')][string]$Mode,
 [Parameter(Mandatory=$true)][string]$InputImage,
 [Parameter(Mandatory=$true)][string]$RawOutput,
 [Parameter(Mandatory=$true)][string]$FinalOutput,
 [Parameter(Mandatory=$true)][string]$QaDir
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S03Finish {
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
    r.Save(output,ImageFormat.Png);Preview(r,Path.Combine(qa,"smile_checkerboard.png"));
    using(var detail=r.Clone(new Rectangle(370,145,210,195),PixelFormat.Format32bppArgb))detail.Save(Path.Combine(qa,"smile_face_detail.png"),ImageFormat.Png);
   }
   using(var m=Make(mask,a.Width,a.Height))m.Save(Path.Combine(qa,"face_mask.png"),ImageFormat.Png);
   using(var d=Make(diff,a.Width,a.Height))d.Save(Path.Combine(qa,"rgba_difference.png"),ImageFormat.Png);
   foreach(var p in paths)p.Dispose();
   return String.Format("{{\"width\":1024,\"height\":1536,\"changed_rgb_pixels\":{0},\"outside_face_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"changed_bbox_inclusive\":[{3},{4},{5},{6}],\"method\":\"guide 3.1.4: face interior mask composite; original RGBA retained outside mask\"}}",changed,outside,alphaDiff,mx0,my0,mx1,my1);
  }
 }
 public static string Sd(string input,string output,string qa) {
  using(var src=new Bitmap(input)) {
   var sp=Read(src);int x0=src.Width,y0=src.Height,x1=-1,y1=-1;
   for(int y=0;y<src.Height;y++)for(int x=0;x<src.Width;x++)if(sp[(y*src.Width+x)*4+3]>=128){x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);}
   if(x1<0||x0==0||y0==0||x1==src.Width-1||y1==src.Height-1)throw new Exception("Empty or clipped silhouette / nontransparent background");
   int cw=x1-x0+1,ch=y1-y0+1;double scale=Math.Min(464.0/cw,464.0/ch);int w=(int)Math.Round(cw*scale),h=(int)Math.Round(ch*scale),left=(512-w)/2,top=488-h;
   using(var dst=new Bitmap(512,512,PixelFormat.Format32bppArgb)) {
    using(var g=Graphics.FromImage(dst)){g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(src,new Rectangle(left,top,w,h),new Rectangle(x0,y0,cw,ch),GraphicsUnit.Pixel);}
    var p=Read(dst);var binary=new bool[512*512];for(int j=0;j<binary.Length;j++)binary[j]=p[j*4+3]>=128;
    long opaque=0,zero=0,partial=0,interiorPartial=0;int fx0=512,fy0=512,fx1=-1,fy1=-1;
    for(int y=0;y<512;y++)for(int x=0;x<512;x++) {
     int j=(y*512+x)*4,alpha=0;if(binary[y*512+x]) {
      int count=0;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<512&&yy>=0&&yy<512&&binary[yy*512+xx])count++;}
      alpha=count==9?255:Math.Min(p[j+3],(int)Math.Round(255.0*count/9));
      if(count==9&&alpha!=255)interiorPartial++;
     }
     p[j+3]=(byte)alpha;if(alpha==255)opaque++;else if(alpha==0){zero++;p[j]=p[j+1]=p[j+2]=0;}else partial++;
     if(alpha>0){fx0=Math.Min(fx0,x);fx1=Math.Max(fx1,x);fy0=Math.Min(fy0,y);fy1=Math.Max(fy1,y);}
    }
    // Resampling may omit a boundary pixel; translate the resulting silhouette to the exact baseline.
    int shift=487-fy1;if(shift!=0){var shifted=new byte[p.Length];for(int y=0;y<512;y++){int yy=y+shift;if(yy>=0&&yy<512)Buffer.BlockCopy(p,y*512*4,shifted,yy*512*4,512*4);}p=shifted;fy0+=shift;fy1+=shift;}
    if(partial==0||interiorPartial!=0||fy1!=487)throw new Exception("Alpha/baseline QA failed");
    using(var final=Make(p,512,512)){final.Save(output,ImageFormat.Png);Preview(final,Path.Combine(qa,"checkerboard.png"));}
    return String.Format("{{\"width\":512,\"height\":512,\"source_size\":[{0},{1}],\"source_crop_inclusive\":[{2},{3},{4},{5}],\"scale\":{6},\"alpha255\":{7},\"alpha0\":{8},\"partial_alpha\":{9},\"interior_partial\":{10},\"bbox_inclusive\":[{11},{12},{13},{14}],\"foot_baseline_last_row\":487,\"bottom_transparent_rows\":24,\"partial_alpha_band\":\"inner 1px silhouette boundary only\"}}",src.Width,src.Height,x0,y0,x1,y1,scale,opaque,zero,partial,interiorPartial,fx0,fy0,fx1,fy1);
   }
  }
 }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
foreach($dest in @($RawOutput,$FinalOutput)) {if(Test-Path -LiteralPath $dest){throw "Refusing to overwrite: $dest"}}
New-Item -ItemType Directory -Force -Path $QaDir | Out-Null
Copy-Item -LiteralPath $InputImage -Destination $RawOutput
if($Mode -eq 'smile') {
 $report=[S03Finish]::Smile((Join-Path $root 'art/final/characters/C01_lina/C01_portrait_combat_neutral.png'),$RawOutput,$FinalOutput,$QaDir)
} else {$report=[S03Finish]::Sd($RawOutput,$FinalOutput,$QaDir)}
[IO.File]::WriteAllText((Join-Path $QaDir 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report
