  dV← {base} Radix4 dV                 
    ; _; lt0; dig; nDig; Scan; ⎕IO; ⎕ML
  ⎕IO ⎕ML←0 1
⍝ base: Could be 10, multiples/powers of 256 (1 byte), or even 1+⌈/|arrV (max)
  :IF 900⌶0 ⋄ base← 512 ⋄ :ENDIF 
⍝ Scan from least to most significant digit (1s dig, <base> dig, <base*2> dig, etc.)
 ⍝ :For dig :In base* ⍳⌈base⍟ ⌈/|dV← ,dV    
 ⍝ Sort into <base> buckets, update dV, then to next digit  
   nDig← ⌈base⍟ ⌈/|dV← ,dV
   Scan← { dig←⍵
        dV⊢← ∊{ ⍵@ ⍺⊣ base⍴⊂⍬ }/ ↓⍉ dV{ ⍺ ⍵ }⌸⍨ base| dig (⌊÷⍨) dV
        dig×base
  }
   _← Scan⍣nDig ⊢1
⍝ Any negative numbers? One more round for the sign.
  :If 1∊lt0←dV<0
    dV←(lt0/dV),dV/⍨~lt0
  :EndIf