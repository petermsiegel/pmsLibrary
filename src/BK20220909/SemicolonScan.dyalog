 SemicolonScan←{
         ⍝ Place  SemicolonScan after DQ/DAQ->SQ processing, macro processing, etc.
         ';'(~∊)∊⍵: ⍵    ⍝ Skip any scanning if we see no semicolons...
         pLBrk pRBrk pLPar pRPar pSemi ←{'\Q',⍵,'\E'}¨'[]();'
         stk←0 ⋄ INPAR INBRK←1 2
         PUSH←{⍺⊣stk,←⍵} ⋄ POP←{⍵⊣stk↓⍨←¯1} ⋄  POPX←{POP⊣ ⍵⊃⍨⊃⌽stk}  ⋄  PEEKX←{⍵⊃⍨⊃⌽stk} 
         pDir←'^\h*::\N*$' ⋄  pEtc← '.' ⍝ pEtc: any char including newline...
         pList← pLBrk pRBrk pLPar pRPar pSemi pDir pSQ pCom  
                iLBrk iRBrk iLPar iRPar iSemi iDir iSQ iCom ←⍳≢pList
         LP0←⎕UCS 0
         res←pList ⎕R {
              CASE←⍵.PatternNum∘∊ ⋄ CASE_iSkip←⍵.PatternNum≥iDir
              m←⍵.Match
              CASE_iSkip: m
              CASE iLBrk: m PU SHINBRK
              CASE iRBrk: POP m
              CASE iLPar: LP0 PUSH INPAR
              CASE iRPar: POPX ')' '))' ')'
            ⍝ Semicolon in brackets:  [pass to APL]
            ⍝ Semicolon in parens:    (a;b;c)  -->  ((a) (b) (c))
            ⍝ Semicolon outside:       a;b;c   -->    a ⋄ b ⋄ c
              CASE iSemi: PEEKX'⋄'  ')('  ';' 
              ○○unreachable○○
         }⍠reOPTS⊣⍵
         '\x00' ⎕R '((' ⊣res
      }