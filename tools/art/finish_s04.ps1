param([ValidateSet('Composite','Shield','Down','Icon','Cutin','Sheets','Verify')][string]$Mode,[string]$InputImage,[string]$OutputImage,[string]$QaDir='art/raw/qa_S04')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class S04 {
 public static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 public static Bitmap Make(byte[] p,int w,int h){var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static void Checker(Bitmap b,string path){using(var c=new Bitmap(b.Width,b.Height))using(var g=Graphics.FromImage(c)){for(int y=0;y<c.Height;y+=24)for(int x=0;x<c.Width;x+=24)g.FillRectangle((x/24+y/24)%2==0?Brushes.White:Brushes.LightGray,x,y,24,24);g.DrawImageUnscaled(b,0,0);c.Save(path,ImageFormat.Png);}}
 static PointF[] Points(float[] p){var r=new PointF[p.Length/2];for(int i=0;i<r.Length;i++)r[i]=new PointF(p[2*i],p[2*i+1]);return r;}
 static double Distance(PointF p,PointF a,PointF b){double dx=b.X-a.X,dy=b.Y-a.Y,t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));}
 public static void Composite(string src,string candidate,string output,string qa,bool shieldOnly){using(var a=new Bitmap(src))using(var b=new Bitmap(candidate)){
  if(a.Size!=b.Size)throw new Exception("Size changed");var ap=Read(a);var bp=Read(b);var result=(byte[])ap.Clone();var mask=new byte[ap.Length];var diff=new byte[ap.Length];
  var polys=shieldOnly?new[]{Points(new float[]{1036,1070,1147,1070,1154,1188,1072,1194,1050,1145})}:new[]{Points(new float[]{532,421,548,383,579,337,614,307,659,282,668,309,648,352,619,397,581,432,550,443}),Points(new float[]{316,1030,395,1030,380,1134,343,1195,310,1195})};
  var paths=new GraphicsPath[polys.Length];for(int k=0;k<polys.Length;k++){paths[k]=new GraphicsPath();paths[k].AddPolygon(polys[k]);}
  long changed=0,outside=0;for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int j=(y*a.Width+x)*4;double weight=0;var p=new PointF(x+.5f,y+.5f);for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(p)){double d=9999;for(int n=0;n<polys[k].Length;n++)d=Math.Min(d,Distance(p,polys[k][n],polys[k][(n+1)%polys[k].Length]));weight=Math.Max(weight,Math.Min(1,d/4));}byte m=(byte)Math.Round(weight*255);mask[j]=mask[j+1]=mask[j+2]=m;mask[j+3]=255;diff[j+3]=255;bool changedHere=false;for(int c=0;c<4;c++){result[j+c]=(byte)Math.Round(ap[j+c]+(bp[j+c]-ap[j+c])*weight);if(result[j+c]!=ap[j+c])changedHere=true;}if(changedHere){changed++;diff[j+2]=255;if(m==0)outside++;}}
  using(var r=Make(result,a.Width,a.Height)){r.Save(output,ImageFormat.Png);Checker(r,Path.Combine(qa,"down_repair_checker.png"));}using(var m=Make(mask,a.Width,a.Height))m.Save(Path.Combine(qa,"down_edit_mask.png"),ImageFormat.Png);using(var d=Make(diff,a.Width,a.Height))d.Save(Path.Combine(qa,"down_edit_diff.png"),ImageFormat.Png);
  foreach(var p in paths)p.Dispose();if(outside!=0)throw new Exception("Mask invariant failed");File.WriteAllText(Path.Combine(qa,"down_repair_qa.json"),"{\"outside_mask_rgba_changed\":"+outside+",\"changed_pixels\":"+changed+"}");
 }}
 public static void Down(string src,string output,string qa){using(var b=new Bitmap(src))using(var dst=new Bitmap(512,512,PixelFormat.Format32bppArgb)){
  // Same 180px head scale as approved idle: raw crown width about 600px. Boot sole at raw y1155.
  double scale=.30;int w=(int)Math.Round(b.Width*scale),h=(int)Math.Round(b.Height*scale),left=(512-w)/2,top=487-(int)Math.Round(1155*scale);
  using(var g=Graphics.FromImage(dst)){g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(b,new Rectangle(left,top,w,h),new Rectangle(0,0,b.Width,b.Height),GraphicsUnit.Pixel);}
  var p=Read(dst);var binary=new bool[512*512];for(int j=0;j<binary.Length;j++)binary[j]=p[j*4+3]>=128;
  for(int y=0;y<512;y++)for(int x=0;x<512;x++){int j=(y*512+x)*4,a=0;if(binary[y*512+x]){int count=0;for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int xx=x+dx,yy=y+dy;if(xx>=0&&xx<512&&yy>=0&&yy<512&&binary[yy*512+xx])count++;}a=count==9?255:Math.Min(p[j+3],(int)Math.Round(255.0*count/9));}p[j+3]=(byte)a;if(a==0)p[j]=p[j+1]=p[j+2]=0;}
  // Locate actual boot silhouette in its expected screen-left x130..168 interval.
  int bootY=-1;for(int y=400;y<512;y++)for(int x=130;x<=168;x++)if(p[(y*512+x)*4+3]>0)bootY=Math.Max(bootY,y);
  int shift=487-bootY;var shifted=new byte[p.Length];for(int y=0;y<512;y++){int yy=y+shift;if(yy>=0&&yy<512)Buffer.BlockCopy(p,y*512*4,shifted,yy*512*4,512*4);}using(var r=Make(shifted,512,512)){r.Save(output,ImageFormat.Png);Checker(r,Path.Combine(qa,"checkerboard.png"));}
  File.WriteAllText(Path.Combine(qa,"qa.json"),"{\"width\":512,\"height\":512,\"scale\":0.30,\"boot_toe_baseline\":487,\"head_width_target\":180,\"vertical_shift\":"+shift+"}");
 }}
 public static void Resize(string src,string output,bool cutin){using(var a=new Bitmap(src)){int w=cutin?1920:256,h=cutin?640:256;Rectangle crop;if(cutin){int ch=a.Width/3;crop=new Rectangle(0,(a.Height-ch)/4,a.Width,ch);}else{int s=Math.Min(a.Width,a.Height);crop=new Rectangle((a.Width-s)/2,(a.Height-s)/2,s,s);}using(var b=new Bitmap(w,h,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(b)){g.Clear(Color.FromArgb(35,24,20));g.CompositingMode=CompositingMode.SourceOver;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(a,new Rectangle(0,0,w,h),crop,GraphicsUnit.Pixel);b.Save(output,ImageFormat.Png);}}}
 public static void Sheets(string qa){string dir="art/final/characters/C01_lina/";string[] faces={"neutral","smile","angry","sad","surprised","embarrassed"};using(var b=new Bitmap(6*240,280))using(var g=Graphics.FromImage(b)){g.Clear(Color.FromArgb(45,35,30));for(int i=0;i<faces.Length;i++)using(var a=new Bitmap(dir+"C01_portrait_combat_"+faces[i]+".png")){g.DrawImage(a,new Rectangle(i*240,20,240,223),new Rectangle(370,145,210,195),GraphicsUnit.Pixel);g.DrawString(faces[i],new Font("Arial",14),Brushes.White,i*240+5,250);}b.Save(Path.Combine(qa,"expressions_contact.png"));}
  string[] sds={"idle","attack","skill","hit","down"};using(var b=new Bitmap(5*512,540))using(var g=Graphics.FromImage(b)){g.Clear(Color.FromArgb(85,85,85));for(int i=0;i<sds.Length;i++){using(var a=new Bitmap(dir+"C01_sd_"+sds[i]+".png"))g.DrawImageUnscaled(a,i*512,0);g.DrawLine(Pens.Yellow,i*512,488,(i+1)*512,488);g.DrawString(sds[i],new Font("Arial",16),Brushes.White,i*512+8,510);}b.Save(Path.Combine(qa,"sd_contact.png"));}
  using(var b=new Bitmap(900,350))using(var g=Graphics.FromImage(b)){g.Clear(Color.FromArgb(45,35,30));string[] icons={"skill1","skill2","ult"};for(int i=0;i<3;i++){using(var a=new Bitmap("art/final/icons/skills/C01_icon_"+icons[i]+".png")){g.DrawImage(a,i*300,0,256,256);g.DrawImage(a,i*300,272,48,48);}g.DrawString(icons[i],new Font("Arial",14),Brushes.White,i*300+60,285);}b.Save(Path.Combine(qa,"icons_contact.png"));}
 }
}
'@
New-Item -ItemType Directory -Force -Path $QaDir | Out-Null
switch($Mode){
 'Composite' {[S04]::Composite('art/raw/C01_sd_down_v1.png',$InputImage,$OutputImage,$QaDir,$false)}
 'Shield' {[S04]::Composite('art/raw/C01_sd_down_masked_v2.png',$InputImage,$OutputImage,$QaDir,$true)}
 'Down' {[S04]::Down($InputImage,$OutputImage,$QaDir)}
 'Icon' {[S04]::Resize($InputImage,$OutputImage,$false)}
 'Cutin' {[S04]::Resize($InputImage,$OutputImage,$true)}
 'Sheets' {[S04]::Sheets($QaDir)}
}
