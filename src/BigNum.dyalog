 ⍝ BigNum class
 ⍝ UNDER DEVELOPMENT. PROTOTYPE ONLY
 
 :Namespace BigNum
 DEBUG←1

⍝   decodeCall: Handle operator name plus monadic vs dyadic plus operands like +⍨. (We treat +⍨⍨ etc. like +⍨)
⍝   fnAtom monadFlag inverseFlag ←  ⍺ ⍺⍺ decodeCall ⍵
⍝          inverseFlag: 0 - no inverse (⍺÷⍵ or +⍵), 1 - regular inverse (⍵+⍺), 2 - selfie ( ⍵ + ⍵)
      decodeCall←{⍺←⊢  
         getOpName←{aa←⍺⍺ ⋄ 3=⎕NC'aa':∊⍕⎕CR 'aa' ⋄ 1 ⎕C aa}   
         decode←{
             atom←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}  
             monad name←⍺ (atom ⍵~'⍨ ')     ⍝ Remove extraneous blanks and inverse ops (+.×~ will be treated the same as +~.×)
             '⍨'∊⍵: name  0      (1+monad) 
                    name  monad  0
         }
         (1≡⍺ 1)decode ⍺⍺ getOpName ⍵
      }

    ⍝ __BN_SOURCE__ is a template for ops BII and BI.
      __BN_SOURCE__←{⍺←⊢
          DEBUG⍴0::⎕SIGNAL/⎕DMX.(EM EN)
          QT←''''
        ⍝ Handle ⍨.   inv ∊ 0 1 2 (0: not inv, 1: inv, s2: elfie)
           fn monad inv←⍺ (⍺⍺ decodeCall) ⍵
        ⍝ CASE←1∘∊(atom fn)∘≡∘⊆¨∘⊆       ⍝ CASE ⍵1 or CASE ⍵1 ⍵2...
          CASE←(atom fn)∘∊∘⊆  

        ⍝ Monadic...
          monad:{                                       ⍝ BI: _EXPORT_: See Build BI/BII below.
            ⍝ math
              CASE'-':_EXPORT_       neg ⍵              ⍝     -⍵
              CASE'+':_EXPORT_       import ⍵           ⍝     canon: ensures ⍵ is valid. Returns in canonical form.
              CASE'|':_EXPORT_       abs ⍵              ⍝     |⍵
              CASE'×':_EXPORT_       ⊃importFast ⍵      ⍝     signum      Returns APL int (∊¯1 0 1), not BII.
              CASE'÷':_EXPORT_       recip ⍵            ⍝     inverse     Why bother? Mostly 0!
            ⍝ Misc
              CASE'<':_EXPORT_       dec ⍵              ⍝     decrement   Optimized for constant in ⍵-1. 
              CASE'≤':_EXPORT_       dec ⍵              ⍝     decrement   I prefer <, but J prefers ≤
              CASE'>':_EXPORT_       inc ⍵              ⍝     increment   Optimized for constant in ⍵+1. I
              CASE'≥':_EXPORT_       inc ⍵              ⍝     increment   I prefer >, but J prefers ≥
              CASE'!':_EXPORT_       fact ⍵             ⍝     factorial   For smallish integers ⍵≥0
              CASE'?':_EXPORT_       roll ⍵             ⍝     roll        For int ⍵>0 (0 invalid: result would always truncate to 0)
              CASE'⍎':               exportApl ⍵        ⍝     aplint      If in range, returns a std APL number; else error               
              CASE'⍕':               prettify exp ∆ ⍵   ⍝     pretty      Returns a pretty BII string: - for ¯, and _ separator every 5 digits.
              CASE'SQRT' '√':_EXPORT_  sqrt ⍵           ⍝     sqrt        See dyadic *0.5
              CASE'⍳':               ⍳importSmallInt ⍵  ⍝     iota ⍵      Allow only small integers... Returns a set of APL integers
              CASE'→':               importFast ⍵       ⍝     internal    Return ⍵ in internal form. 
              CASE'⍟':               log ⍵              ⍝     log         10 log ⍵
            ⍝ Bit manipulation
              CASE'⊥':_EXPORT_       bitsImport ⍵       ⍝     bitsImport  Convert bits to bigint
              CASE'⊤':               bitsExport ⍵       ⍝     bitsExport  Convert bigint ⍵ to bits: sign bit followed by unsigned bit equiv to ⍵
              CASE'~':_EXPORT_       bitsImport ~ bitsExport ⍵  ⍝  Reverses all the bits in a bigint (why?)                                          
              CASE'⎕AT':             getBIAttributes ⍵  ⍝     ⎕AT         <num hands> <num bits> <num 1 bits> 
              err eCANTDO1,QT,QT,⍨fn                    ⍝     Not found.
          }⍵
      ⍝ Dyadic...
        ⍝ See discussion of ⍨ above...
          ⍺{
            ⍝ High Use: [Return BigInt]
              CASE'+':_EXPORT_         ⍺ add ⍵
              CASE'-':_EXPORT_         ⍺ sub ⍵
              CASE'×':_EXPORT_         ⍺ mul ⍵
              CASE'÷':_EXPORT_         ⍺ div ⍵                  ⍝ Integer divide: ⌊⍺÷⍵
              CASE'*':_EXPORT_         ⍺ pow ⍵                  ⍝ Power / Roots I.    num *BI  ÷r
              CASE'*∘÷' '*⊢÷':_EXPORT_ ⍵ root ⍺                 ⍝         Roots II.   num *∘÷BI r
              CASE'√' 'ROOT':_EXPORT_  ⍺ root ⍵                 ⍝         Roots III.  r ('ROOT'BI) num
     
        ⍝ ↑ ↓ Decimal shift (mul, div by 10*⍵)
        ⍝ ⌽   Binary shift  (mul, div by 2*⍵)
              CASE'↑':_EXPORT_        ⍵ mul10Exp ⍺               ⍝  ⍵×10*⍺,   where ±⍺. Decimal shift.
              CASE'↓':_EXPORT_        ⍵ mul10Exp-⍺               ⍝  ⍵×10*-⍺   where ±⍺. Decimal shift right (+) or left (-).
              CASE'⌽':_EXPORT_        ⍵ mul2Exp ⍺                ⍝  ⍵×2*⍺     where ±⍺. Binary shift left (+) or right (-).
              CASE'|':_EXPORT_        ⍺ rem ⍵                    ⍝ remainder: |   (⍺ | ⍵) <==> (⍵ modulo a)
        ⍝ Logical: [Return single boolean, 1∨0]
              CASE'<':                ⍺ lt ⍵
              CASE'≤':                ⍺ le ⍵
              CASE'=':                ⍺ eq ⍵
              CASE'≥':                ⍺ ge ⍵
              CASE'>':                ⍺ gt ⍵
              CASE'≠':                ⍺ ne ⍵     
        ⍝ Other fns
              CASE'⌈':_EXPORT_        (∆⍺){⍺ ge ⍵: ⍺ ⋄ ⍵}∆⍵     ⍝ ⍺ ⌈ ⍵
              CASE'⌊':_EXPORT_        (∆⍺){⍺ le ⍵: ⍺ ⋄ ⍵}∆⍵     ⍝ ⍺ ⌊ ⍵
              CASE'∨' 'GCD':_EXPORT_  ⍺ gcd ⍵                   ⍝ ⍺∨⍵ as gcd.  NOT boolean or.
              CASE'∧' 'LCM':_EXPORT_  ⍺ lcm ⍵                   ⍝ ⍺∧⍵ as lcm.  NOT boolean and.

              CASE '⍟':_EXPORT_       ⍺ log ⍵                   ⍝ ⍺ log ⍵                
     
              CASE'MOD':_EXPORT_      ⍵ rem ⍺                   ⍝ modulo:  Same as |⍨
              CASE'SHIFTB':_EXPORT_   ⍺ mul2Exp ⍵               ⍝ Binary shift:  ⍺×2*⍵,  where ±⍵.   See also ⌽
              CASE'SHIFTD':_EXPORT_   ⍺ mul10Exp ⍵              ⍝ Decimal shift: ⍺×10*⍵, where ±⍵.   See also ↑ and ↓.
              CASE'DIVREM':_EXPORT_   ¨⍺ divRem ⍵               ⍝ Returns pair:  (⌊⍺÷⍵) (⍵|⍺)
              CASE'MODMUL' 'MMUL':_EXPORT_ ⍺ modMul ⍵           ⍝ ⍺ modMul ⍵0 ⍵1 ==> ⍵1 | ⍺ × ⍵0.
              CASE'⍴':               (importSmallInt ⍺)⍴⍵       ⍝ Standard ⍴: Requires ⍺ in ⍺ ⍴ ⍵ to be in range of APL int.
              err eCANTDO2,QT,QT,⍨fn                            ⍝ Not found!
          }{2=inv:⍵ ⍺⍺ ⍵ ⋄ inv:⍵ ⍺⍺ ⍺ ⋄ ⍺ ⍺⍺ ⍵}⍵                ⍝ Handle ⍨.   inv ∊ 0 1 2 (0: not inv, 1: inv, s2: elfie)
      }

      export←{ 
         
       }
      import←{ 
         0=1↑0⍴⍵: ∇⍕⍵
         sign mantissa expSign exponent←'^([¯-]?)([\d\.]+) (?:[eE]([¯-])(\d+))?$' ⎕S '\1\n\2\n\3\n\4\n'⊣⍵
         sign←sign∊'-¯'   
         dp←mantissa⍳'.'
         exponent←expSign{0=≢⍵: '0'  ⋄ (¯1×⍺∊'-¯')×⊃⌽⎕VFI ⍵}exponent
         exponent+←dp
         (sign/'-'),(exponent~'.'),'E',⍕exponent
       }

        ⍝ Build BI/BII.
    ⍝ BI: Change _EXPORT_ to string imp.
    ⍝ BII:  Change _EXPORT_ to null string. Use name BII in place of BI.
      ⎕FX'__BN_SOURCE__' '_EXPORT_¨?'⎕R'BNI' ''      ⊣⎕NR'__BN_SOURCE__'
      ⎕FX'__BN_SOURCE__' '_EXPORT_'  ⎕R 'BN' 'export'⊣⎕NR'__BN_SOURCE__'
      ___←⎕EX '__BN_SOURCE__'



       :Section Bigint Namespace - Postamble
        _namelist_←'BN'
        ___←0 ⎕EXPORT ⎕NL 3 4
        ___←1 ⎕EXPORT {⍵[⍋↑⍵]}{⍵⊆⍨' '≠⍵}  _namelist_
        ⎕PATH←⎕THIS{0=≢⎕PATH:⍕⍺⊣⎕← '⎕PATH was null. Setting to ''',(⍕⍺),''''⋄ ⍵}⎕PATH
        ⎕EX '___'
    :EndSection Bigint Namespace - Postamble
    :EndNamespace