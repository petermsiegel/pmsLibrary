 arrV←Radix2 arrV                 
    ; IX; aI; base; cntV; i; ixV; lt0; max; outV
    ; place; ⎕IO; ⎕ML

 ⎕IO ⎕ML←0 1
 IX←{base|⍵(⌊÷)place}
 base←256

 max←⌈/|outV←arrV←,arrV
 :For place :In base*⍳⌈base⍟max
     :If place=1 ⋄ cntV←base⍴0 ⋄ :Else ⋄ cntV[]←0 ⋄ :EndIf
     ixV←IX arrV
     :For i :In ixV
         cntV[i]+←1
     :EndFor
     cntV←+\cntV
     :For aI i :InEach ⌽¨arrV ixV
         outV[cntV[i]-1]←aI
         cntV[i]-←1
     :EndFor
     arrV←outV
 :EndFor
 :If 1∊lt0←arrV<0
     arrV←(lt0/arrV),arrV/⍨~lt0
 :EndIf