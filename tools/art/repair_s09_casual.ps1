$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qa=Join-Path $root 'art/raw/qa_S09'
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class S09Repair {
 static void Poly(Graphics g,Brush brush,string spec) {
  string[] parts=spec.Split(';');Point[] pts=new Point[parts.Length];
  for(int i=0;i<parts.Length;i++){string[] a=parts[i].Split(',');pts[i]=new Point(int.Parse(a[0]),int.Parse(a[1]));}
  g.FillPolygon(brush,pts);
 }
 public static string Run(string before,string edit,string output,string maskPath,string diffPath) {
  using(var a=new Bitmap(before)) using(var b=new Bitmap(edit)) using(var o=new Bitmap(a)) using(var m=new Bitmap(a.Width,a.Height,PixelFormat.Format24bppRgb)) using(var d=new Bitmap(a.Width,a.Height,PixelFormat.Format24bppRgb)) {
   if(a.Size!=b.Size)throw new Exception("Edit dimensions changed");
   using(var g=Graphics.FromImage(m)) {
    g.Clear(Color.Black);
    // Clothing envelope includes old/new garment outlines and their narrow background margin.
    foreach(string p in new[]{
     "60,174;540,174;540,824;60,824",
     "600,174;963,174;963,824;600,824",
     "1008,174;1480,174;1480,824;1008,824",
     "278,160;332,160;332,208;278,208",
     "1206,157;1283,157;1283,200;1206,200",
     "91,294;137,285;174,307;209,346;228,383;208,425;184,455;119,472;88,451;68,403;72,352",
     "405,430;475,430;485,475;464,530;424,548;392,506;391,440",
     "218,435;290,442;357,442;390,451;422,535;452,661;489,785;476,818;127,818;127,767;171,600;202,493",
     "660,290;698,290;705,320;684,329;661,325",
     "706,395;750,385;846,351;875,360;879,422;858,496;797,539;743,537;703,477",
     "696,454;747,480;805,513;860,480;886,545;917,674;950,790;937,820;646,820;646,769;674,599",
     "1065,332;1105,342;1148,395;1156,447;1120,504;1096,540;1061,536;1042,503;1031,437;1043,377",
     "1384,305;1426,281;1452,293;1470,347;1470,413;1445,455;1408,464;1373,416;1361,360",
     "1150,488;1191,505;1286,515;1352,514;1380,490;1404,596;1427,713;1445,795;1423,820;1066,820;1066,775;1108,624"
    }) Poly(g,Brushes.White,p);
    // Exact immutable objects and skin patches, including braid and book covers/pages.
    foreach(string p in new[]{
     "96,250;140,246;143,296;120,313;94,299",
     "282,322;346,326;384,332;479,284;527,275;527,306;511,414;481,432;411,417;397,407;367,410;299,390",
     "362,400;397,402;406,416;401,440;378,434;366,424",
     "643,250;677,250;682,305;661,317;644,300",
     "608,334;727,320;824,272;852,266;854,285;838,377;748,402;706,402;671,410;633,399",
     "676,402;698,399;710,414;703,437;687,434;676,423",
     "1013,284;1035,280;1089,302;1108,332;1093,390;1045,398;1025,367",
     "1408,250;1440,250;1457,266;1447,305;1427,313;1415,294",
     "332,153;378,152;398,254;384,319;345,321;332,263",
     "774,157;850,143;872,173;831,225;781,268;754,261;763,218"
    }) Poly(g,Brushes.Black,p);
   }
   int changed=0,outside=0,alpha=0;
   for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){
    Color c=a.GetPixel(x,y),e=b.GetPixel(x,y);bool allow=m.GetPixel(x,y).R>0;
    bool bodyArea=(x>=60&&x<=540)||(x>=600&&x<=963)||(x>=1008&&x<=1480);
    bool oldNavy=c.B>c.R+12&&c.B>c.G+6&&c.R<110;
    if(bodyArea&&y>=200&&y<=824&&oldNavy)allow=true;
    // Protect the wood staff wherever a clothing polygon passes behind it.
    bool staffZone=(x>=100&&x<=137)||(x>=637&&x<=696)||(x>=1404&&x<=1452);
    bool brown=c.R>c.G+8&&c.G>c.B+6&&c.R<155;
    bool editedBrown=e.R>e.G+8&&e.G>e.B+6&&e.R<165;
    if(allow&&staffZone&&brown&&editedBrown)allow=false;
    // Keep the shawl and its tassels. It is warm neutral wool; the erroneous robe is blue.
    bool frontShawl=(x>=176&&x<=278&&y>=178&&y<=318)||(x>=278&&x<=337&&y>=209&&y<=294)||(x>=387&&x<=431&&y>=184&&y<=305)||(x>=242&&x<=287&&y>=295&&y<=501)||(x>=139&&x<=214&&y>=418&&y<=568)||(x>=437&&x<=465&&y>=449&&y<=674);
    bool sideShawl=(x>=774&&x<=899&&y>=188&&y<=309)||(x>=862&&x<=917&&y>=285&&y<=650);
    bool rearShawl=(x>=1106&&x<=1400&&y>=182&&y<=337)||(x>=1134&&x<=1390&&y>=318&&y<=499)||(x>=1271&&x<=1409&&y>=490&&y<=626)||(x>=1093&&x<=1137&&y>=450&&y<=569);
    bool shawlZone=frontShawl||sideShawl||rearShawl;
    bool warmWool=c.R>=c.G&&c.G>=c.B&&c.R>65&&c.R-c.B<42;
    bool editedWarmWool=e.R>=e.G&&e.G>=e.B&&e.R>65&&e.R-e.B<42;
    if(allow&&shawlZone&&warmWool&&editedWarmWool)allow=false;
    bool skin=c.R>180&&c.R>c.G+18&&c.G>c.B+10;
    if(allow&&skin&&y<166)allow=false;
    if(allow){o.SetPixel(x,y,Color.FromArgb(c.A,e.R,e.G,e.B));m.SetPixel(x,y,Color.White);}else m.SetPixel(x,y,Color.Black);
    Color f=o.GetPixel(x,y);bool delta=c.ToArgb()!=f.ToArgb();
    if(delta){changed++;if(m.GetPixel(x,y).R==0)outside++;d.SetPixel(x,y,Color.Red);}else d.SetPixel(x,y,Color.Black);
    if(c.A!=f.A)alpha++;
   }
   o.Save(output,ImageFormat.Png);m.Save(maskPath,ImageFormat.Png);d.Save(diffPath,ImageFormat.Png);
   if(outside!=0||alpha!=0)throw new Exception("Immutable pixels changed");
   return "outside_mask_RGBA_diff_pixels="+outside+"; alpha_diff_pixels="+alpha+"; changed_inside_mask="+changed;
  }
 }
}
'@
$out=Join-Path $qa 'C03_ref_casual_repaired.png'
$result=[S09Repair]::Run((Join-Path $root 'art/raw/C03_ref_casual_v1.png'),(Join-Path $root 'art/raw/C03_ref_casual_v2.png'),$out,(Join-Path $qa 'C03_ref_casual_clothing_mask.png'),(Join-Path $qa 'C03_ref_casual_clothing_diff.png'))
[IO.File]::WriteAllText((Join-Path $qa 'C03_ref_casual_repair_verification.txt'),$result,[Text.UTF8Encoding]::new($false))
if((Import-Csv -Encoding UTF8 (Join-Path $root 'art/manifest.csv') | Where-Object id -eq 'C03_ref_casual').status -eq 'approved') {throw 'Preserve approved asset.'}
Copy-Item -LiteralPath $out -Destination (Join-Path $root 'art/refs/C03_ref_casual.png')
$result
