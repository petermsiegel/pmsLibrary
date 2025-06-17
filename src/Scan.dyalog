 Scan←{
     sp dq sq esc lb rb om omu ra da pct←' "''`{}⍵⍹→↓%'  
     sep←'⋄'
     nl← ⎕UCS 10
     TFSpecial← ⌊/⍳∘(esc, lb)
     CFSpecial← ⌊/⍳∘(sp, dq, sq, esc, lb, rb, om, omu, ra, da, pct)
     Qt← { 0=≢⍵: ⍬ ⋄ ⍬⊣ flds,← ⊂sq, sq,⍨ ⍵/⍨ 1+sq=⍵ }

     TF←{ 
         0=≢⍵: Qt ⍺
         p←TFSpecial ⍵
         p=≢⍵: Qt ⍺, ⍵ 
         type←p⌷⍵
         pfx←p↑⍵
         type=esc:(⍺,pfx,TFEsc ⍵↓⍨ p+1)∇ ⍵↓⍨p+2
         type=lb: CF ⍵↓⍨ p ⊣ Qt ⍺, pfx 
         ∘∘∘Logic Error (Unreachable)∘∘∘⊣ ⎕← '⍺' ⍺ ⊣ ⎕← '⍵' ⍵ 
     }
     TFEsc←{  
         0=≢⍵:esc ⋄ ch← 0⌷⍵
         ch= sep: nl 
         ch∊ esc, lb, rb: 0⌷⍵
         esc, ch 
     }
    TrimL← { ⍵↓⍨  +/∧\ ⍵= sp}
    TrimR← { ⍵↓⍨ -+/∧\⌽⍵= sp}
    TrimR1← { p←  +/∧\⌽⍵= sp ⋄ 0=p: ⍵ ⋄ ⍵↓⍨ 1-p}
    CFEsc←{  
      0=≢⍵:esc ⋄ ch← 0⌷⍵ ⋄ w← 1↓⍵ 
      ch= om: Omg w 
      ch∊ 'BOF': ch {
        fn← 'Box' 'Over' '⎕FMT'⊃⍨ 'BO'⍳ ⍺ 
        (' ', fn, ' '/⍨ ' '≠⊃⍵) ⍵ 
      } w 
      ch= sep: nl w 
      ch∊ esc, lb, rb: (0⌷⍵) w 
          (esc, ch) w  
    }
    QSEsc←{
      ch← ⍵  
      ch= sep: nl 
      esc,⍵
    }
    SF← { ⍝ sfFlag pfx sfx
      rb= ⊃⍵: 1 '' (1↓⍵)                 ⍝ Null SF:     {}
      sp≠ ⊃⍵: 0 '' ⍵                     ⍝ Not a SF:    {code...}
        p← +/∧\ ⍵= sp 
      rb≠ ⊃p↓ ⍵: 0 ('') (p↓⍵)            ⍝ Not a SF:    { sp sp code...}
        flds,← ⊂'(','⍴'''')',⍨ ⍕p        ⍝ Non-null SF: { }, etc.
        1 '' (⍵↓⍨ 1+p)  
    }
    Int←{ wid← +/∧\⍵∊⎕D
      0= wid: 0 0 ⍵ ⋄ 1 (⊃⊃⌽⎕VFI wid↑⍵) (wid↓⍵)  
    }
    omgCnt←0 
    Omg← {
      b i w← Int ⍵ 
      b: ('(⍵⍴⍨', ,')',⍨ '⎕IO+',⍕omgCnt⊢← i) w  
         ('(⍵⍴⍨', ,')',⍨ '⎕IO+',⍕omgCnt⊢← omgCnt+ 1) w  
    }
    QS← { ⍝ ∇ str_starting_w_qt.  
      qt← ⊃⍵  
      wL← ¯2+ ≢⍵
      qS← ''{
        0=≢⍵: ⍺ 
          p← ⌊/⍵⍳ qt,esc 
        p= ≢⍵: 11 ⎕SIGNAL⍨ '∆F No closing quote on code field string'
        esc= p⌷⍵: (⍺, (⍵↑⍨ p), ⎕←QSEsc ⎕←⊃⍵↓⍨ p+1) ∇ ⍵↓⍨ wL-← p+2 
       ⍝ Use APL rules for ".."".."
        qt= ⊃⍵↓⍨ p+1: (⍺, ⍵↑⍨ p+1) ∇ ⍵↓⍨ wL-← p+2  
          ⍺, ⍵↑⍨ wL-← p 
      } 1↓⍵
      qS (⍵↑⍨ -wL)
    }
    CF←{  
      nBr ←1 ⋄ isSF a w← SF 1↓⍵ 
      isSF: a TF w 
      a w← a{
        0= ≢⍵: ⍺ ⍵
          p←CFSpecial ⍵
        p=≢⍵: 11 ⎕SIGNAL⍨ '∆F: Closing brace "}" is missing'
          pfx ch w← (⍺, p↑⍵) (p⌷⍵)  (⍵↓⍨ p+1 )  
        ch=sp: (pfx, ch) ∇ TrimL w  
        ch∊ sq,dq: (pfx,sq, sq,⍨ a/⍨ 1+a=sq) ∇ w ⊣ a w← QS ch,w 
        ch=esc: (pfx, eStr ) ∇ w⊣ eStr w← CFEsc w
        ch=lb: (pfx, ch) ∇ w ⊣ nBr+← 1
        (ch=rb)∧ nBr>1: (pfx, ch) ∇ w ⊣ nBr-← 1 
        ch=omu: (pfx, cod) ∇ w⊣  cod w← Omg w
        ch∊'→↓%': pfx{
            p← +/∧\⍵= sp 
          rb≠ p⌷⍵: ⍺ CF ⍵ 
          nBr>1: ⍺ CF ⍵ 
            rawS← sq,sq,⍨'???' 
            flds,← ⊂'(', lb, rawS, ' OVER ', ⍺, rb, '⍵)' 
            '' ('' TF ⍵↓⍨ p+1)
        } w  
        ch=rb: (TrimR pfx) w   
          (pfx, ch) ∇ w 
      } w
      0=≢a: '' TF w
      '' TF w⊣ flds,← ⊂'(', lb, a, rb, '⍵)'  
    }

    flds←⍬
    flds⊣ '' TF ⍵
 }
