∆F_DFN←{
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
'help'≡⎕C ⍺: 0⍴⎕←'No help yet'
  (⊃⍺) ((⊃⎕RSI){
    0:: ⎕SIGNAL ⊂⎕DMX.(('EM' ('∆F ',EM))('EN' EN)('Message' Message))
     1=⍺:  ⍺⍺⍎  ⍵   ⍝ Includes original ⍵ as ⍵⍵ 
     0=⍺:       ⍵
    ¯1=⍺:       ⍵
    ¯2=⍺: ⎕SE.Dyalog.Utils.disp ⍪⍵
     ∘∘unreachable∘∘ ⍵⍵ 
  }(⊆⍵))⍺{

  (mo bo) esc←(2↑⍺)(⊃'`',⍨2↓⍺)
  fmtS←⊃⊆⍵
    _chn←     '{⊃,/⍵↑⍨¨⌈/≢¨⍵}⎕FMT¨'       '⍙ⒸⒽⓃ¨' ⊃⍨ mo<0    ⍝ ⍙ⒸⒽⓃ¨ aligns & catenates arrays 
    _box← bo/ '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨' ⊃⍨ mo<0    ⍝ ⍙ⒷⓄⓍ¨ calls dfns.display 
  preCode← _chn, _box, '⌽'                                    
    _ovr← '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄' ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
  rtDefs← '⍙ⓄⓋⓇ←', _ovr '{...}⋄' ⊃⍨ mo<0                     ⍝ runtime defs, if required 

  omCount←0                                                  ⍝ See OmQ
  inclRTD←0

⍝ ␠  '  "  ⋄   ⍝  :   {  }  $   %   ⍵  ⍹
  sp sq dq eos cm cln lb rb fmt ovr om um←' ''"⋄⍝:{}$%⍵⍹'
  nl← ⎕UCS 13                                         ⍝ newline, here: carriage return

  NotA← ⊃⊣⍤(~∊)       
  IsA←  ⊃⊣⍤∊          
  LenLB← {+/∧\' '=⍵}
  SkipTB← { ⍵↓⍨ -+/∧\⌽' '=⍵}
  SkipLB← { ⍵↓⍨  +/∧\ ' '=⍵}
  SkipCm← {   
    cm≠⊃⍵: '' ⍵ 
    cm{
      0=≢⍵: ⍺ ⍵ 
      ⍵ IsA lb rb eos: ⍺ ⍵ 
      ⍵ NotA esc: (⍺, ⊃⍵) ∇ 1↓⍵
        w1← 1↓⍵
      w1 IsA lb rb eos: (⍺, 2↑⍵) ∇ 1↓w1
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
      (⍵ IsA qt)∧w1 IsA qt: (⍺,qt) ∇ 1↓w1
      ⍵ IsA qt:  (Qt2Cod ⍺) (SkipLB w1)
      ⍵ NotA esc:   (⍺, ⊃⍵)  ∇ 1↓⍵
      w1 IsA eos:   (⍺, nl)  ∇ 1↓w1
      w1 IsA esc:   ⍺ (∇ ProcEsc ¯1) 1↓w1  
   ⍝   w1 IsA esc:   (⍺, esc) ∇ 1↓w1
    ⍝ w1 IsA lb rb: (⍺, 2↑⍵) ∇ 1↓w1
        (⍺,⊃⍵)∇ w1 
    }1↓⍵
  }
  Qt2Cod←{ 
      Q← {⍵/⍨ 1+⍵=sq}
      sq sp←''' ' ⋄ useMix←0
      r← ⎕FMT Q ⍵
    1=≢r: sp,sq,(∊r),sq,sp 
    useMix: '(↑',(¯1↓∊sq,¨(SkipTB¨↓r),¨⊂sq sp),')'   
      '(',(sq,sq,⍨∊r),'⍴⍨',(⍕⍴r),')'
  }
  T2Q← sq∘{ ⍺, ⍺,⍨ ⍵/⍨ 1+⍺= ⍵ }  
  ProcEsc← { w1← 1↓⍵
    ⍵ IsA eos:       (⍺, nl            )⍺⍺ w1
    ⍵ IsA esc:       (⍺, ⊃⍵            )⍺⍺ w1
    ⍵ IsA lb rb:     (⍺,(esc/⍨¯1=⍵⍵) ,⊃⍵)⍺⍺ w1 
    1≠⍵⍵:            (⍺, esc, ⊃⍵       )⍺⍺ w1 
    ⍵ NotA om um:    (⍺, esc, ⊃⍵       )⍺⍺ w1 
                     (⍺, '(', o, ')'   )⍺⍺ w ⊣ o w← OmQ w1                   
  } 
  OmQ← {
     dig← ⍵↑⍨+/∧\⍵∊⎕D 
     0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omCount)) (SkipLB ⍵     )  ⊣ omCount+← 1
             ('⍵⊃⍨⎕IO+',(⍕omCount)) (SkipLB ⍵↓⍨≢dig) ⊣ omCount∘← ⊃⌽⎕VFI dig  
  }
 
  TF←{
    0=≢⍵: ''
    tf w← ''{
       0=≢⍵:       ⍺ ⍵
       ⍵ IsA sp:  (⍺, p↑⍵)∇ p↓⍵ ⊣ p← LenLB ⍵
       ⍵ IsA lb:   ⍺ ⍵
       ⍵ IsA esc:  ⍺ (∇ProcEsc 0) 1↓⍵
                  (⍺, ⊃⍵)  ∇ 1↓⍵
    } ⍵
    (Qt2Cod tf) w
  }
  CF←{
     0=≢⍵: '' ⍵ 
     ⍵ NotA lb: '' ⍵
     brks← 0
     r w←''{
        0=≢⍵: ⍺ ⍵                                     ⍝ Terminate
        ⍵ IsA sp: (⍺, 1↑⍵)∇ ⍵↓⍨ p← LenLB ⍵
        ⍵ IsA lb: (⍺, ⊃⍵) ∇ 1↓ ⍵⊣ brks+← 1 
        ⍵ IsA rb: ⍺ ∇{ brks-← 1 ⋄ w1← 1↓⍵
          brks≤0: (⍺, ⊃⍵) w1                          ⍝ Terminate! 
          (⍺, ⊃⍵) ⍺⍺ w1                      
        } ⍵
          w1← 1↓⍵ 
        ⍵ IsA sq dq:   (⍺, q           ) ∇ w⊣ q w← GetQt ⍵
        ⍵ IsA fmt:     (⍺, ' ⎕FMT '    ) ∇ SkipLB w1
        ⍵ IsA ovr:     (⍺, ' ⍙OVR '    ) ∇ SkipLB w1 ⊣ inclRTD∘← 1
        ⍵ IsA um:      (⍺, '(', o, ')' ) ∇ w ⊣ o w← OmQ w1
        ⍵ IsA esc:      ⍺ (∇ProcEsc 1) w1   
        ⍵ IsA cm:       ⍺             ∇ ⊃⌽SkipCm ⍵
                       (⍺, ⊃⍵       ) ∇ w1 
     } SkipLB 1↓⍵
     ('({', r, '⍵)') w 
  }
  SFQ← {  
    ⍵ NotA lb: ⍬
      w←⊃⌽SkipCm ⍵↓⍨1+p← LenLB 1↓⍵
      w1← 1↓w 
    w NotA cln rb: ⍬ 
    isRB← w IsA rb
    isRB∧ 0=p: ('') w1
        sCod← '(''''⍴⍨'
    isRB:  (sCod,(⍕p),')')  w1
        EOS← { ⍵↓⍨1+⍵⍳rb } 
      w1 IsA um om:                   (sCod, o,')') (EOS w)  ⊣ o w← OmQ w1     
     (w1 IsA esc) ∧ (1↓w1) IsA om um: (sCod, o,')') (EOS w)  ⊣ o w← OmQ 2↓w1      
      ok num← ⎕VFI {⍵↑⍨⌊/⍵⍳':}'} w1
    1≢⍥ ,ok: ⍬                                        ⍝ Fail if not exactly 1 valid number
    num=0:   '' (EOS w1)                              ⍝ If 0-length space field, return null.
      (sCod,(⍕num),')')  (EOS w1) 
  }
  Main←{
    0=≢⍵: ⍺ 
    CSF←{
       ×≢sfq←SFQ ⍵: (⍺, ⊂⍣(0≠≢sf)⊢sf ) ⍺⍺ w⊣ sf w← sfq  
                    (⍺, ⊂⍣(0≠≢cf)⊢cf ) ⍺⍺ w⊣ cf w← CF ⍵ 
    }   
    ⍵ IsA lb: ⍺ ∇CSF ⍵   
      tf w← TF ⍵    
      (⍺, ⊂⍣(0≠≢tf)⊢tf) ∇ w    
  }
  code← ⌽⍬ Main fmtS

  pre←   preCode,⍨ rtDefs/⍨ inclRTD 
  1=mo: '{',  pre, (∊code), '}⍵⍵'
  0=mo: '{{', pre, (∊code), '}', (T2Q fmtS),',⊆⍵}'
      (⊂'{{', pre),  code, ⊂'}', (T2Q 50∘Trunc fmtS),',⊆⍵}⍵'
}⍵
}
