$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class S01Alpha {
    public static string Run(string input, string output, string preview) {
        using(var src = new Bitmap(input)) {
            int w=src.Width,h=src.Height;
            if(w!=1024 || h!=1536) throw new Exception("Unexpected portrait size");
            var rect=new Rectangle(0,0,w,h);
            var data=src.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
            byte[] pixels=new byte[data.Stride*h]; Marshal.Copy(data.Scan0,pixels,0,pixels.Length);
            int stride=data.Stride; src.UnlockBits(data);
            byte[] original=(byte[])pixels.Clone();
            bool[] mask=new bool[w*h];
            for(int y=0;y<h;y++) for(int x=0;x<w;x++) mask[y*w+x]=original[y*stride+x*4+3]>=128;
            long opaque=0,transparent=0,partial=0,changed=0,rgb=0,deepPartial=0;
            for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                int i=y*stride+x*4,a=0;
                if(mask[y*w+x]) {
                    int count=0;
                    for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
                        int xx=x+dx,yy=y+dy;
                        // Canvas crop edges are not silhouette boundaries.
                        if(xx<0 || xx>=w || yy<0 || yy>=h || mask[yy*w+xx]) count++;
                    }
                    // Retain native edge coverage when present; feather binary edges inward by one pixel.
                    a=count==9?255:Math.Min(original[i+3],(int)Math.Round(255.0*count/9));
                    if(count==9 && a!=255) deepPartial++;
                }
                pixels[i+3]=(byte)a;
                if(a!=original[i+3])changed++;
                if(a==255)opaque++;else if(a==0)transparent++;else partial++;
                for(int c=0;c<3;c++)if(pixels[i+c]!=original[i+c])rgb++;
            }
            using(var dst=new Bitmap(w,h,PixelFormat.Format32bppArgb)) {
                var target=dst.LockBits(rect,ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
                if(target.Stride!=stride)throw new Exception("Stride mismatch");
                Marshal.Copy(pixels,0,target.Scan0,pixels.Length);dst.UnlockBits(target);
                dst.Save(output,ImageFormat.Png);
                using(var check=new Bitmap(w,h))using(var g=Graphics.FromImage(check)) {
                    for(int y=0;y<h;y+=32)for(int x=0;x<w;x+=32)
                        g.FillRectangle((x/32+y/32)%2==0?Brushes.LightGray:Brushes.White,x,y,32,32);
                    g.DrawImageUnscaled(dst,0,0);check.Save(preview,ImageFormat.Png);
                }
            }
            return String.Format("{{\"width\":{0},\"height\":{1},\"alpha255\":{2},\"alpha0\":{3},\"partial_alpha\":{4},\"alpha_changes\":{5},\"rgb_changes\":{6},\"interior_partial\":{7},\"geometry\":\"unchanged; RGB pixel-identical; alpha>=128 source silhouette preserved; partial alpha only in inner 1px boundary\"}}",w,h,opaque,transparent,partial,changed,rgb,deepPartial);
        }
    }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$qa=Join-Path $root 'art/raw/qa_S01_approval'
New-Item -ItemType Directory -Force -Path $qa,(Join-Path $root 'art/refs'),(Join-Path $root 'art/final/characters/C01_lina') | Out-Null
$utf8=[Text.UTF8Encoding]::new($false)
foreach($outfit in @('combat','casual')) {
    $source=Join-Path $root "art/raw/C01_portrait_${outfit}_neutral_v2.png"
    $final=Join-Path $root "art/final/characters/C01_lina/C01_portrait_${outfit}_neutral.png"
    if(Test-Path -LiteralPath $final){throw "Destination already exists: $final"}
    $before=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $report=[S01Alpha]::Run($source,$final,(Join-Path $qa "${outfit}_checkerboard.png"))
    [IO.File]::WriteAllText((Join-Path $qa "${outfit}.json"),$report,$utf8)
    $promptSource=[IO.Path]::ChangeExtension($source,'prompt.txt')
    $promptFinal=[IO.Path]::ChangeExtension($final,'prompt.txt')
    Copy-Item -LiteralPath $promptSource -Destination $promptFinal
    [IO.File]::AppendAllText($promptFinal,"`n`nAPPROVAL COPY - 2026-10-15 (Asia/Seoul)`nUser approved S01 v2. Historical generation notes above are retained verbatim.`nSource: $source`nSource SHA256: $before`nApproved output: $final`nPostprocessing: tools/art/approve_s01.ps1; style-guide section 6; alpha>=128 source silhouette retained; interior alpha 255; partial alpha only within inner 1px boundary; RGB unchanged; no scaling, cropping, mirroring or repositioning.`nQA: $report`n",$utf8)
    if($before -ne (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash){throw 'Raw source changed'}
    "$outfit $report"
}
$anchor=Join-Path $root 'art/refs/style-anchor.png'
if(Test-Path -LiteralPath $anchor){throw 'Style anchor already exists'}
Copy-Item -LiteralPath (Join-Path $root 'art/final/characters/C01_lina/C01_portrait_combat_neutral.png') -Destination $anchor
Copy-Item -LiteralPath (Join-Path $root 'art/final/characters/C01_lina/C01_portrait_combat_neutral.prompt.txt') -Destination ([IO.Path]::ChangeExtension($anchor,'prompt.txt'))
