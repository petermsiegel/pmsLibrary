∆F_DFN←{
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
  'help'≡⎕C ⍺: 0⍴⎕←'No help yet'

  (mo bo) esc←(2↑⍺)(⊃'`',⍨2↓⍺)
  fmtS←⍵
  omCount←0 
⍝ ␠  '  "  ⋄   ⍝  :   {  }  $   %
  sp sq dq eos cm cln lb rb fmt ovr om um←' ''"⋄⍝:{}$%⍵⍹'
  nl← ⎕UCS 13                                         ⍝ newline, here: carriage return

  NotA← { ⍵(~∊)⍨⊃⍺}
  IsA←  { ⍵ ∊⍨  ⊃⍺}
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
  GetQt←{   
    sp sq dq eos cm cln lb rb fmt←' ''"⋄⍝:{}$'
    ~sq dq∊⍨⊃⍵: '' ⍵
    qt← ⊃⍵
    ''{
      0=≢⍵: (Qt2Cod ⍺) (SkipLB ⍵ )
        w1← 1↓⍵
      (⍵ IsA qt)∧w1 IsA qt: (⍺,qt) ∇ 1↓w1
      ⍵ IsA qt:  (Qt2Cod ⍺) (SkipLB w1)
      ⍵ NotA esc: (⍺, ⊃⍵) ∇ 1↓⍵
      w1 IsA eos:   (⍺, nl) ∇ 1↓w1
      w1 IsA esc:   (⍺, ⊃⍵) ∇ 1↓w1
    ⍝ w1 IsA lb rb: (⍺, 2↑⍵) ∇ 1↓w1
        (⍺,⊃⍵)∇ w1 
    }1↓⍵
  }
  Qt2Cod←{ 
      Q← {⍵/⍨ 1+⍵=sq}
      sq sp←''' ' ⋄ useMix←1
      r← ⎕FMT Q ⍵
    1=≢r: sp,sq,(∊r),sq,sp 
    useMix: '(↑',(¯1↓∊sq,¨(SkipTB¨↓r),¨⊂sq sp),')'   
      '(',(sq,sq,⍨∊r),'⍴⍨',(⍕⍴r),')'
  }
  ProcEsc← { w1← 1↓⍵
    ⍵ IsA eos:       (⍺, nl          )⍺⍺ w1
    ⍵ IsA lb rb esc: (⍺, ⊃⍵          )⍺⍺ w1
    ~⍵⍵:             (⍺, esc, ⊃⍵     )⍺⍺ w1 
    ⍵ IsA om um:     (⍺, '(', o, ')' )⍺⍺ w ⊣ o w← OmQ w1
                     (⍺, esc, ⊃⍵ )⍺⍺ w1 
  } 
  OmQ← {
     dig← ⍵↑⍨+/∧\⍵∊⎕D 
     0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omCount)) (SkipLB ⍵)        ⊣ omCount+← 1
             ('⍵⊃⍨⎕IO+',(⍕omCount))(SkipLB ⍵↓⍨≢dig) ⊣ omCount∘← ⊃⌽⎕VFI dig  
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
        ⍵ IsA ovr:     (⍺, ' ⍙OVR '    ) ∇ SkipLB w1
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
      w1 IsA um:                      (sCod, o,')') (EOS w)  ⊣ o w← OmQ w1     
     (w1 IsA esc) ∧ (1↓w1) IsA om um: (sCod, o,')') (EOS w)  ⊣ o w← OmQ 2↓w1      
      ok num← ⎕VFI {⍵↑⍨⌊/⍵⍳':}'} w1
    1≢⍥ ,ok: ⍬                                        ⍝ Fail if not exactly 1 valid number
      (sCod,(⍕num),')')  (EOS w1) 
  }
  Main←{
    0=≢⍵: ⍺ 
    CSF←{
       ×≢sfq←SFQ ⍵: (⍺, ⊂⍣(0≠≢sf)⊢sf ) ⍺⍺ w⊣ sf w← sfq  
                    (⍺, ⊂⍣(0≠≢cf)⊢cf ) ⍺⍺ w⊣ cf w← CF ⍵ 
    }   
    ⍵ IsA lb: ⍺          ∇CSF ⍵   
    tf w← TF ⍵    
             (⍺, ⊂⍣(0≠≢tf)⊢tf) ∇ w    
  }
  ⍬ Main fmtS
}
