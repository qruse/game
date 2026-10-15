param(
 [ValidateSet('Prepare','Composite','Verify')][string]$Mode='Prepare',
 [string]$Candidate,
 [string]$QaDir='art/raw/C01_sd_attack_rework_20261015_01'
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
public static class AttackRework {
 public static byte[] Read(Bitmap b) {
  var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  if(d.Stride!=b.Width*4)throw new Exception("Unexpected stride");
  var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;
 }
 public static Bitmap Make(byte[] p,int w,int h) {
  var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;
 }
 static PointF[] Points(float[] p) {var a=new PointF[p.Length/2];for(int i=0;i<a.Length;i++)a[i]=new PointF(p[i*2],p[i*2+1]);return a;}
 static double Distance(PointF p,PointF a,PointF b) {
  double dx=b.X-a.X,dy=b.Y-a.Y,t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));
  return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));
 }
 public static void Preview(Bitmap b,string path) {
  using(var o=new Bitmap(b.Width,b.Height))using(var g=Graphics.FromImage(o)) {
   for(int y=0;y<b.Height;y+=16)for(int x=0;x<b.Width;x+=16)g.FillRectangle((x/16+y/16)%2==0?Brushes.LightGray:Brushes.White,x,y,16,16);
   g.DrawImageUnscaled(b,0,0);o.Save(path,ImageFormat.Png);
  }
 }
 public static void Prepare(string original,string dir) {
  using(var b=new Bitmap(original)) {
   if(b.Width!=512||b.Height!=512)throw new Exception("Expected 512x512 edit target");
   var polys=new[]{
    Points(new float[]{85,174,117,165,143,161,160,155,183,143,207,133,216,139,216,150,201,162,189,181,173,202,158,218,142,237,115,244,86,235,81,214}),
    Points(new float[]{295,145,306,153,316,166,327,178,343,185,354,195,349,210,337,224,327,235,316,232,307,218,307,200,306,191,298,174})
   };
   var paths=new GraphicsPath[polys.Length];for(int i=0;i<paths.Length;i++){paths[i]=new GraphicsPath();paths[i].AddPolygon(polys[i]);}
   var p=Read(b);var mask=new byte[p.Length];var overlay=(byte[])p.Clone();
   for(int y=0;y<512;y++)for(int x=0;x<512;x++) {
    int j=(y*512+x)*4;double w=0;var pt=new PointF(x+.5f,y+.5f);
    for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(pt)) {
     double dist=1000;for(int n=0;n<polys[k].Length;n++)dist=Math.Min(dist,Distance(pt,polys[k][n],polys[k][(n+1)%polys[k].Length]));
     w=Math.Max(w,Math.Min(1,dist/4.0));
    }
    byte m=(byte)Math.Round(255*w);mask[j]=mask[j+1]=mask[j+2]=m;mask[j+3]=255;
    if(m>0){overlay[j]=(byte)(overlay[j]*.5+127);overlay[j+1]=(byte)(overlay[j+1]*.5+127);overlay[j+2]=(byte)(overlay[j+2]*.5);overlay[j+3]=255;}
   }
   using(var m=Make(mask,512,512))m.Save(Path.Combine(dir,"edit_mask.png"),ImageFormat.Png);
   using(var o=Make(overlay,512,512))Preview(o,Path.Combine(dir,"mask_overlay.png"));
   Preview(b,Path.Combine(dir,"before_checkerboard.png"));
   foreach(var path in paths)path.Dispose();
  }
 }
 public static string Composite(string original,string candidate,string maskPath,string output,string dir) {
  using(var a=new Bitmap(original))using(var source=new Bitmap(candidate))using(var b=new Bitmap(512,512,PixelFormat.Format32bppArgb))using(var mask=new Bitmap(maskPath)) {
   using(var g=Graphics.FromImage(b)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(source,new Rectangle(0,0,512,512));}
   var ap=Read(a);var bp=Read(b);var mp=Read(mask);var result=(byte[])ap.Clone();
   // Blend premultiplied colors locally; all zero-mask bytes retain the original values.
   for(int j=0;j<ap.Length;j+=4)if(mp[j]>0) {
    double w=mp[j]/255.0,aa=ap[j+3]/255.0,ba=bp[j+3]/255.0,alpha=aa*(1-w)+ba*w;
    for(int c=0;c<3;c++)result[j+c]=alpha>0?(byte)Math.Round((ap[j+c]*aa*(1-w)+bp[j+c]*ba*w)/alpha):(byte)0;
    result[j+3]=(byte)Math.Round(alpha*255);
   }
   // Normalize only editable alpha: opaque interior, native soft silhouette within 1 pixel.
   var solid=new bool[512*512];for(int i=0;i<solid.Length;i++)solid[i]=result[i*4+3]>=128;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++) {
    int j=(y*512+x)*4;if(mp[j]==0)continue;
    if(!solid[y*512+x]){result[j]=result[j+1]=result[j+2]=result[j+3]=0;continue;}
    int count=0;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<512&&yy>=0&&yy<512&&solid[yy*512+xx])count++;}
    result[j+3]=(byte)(count==9?255:Math.Min(result[j+3],(int)Math.Round(255.0*count/9)));
   }
   using(var o=Make(result,512,512)){o.Save(output,ImageFormat.Png);Preview(o,Path.Combine(dir,"after_checkerboard.png"));
    using(var crop=o.Clone(new Rectangle(75,125,290,125),PixelFormat.Format32bppArgb))
    using(var detail=new Bitmap(1160,500))using(var g=Graphics.FromImage(detail)){g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;g.DrawImage(crop,0,0,1160,500);detail.Save(Path.Combine(dir,"hair_detail_4x.png"),ImageFormat.Png);}
   }
   return Verify(original,output,maskPath,dir);
  }
 }
 public static string Verify(string original,string final,string maskPath,string dir) {
  using(var a=new Bitmap(original))using(var b=new Bitmap(final))using(var m=new Bitmap(maskPath)) {
   if(a.Width!=512||a.Height!=512||a.Size!=b.Size||m.Size!=a.Size)throw new Exception("Size changed");
   var ap=Read(a);var bp=Read(b);var mp=Read(m);var diff=new byte[ap.Length];
   long changed=0,outside=0,alphaChanged=0,zero=0,opaque=0,partial=0,deep=0,feet=0;int maxy=-1,minx=512,miny=512,maxx=-1;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++) {
    int j=(y*512+x)*4;bool differs=false;for(int c=0;c<4;c++)if(ap[j+c]!=bp[j+c])differs=true;
    diff[j+3]=255;if(differs){changed++;diff[j+2]=255;minx=Math.Min(minx,x);miny=Math.Min(miny,y);maxx=Math.Max(maxx,x);if(mp[j]==0)outside++;if(y>=400)feet++;}
    if(ap[j+3]!=bp[j+3])alphaChanged++;
    int alpha=bp[j+3];if(alpha==0){zero++;continue;}maxy=Math.Max(maxy,y);if(alpha==255){opaque++;continue;}partial++;
    bool edge=false;for(int dy=-2;dy<=2;dy++)for(int dx=-2;dx<=2;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<512&&yy>=0&&yy<512&&bp[(yy*512+xx)*4+3]==0)edge=true;}
    if(!edge)deep++;
   }
   using(var d=Make(diff,512,512))d.Save(Path.Combine(dir,"rgba_difference.png"),ImageFormat.Png);
   if(changed==0||outside!=0||feet!=0||deep!=0||partial==0||maxy!=487)throw new Exception("Saved PNG invariants failed");
   string json=String.Format("{{\"width\":512,\"height\":512,\"changed_rgba_pixels\":{0},\"outside_mask_rgba_changed_pixels\":{1},\"alpha_changed_pixels_inside_mask\":{2},\"alpha0\":{3},\"alpha255\":{4},\"partial_alpha\":{5},\"partial_more_than_2px_from_zero\":{6},\"feet_region_y400_511_changed_pixels\":{7},\"foot_baseline_last_row\":{8},\"bottom_transparent_rows\":24,\"changed_bbox_xyxy_inclusive\":[{9},{10},{11},{12}]}}",changed,outside,alphaChanged,zero,opaque,partial,deep,feet,maxy,minx,miny,maxx,FindMaxChangedY(ap,bp));
   File.WriteAllText(Path.Combine(dir,"verification.json"),json);return json;
  }
 }
 static int FindMaxChangedY(byte[] a,byte[] b){int max=-1;for(int j=0;j<a.Length;j++)if(a[j]!=b[j])max=Math.Max(max,j/4/512);return max;}
}
'@
$target='art/final/characters/C01_lina/C01_sd_attack.png'
$backup=Join-Path $QaDir 'C01_sd_attack_before.png'
if($Mode -eq 'Prepare') {
 if(Test-Path -LiteralPath $QaDir){throw "Refusing to reuse QA directory: $QaDir"}
 New-Item -ItemType Directory -Path $QaDir | Out-Null
 Copy-Item -LiteralPath $target -Destination $backup
 Copy-Item -LiteralPath ($target -replace '\.png$','.prompt.txt') -Destination (Join-Path $QaDir 'C01_sd_attack_before.prompt.txt')
 $protected=@(Get-ChildItem art -Recurse -File | Where-Object {($_.Extension -eq '.png' -or $_.Name.EndsWith('.prompt.txt')) -and $_.FullName -notlike '*\art\raw\*' -and $_.FullName -ne (Join-Path (Get-Location) $target.Replace('/','\')) -and $_.FullName -ne (Join-Path (Get-Location) ($target.Replace('/','\') -replace '\.png$','.prompt.txt'))} | ForEach-Object { @{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} })
 $protected | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $QaDir 'protected_hashes.json') -Encoding UTF8
 [AttackRework]::Prepare($backup,$QaDir)
 Write-Output "Prepared backup, fixed edit mask and $($protected.Count) protected file hashes in $QaDir"
} elseif($Mode -eq 'Composite') {
 if(-not(Test-Path -LiteralPath $Candidate)){throw 'Candidate missing'}
 [AttackRework]::Composite($backup,$Candidate,(Join-Path $QaDir 'edit_mask.png'),(Join-Path $QaDir 'candidate_composite.png'),$QaDir)
} else {
 [AttackRework]::Verify($backup,$target,(Join-Path $QaDir 'edit_mask.png'),$QaDir)
 foreach($p in (Get-Content -LiteralPath (Join-Path $QaDir 'protected_hashes.json') -Encoding UTF8 -Raw | ConvertFrom-Json)) {
  if((Get-FileHash -LiteralPath $p.path -Algorithm SHA256).Hash -ne $p.sha256){throw "Protected file changed: $($p.path)"}
 }
 Write-Output 'All other image and prompt hashes unchanged.'
}
