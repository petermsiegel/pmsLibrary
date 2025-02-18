    :namespace ⍙F 
        ⎕IO ⎕ML← 0 1

        ∇ r← LOAD 
        ⍝ Load C F-string routines (two versions: ∆F2 for 2-byte chars and ∆F4 for 4-byte chars)
        ⍝ At 16 (/32) bits, the <#C2 and >#C2 ⎕NA format allows strings up to humongous 64K (/2*32) bytes.
          '∆F4' ⎕NA 'I4 ∆F/∆F.dylib|fs_format4 <{C4 U1[5]} <#C4[] >#C4[] I4' 
          '∆F2' ⎕NA 'I4 ∆F/∆F.dylib|fs_format2 <{C4 U1[5]} <#C2[] >#C2[] I4'
          'Canon' ⎕NA '∆F/∆F.dylib|canon =#C4[] C4'       ⍝ Canon str escCh
          r←⍬
        ∇ 
        LOAD 

      ⍝ Load the UCS-2 source code for the run-time library routines from ∆F.dylib: A, B, D, M
        A←{⍺←0⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}
        B←{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}
        D←0∘⎕SE.Dyalog.Utils.disp¯1∘↓
        M←{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}

        ⍝ Options: Principle is dfn (option 1), where a single digit is presented as the left arg to ∆F. 
        keys← ⎕C 'escCh' 'dfn' 'debug' 'box' 'useNs' 'lib'  'bufSize'  
        vals←    '`'      0     0       0     0       1      1024 
        princ←            1 
      ⍝ Evaluate internal and CallF_C options (⍺). Options are in the style of Dyalog ⍠ (variant) options.
        EvalOpts← { 
          0=≢⍵:  vals                           ⍝ Fastest: all default options
          0:: 'Invalid option(s)' ⎕SIGNAL 11   
          0≡⊃0⍴⍵: ⍵@princ⊢ vals                 ⍝ Fast: only principle option is set (via a single integer)
            nK nV← ↓⍉↑ ,∘⊂⍣(2= |≡⍵)⊢ ⍵          
            nV@(keys⍳ ⎕C nK)⊣ vals              ⍝ Slower: all options are set by key-value pairs
        }
        CallF_C← {  
            res2← (⊃⍵⍵) { ⍺: ∆F4 ⍵ ⋄ ∆F2 ⍵}  ⍺⍺, ⍵ ⍵                 
          ¯1≠⊃res2: res2, ⍵                      ⍝ Success. return result: rc, code_buffer  
          ⍺≤0:      res2, ⍵                      ⍝ If we've tried too many times, return (with error code) as is.
            newSize← 1024⌈(⊃⌽⍵⍵)× ⍵              ⍝ Increase the storage estimate and retry...
            _← ⍺⍺{0 2⊃⍺: ⎕←⍵ ⋄ ⍵ } 'Retrying ∆F with bufSize',newSize,' Was',⍵ 
            (⍺-1) ∇ newSize  
        } 
      ⍝ Failure: buffer too small
        ErrorSpace← ⎕SIGNAL/ {⌽911,⍥⊂'RUNTIME ERROR: Formatting buffer too small (size: ',(⍕⍵),' elements)'} 
    :EndNamespace 