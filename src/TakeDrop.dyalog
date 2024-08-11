(rc out)←TD (offset outRaw inRaw inRows inCols tRows tCols dRows dCols)
  ;keepRows;keepCols;inPtr;outPtr;skip
  ;r;c
  ;MAGIC_OFFSET
  ;⎕IO;⎕ML

⎕IO ⎕ML← 0 1      
MAGIC_OFFSET← 10                     ⍝ I32 (10×4 bytes) 

:IF 0∊ 323= 181⌶¨inRaw outRaw
    ⎕←'outRaw and inRaw must have ⎕DR 323 (I32)'
    rc←11 ⋄ :goto F_A_I_L
:EndIf 
        
:If offset=¯1 
    offset← MAGIC_OFFSET 
:EndIf 

:If tRows<0 ⋄ :OrIf tCols<0 ⋄ :OrIf dRows<0 ⋄ :OrIf dCols<0
    ⎕←'We only allow take and drop of positive offsets'
    rc←911 ⋄ :goto F_A_I_L
:EndIf

inPtr←offset
keepRows keepCols←inRows inCols
:If dRows>0 
  inPtr+← dRows×inCols 
:EndIf
keepRows-← |dRows
:If dCols>0 
  inPtr+← dCols 
:EndIf
keepCols-← |dCols

skip←inCols-tCols

outPtr←offset 

:If tRows>keepRows ⋄ :OrIf tCols>keepCols
    rc←11 ⋄ :Return
:EndIf


:For r :In ⍳tRows
    :For c :In ⍳tCols
        outRaw[outPtr]←inRaw[inPtr]
        outPtr+←inPtr+←1
    :EndFor
    inPtr+←skip
:EndFor

out← tRows tCols⍴ offset↓ outRaw      ⍝ APL only!
rc←0
:Return

F_A_I_L: out←0 0⍴0 

