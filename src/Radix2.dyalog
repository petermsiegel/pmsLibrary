 arrV← Radix2 arrV                 
    ; aI; base; c; cntV;  im; lt0; mapV; outV
    ; place; ⎕IO; ⎕ML

 ⎕IO ⎕ML←0 1
 base←256   ⍝ Could be 10, multiples/powers of 256 (1 byte), or even ⌈/|arrV (max)

 outV← arrV← ,arrV
 :For place :In base* ⍳⌈base⍟ ⌈/|arrV    ⍝ Sort only as many places as needed
    ⍝ Map array elements into buckets
      mapV← base| arrV (⌊÷) place 
    ⍝ Calculate cumulative count in each bucket
      im c← ↓⍉{⍺,≢⍵}⌸ mapV                 
      cntV← ¯1+ +\ c@ im⊣ base⍴0
    ⍝ Place output elements in sorted order based on bucket counts
      arrV { outV[cntV[⍵]]← ⍺ ⋄ cntV[⍵]-←1 }¨⍥⌽ mapV
    ⍝ Update arrV
      arrV←outV
 :EndFor
 :If 1∊lt0←arrV<0
     arrV←(lt0/arrV),arrV/⍨~lt0
 :EndIf