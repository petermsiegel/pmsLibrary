∆F_DFN←{
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
'help'≡⎕C ⍺: 0⍴⎕←'No help yet'
  (⊃⍺) ((⊃⎕RSI){
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' ('∆F ',EM))('EN' EN)('Message' Message))
      1=⍺:  ⍺⍺⍎ ⍵                                            ⍝ ⍵ string includes original ⍵ as ⍵⍵ 
     ¯2=⍺: ⎕SE.Dyalog.Utils.disp ⍪⍵
           ⍵    
      ∘∘unreachable∘∘ ⍵⍵ 
  }(⊆⍵))⍺{
  0:: ⎕SIGNAL ⊂⎕DMX.(('EM' ('∆F ',EM))('EN' EN)('Message' Message))
    (mo bo) esc←(2↑⍺)(⊃'`',⍨2↓⍺)
    fmtS←⊃⊆⍵
      _chn←     '{⊃,/⍵↑⍨¨⌈/≢¨⍵}⎕FMT¨'       '⍙ⒸⒽⓃ¨' ⊃⍨ mo<0    ⍝ ⍙ⒸⒽⓃ¨ aligns & catenates arrays 
      _box← bo/ '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨' ⊃⍨ mo<0    ⍝ ⍙ⒷⓄⓍ¨ calls dfns.display 
    preCode← _chn, _box, '⌽'                                    
      _ovr← '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄' ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
    rtDefs← '⍙ⓄⓋⓇ←', _ovr '{...}⋄' ⊃⍨ mo<0                     ⍝ runtime defs, if required 

    omIx←0                                                     ⍝ See SplitOm
    inclRTD←0

  ⍝ '  "  ⋄   ⍝  :   {  }  $   %   ⍵  ⍹                        ⍝ ⍹: omega underbar                              
    sq dq eos cm cln lb rb fmt ovr om omU← '''"⋄⍝:{}$%⍵⍹'  
    sp← ' '
    nl← ⎕UCS 13                                                ⍝ newline: carriage return [sic!]
    impCF←  sq dq cm cln lb rb fmt ovr om omU esc              ⍝ stuff you need to eval 1 by 1
    impTF←               lb rb                esc    

    NotCase← ⊃⊣⍤(~∊)                                           ⍝ Is (⊃⍺) not in ⍵?
    Case←  ⊃⊣⍤∊                                                ⍝ Is (⊃⍺) in ⍵?  
    LenLB← {+/∧\' '=⍵}
    SkipLB← { ⍵↓⍨  +/∧\ ' '=⍵}
    SkipTB← { ⍵↓⍨ -+/∧\⌽' '=⍵}
    SkipCm← ⊃∘⌽{   
      cm≠⊃⍵: '' ⍵ 
      cm{
        0=≢⍵: ⍺ ⍵ 
        ⍵ Case lb rb eos: ⍺ ⍵ 
        ⍵ NotCase esc: (⍺, ⊃⍵) ∇ 1↓⍵
          w1← 1↓⍵
        w1 Case lb rb eos: (⍺, 2↑⍵) ∇ 1↓w1
          (⍺, ⊃⍵)∇ w1 
      }1↓⍵
    }
    Trunc← { ⍺←50 ⋄ ⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨0⌈⍺-4 } 
    GetQt←{   
      ~sq dq∊⍨⊃⍵: '' ⍵
      qt← ⊃⍵
      ''{
        0=≢⍵: (Qt2Cod ⍺) (SkipLB ⍵ )
          w1← 1↓⍵
        (⍵ Case qt)∧w1 Case qt: (⍺,qt) ∇ 1↓w1
        ⍵ Case qt:     (Qt2Cod ⍺) (SkipLB w1)
        ⍵ NotCase esc: (⍺, ⊃⍵)  ∇ 1↓⍵
        w1 Case eos:   (⍺, nl)  ∇ 1↓w1
        w1 Case esc:  s ⍺ (∇ ProcEsc peQt) 1↓w1   
          (⍺,⊃⍵)∇ w1 
      }1↓⍵
    }
    SplitNot← { 0=p← +/∧\~⍵∊ ⍺: '' ⍵ ⋄ ( p↑⍵ ) (p↓⍵) }
    T2Q← sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }                              ⍝ Text to Quote String 

    Qt2Cod←{ 
        Q← {⍵/⍨ 1+⍵=sq}
        sq sp←''' ' ⋄ useMix←0
        r← ⎕FMT Q ⍵
      1=≢r: sp,sq,(∊r),sq,sp 
      useMix: '(↑',(¯1↓∊sq,¨(SkipTB¨↓r),¨⊂sq sp),')'   
        '(',(sq,sq,⍨∊r),'⍴⍨',(⍕⍴r),')'
    }
    ProcEsc← { w1← 1↓⍵
      ⍵ Case eos:       (⍺, nl         )⍺⍺ w1
      ⍵ Case esc:       (⍺, ⊃⍵         )⍺⍺ w1
      ⍵ Case lb rb:     (⍺, e, ⊃⍵      )⍺⍺ w1 ⊣ e← esc/⍨ peQt=⍵⍵ 
      peCF≠⍵⍵:          (⍺, esc, ⊃⍵    )⍺⍺ w1 
      ⍵ NotCase om omU: (⍺, esc, ⊃⍵    )⍺⍺ w1 
                        (⍺, '(', o, ')')⍺⍺ w  ⊣ o w← SplitOm w1                   
    } ⋄ peQt peTF peCF ← 0 1 2
    SplitOm← {
      dig← ⍵↑⍨+/∧\⍵∊⎕D 
      0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipLB ⍵     )  ⊣ omIx+← 1
              ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipLB ⍵↓⍨≢dig) ⊣ omIx⊢← ⊃⌽⎕VFI dig  
    }
  ⍝ Major Fns 
    TF←{
      0=≢⍵: ''
      tf w← ''{
        0=≢⍵:       ⍺ ⍵
        ×≢⊃t w← impTF SplitNot ⍵: (⍺, t) ∇ w                  ⍝ Fast skip of "unimportant" chars!
        ⍵ Case sp:  (⍺, p↑⍵)∇ p↓⍵ ⊣ p← LenLB ⍵
        ⍵ Case lb:   ⍺ ⍵
        ⍵ Case esc:  ⍺ (∇ ProcEsc peTF) 1↓⍵   
                    (⍺, ⊃⍵)  ∇ 1↓⍵
      } ⍵
      (Qt2Cod tf) w
    }
    CF←{
      0=≢⍵: '' ⍵ 
      ⍵ NotCase lb: '' ⍵
      brks← 0
      r w←''{
          0=≢⍵: ⍺ ⍵                                            ⍝ Terminate
          ×≢⊃t w← impCF SplitNot ⍵: (⍺, t) ∇ w                 ⍝ Fast skip of "unimportant" chars!
          ⍵ Case sp: (⍺, 1↑⍵)∇ ⍵↓⍨ p← LenLB ⍵
          ⍵ Case lb: (⍺, ⊃⍵) ∇ 1↓ ⍵⊣ brks+← 1 
          ⍵ Case rb: ⍺ ∇{ brks-← 1 ⋄ w1← 1↓⍵
            brks≤0: (⍺, ⊃⍵) w1                                 ⍝ Terminate! 
            (⍺, ⊃⍵) ⍺⍺ w1                      
          } ⍵
            w1← 1↓⍵ 
          ⍵ Case sq dq:   (⍺, q           ) ∇ w⊣ q w← GetQt ⍵
          ⍵ Case fmt:     (⍺, ' ⎕FMT '    ) ∇ SkipLB w1
          ⍵ Case ovr:     (⍺, ' ⍙ⓄⓋⓇ '    ) ∇ SkipLB w1 ⊣ inclRTD∘← 1
          ⍵ Case omU:      (⍺, '(', o, ')' )∇ w ⊣ o w← SplitOm w1
          ⍵ Case esc:      ⍺ (∇ ProcEsc peCF) w1    
          ⍵ Case cm:       ⍺                ∇ SkipCm ⍵
                        (⍺, ⊃⍵          )  ∇ w1 
      } SkipLB 1↓⍵
      ('({', r, '⍵)') w 
    }
    SplitSF← {  
      ⍵ NotCase lb: 11 ⎕SIGNAL⍨ 'Logic error!' ⍝ 0 '' ⍵
        w← SkipCm ⍵↓⍨1+p← LenLB 1↓⍵
        w1← 1↓w 
      w NotCase cln rb: 0 '' ⍵ 
      isRB← w Case rb
      isRB∧ 0=p: 1 '' w1  
          sCod← '(''''⍴⍨'
      isRB:  1 (sCod,(⍕p),')')  w1
          EOS← { ⍵↓⍨1+⍵⍳rb } 
        w1 Case omU om:                   1 (sCod, o,')') (EOS w)  ⊣ o w← SplitOm w1     
      (w1 Case esc) ∧ (1↓w1) Case om omU: 1 (sCod, o,')') (EOS w)  ⊣ o w← SplitOm 2↓w1      
        ok num← ⎕VFI {⍵↑⍨⌊/⍵⍳':}'} w1
      1≢⍥, ok: 0 '' ⍵                                            ⍝ Fail if not exactly 1 valid number
      num=0:   1 '' (EOS w1)                                     ⍝ If 0-length space field, field is null.
        1 (sCod,(⍕num),')')  (EOS w1) 
    }

    Main←{
      0=≢⍵: ⍺  
      ⍵ NotCase lb: w ∇⍨ ⍺, ⊂⍣(×≢tf)⊢ tf ⊣tf w← TF ⍵ 
        isSF sf w←SplitSF ⍵
      isSF: w ∇⍨ ⍺, ⊂⍣(×≢sf)⊢sf 
        cf w← CF ⍵ 
        w ∇⍨ ⍺, ⊂⍣(×≢cf)⊢cf 
    }
    code← ⌽⍬ Main fmtS

    pre←   preCode,⍨ rtDefs/⍨ inclRTD 
    1=mo: '{',  pre, (∊code), '}⍵⍵'
    0=mo: '{{', pre, (∊code), '}', (T2Q fmtS),',⊆⍵}'
        (⊂'{{', pre),  code, ⊂'}', (T2Q 25∘Trunc fmtS),',⊆⍵}⍵'
  }⍵
}
