 (obj lib)←sharpPlot;LIB;defPar;lib;libName;myLib;new;top;wsName
⍝  To use cross-platform SharpPlot from any workspace, all you need to do is:
⍝      obj lib ← sharpPlot
⍝  This does:
⍝      1) Checks for presence of #.__SharpLib
⍝      2) If not present, loads it from workspace SharpPlot.dws into #
⍝      3) Returns: obj lib
⍝         obj: ⎕NEW lib.SharpPlot
⍝         lib: #.__SharpLib     [a ns ref, not a string]
⍝   TO view any created plot, call
⍝      [title] lib.View plot

⍝*** Initialize SharpPlot library                 DEFAULT            TYPE
⍝    wsName   source namespace;                  'sharpplot.dws'    str
⍝    libName  namespace name we will use;        '__SharpLib'       str
⍝    top      namespace ref it's located in.     #                  ns ref
⍝    LIB←     namespace ref for libName          #.__SharpLib       ns ref
 wsName libName top←'sharpplot.dws' '__SharpLib'#
 lib←{wsName libName top←⍵
     0≠top.⎕NC libName:top⍎libName
     wsName{
         _←⍵.⎕CY ⍺
         ⍵.System.Drawing←⍵.System←⍵.Causeway←⍵
         ⍵.View←{1:_←⍺(3500⌶)⍵}
         ⍵
     }⍎libName top.⎕NS''
 }wsName libName top

 obj←⎕NEW lib.SharpPlot

 ⍝ obj.Show: Renders in Svg mode with SvgMode.Stretchable (3)
 {}obj.⎕FX'{me}←Show' 'me←⎕THIS' '{}(3500⌶) RenderSvg 3'

  ⍝⍣§./sharpPlot.dyalog §0 §2019 4 30 22 4 45 396 §eúQÕQ §0
