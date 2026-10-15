param([string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;using System.Runtime.InteropServices;using System.IO;
public static class S10CutinRepair {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p,int w,int h){var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 public static string Run(string original,string edit,string output,string qa){using(var a=new Bitmap(original))using(var s=new Bitmap(edit))using(var b=new Bitmap(1920,640,PixelFormat.Format32bppArgb)){
 using(var g=Graphics.FromImage(b)){g.Clear(Color.FromArgb(20,25,35));g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(s,0,0,1920,640);}var ap=Read(a);var native=Read(b);double best=double.MaxValue,scale=1;int txBest=0,tyBest=0;
 for(double sc=.94;sc<=1.08;sc+=.0025)for(int tx=-60;tx<=90;tx+=3)for(int ty=-40;ty<=40;ty+=3){double score=0;int n=0;for(int y=170;y<=310;y+=12)for(int x=1000;x<=1220;x+=12){int xx=(int)Math.Round((x-tx)/sc),yy=(int)Math.Round((y-ty)/sc);if(xx<0||xx>=1920||yy<0||yy>=640)continue;int j=(y*1920+x)*4,k=(yy*1920+xx)*4;for(int c=0;c<3;c++)score+=Math.Abs(ap[j+c]-native[k+c]);n+=3;}score/=n;if(score<best){best=score;scale=sc;txBest=tx;tyBest=ty;}}
 var bp=new byte[native.Length];for(int y=0;y<640;y++)for(int x=0;x<1920;x++){double sx=Math.Max(0,Math.Min(1919,(x-txBest)/scale)),sy=Math.Max(0,Math.Min(639,(y-tyBest)/scale));int x0=(int)sx,y0=(int)sy,x1=Math.Min(1919,x0+1),y1=Math.Min(639,y0+1);double fx=sx-x0,fy=sy-y0;int j=(y*1920+x)*4;for(int c=0;c<3;c++)bp[j+c]=(byte)Math.Round(native[(y0*1920+x0)*4+c]*(1-fx)*(1-fy)+native[(y0*1920+x1)*4+c]*fx*(1-fy)+native[(y1*1920+x0)*4+c]*(1-fx)*fy+native[(y1*1920+x1)*4+c]*fx*fy);bp[j+3]=255;}
 using(var aligned=Make(bp,1920,640))aligned.Save(Path.Combine(qa,"registered_hands_edit.png"),ImageFormat.Png);
 var rp=(byte[])ap.Clone();var mask=new byte[rp.Length];var diff=new byte[rp.Length];
 var protect=new GraphicsPath();protect.AddPolygon(new[]{new PointF(850,0),new PointF(1320,0),new PointF(1350,95),new PointF(1340,195),new PointF(1305,260),new PointF(1260,320),new PointF(1210,360),new PointF(1155,375),new PointF(1095,354),new PointF(1005,325),new PointF(935,288),new PointF(900,235),new PointF(860,145),new PointF(835,80)});
 long changed=0,outside=0,face=0;for(int y=0;y<640;y++)for(int x=0;x<1920;x++){int j=(y*1920+x)*4;
 // Moving the very large foreground book reveals the scene behind it. Carry that
 // edited scene through a broad arm/prop integration mask, preserving the head core.
 double radius=Math.Sqrt(Math.Pow((x-1140.0)/150,2)+Math.Pow((y-230.0)/120,2));
 double weight=Math.Max(0,Math.Min(1,(radius-.82)/.18));
 int m=(int)Math.Round(weight*255);mask[j]=mask[j+1]=mask[j+2]=(byte)m;mask[j+3]=diff[j+3]=255;bool differs=false;for(int c=0;c<3;c++){rp[j+c]=(byte)Math.Round(ap[j+c]+(bp[j+c]-ap[j+c])*weight);if(rp[j+c]!=ap[j+c])differs=true;}rp[j+3]=255;
 if(differs){changed++;diff[j+2]=255;if(m==0)outside++;if(x>=1060&&x<=1220&&y>=180&&y<=290)face++;}}
 if(outside!=0||face!=0)throw new Exception("Cutin protected face failed");using(var r=Make(rp,1920,640))r.Save(output,ImageFormat.Png);using(var m=Make(mask,1920,640))m.Save(Path.Combine(qa,"hands_mask.png"),ImageFormat.Png);using(var d=Make(diff,1920,640))d.Save(Path.Combine(qa,"hands_rgba_difference.png"),ImageFormat.Png);protect.Dispose();
 return "{\"size\":[1920,640],\"changed_rgb_pixels\":"+changed+",\"outside_mask_rgba_changed\":"+outside+",\"protected_face_changed\":"+face+",\"alpha255\":1228800,\"registration_scale\":"+scale.ToString(System.Globalization.CultureInfo.InvariantCulture)+",\"translation\":["+txBest+","+tyBest+"],\"registration_mae\":"+best.ToString(System.Globalization.CultureInfo.InvariantCulture)+"}";
 }}}
'@
$qa=Join-Path (Get-Location) 'art/raw/qa_S10_remaining/C03_cutin'
$raw='art/raw/C03_cutin_v2.png';if(-not(Test-Path $raw)){Copy-Item -LiteralPath $Source -Destination $raw}
$target=(Resolve-Path art/final/characters/C03_adelheid/C03_cutin.png).Path
if(-not(Test-Path "$qa/before_hands_repair.png")){Copy-Item $target "$qa/before_hands_repair.png"}
$report=[S10CutinRepair]::Run("$qa/before_hands_repair.png",(Resolve-Path $raw).Path,"$qa/hands_repaired.png",$qa)
[IO.File]::WriteAllText("$qa/hands_repair_qa.json",$report,[Text.UTF8Encoding]::new($false))
$report
