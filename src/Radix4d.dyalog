Radix4d←{ 
    ⎕IO ⎕ML←0 1
  ⍝ base: Could be 10, multiples/powers of 256 (1 byte), or even 1+⌈/|arrV (max)
    ⍺← 512 ⋄  base← ⍺
  ⍝ Scan from least to most significant digit: 1 (base*0), base*1, base*2,... base*(nDig-1)
  ⍝ Sort into <base> buckets, updating <dV> after each of <nDig> rounds. 
    nDig← ⌈base⍟ ⌈/|dV← ,⍵
    Ø← { 
      dV⊢← ∊{ ⍵@ ⍺⊣ base⍴⊂⍬ }/ ↓⍉ dV{ ⍺ ⍵ }⌸⍨ base| ⍵ (⌊÷⍨) dV 
      ⍵×base 
    }⍣ nDig⊢ 1
  ⍝ Any negative numbers? One more round for the sign.
    1∊lt0←dV<0: (lt0/ dV), dV/⍨~lt0 ⋄ dV
  }