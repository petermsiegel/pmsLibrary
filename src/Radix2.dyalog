  arrV← {base} Radix2 arrV                 
    ; aI; base; cntV;  f; ix; lt0; mapV; outV; place
    ; ⎕IO; ⎕ML

  ⎕IO ⎕ML←0 1
⍝ base: Could be 10, multiples/powers of 256 (1 byte), or even 1+⌈/|arrV (max)
  :IF 900⌶0 ⋄ base← 512 ⋄ :ENDIF 
    
  outV← arrV← ,arrV
  :For place :In ,base* ⍳⌈base⍟ ⌈/|arrV    ⍝ Sort only as many places as needed
    ⍝ Map array elements into buckets by (the current) base
      mapV← base| arrV (⌊÷) place 
    ⍝ Calculate count frequencies (f) across buckets, accumulating left to right
      cntV← ¯1+ +\ f@ ix⊣ base⍴0 ⊣ ix f← ↓⍉{⍺,≢⍵}⌸ mapV               
    ⍝ Put output elements in sorted order, building right to left  
      arrV {outV[ cntV[⍵] ]← ⍺ ⋄ cntV[⍵]-←1 }¨⍥⌽ mapV
    ⍝ Update arrV
      arrV←outV
  :EndFor
⍝ Any negative numbers? One more round for the sign.
  :If 1∊lt0←arrV<0
    arrV←(lt0/arrV),arrV/⍨~lt0
  :EndIf