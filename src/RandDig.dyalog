﻿  RandDig←{
  ⍝ Use entropy from /dev/random to generate a char string representation of a <count>-digit number.
  ⍝     RandDig <count>
  ⍝
      gen←⍺ 
      Cleanup← {0=⎕NC ⍵: ⍬ ⋄ ⎕NUNTIE ⎕OR ⍵}      ⍝ Do nothing unless var. ⍵ is defined...
      _count←0 
      0:: ⎕DMX.(EM ⎕SIGNAL EN)⊣  Cleanup 'randFile' 
      gen.STOP:: 'RandDig complete:', _count,'#s generated' ⊣  Cleanup 'randFile' 
      SIG_NDIGITS← 'nDigits (# of digits requested) must be ≥0 (0=STOP)'  901 

      ⎕IO ⎕PP←0 34
    ⍝ RcvDig: If user sends a new nDig (non-⎕NULL send) as ⍵, validate and return it; 
    ⍝         else return ⍺.
      RcvDig← { ⍵≡⎕NULL: ⍺ ⋄ (0≠⊃0⍴⍵)∨1≠≢⍵: ⎕SIGNAL/SIG_NDIGITS ⋄ ⍵≥0: ⍵ ⋄ ⎕SIGNAL/SIG_NDIGITS  }
      GetDig←{
          fmt←83    ⍝  83: 1-byte integer (we'll map it onto single digits inefficiently)
          bS← 4096  ⍝  ≥1K digits as bytes
          fN nD← ⍺ ⍵
          nD≤ ≢bufG: out⊣ bufG∘← nD↓ bufG⊣ out←nD↑ bufG ⍝ ⊣⍞←'Yielding', nD, 'Digits... '
          bufG,← t← ⎕D[ 10|⎕NREAD fN fmt bS ¯1]
          0= ≢t: 'Unable to retrieve any entropy!'⎕SIGNAL 911
          ⍞←'Received entropy of',(≢t),'dig. '
          fN ∇ nD 
      }
      YieldLoop← { 
          fN nD← ⍺ ⍵ 
          in←gen.Yield fN GetDig nD ⋄ _count+← 1 
          0< nD← nD RcvDig in: fN ∇ nD ⋄ 0
      }

      0= nDig← 50 RcvDig ⍵: ⎕SIGNAL/SIG_NDIGITS
      bufG←''
      randFile← '/dev/random' ⎕NTIE 0

      nDig← randFile YieldLoop nDig  
      _← Cleanup 'randFile' 
      'Done! [FN RETURN]' _count 
  }
