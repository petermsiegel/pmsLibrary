lnsOut← Macros lnsIn
    ; _; badDirI; badDirP; badOptsE; cmI; cmP; copyI; copyP; defI; defP; keysV; lineNum
    ; lnStartI; lnStartP; missingE; myLns; myNm; nc; nmI; nmP; nmP1_t; pats; qtsI; qtsP
    ; undefI; undefP; valsV
    ; BadCpyÊ; BadDirÊ; BadNmÊ; BadValÊ; CR; Canon; Cm; Copy; DEBUG; Exists; Get; Match
    ; ParseArgs; ProcLns; Set; Show; Undef
    ; ⎕IO; ⎕ML

    DEBUG←1
    ⎕IO ⎕ML←0 1
    CR← ⎕UCS 13 
  ⍝ error messages 
    missingE← ⊂('EN' 11)('Message' 'Invalid argument (⍵): Invalid or missing function or op')
    badOptsE← ⊂('EN' 11)('Message' 'Invalid or superfluous option(s) (⍺)')
    BadCpyÊ←  {⊂('EN' 11)('Message' ('::COPY Could not find fn(s)/op(s): ',⍵)) }
    BadNmÊ←   {⊂('EN' 11)('Message' ('Invalid macro name "','"',⍨ ⍵)) }
    BadValÊ←  {⊂('EN' 11)('Message' ('::DEFE failed evaluating expression "','"',⍨ ⍵)) }
    BadDirÊ←  {⊂('EN' 11)('Message' ('Invalid macro directive "','"',⍨ ⍵)) }

    :Trap 0/⍨ ~DEBUG  
      Copy←{
          ~':'∊⍵:'Copy: argument syntax: dir: name1 [name2 [...]]'⎕SIGNAL 11
          dir names←':'(≠⊆⊢)⍵
          dir~← ' ' ⋄ names←' '(≠⊆⊢)names
          ns←⎕NS ⍬
        11:: ⎕SIGNAL BadCpyÊ ⍵
          _←names ns.⎕CY dir 
          ⊃,/ns.(⎕NR¨⎕NL-3 4)
      }
      ParseArgs← {  
        ⍝  Returns: (lines name) rc:
        ⍝         rc is 0, if error, else the nameclass of <name>.
        ⍝ 
          NL← ⎕UCS 13
        0=≢⍵:        (⍬ ⍬) 0
        0/⍨ ~DEBUG:: (⍬ ⍬) 0
        (myLns myNm) nc← { 
            VV2Fn← { ns← ⎕NS ⍬ ⋄ (⍵ myNm ) (ns.⎕NC ⊂,myNm←ns.⎕FX ⍵)  }
            ⍝ Case 1: ⍵ is a name 
            1=≢⊆⍵: {      
              ⍝ Case 1a: ⍵ is a filename prefixed by 'file://'
                p≡⍥⎕C ⍵↑⍨ nP← ≢p←'file://': VV2Fn ⊃⎕NGET (nP↓ ⍵) 1
              ⍝ Case 1b: ⍵ is a function name (simple or prefixed)
                  ((⎕NR ⍵ ) (⌽r↑⍨ '.'⍳⍨ r←⌽⍵)) (ns.⎕NC ⊂,⍵) ⊣ ns← ⊃⎕RSI
            } ⍵  
            ⍝ Case 2: ⍵ is a fn/op body (vector of char vectors, i.e. multi-line)
              VV2Fn ⍵ 
        }⍵ 
        0=≢myLns: (⍬ ⍬) 0   
        3 4(~∊⍨) ⌊nc:  ⎕SIGNAL missingE  
          (myLns myNm) nc 
      }
  
      keysV← ⍬
      valsV← ⍬
    ⍝ Canon: If ⍺=0, ignore invalid non-sys names...
      Canon← { '⎕'=⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }
      Set← {  
          Parens← '('∘,,∘')'
          QTs← {qt←'''' ⋄ (qt∘,,∘qt)⍵/⍨ 1+⍵=qt }
          Eval← {0:: ⎕SIGNAL BadValÊ ⍵ ⋄ ⍕⍎⍵ }
          opts← ⎕C⍺⍺
          ⍺← ⊢
          k v←⍺ ⍵ 
          vC← Parens⍣ ('p'∊ opts)⊢ QTs⍣ ('q'∊ opts)⊢ Eval⍣ ('e'∊ opts)⊢  ⍕v
        (p←keysV⍳ ⊂kC← Canon k) ≥ ≢keysV: keysV,← ⊂kC ⊣ valsV,← ⊂vC
        1: (p⊃ valsV)← vC  
      }
      Undef←{  
          (p← keysV⍳ ⊂kC← Canon ⍵)≥ ≢keysV: 0
          1⊣ keysV⊢← keysV/⍨ q ⊣ valsV⊢← valsV/⍨ q← p≠ ⍳≢keysV 
      }
      Get←    { (p← keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV: p⊃ valsV ⋄ ⍵ }
      Exists← { (   keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV }
      Show←   { ⍬⊣ keysV{ ⎕←((8⌈≢_)↑ _←'"','"',⍨⍺),' → "','"',⍨⍵ }¨valsV }

      Cm← '⍝ '∘,
    ⍝ Regex Patterns
      nmP1_t← '[\pL_∆⍙][\w_∆⍙]*'
      nmP←    '(?<!\.)⎕?',nmP1_t,'(?:\.',nmP1_t,')?(?!\.)' 
      qtsP← '(''[^'']*'')+' 
      cmP← '⍝.*$' 
      defP←    '(?xi) ^\s* :: def ([QEP]*) \s+ (',nmP,') [\s←]+ (.*) $' 
      undefP←  '(?xi) ^\s* :: undef \s+ (',nmP,') .* $'
      copyP←   '(?xi) ^\s* :: copy \s+ ([^:]+:.*) $'
      badDirP← '(?xi) ^\s* :: .*$| :{1} (def|undef|copy) .* $'
      pats←   nmP qtsP cmP defP undefP copyP badDirP
      nmI qtsI cmI defI undefI copyI badDirI← ⍳≢pats
      lineNum←0

      continueP← '(?:\.{2,3}|…)\h*((?:⍝.*)?)\n'   ⍝ 2-3 dots OR ellipses Unicode char.
      pcBufG← ⍬
      ProcCont←qtsP cmP continueP '\n?$' ⎕R {  
        ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
        C 0 1: ∆F 0 ⋄ C 2: ' ' ⊣ pcBufG,← ⊂∆F 1
        (pcBufG⊢← ⍬)⊢ (∊' ',¨ pcBufG), ∆F 0
      }⍠('UCP' 1)('Mode' 'M')('EOL' 'LF')
      ProcLns← ⍬∘{
        Match← pats ⎕R { 
        ⍝ extern: linesG
          ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
          f0← ⍵.Match
          C qtsI cmI: f0 
          C nmI:  Get f0
          ⋄ Sub←  nmP qtsP cmP ⎕R { f0← ⍵.Match ⋄ ⍵.PatternNum= 0: Get f0 ⋄ f0 }  
          C defI: Cm f0⊣ f2 (f1 Set) Sub f3 ⊣ f1 f2 f3← ∆F¨1 2 3 
          C undefI: Cm f0⊣ Undef ∆F 1 
          C copyI:  Cm f0 ⊣ linesG,⍨← Copy ∆F 1
          ⎕SIGNAL BadDirÊ f0
        }⍠('UCP' 1)
        0=≢ ⍵: ⍺  
        curG← ⊃⍵ ⋄ linesG← 1↓⍵ 
        linesG ∇⍨ ⍺,⊂ Match curG
      }

      (myLns myNm) nc← ParseArgs lnsIn
      lnsOut← (1↑myLns), ProcLns ProcCont 1↓myLns

    :Else 
      ⎕SIGNAL ⊂⎕DMX.('EN' 'EM' 'Message',⍥⊆¨EN EM Message)
    :EndTrap