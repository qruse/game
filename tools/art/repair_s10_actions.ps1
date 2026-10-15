param([ValidateSet('braid','arms','foot')][string]$Mode,[string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;using System.Runtime.InteropServices;using System.IO;
public static class S10Repair {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new byte[b.Width*b.Height*4];Marshal.Copy(d.Scan0,p,0,p.Length);b.UnlockBits(d);return p;}
 static Bitmap Make(byte[] p,int w,int h){var b=new Bitmap(w,h,PixelFormat.Format32bppArgb);var d=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(p,0,d.Scan0,p.Length);b.UnlockBits(d);return b;}
 static double Distance(PointF p,PointF a,PointF b){double dx=b.X-a.X,dy=b.Y-a.Y,t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));}
 public static string Braid(string original,string edit,string output,string qa,bool arms){using(var a=new Bitmap(original))using(var b=new Bitmap(edit)){
 int w=a.Width,h=a.Height;var ap=Read(a);var bp=Read(b);double best=double.MaxValue,bs=1;int bx=0,by=0;
 // Register unedited facial landmarks; the model moved the whole source despite the local edit request.
 for(double s=.94;s<=1.04;s+=.002)for(int tx=-40;tx<=60;tx+=2)for(int ty=-70;ty<=40;ty+=2){double score=0;int n=0;for(int y=350;y<=495;y+=12)for(int x=530;x<=710;x+=12){int xx=(int)Math.Round((x-tx)/s),yy=(int)Math.Round((y-ty)/s);if(xx<0||yy<0||xx>=b.Width||yy>=b.Height)continue;int j=(y*w+x)*4,k=(yy*b.Width+xx)*4;for(int c=0;c<3;c++)score+=Math.Abs(ap[j+c]-bp[k+c]);n+=3;}score/=n;if(score<best){best=score;bs=s;bx=tx;by=ty;}}
 using(var aligned=new Bitmap(w,h,PixelFormat.Format32bppArgb)){
 using(var g=Graphics.FromImage(aligned)){g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;g.DrawImage(b,new RectangleF(bx,by,(float)(b.Width*bs),(float)(b.Height*bs)),new RectangleF(0,0,b.Width,b.Height),GraphicsUnit.Pixel);}
 aligned.Save(Path.Combine(qa,"aligned_edit.png"),ImageFormat.Png);var ep=Read(aligned);var result=(byte[])ap.Clone();var mask=new byte[ap.Length];var diff=new byte[ap.Length];
 PointF[][] polys={new[]{new PointF(398,451),new PointF(449,451),new PointF(479,483),new PointF(485,518),new PointF(510,542),new PointF(537,575),new PointF(551,605),new PointF(578,632),new PointF(598,668),new PointF(611,704),new PointF(600,747),new PointF(578,773),new PointF(531,768),new PointF(515,730),new PointF(501,682),new PointF(477,656),new PointF(458,626),new PointF(448,589),new PointF(422,557),new PointF(402,520)},new[]{new PointF(593,513),new PointF(632,500),new PointF(669,506),new PointF(698,529),new PointF(718,568),new PointF(725,610),new PointF(742,653),new PointF(756,700),new PointF(758,750),new PointF(730,784),new PointF(692,770),new PointF(667,728),new PointF(650,686),new PointF(626,652),new PointF(607,610)}};
 if(arms)polys=new[]{new[]{new PointF(180,460),new PointF(330,460),new PointF(365,510),new PointF(423,512),new PointF(498,526),new PointF(562,535),new PointF(605,516),new PointF(694,516),new PointF(716,523),new PointF(750,514),new PointF(828,496),new PointF(912,488),new PointF(955,513),new PointF(1008,537),new PointF(1036,593),new PointF(1060,719),new PointF(1065,960),new PointF(1030,1035),new PointF(945,1072),new PointF(825,1090),new PointF(735,1115),new PointF(570,1127),new PointF(400,1120),new PointF(245,1050),new PointF(120,1030),new PointF(120,680)},new[]{new PointF(840,160),new PointF(1254,160),new PointF(1254,650),new PointF(1030,700),new PointF(904,703),new PointF(833,654)}};
 var paths=new GraphicsPath[polys.Length];for(int k=0;k<paths.Length;k++){paths[k]=new GraphicsPath();paths[k].AddPolygon(polys[k]);}
 long changed=0,outside=0,alpha=0;for(int y=0;y<h;y++)for(int x=0;x<w;x++){int j=(y*w+x)*4;double weight=0;var pt=new PointF(x+.5f,y+.5f);for(int k=0;k<paths.Length;k++)if(paths[k].IsVisible(pt)){double d=999;for(int i=0;i<polys[k].Length;i++)d=Math.Min(d,Distance(pt,polys[k][i],polys[k][(i+1)%polys[k].Length]));weight=Math.Max(weight,Math.Min(1,d/4));}int mv=(int)Math.Round(weight*255);mask[j]=mask[j+1]=mask[j+2]=(byte)mv;mask[j+3]=diff[j+3]=255;bool different=false;for(int c=0;c<3;c++){result[j+c]=(byte)Math.Round(ap[j+c]+(ep[j+c]-ap[j+c])*weight);if(result[j+c]!=ap[j+c])different=true;}if(different){changed++;diff[j+2]=255;if(mv==0)outside++;}if(result[j+3]!=ap[j+3])alpha++;}
 // Arm/prop changes move silhouette, so their local mask also carries edited alpha.
 if(arms){alpha=0;for(int j=0;j<result.Length;j+=4){result[j+3]=(byte)Math.Round(ap[j+3]+(ep[j+3]-ap[j+3])*mask[j]/255.0);if(result[j+3]!=ap[j+3])alpha++;}}
 if(outside!=0||(!arms&&alpha!=0))throw new Exception("Repair invariant");using(var r=Make(result,w,h))r.Save(output,ImageFormat.Png);using(var m=Make(mask,w,h))m.Save(Path.Combine(qa,arms?"arms_mask.png":"braid_mask.png"),ImageFormat.Png);using(var d=Make(diff,w,h))d.Save(Path.Combine(qa,arms?"arms_rgba_difference.png":"braid_rgba_difference.png"),ImageFormat.Png);foreach(var p in paths)p.Dispose();
 return "{\"alignment_scale\":"+bs.ToString(System.Globalization.CultureInfo.InvariantCulture)+",\"alignment_translation\":["+bx+","+by+"],\"facial_landmark_mae\":"+best.ToString(System.Globalization.CultureInfo.InvariantCulture)+",\"changed_rgb_pixels\":"+changed+",\"outside_mask_rgba_changed\":"+outside+",\"alpha_changed\":"+alpha+"}";
 }}}
 public static string Foot(string input,string output){using(var a=new Bitmap(input)){var p=Read(a);int foot=-1;for(int y=390;y<512;y++)for(int x=70;x<=120;x++)if(p[(y*512+x)*4+3]>0)foot=Math.Max(foot,y);if(foot<420)throw new Exception("Boot not found");int shift=487-foot;var q=new byte[p.Length];int lost=0;for(int y=0;y<512;y++){int yy=y+shift;if(yy>=0&&yy<512)Buffer.BlockCopy(p,y*512*4,q,yy*512*4,512*4);else for(int x=0;x<512;x++)if(p[(y*512+x)*4+3]>0)lost++;}if(lost!=0)throw new Exception("Would clip sprite");using(var b=Make(q,512,512))b.Save(output,ImageFormat.Png);return "{\"boot_scan_x\":[70,120],\"boot_before\":"+foot+",\"shift_y\":"+shift+",\"boot_after\":487,\"clipped_pixels\":0}";}}
}
'@
$qa=Join-Path (Get-Location) 'art/raw/qa_S10_remaining'
if($Mode -eq 'braid' -or $Mode -eq 'arms'){
 $dir=Join-Path $qa 'C03_sd_attack';New-Item -ItemType Directory -Force $dir|Out-Null
 $raw=if($Mode -eq 'braid'){'art/raw/C03_sd_attack_v2.png'}else{'art/raw/C03_sd_attack_v3.png'}
 if(-not(Test-Path $raw)){Copy-Item -LiteralPath $Source -Destination $raw}
 $original=if($Mode -eq 'braid'){(Resolve-Path art/raw/C03_sd_attack_v1.png).Path}else{(Join-Path $dir 'repaired_source.png')}
 $out=if($Mode -eq 'braid'){'repaired_source.png'}else{'arms_repaired_source.png'}
 $report=[S10Repair]::Braid($original,(Resolve-Path $raw).Path,(Join-Path $dir $out),$dir,($Mode -eq 'arms'))
 [IO.File]::WriteAllText((Join-Path $dir ($Mode+'_repair_qa.json')),$report,[Text.UTF8Encoding]::new($false))
}else{
 $dir=Join-Path $qa 'C03_sd_down';$path=(Resolve-Path art/final/characters/C03_adelheid/C03_sd_down.png).Path
 Copy-Item $path (Join-Path $dir 'before_foot_alignment.png')
 $report=[S10Repair]::Foot($path,(Join-Path $dir 'foot_aligned.png'))
 Copy-Item (Join-Path $dir 'foot_aligned.png') $path -Force
 [IO.File]::WriteAllText((Join-Path $dir 'foot_alignment.json'),$report,[Text.UTF8Encoding]::new($false))
}
$report
