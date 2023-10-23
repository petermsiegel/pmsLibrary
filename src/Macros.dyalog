outputLines← Macros input
    ; _; badOptsE; keysV; missingE; myLns; myNm; nc; valsV
    ; BadValE; Canon; DEBUG; Exists; Get; Match; ParseArgs; Set; Show; Undef
    ; ⎕IO; ⎕ML

    DEBUG←1
    ⎕IO ⎕ML←0 1
  ⍝ error messages 
    missingE← ⊂('EN' 11)('Message' 'Invalid or missing function or op')
    badOptsE← ⊂('EN' 11)('Message' 'Invalid or superfluous option(s)')
    BadNmÊ←   {⊂('EN' 11)('Message' ('Invalid macro name "','"',⍨ ⍵)) }
    BadValE←  {⊂('EN' 11)('Message' ('::DEFE failed evaluating expression "','"',⍨ ⍵)) }
    BadDirÊ←  {⊂('EN' 11)('Message' ('Invalid macro directive "','"',⍨ ⍵)) }

    :Trap 0 
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
          (myLns myNm) nc 
      }
  
      keysV← ⍬
        valsV← ⍬
      ⍝ Canon: If ⍺=0, ignore invalid non-sys names...
        Canon← { '⎕'=⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }
        Set← {  
            Parens← '('∘,,∘')'
            QTs← {qt←'''' ⋄ (qt∘,,∘qt)⍵/⍨ 1+⍵=qt }
            Eval← {0:: ⎕SIGNAL BadValE ⍵ ⋄ ⍕⍎⍵ }
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
      ⍝ For testing only
        _← 'fred' 'jack' '⎕io'  'florentine' (''Set)¨'<FRED>' (?0) 3 (⎕TS)
        _← 'florentine' ('PE'Set) '⎕ts'
        ⍝ _← Show ⍬

      Match←{
        nmP1_t← '[\pL_∆⍙][\w_∆⍙]*'
        nmP←    '(?<!\.)⎕?',nmP1_t,'(?:\.',nmP1_t,')?(?!\.)' 
        qtsP← '(''[^'']*'')+' 
        cmP← '⍝.*$' 
        defP←    '(?xi) ^ :{1,2} def ([QEP]*) \s+ (',nmP,') [\s←]+ (.*) $' 
        undefP←  '(?xi) ^ :{1,2} undef \s+ (',nmP,') .* $'
        badDirP← '(?xi) ^ :{2} .*$| :{1} (def|undef) .* $'
        pats←  nmP qtsP cmP defP undefP badDirP
        nmI qtsI cmI defI undefI badDirI← ⍳≢pats
        pats ⎕R { 
          ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
          C←  ⍵.PatternNum∘∊
          f0← ⍵.Match
          C qtsI cmI: f0 
          C nmI:    Get f0
          Sub←  nmP qtsP cmP ⎕R { f0← ⍵.Match ⋄ ⍵.PatternNum= 0: Get f0 ⋄ f0 }  
          C defI: '⍝ ',f0⊣ f2 (f1 Set) Sub f3 ⊣ f1 f2 f3← ∆F¨1 2 3 
          C undefI: '⍝ ',f0⊣ Undef ∆F 1 
          ⎕SIGNAL BadDirÊ f0
        }⍠('UCP' 1)⊣ ⊆⍵
      }

      (myLns myNm) nc← ParseArgs input
      :IF nc (~∊) 3.1 3.2 4.1 4.2  ⋄ ⎕SIGNAL missingE ⋄ :ENDIF
      outputLines← (⊂⊃myLns), Match 1↓myLns

    :Else 
      ⎕SIGNAL ⊂⎕DMX.('EN' 'EM' 'Message',⍥⊆¨EN EM Message)
    :EndTrap