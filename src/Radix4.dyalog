  dV← {base} Radix4 dV                 
    ; Ø; lt0; nDig; ⎕IO; ⎕ML
  ⎕IO ⎕ML←0 1
⍝ base (# buckets): Could be 10, multiples/powers of 256 (1 byte), or even 1+⌈/|arrV (max)
  :IF 900⌶0 ⋄ base← 512 ⋄ :ENDIF 
⍝ Scan from least to most significant digit: <least=1>, base, base*2, base*(nDig-1)
⍝ Organize into <base> buckets, updating <dV> after each of <nDig> rounds. 
  nDig← ⌈base⍟ ⌈/|dV← ,dV  
  Ø← { 
    dV⊢← ∊{ ⍵@ ⍺⊣ base⍴⊂⍬ }/       ↓⍉dV{ ⍺ ⍵ }⌸⍨ base| ⍵ (⌊÷⍨) dV 
    ⍝     map buckets onto new dV    Place elem of dV for this digit into <base> buckets  
    ⍵×base                         ⍝ Next digit
  }⍣ nDig⊢ 1                       ⍝ Iterate nDig, starting at 1
⍝ Any negative numbers? One more round for the sign.
  :If 1∊lt0←dV<0
    dV← (lt0/ dV), dV/⍨~lt0
  :EndIf