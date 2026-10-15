param([Parameter(Mandatory=$true)][string]$Id,[string]$Source,[ValidateSet('portrait','sd','face','cutin','mask')][string]$Kind,[int]$CropX=368,[int]$CropY=96,[int]$CropSize=288,[double]$Scale=0,[string]$Polygons,[string]$WorkingSource)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.IO;
public static class S10Remaining {
 public static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);if(d.Stride!=b.Width*4)throw new Exception("Stride");var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static Bitmap Make(byte[] p,int w,int h){var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static int[] Bounds(byte[] p,int w,int h,int cutoff){int x0=w,y0=h,x1=-1,y1=-1;for(int y=0;y<h;y++)for(int x=0;x<w;x++)if(p[(y*w+x)*4+3]>=cutoff){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}return new[]{x0,y0,x1,y1};}
 public static void Preview(Bitmap b,string path){using(var p=new Bitmap(b.Width,b.Height))using(var g=Graphics.FromImage(p)){g.Clear(Color.FromArgb(225,225,225));g.DrawImageUnscaled(b,0,0);p.Save(path,ImageFormat.Png);}}
 static PointF[] P(float[] xy){var r=new PointF[xy.Length/2];for(int i=0;i<r.Length;i++)r[i]=new PointF(xy[i*2],xy[i*2+1]);return r;}
 static double Dist(PointF p,PointF a,PointF b){double dx=b.X-a.X,dy=b.Y-a.Y,t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));}
 public static string Face(string original,string edit,string output,string qa,int cx,int cy,int size,string maskPath){
 using(var a=new Bitmap(original))using(var source=new Bitmap(edit))using(var e=new Bitmap(size,size,PixelFormat.Format32bppArgb)){
 using(var g=Graphics.FromImage(e)){g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(source,new Rectangle(0,0,size,size),0,0,source.Width,source.Height,GraphicsUnit.Pixel);}
 var ap=Read(a);var ep=Read(e);var result=(byte[])ap.Clone();var mask=new byte[ap.Length];var diff=new byte[ap.Length];
 using(var mb=new Bitmap(maskPath)){
 var mp=Read(mb);long changed=0,outside=0,alpha=0;
 for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int j=(y*a.Width+x)*4;double weight=mp[j]/255.0;for(int c=0;c<3;c++)mask[j+c]=mp[j];mask[j+3]=diff[j+3]=255;
 if(weight>0){if(x<cx||x>=cx+size||y<cy||y>=cy+size)throw new Exception("Mask outside crop");int k=((y-cy)*size+x-cx)*4;for(int c=0;c<3;c++)result[j+c]=(byte)Math.Round(ap[j+c]+(ep[k+c]-ap[j+c])*weight);}
 bool different=false;for(int c=0;c<4;c++)if(result[j+c]!=ap[j+c])different=true;
 if(different){changed++;diff[j+2]=255;if(weight==0)outside++;}if(result[j+3]!=ap[j+3])alpha++;
 }
 if(outside!=0||alpha!=0||changed==0)throw new Exception("Face invariant failed");
 using(var r=Make(result,a.Width,a.Height)){r.Save(output,ImageFormat.Png);Preview(r,Path.Combine(qa,"preview.png"));using(var detail=r.Clone(new Rectangle(cx,cy,size,size),PixelFormat.Format32bppArgb))detail.Save(Path.Combine(qa,"face_detail.png"),ImageFormat.Png);}
 using(var m=Make(mask,a.Width,a.Height))m.Save(Path.Combine(qa,"face_mask.png"),ImageFormat.Png);using(var d=Make(diff,a.Width,a.Height))d.Save(Path.Combine(qa,"rgba_difference.png"),ImageFormat.Png);
 return String.Format("{{\"size\":[1024,1536],\"changed_rgb_pixels\":{0},\"outside_face_rgba_changed_pixels\":{1},\"alpha_changed_pixels\":{2},\"crop\":[{3},{4},{5},{5}],\"method\":\"guide3.1.4 face-mask composite; entire original alpha retained\"}}",changed,outside,alpha,cx,cy,size);
 }} }
 public static void Mask(string output,int w,int h,string polygons){var mask=new byte[w*h*4];var lists=polygons.Split('|');var pp=new PointF[lists.Length][];var paths=new GraphicsPath[lists.Length];for(int k=0;k<lists.Length;k++){string[] vals=lists[k].Split(',');float[] f=new float[vals.Length];for(int i=0;i<f.Length;i++)f[i]=float.Parse(vals[i],System.Globalization.CultureInfo.InvariantCulture);pp[k]=P(f);paths[k]=new GraphicsPath();paths[k].AddPolygon(pp[k]);}
 for(int y=0;y<h;y++)for(int x=0;x<w;x++){var p=new PointF(x+.5f,y+.5f);double v=0;for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(p)){double d=1000;for(int n=0;n<pp[k].Length;n++)d=Math.Min(d,Dist(p,pp[k][n],pp[k][(n+1)%pp[k].Length]));v=Math.Max(v,Math.Min(1,d/3));}int j=(y*w+x)*4;mask[j]=mask[j+1]=mask[j+2]=(byte)Math.Round(255*v);mask[j+3]=255;}
 using(var b=Make(mask,w,h))b.Save(output,ImageFormat.Png);foreach(var p in paths)p.Dispose();}
 public static string Asset(string source,string output,string qa,string kind,double scale){using(var src=new Bitmap(source)){
 int w=kind=="sd"?512:kind=="cutin"?1920:1024,h=kind=="sd"?512:kind=="cutin"?640:1536;
 if(kind=="portrait"&&(src.Width!=w||src.Height!=h))throw new Exception("Portrait registration must remain1024x1536");
 var sb=Bounds(Read(src),src.Width,src.Height,128);int dx=0,dy=0,dw=w,dh=h;Rectangle crop=new Rectangle(0,0,src.Width,src.Height);
 using(var canvas=new Bitmap(w,h,PixelFormat.Format32bppArgb)){
 using(var g=Graphics.FromImage(canvas)){g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;
 if(kind=="sd"){int cw=sb[2]-sb[0]+1,ch=sb[3]-sb[1]+1;if(scale<=0)scale=Math.Min(464.0/cw,464.0/ch);dw=(int)Math.Round(cw*scale);dh=(int)Math.Round(ch*scale);if(dw>500||dh>488)throw new Exception("Sprite exceeds canvas at chosen scale");dx=(512-dw)/2;dy=488-dh;crop=new Rectangle(sb[0],sb[1],cw,ch);}
 if(kind=="cutin"){int ch=Math.Min(src.Height,src.Width/3);int cw=ch*3;crop=new Rectangle((src.Width-cw)/2,(src.Height-ch)/2,cw,ch);}
 if(kind=="portrait")g.DrawImageUnscaled(src,0,0);else g.DrawImage(src,new Rectangle(dx,dy,dw,dh),crop,GraphicsUnit.Pixel);}
 var p=Read(canvas);long opaque=0,transparent=0,partial=0,deep=0;
 if(kind!="cutin"){var native=(byte[])p.Clone();var solid=new bool[w*h];for(int j=0;j<solid.Length;j++)solid[j]=p[j*4+3]>=128;
 for(int y=0;y<h;y++)for(int x=0;x<w;x++){int j=(y*w+x)*4,n=0;bool near=false;for(int oy=-1;oy<=1;oy++)for(int ox=-1;ox<=1;ox++){int xx=x+ox,yy=y+oy;if(xx<0||xx>=w||yy<0||yy>=h){if(kind=="portrait")n++;}else if(solid[yy*w+xx]){n++;near=true;}}int a=n==9?255:near?native[j+3]:0;if(solid[y*w+x]&&n<9&&a==255)a=(int)Math.Round(255.0*n/9);p[j+3]=(byte)a;if(a==0)p[j]=p[j+1]=p[j+2]=0;if(n==9&&a!=255)deep++;}
 if(kind=="sd"){var bounds=Bounds(p,w,h,1);int shift=487-bounds[3];if(shift!=0){var q=new byte[p.Length];for(int y=0;y<h;y++){int yy=y+shift;if(yy>=0&&yy<h)Buffer.BlockCopy(p,y*w*4,q,yy*w*4,w*4);}p=q;}}
 }
 for(int j=0;j<p.Length;j+=4){if(p[j+3]==255)opaque++;else if(p[j+3]==0)transparent++;else partial++;}
 var bbox=Bounds(p,w,h,1);using(var final=Make(p,w,h)){final.Save(output,ImageFormat.Png);Preview(final,Path.Combine(qa,"preview.png"));}
 if(kind!="cutin"&&(opaque<10000||transparent<10000||partial==0||deep!=0))throw new Exception("Alpha QA failed");
 return String.Format("{{\"size\":[{0},{1}],\"source_size\":[{2},{3}],\"alpha255\":{4},\"alpha0\":{5},\"partial_alpha\":{6},\"interior_partial\":{7},\"bbox\":[{8},{9},{10},{11}],\"uniform_scale\":{12},\"mirrored\":false}}",w,h,src.Width,src.Height,opaque,transparent,partial,deep,bbox[0],bbox[1],bbox[2],bbox[3],scale.ToString(System.Globalization.CultureInfo.InvariantCulture));
 }}}
}
'@
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if($Kind -eq 'mask'){
 [S10Remaining]::Mask((Join-Path $root ('art/raw/qa_S10_remaining/'+$Id+'_face_mask.png')),1024,1536,$Polygons)
 return
}
$qa=Join-Path $root ('art/raw/qa_S10_remaining/'+$Id)
New-Item -ItemType Directory -Force -Path $qa | Out-Null
$raw=Join-Path $root ('art/raw/'+$Id+'_v1.png')
$final=Join-Path $root ('art/final/characters/C03_adelheid/'+$Id+'.png')
if(Test-Path -LiteralPath $final){throw "Refusing final overwrite: $Id"}
if(-not(Test-Path -LiteralPath $raw)){Copy-Item -LiteralPath $Source -Destination $raw}
if($Kind -eq 'face'){
 $outfit=if($Id -match '_casual_'){'casual'}else{'combat'}
 $neutral=Join-Path $root ('art/final/characters/C03_adelheid/C03_portrait_'+$outfit+'_neutral.png')
 $mask=Join-Path $root ('art/raw/qa_S10_remaining/'+$outfit+'_face_mask.png')
 $report=[S10Remaining]::Face($neutral,$raw,$final,$qa,$CropX,$CropY,$CropSize,$mask)
}else{
 $inputToFinish=if($WorkingSource){(Resolve-Path $WorkingSource).Path}else{$raw}
 $report=[S10Remaining]::Asset($inputToFinish,$final,$qa,$Kind,$Scale)
}
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$metaPath=Join-Path $root ('art/raw/qa_S10_remaining/'+$Id+'.json')
if(Test-Path $metaPath){
 $meta=Get-Content -Raw -Encoding UTF8 $metaPath|ConvertFrom-Json
 $meta|Add-Member -NotePropertyName source -NotePropertyValue $Source -Force
 [IO.File]::WriteAllText($metaPath,($meta|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
}
$report
