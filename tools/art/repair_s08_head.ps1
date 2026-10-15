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
public static class S08Head {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p){var b=new Bitmap(512,512,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,512,512),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static string Run(string original,string edit,string output,string qa){
  using(var a=new Bitmap(original))using(var e=new Bitmap(edit))using(var b=new Bitmap(512,512,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(b)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(e,new Rectangle(0,0,512,512));}
   var op=Read(a);var ep=Read(b);var mask=new bool[512*512];for(int j=0;j<mask.Length;j++)mask[j]=ep[j*4+3]>=128;
   for(int y=0;y<512;y++)for(int x=0;x<512;x++){
    int j=(y*512+x)*4,n=0;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<512&&yy>=0&&yy<512&&mask[yy*512+xx])n++;}
    int alpha=n==9?255:n>0?ep[j+3]:0;if(mask[y*512+x]&&n<9&&alpha==255)alpha=(int)Math.Round(255.0*n/9);ep[j+3]=(byte)alpha;if(alpha==0)ep[j]=ep[j+1]=ep[j+2]=0;
   }
   // Register only the edited head crown to the approved24px top margin.
   int headTop=512;for(int y=0;y<100;y++)for(int x=120;x<450;x++)if(ep[(y*512+x)*4+3]>0)headTop=Math.Min(headTop,y);
   int headShift=24-headTop;if(headShift!=0){var shifted=new byte[ep.Length];for(int y=0;y<512;y++){int yy=y+headShift;if(yy>=0&&yy<512)Buffer.BlockCopy(ep,y*2048,shifted,yy*2048,2048);}ep=shifted;}
   // Mask covers the head and upper-neck transition. All other RGBA are copied from original.
   var result=(byte[])op.Clone();var mp=new byte[op.Length];var diff=new byte[op.Length];
   var points=new[]{new PointF(151,15),new PointF(420,15),new PointF(425,204),new PointF(373,239),new PointF(295,239),new PointF(250,219),new PointF(156,203)};
   using(var path=new GraphicsPath()){
    path.AddPolygon(points);long changed=0,outside=0,alphaChanges=0;
    for(int y=0;y<512;y++)for(int x=0;x<512;x++){
     int j=(y*512+x)*4;bool inside=path.IsVisible(x+.5f,y+.5f);mp[j+3]=diff[j+3]=255;
     if(inside){double weight=y>219?Math.Max(0,(239.0-y)/20):1;mp[j]=mp[j+1]=mp[j+2]=(byte)Math.Round(255*weight);for(int c=0;c<4;c++)result[j+c]=(byte)Math.Round(op[j+c]+(ep[j+c]-op[j+c])*weight);}
     bool differs=false;for(int c=0;c<4;c++)if(result[j+c]!=op[j+c])differs=true;
     if(differs){changed++;diff[j+2]=255;if(!inside)outside++;}if(result[j+3]!=op[j+3])alphaChanges++;
    }
    var joinedMask=new bool[512*512];for(int j=0;j<joinedMask.Length;j++)joinedMask[j]=result[j*4+3]>=128;
    for(int y=1;y<511;y++)for(int x=1;x<511;x++)if(path.IsVisible(x+.5f,y+.5f)){
     bool deep=true;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++)if(!joinedMask[(y+dy)*512+x+dx])deep=false;
     if(deep)result[(y*512+x)*4+3]=255;
    }
    changed=outside=alphaChanges=0;Array.Clear(diff,0,diff.Length);
    for(int y=0;y<512;y++)for(int x=0;x<512;x++){
     int j=(y*512+x)*4;diff[j+3]=255;bool differs=false;for(int c=0;c<4;c++)if(result[j+c]!=op[j+c])differs=true;
     if(differs){changed++;diff[j+2]=255;if(!path.IsVisible(x+.5f,y+.5f))outside++;}if(result[j+3]!=op[j+3])alphaChanges++;
    }
    int y0=512,y1=-1;long opaque=0,partial=0,zero=0,deepPartial=0;
    var fm=new bool[512*512];for(int j=0;j<fm.Length;j++)fm[j]=result[j*4+3]>=128;
    for(int y=0;y<512;y++)for(int x=0;x<512;x++){
     int j=(y*512+x)*4,alpha=result[j+3];if(alpha>0){y0=Math.Min(y0,y);y1=Math.Max(y1,y);}if(alpha==255)opaque++;else if(alpha==0)zero++;else{partial++;bool deep=true;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx<0||xx>=512||yy<0||yy>=512||!fm[yy*512+xx])deep=false;}if(deep)deepPartial++;}
    }
    if(outside!=0||y1!=487||y0!=24||deepPartial!=0)throw new Exception("Outside mask/alpha/baseline invariant failed: top="+y0+", bottom="+y1+", deepPartial="+deepPartial);
    using(var final=Make(result)){
     final.Save(output,ImageFormat.Png);
     foreach(string background in new[]{"checkerboard","dark","light"})using(var preview=new Bitmap(512,512))using(var g=Graphics.FromImage(preview)){
      g.Clear(background=="dark"?Color.FromArgb(27,31,36):Color.White);if(background=="checkerboard")for(int y=0;y<512;y+=16)for(int x=0;x<512;x+=16)g.FillRectangle((x/16+y/16)%2==0?Brushes.LightGray:Brushes.White,x,y,16,16);g.DrawImageUnscaled(final,0,0);preview.Save(Path.Combine(qa,background+".png"),ImageFormat.Png);
     }
    }
    using(var m=Make(mp))m.Save(Path.Combine(qa,"head_mask.png"),ImageFormat.Png);using(var d=Make(diff))d.Save(Path.Combine(qa,"head_rgba_diff.png"),ImageFormat.Png);
    return String.Format("{{\"size\":[512,512],\"source_edit_size\":[{0},{1}],\"changed_pixels\":{2},\"outside_mask_rgba_changed_pixels\":{3},\"alpha_changes_inside_mask\":{4},\"alpha255\":{5},\"alpha0\":{6},\"partial_alpha\":{7},\"interior_partial\":{8},\"visible_y_bounds\":[{9},{10}],\"foot_baseline\":487,\"method\":\"local head and upper-neck RGBA mask composite; all outside pixels identical\"}}",e.Width,e.Height,changed,outside,alphaChanges,opaque,zero,partial,deepPartial,y0,y1);
   }
  }
 }
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S08/sd'
$raw=Join-Path $root 'art/raw/C02_sd_idle_v2.png'
if(Test-Path -LiteralPath $raw){if((Get-FileHash -LiteralPath $raw).Hash -ne (Get-FileHash -LiteralPath $Source).Hash){throw 'Raw v2 exists with different data'}}else{Copy-Item -LiteralPath $Source -Destination $raw}
$report=[S08Head]::Run((Join-Path $qa 'before_head_edit.png'),$raw,(Join-Path $qa 'head_edit_composite.png'),$qa)
Copy-Item -LiteralPath (Join-Path $qa 'head_edit_composite.png') -Destination (Join-Path $root 'art/final/characters/C02_cecile/C02_sd_idle.png')
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report
