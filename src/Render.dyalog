:Namespace Render ⍝ V2.03
⍝⍝⍝⍝ PMS: Copied from: /Applications/Dyalog-18.2.app/Contents/Resources/Dyalog/SALT/spice/Render.dyalog

⍝ 2018 08 16 Adam: Initial commit
⍝ 2019 04 15 Adam: utf-8 in title
⍝ 2019 04 30 Adam: error msg tweak
⍝ 2021 02 18 Adam: handle new behaviour of ⎕S in 18.0
⍝ 2021 07 08 Adam: ]html: handle URLs using a heuristic, add -raw, default HTMLRenderer title
⍝ 2021 07 19 Adam: ]html: detect local file, handle nested HTML
⍝ 2021 07 23 Adam: handle long input, don't encode UTF-8
⍝ 2021 10 20 Adam: Insert missing : in heuristic, always define exists

    ⎕IO←1 ⋄ ⎕ML←1

    :SECTION IBEAMS
    L←819⌶           ⍝ Lowercase
    ride←3501⌶⍬      ⍝ Controlled by RIDE protocol?
    RideRender←3500⌶ ⍝ Send HTML thorugh RIDE protocol
    :ENDSECTION

    :SECTION UCMD
    syntax←'[-url]'

    ∇ r←List
      r←⎕NS¨⍬ ⍬
      r.Name←'HTML' 'Plot'
      r.Desc←'Render HTML/SVG or a website' 'Plot data'
      r.(Group Parse)←⊂'Output' ''
    ∇

    ∇ r←Run(cmd input);Causeway;SharpPlot;System;exists;expr;html;raw;type;typeIdx;typeNames;⎕USING
      ⍝ Input is raw to avoid quotes being interpreted as argument delimiters
      ⍝ Instead, we do custom parsing:
     
      r←⍬⊤⍬
      :Select cmd
      :Case 'HTML'
          raw←'^\s*-r(aw?)?\s+|\s+-r(aw?)?\s*$'
          :If ≢raw ⎕S 3⊢input
              input←raw'^|''|$'⎕R'' '&'''⊢input
          :EndIf
          input←##.THIS⍎input
     
          input(¯1↓∘∊,¨⍥⊆)←⎕UCS 10 ⍝ join if nested
     
          exists←{10::0 ⋄ ∆NEXISTS ⍵}input
          :If ≢'^\s*(https?://|([-\w]+\.)+\w\w+)'⎕S 3⍠'Mode' 'D'⊢input ⍝ looks like URL
          :OrIf ride∧exists
              input←'''' '\"'⎕R'\&apos;' '\&quot;'⊢input
              input,⍨←'http://'/⍨~exists∨≢'^https?://'⎕S 3⊢input
              input←'<meta http-equiv="refresh" content="0;url=''',input,'''">'
          :EndIf
     
          Show&input
      :Case 'Plot'
          type←'Line'ParseType input
          typeIdx←Chart.GetTypes Where type
          :If ×typeIdx
              expr←Expr input
              SharpPlot←NewSharpPlot
              (SharpPlot⍎Chart.GetMethod typeIdx⊃Chart.GetTypes)##.THIS⍎expr
              expr Show&SharpPlot.RenderSvg Causeway.SvgMode.FixedAspect
          :Else
              r←'** Invalid type: ',type
          :EndIf
      :EndSelect
    ∇

    ∇ r←level Help cmd;n;s;type
      n←List.Name⍳⊂cmd
      :If 'Plot'≡cmd
          type←ParseType ##.##.arg
      :AndIf 0≢type
          n←Chart.GetTypes Where type
          :If ×n
              type←n⊃Chart.GetTypes
              (syntax description)←DescribeData type
              r←⊂']',cmd,syntax,' -type=',type
              r,←,/': ' '. ' '.',¨⍨n⊃1↓Chart.(CHARTS[;DESC])
              :If ×level
                  r,←description
              :Else
                  r,←⊂']',cmd,' -type=',type,' -??   ⍝ for argument details'
              :EndIf
          :Else
              r←,⊂'* Invalid chart type: ',type
              r,←⊂'Valid chart type names are:'
              r,←,/' ',¨Chart.GetTypes
          :EndIf
      :Else
          r←n⌷List.Desc
          r,←⊂'    ]',cmd,n⊃' <content> [-raw]' ' <data> [-type=<name>]'
          :If ×level
              r,←⊂''
              :Select cmd
              :Case 'HTML'
                  r,←⊂'<content>  an expression returning HTML/SVG code or a URL'
                  r,←⊂''
                  r,←⊂'-raw       treat <content> as raw HTML/SVG or URL rather than an expression'
              :Case 'Plot'
                  r,←⊂'<data>  a simple vector or a vector of vectors (one per co-ordinate or series)'
                  r,←⊂'<name>  the type of chart to be produced (default: Line), one of:'
                  :If 1=level
                      r,←⊂'           ',∊' ',¨Chart.GetTypes
                      r,←⊂''
                      r,←⊂']',cmd,' -???              ⍝ for summary description of chart types'
                      r,←⊂']',cmd,' -type=<name> -?   ⍝ for detailed description of specified chart type'
                  :Else
                      r,←↓⍕'  '_ ListTypes
                  :EndIf
              :EndSelect
              s←'Rendering will happen by sending through the RIDE protocol if APL is being controlled through that ('
              s,←'not' 'as is'⊃⍨1+ride
              s,←' the case right now), otherwise a stand-alone HTMLRenderer will be used.'
              r,←''s
          :Else
              r,←⊂''
              r,←⊂']',cmd,' -??   ⍝ for details'
          :EndIf
      :EndIf
    ∇
    :ENDSECTION

    :SECTION UTILS

    ∇ SharpPlot←NewSharpPlot
      :If 0=⎕NC'Causeway'
          ⎕USING←',system.dll' ',system.drawing.dll' ',sharpplot.dll'
      :AndIf 0=⎕NC'Causeway'
          (System.Drawing←System←Causeway←⎕NS ⍬).⎕CY'sharpplot.dws'
      :EndIf
      SharpPlot←⎕NEW Causeway.SharpPlot
    ∇

    ∇ types←ListTypes
      types←Chart.(GetTypes,⍪'^\w+'⎕R''⊢2⊃¨1↓CHARTS[;DESC])
    ∇

    ∇ (syntax description)←DescribeData type;n;types;names
      (types names)←Chart.GetSeries type
      types←Chart.GetFormatDescription¨types
      syntax←∊' ',¨names
      description←↓⍕' ',names,⍪types
    ∇

    ∇ html←Render ref
      :Trap 0
          ref←⎕NEW⍣(~9.1∊⎕NC'ref')⊢ref
          :If 3=⌊|ref.⎕NC⊂'Compose'
              ref.Compose
          :EndIf
          html←ref.Render
      :Else
          html←'[unable to render]'
      :EndTrap
    ∇

      ParseType←{
          ⍺←⊢
          ⍺ If(0∘≡)((⎕NEW ⎕SE.Parser'-type=').Parse⍕'-\w+=\w+'⎕S'&'⊢'''[^'']'''⎕R''⊢⍵).type
      }
      Show←{
          9∊⎕NC'⍵':(⍕∇ Render)⍵
          ⍺←⊃'3500⌶'_⍨∘∊'<title>(.*)</title>'⎕S'\1'
          ride:11 Err'Unable to initialise HTMLRenderer'/⍨¯1=(⍺ RideRender⊢)⍵
          Format←'<meta charset="utf-8">',(⍺ Document 96∘Shrink)⍣(2∊⎕NC'⍺')
          '0'∊⎕SE.SALTUtils.getEnvir'ENABLE_CEF':11 Err'HTMLRenderer is disabled (ENABLE_CEF=0)'
          11::11 Err'Unable to initialise HTMLRenderer'
          (#.⎕NEW'HTMLRenderer'_'Caption' 'HTMLRenderer'_{∆NEXISTS ⍵:'URL'⍵ ⋄ 'HTML'_ Format ⍵}⍵).Wait
      }
      If←{
          ⍺←⊢
          ⍺(⍺⍺⊣⊢)⍣(⍺ ⍵⍵ ⍵)⊢⍵
      }

    Char←{⎕UCS⍎⍵.Match(⊢(⍕16⊥¯1+1↓⍳)If('x'∊⊣)∩)ÖL⎕D,⎕A}
    Document←{'<html><head><title>',(Entity∊⍺),'</title></head><body>',⍵,'</body></html>'}
    Shrink←{' height="100%"'⎕R(' height="',(⍕⍺),'\%"')⊢⍵}

    _←{⍺⍵}           ⍝ Juxtapose
    ÖL←{(L⍺)⍺⍺(L⍵)}  ⍝ Over Lowercase
    ∆NEXISTS←{10::0 ⋄ ⎕NEXISTS ⍵}

    Err←⎕SIGNAL{(⊂('EN'⍺)('Message'⍵))/⍨×≢⍵}
    Where←⊃∘⍸(∨/⍷⍨ÖL)¨∘⊂

    Expr←'^ +| +$'⎕R''∘⊢'''[^'']''' '-\w+=\w+'⎕R'&' ''
    Entity←'<' '\&'⎕R'\&lt;' '\&amp;'
    Unentity←'&#[\da-fx]+;'⎕R Char⍠1∘⊢'&amp;' '&lt;' '&gt;'⎕R'\&' '<' '>'⍠1
    :ENDSECTION
    :Namespace Chart ⍝ from ChartWizard.dyalog
        (⎕IO ⎕ML ⎕WX)←1 1 3  ⍝!!! Mantis 10862
        ⍝⍝⍝⍝⍝ CHART TYPES ⍝⍝⍝⍝⍝
        TYPE←1        ⍝ charttype identifier
        METHOD←2      ⍝ chart draw method name
        STYLE←3       ⍝ chart style namespace
        DEF←4         ⍝ default serie indices
        ARGS←5        ⍝ seriestypes : 'N'=Numeric ⋄ 'A'=Any (text or numeric) ⋄ UPPERCASE=nested=multiple ⋄ lowercase=flat=single
        SERIES←6      ⍝ name of series
        LIMIT←7       ⍝ maximum number of points
        DESC←8        ⍝ description : [1] display name ⋄ [2] "technical" overview ⋄ [3] "didactic" overview
        COLS←8

        CHARTS←0 COLS⍴0
        CHARTS⍪←''          ''                 '⎕NULL'                       0         ⍬        ⍬                                    ¯1       ('Invalid chart type')
        CHARTS⍪←'Bar'       'DrawBarChart'     'Causeway.BarChartStyles'     (,1)      (,'N')   (,¨,⊂'Values')                       10000    ('Bar chart' 'Draw side-by-side bars rising from a baseline' 'Useful for small summary data')
        CHARTS⍪←'Box'       'DrawBoxPlot'      'Causeway.BoxPlotStyles'      (,1)      (,'naa') (,¨'Values' 'Category1' 'Category2') 1000000  ('Box-and-Whiskers plot' 'Draw quartiles of mono- or bi-variate numerical distributions' 'Useful to explore yet-unmodelled correlations between numerical variables')
        CHARTS⍪←'Bubble'    'DrawBubbleChart'  'Causeway.BubbleChartStyles'  (,3 1 2)  (,'nnn') (,¨'Y' 'X' 'Z')                      10000    ('Bubble chart' 'Draw bubbles scaled by Z value at XY positions' 'Useful for small XYZ data')
        CHARTS⍪←'Cloud'     'DrawCloudChart'   'Causeway.CloudChartStyles'   (,3 2 1)  (,'nnN') (,¨'X' 'Y' 'Z')                      10000    ('Cloud chart' 'Draw markers on a 3D XYZ space' 'Useful for large XYZ data when point of view can be manually adjusted')
        CHARTS⍪←'Contour'   'DrawContourPlot'  'Causeway.ContourPlotStyles'  (,3 2 1)  (,'nnn') (,¨'X' 'Y' 'Z')                      1000     ('Contour plot' 'Draw 2D projection of XYZ regression surface' 'The best way to visualise trend of XYZ series')
        CHARTS⍪←'Dial'      'DrawDialChart'    'Causeway.DialChartStyles'    (,1)      (,'nn')  (,¨'Values' 'Radii')                 1000     ('Dial chart' 'Draw arrows pointing at values on a semi-circular dial' 'Useful for elaborate display of small series as gauges')
        CHARTS⍪←'Gantt'     'DrawGanttChart'   'Causeway.GanttChartStyles'   (,1 2 3)  (,'nnn') (,¨'Y' 'XStart' 'XEnd')              10000    ('Gantt chart' 'Draw bars, specifying start and end points' 'Useful for time-wise status monitoring')
        CHARTS⍪←'Histogram' 'DrawHistogram'    'Causeway.HistogramStyles'    (,1)      (,'a')   (,¨,⊂'Values')                       1000000  ('Histogram' 'Draw the value distribution of an unordered series' 'Useful to visualise the statistical repartition of mono-variate samples')
        CHARTS⍪←'Line'      'DrawLineGraph'    'Causeway.LineGraphStyles'    (,1)      (,'Nn')  (,¨'Y' 'X')                          10000    ('Line graph' 'Draw connected values on an XY plane' 'Useful for sequential series, typically time series')
        CHARTS⍪←'MinMax'    'DrawMinMaxChart'  'Causeway.MinMaxChartStyles'  (,1 2)    (,'nnn') (,¨'YMax' 'YMin' 'X')                10000    ('Min-Max chart' 'Draw mono-variate ranges on an XY plane' 'Useful for spanned sequential data, typically time series with error bars')
        CHARTS⍪←'Pie'       'DrawPieChart'     'Causeway.PieChartStyles'     (,1)      (,'nn')  (,¨'Values' 'Explode')               1000     ('Pie/Rose chart' 'Draw numeric series as angular portions of a disk' 'Useful for small summary series')
        CHARTS⍪←'Polar'     'DrawPolarChart'   'Causeway.PolarChartStyles'   (,1)      (,'Nn')  (,¨'Y' 'X')                          10000    ('Polar/Radar chart' 'Draw XY series where X is angular' 'Useful for angular data, or arbitrarily-categorised performance comparison')
        CHARTS⍪←'Response'  'DrawResponsePlot' 'Causeway.ResponsePlotStyles' (,1)      (,'Nnn') (,¨'Z' 'X' 'Y')                      1000000  ('Response surface' 'Draw Z surface on a 3D XYZ space' 'Useful for rectangular numerical data, or bi-variate mathematical functions')
        CHARTS⍪←'Scatter'   'DrawScatterPlot'  'Causeway.ScatterPlotStyles'  (,1 2)    (,'Nn')  (,¨'Y' 'X')                          10000    ('Scatter plot' 'Draw markers on an XY plane' 'Useful for discrete XY data')
        CHARTS⍪←'Step'      'DrawStepChart'    'Causeway.StepChartStyles'    (,1)      (,'nn')  (,¨'Y' 'X')                          10000    ('Step chart' 'Draw a constant XY line with discrete changes' 'Useful for sequential data with instantaneous changes')
        CHARTS⍪←'Table'     'DrawTable'        'Causeway.TableStyles'        (,1)      (,'A')   (,¨,⊂'Values')                      ¯1       ('Data Table' 'Draw rows and columns of text'  'Useful for small text summary of series')
        CHARTS⍪←'Tower'     'DrawTowerChart'   'Causeway.TowerChartStyles'   (,1)      (,'N')   (,¨,⊂'Values')                       1000     ('Tower chart' 'Draw a matrix of Z-scaled bars on a 3D XYZ space' 'Useful for small rectangular summary data, if point of view can be manually adjusted')
        CHARTS⍪←'Trace'     'DrawTraceChart'   'Causeway.TraceChartStyles'   (,1)      (,'Nn')  (,¨'Inner' 'X')                      10000    ('Trace chart' 'Draw XY lines alongside' 'Useful to spot sharp changes in a couple of sequential series')
        CHARTS⍪←'TreeMap'   'DrawTreeMap'      'Causeway.TreeMapStyles'      (,1)      (,'nnn') (,¨'Area' 'Depth' 'Altitude')        10000    ('Tree map' 'Draw nested rectangles of specified area (and possibly altitude)' 'Useful for tree-shaped mono- or bi-variate numerical data')
        CHARTS⍪←'Triangle'  'DrawTriangle'     'Causeway.TriangleStyles'     (,1 2 3)  (,'nnn') (,¨'X' 'Y' 'Z')                      10000    ('Triangle plot' 'Represent proportions of 3 variables on a triangle' 'Useful to represent proportions of 3 constituents')
        CHARTS⍪←'Vector'    'DrawVectors'      'Causeway.VectorStyles'       (,2 4 1 3)(,'nnnn')(,¨'X1' 'Y1' 'X2' 'Y2')              10000    ('Vector field' 'Draw XY vectors' 'Useful for data where each item is a XY pair')
        CHARTS⍪←'XBar'      'DrawXBarChart'    'Causeway.XBarChartStyles'    (,1 2)    (,'Nn')  (,¨'Y' 'X')                          10000    ('X-Bar chart' 'Draw bars at specified X positions' 'Useful for discrete sequential data, typically discrete values that occur at particular times')
        ⍝TODO : Venn ?

        ∇ charttypes←GetTypes
          charttypes←CHARTS[;TYPE]~⊂''
        ∇
        ∇ ∆style←GetStyle charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no style' ⋄ :EndIf  ⍝ yet another empty array joke
          ∆style←⊃CHARTS[CHARTS[;TYPE]⍳⊂charttype;STYLE]
        ∇
        ∇ name←GetMethod charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no method' ⋄ :EndIf
          name←⊃CHARTS[CHARTS[;TYPE]⍳⊂charttype;METHOD]
        ∇
        ∇ name←GetLimit charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no limit' ⋄ :EndIf
          name←⊃CHARTS[CHARTS[;TYPE]⍳⊂charttype;LIMIT]
        ∇
        ∇ (types names)←GetSeries charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no series' ⋄ :EndIf
          (types names)←CHARTS[CHARTS[;TYPE]⍳⊂charttype;ARGS SERIES]
        ∇
        ∇ tip←GetTip charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no tip' ⋄ :EndIf
          tip←⊃CHARTS[CHARTS[;TYPE]⍳⊂charttype;DESC]
        ∇
        ∇ desc←GetFormatDescription type
          :Select type
          :Case 'N' ⋄ desc←'multiple numeric vectors'
          :Case 'n' ⋄ desc←'a numeric vector'
          :Case 'A' ⋄ desc←'multiple numeric or strings vectors'
          :Case 'a' ⋄ desc←'a single numeric or strings vector'
          :Else ⋄ Gui.Error'Unknown serie type'
          :EndSelect
        ∇
        ∇ indices←GetDefaultIndices charttype
          indices←⊃CHARTS[CHARTS[;TYPE]⍳⊂charttype;DEF]
        ∇
        ∇ indices←GetIndices charttype
          :If 0∊⍴charttype ⋄ Error'No chart has no series' ⋄ :EndIf
          indices←GetDefaultIndices charttype
          indices∪←⍳⍴2⊃GetSeries charttype
        ∇
        ∇ prop←GetStylesProperty ∆styles
          prop←{¯1↓(⌽∧\⌽⍵≠'.')/⍵}⍕∆styles         ⍝ (Causeway.XXXs) → 'XXXs'
          prop←(-'s'=⊃⌽prop)↓prop                 ⍝ 'XXXs' → 'XXX'
        ∇
        ∇ styles←GetPropertyStyles prop
          styles←'Causeway.',prop,'s'             ⍝ 'XXX' → 'Causeway.XXXs'
        ∇
        ⍝ ∇ styles←GetStyles style                  ⍝ chart styles that have such style
        ⍝   styles←CHARTS[;STYLE]
        ⍝   styles←(2=⌊|⎕NC styles,¨⊂'.',style)/styles
        ⍝ ∇
        ∇ prop←GetStyleProperty ∆style
          :If 0=∆style ⋄ Gui.Error'Empty style doesn''t have a property' ⋄ :EndIf
          prop←GetStylesProperty ∆style.GetType   ⍝ (Causeway.XXXs.YYY) → 'XXX'
        ∇

        ∆WIZARDICON←⎕NULL
        ∇ ∆icon←GetWizardIcon
          :If ∆WIZARDICON≡⎕NULL
              ∆WIZARDICON←⎕NEW'Icon'(⊂'File'(Util.GetDyalogPath,'samples\Causeway\chartwizard16.gif'))
          :EndIf
          ∆icon←∆WIZARDICON
        ∇
        CHARTCBITS←⍬
        ∇ cbits←GetCBits;types;∆icon
          :If 0∊⍴CHARTCBITS
              ∆icon←⎕NEW'Icon'(⊂'File'(Util.GetDyalogPath,'samples\Causeway\charts32.gif'))
              types←'Bar' 'Box' 'Bubble' 'Cloud' 'Contour' 'Dial' 'Gantt' 'Histogram' 'Line' 'MinMax' 'Pie' 'Polar' 'Response' 'Scatter' 'Step' 'Table' 'Tower' 'Trace' 'TreeMap' 'Triangle' 'Vector' 'XBar' 'Wizard'
              cbits←∆icon.CBits ⋄ cbits←((2⊃⍴cbits)⍴32↑1)⊂[2]cbits ⍝ chop icons
              CHARTCBITS←cbits[types⍳GetTypes,⊂'Wizard']  ⍝ reorder to current fashion - use wizard for last one (unknown, empty or invalid charttypes)
          :EndIf
          cbits←CHARTCBITS
        ∇
        ∇ ∆img←GetImageList;path
          ∆img←⎕NEW'ImageList'(('Size'(32 32))('Masked' 0)('MapCols' 0))
          {}∆img.⎕NEW'Bitmap'(⊂'CBits'(⊃,/GetCBits))
        ∇
        ∇ ∆icon←GetIcon charttype;cbits
          cbits←(GetTypes⍳⊂charttype)⊃GetCBits
          ∆icon←⎕NEW'Icon'(('Style' 'Large')('CBits'cbits)('Size'(32 32)))
        ∇

        ∇ ∆sp Print txt;x;y          ⍝ overdraw Causeway.SharpPlot instance with error message
          ∆sp.Reset ⍬
          ∆sp.SetMargins(0 0 0 0) ⋄ ∆sp.Gutter←0 ⋄ ∆sp.DrawFrame
          ∆sp.SetNoteFont'APL385 Unicode' 10 System.Drawing.FontStyle.Regular System.Drawing.Color.Red
          ∆sp.NoteStyle←Causeway.NoteStyles.Absolute
          ∆sp.DrawNote(Util.UnNestText txt)5(¯15+2⊃∆sp.GetPaperSize)  ⍝!!! substract fontsize - drawnote position is bottom-left of first character
        ∇

    :EndNamespace
:EndNamespace
