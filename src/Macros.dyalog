lnsOut← Macros lnsIn
    ; _; badDirI; badDirP; badOptsE; cmI; cmP; copyI; copyP; defI; defP; keysV; lineNum
    ; lnStartI; lnStartP; missingE; myLns; myNm; nc; nmI; nmP; nmP1_t; pats; qtsI; qtsP
    ; undefI; undefP; valsV
    ; BadCpyÊ; BadDirÊ; BadNmÊ; BadValÊ; nlC; Canon; Cm; Copy; DEBUG; Exists; Get; Match
    ; ParseArgs; ProcLns; Set; Show; Undef
    ; ⎕IO; ⎕ML

    DEBUG←1
    ⎕IO ⎕ML←0 1
    nlC← ⎕UCS 13 
  ⍝ error messages 
    missingE←  ⊂('EN' 11)('Message' 'Invalid argument (⍵): Invalid or missing function or op')
    badOptsE←  ⊂('EN' 11)('Message' 'Invalid or superfluous option(s) (⍺)')
    BadCpyÊ←  {⊂('EN' 11)('Message' ('::COPY Could not find fn(s)/op(s): ',⍵)) }
    BadNmÊ←   {⊂('EN' 11)('Message' ('Invalid macro name "','"',⍨ ⍵)) }
    BadValÊ←  {⊂('EN' 11)('Message' ('::DEFE failed evaluating expression "','"',⍨ ⍵)) }
    BadDirÊ←  {⊂('EN' 11)('Message' ('Invalid macro directive "','"',⍨ ⍵)) }
    BadFileÊ← {⊂('EN' 11)('Message' ('Invalid/Missing file: ''','''',⍨ ⍵)) }

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
      Include←{ sysDir← './'
         fi← (sysDir/⍨ '<'=⊃⍵), fi← {'<"'∊⍨ ⊃⍵: 1↓¯1↓⍵ ⋄ ⍵}⍵
        0:: ⎕SIGNAL BadFileÊ fi
         ⊃⎕NGET fi 1 
      }
      ParseArgs← {  
        ⍝  Returns: (lines name) rc:
        ⍝         rc is 0, if error, else the nameclass of <name>.
        ⍝ 
          nlC← ⎕UCS 13
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

      ⋄ Cm←  '⍝ '∘,
      ⋄ Dir← '(?xi) ^ \h*  ::'∘,     ⍝ Preamble for directives...
    ⍝ Regex Patterns
      nmP1_t←  '[\pL_∆⍙][\w_∆⍙]*'
      nmP←     '(?<!\.)⎕?',nmP1_t,'(?:\.',nmP1_t,')?(?!\.)' 
      qtsP←    '(''[^'']*'')+' 
      cmP←     '⍝.*$'   ⍝ Order after directives, since they may appear as comments
      defP←    Dir'def ([QEP]*) \h+ (',nmP,') [\h←]+ (.*) $' 
      undefP←  Dir'undef \s+ (',nmP,') .* $'
      copyP←   Dir'copy((?:RAW|RA|R)?) \h+ ([^:]+:.*) $'
      includeP←Dir'include((?:RAW|RA|R)?) \h+ ("[^"]+"|<[^>]+>|[^ ]+) \h* $'
      ifP←     Dir'if(?:ndef|def|) \h+ (.*) $'
      elseIfP← Dir'el(?:se)?if(?:ndef|def|) \h+ (.*) $'
      elseP←   Dir'else \h* ()  $'
      endIfP←  Dir'end(?:if)? \h* () $'
      badDirP← Dir'.*$'
      pats←   nmP qtsP defP undefP copyP includeP ifP elseIfP elseP endIfP badDirP cmP  
              nmI qtsI defI undefI copyI includeI ifI elseIfI elseI endIfI badDirI cmI ← ⍳≢pats
      lineNum←0

      continueP← '(?:\.{2,3}|…)\h*((?:⍝.*)?)\n'   ⍝ 2-3 dots OR ellipses Unicode char.
      pcBufG← ⍬
      ProcCont←qtsP cmP continueP '\n?$' ⎕R {  
        ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
        C 0 1: ∆F 0 ⋄ C 2: ' ' ⊣ pcBufG,← ⊂∆F 1
        (pcBufG⊢← ⍬)⊢ (∊' ',¨ pcBufG), ∆F 0
      }⍠('UCP' 1)('Mode' 'M')('EOL' 'LF')

      condStkG← 1 
      Conditionals←{ f0 f1← ⍵ 
        '⍝ [',(⍕⍺),'] ',f0,' cond: "','"',⍨f1
      }
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
            C copyI:  { f1 f2← ∆F¨1 2 ⋄ lns← Copy f2
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C includeI:  { f1 f2← ∆F¨1 2 ⋄ lns← Include f2 
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C ifI elseIfI elseI endIfI: (⍵.PatternNum-ifI) Conditionals f0 (∆F 1)
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