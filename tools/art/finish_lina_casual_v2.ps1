param(
    [Parameter(Mandatory=$true)][string]$EditedImage
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class LinaCasualRevision {
    static double EdgeDistance(PointF p, PointF a, PointF b) {
        double dx=b.X-a.X, dy=b.Y-a.Y;
        double t=Math.Max(0,Math.Min(1,((p.X-a.X)*dx+(p.Y-a.Y)*dy)/(dx*dx+dy*dy)));
        return Math.Sqrt(Math.Pow(p.X-a.X-t*dx,2)+Math.Pow(p.Y-a.Y-t*dy,2));
    }
    static PointF[] P(float[] xy) {
        PointF[] p=new PointF[xy.Length/2];
        for(int i=0;i<p.Length;i++) p[i]=new PointF(xy[i*2],xy[i*2+1]);
        return p;
    }
    public static string Run(string source,string edit,string output,string qaDir) {
        using(var original=new Bitmap(source)) using(var edited=new Bitmap(edit)) {
            if(original.Width!=1024 || original.Height!=1536 || edited.Size!=original.Size)
                throw new Exception("Expected both images to be 1024x1536; no scaling permitted.");
            // Three face-interior masks avoid the hair, jaw silhouette, ears and neck.
            var polygons=new [] {
                P(new float[]{400,200,420,195,438,201,451,216,452,237,435,250,418,247,407,232}),
                P(new float[]{479,184,498,170,530,163,545,170,550,191,545,216,524,229,497,226,484,213}),
                P(new float[]{421,248,446,237,473,245,493,235,541,220,550,241,540,272,518,296,491,314,462,300,440,281})
            };
            var paths=new GraphicsPath[polygons.Length];
            for(int i=0;i<paths.Length;i++){paths[i]=new GraphicsPath();paths[i].AddPolygon(polygons[i]);}
            using(var result=new Bitmap(1024,1536,PixelFormat.Format32bppArgb))
            using(var mask=new Bitmap(1024,1536,PixelFormat.Format32bppArgb))
            using(var difference=new Bitmap(1024,1536,PixelFormat.Format32bppArgb)) {
                long changed=0,outsideRgb=0,opaque=0,transparent=0;
                for(int y=0;y<1536;y++) for(int x=0;x<1024;x++) {
                    Color a=original.GetPixel(x,y), b=edited.GetPixel(x,y);
                    double weight=0;
                    if(x>=395 && x<=555 && y>=158 && y<=318) {
                        var p=new PointF(x+0.5f,y+0.5f);
                        for(int k=0;k<paths.Length;k++) if(paths[k].IsVisible(p)) {
                            double d=1000;
                            for(int j=0;j<polygons[k].Length;j++)
                                d=Math.Min(d,EdgeDistance(p,polygons[k][j],polygons[k][(j+1)%polygons[k].Length]));
                            weight=Math.Max(weight,Math.Min(1,d/5.0));
                        }
                    }
                    int r=(int)Math.Round(a.R+(b.R-a.R)*weight);
                    int g=(int)Math.Round(a.G+(b.G-a.G)*weight);
                    int bl=(int)Math.Round(a.B+(b.B-a.B)*weight);
                    // Native matte from v1; remove faint background residue and make every retained pixel opaque.
                    int alpha=a.A>=128?255:0;
                    result.SetPixel(x,y,Color.FromArgb(alpha,r,g,bl));
                    int m=(int)Math.Round(weight*255);
                    mask.SetPixel(x,y,Color.FromArgb(255,m,m,m));
                    bool differs=r!=a.R || g!=a.G || bl!=a.B;
                    if(differs) changed++;
                    if(weight==0 && differs) outsideRgb++;
                    difference.SetPixel(x,y,differs?Color.Red:Color.Black);
                    if(alpha==255) opaque++; else transparent++;
                }
                if(outsideRgb!=0) throw new Exception("RGB changed outside face mask.");
                result.Save(output,ImageFormat.Png);
                mask.Save(System.IO.Path.Combine(qaDir,"C01_casual_v2_face_mask.png"),ImageFormat.Png);
                difference.Save(System.IO.Path.Combine(qaDir,"C01_casual_v2_rgb_difference.png"),ImageFormat.Png);
                using(var preview=new Bitmap(1024,1536)) using(var g=Graphics.FromImage(preview)) {
                    for(int y=0;y<1536;y+=32) for(int x=0;x<1024;x+=32)
                        g.FillRectangle(((x/32+y/32)%2==0)?Brushes.LightGray:Brushes.White,x,y,32,32);
                    g.DrawImageUnscaled(result,0,0);
                    preview.Save(System.IO.Path.Combine(qaDir,"C01_casual_v2_checkerboard.png"),ImageFormat.Png);
                }
                foreach(var p in paths)p.Dispose();
                return String.Format("{{\"width\":1024,\"height\":1536,\"changed_rgb_pixels\":{0},\"outside_face_rgb_changes\":{1},\"alpha_255_pixels\":{2},\"alpha_0_pixels\":{3},\"partial_alpha_pixels\":0,\"alpha_threshold\":128}}",changed,outsideRgb,opaque,transparent);
            }
        }
    }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$raw=Join-Path $root 'art/raw'
$out=Join-Path $raw 'C01_portrait_casual_neutral_v2.png'
if(Test-Path -LiteralPath $out){throw "Output already exists: $out"}
$qa=Join-Path $raw 'qa_C01_casual_v2'
New-Item -ItemType Directory -Path $qa -Force | Out-Null
$report=[LinaCasualRevision]::Run((Join-Path $raw 'C01_portrait_casual_neutral_v1.png'),$EditedImage,$out,$qa)
[IO.File]::WriteAllText((Join-Path $qa 'qa.json'),$report,[Text.UTF8Encoding]::new($false))
$report
