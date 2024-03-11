∆F←{
⍝H 
⍝H ∆F: Very simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝H     [opts] ∆F fmt_str

⍝H ⍺ OPTIONS:   modeO boxO escO 
⍝H   modeO←1   generate and execute
⍝H   boxO←0    [NOT IMPLEMENTED. Leave at 0] don't box each item 
⍝H   escO←'`'  escape char
⍝H *** NO OTHER HELP AVAILABLE ***

  ⍺←1 0 '`'
⍝ Fast Path: Make this ∆F call a nop? 
  0=≢⍺: 1 0⍴''                                                 
 'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
  0/ 0 1003:: ⎕SIGNAL ⊂⎕DMX.(('EM',⍥⊂'∆F ',EM)('Message' Message),⊂'EN',⍥⊂ EN 999⊃⍨1000≤EN)

⍝ ---------------------------
  (⊃⍺) ((⊃⎕RSI){ 
⍝ STAGE II: Execute/Display code from Stage I
        ⍙ⓄⓋⓇ← {⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵} 
        ⍙ⒸⒽⓃ← {⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵}
      1=⍺: ⍙ⒸⒽⓃ ⌽⊆ ⍺⍺⍎'{', (∊⌽⊃⌽⍵), '}⍵⍵' 
        pre← '⍙ⒸⒽⓃ←{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵}⋄' 
        pre,← (⊃⍵)/ '⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄' 
        Enqt← { s,s,⍨ ⍵/⍨ 1+⍵=s←''''}
      0=⍺: ∊'{{',pre,'⍙ⒸⒽⓃ ',(∊⌽⊃⌽⍵),'}',(Enqt⊃⍵⍵),',⍥⊆⍵}'
     ¯1=⍺: ⊃⌽⍵ 
     ¯2=⍺: ⎕SE.Dyalog.Utils.disp⍪ ⊃⌽⍵ 
        ⍵⍵⊣ ⎕SIGNAL/ 'LOGIC ERROR' 911   ⍝ ⍵⍵: Enable ⍵⍵, used in case (1=⍺) above.
⍝ ---------------------------
  }(,⊆⍵))⍺{                                                     ⍝ ⊆⍵: original f-string
⍝ STAGE I: Analyse fmt string, pass code equivalent to Stage II above to execute or display
⍝ --------------------------- 
⍝ CONSTANTS     
⍝               
    ⎕io ⎕ml←0 1                  
  ⍝ ...Ê: Error messages/dfn. See Ê below.
    opt0Ê← ('Message' 'Invalid option (mode)')       ('EN' 11) 
    opt1Ê← ('Message' 'Invalid option (box)')        ('EN' 11) 
    opt2Ê← ('Message' 'Invalid option (escape char)')('EN' 11) 
    fStrÊ← ('Message' 'Invalid right arg (f-string)')('EN' 11) 
    qStrÊ← ('Message' 'No closing quote found for string')('EN' 11)
    brcÊ←  ('Message' 'No closing brace "}" found for code field')('EN' 11)
    logÊ←  ('EM'      'LOGIC ERROR: UNREACHABLE')    ('EN' 99) 
      
  ⍝ ...Cod:  Two choices presented: Actual code (if modO≥0) and pseudo-code (otherwise).
  ⍝ ..C: Constants.
  ⍝ ␠   '   "   ⋄     ⍝  :                                     ⍝1 Constants. See also escO option.
    spC sqC dqC eosC cmC clnC← ' ''"⋄⍝:'                     
  ⍝ {   }   $    %    ↓   ⍵   ⍹    →                           ⍝2 Constants.
    lbC rbC fmtC ovrC dnC omC omUC raC← '{}$%↓⍵⍹→'                  
    nlC← ⎕UCS 13                                               ⍝3 newline: carriage return [sic!]
    sdArrows← '▶' '▼'                                          ⍝4 for self-documenting strings
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"    
    NSpan← { ⍺←spC ⋄ +/∧\⍵∊ ⍺}                                 ⍝ How many leading <⍺←spC> in ⍵?
    EnQt← { sqC,sqC,⍨ ⍵/⍨ 1+ sqC= ⍵ }                          ⍝ Put str in quotes by APL rules
⍝ 
    _ScanEsc_← { ch← ⊃⍵  
        eosC= ch: ⍺⍺ 1↓⍵ ⊣ F_Cat nlC  
        escO lbC rbC∊⍨ ch: ⍺⍺ 1↓⍵⊣ F_Cat ch  
        ⍵⍵∧ omC omUC∊⍨ ch:⍺⍺ _Omega 1↓⍵ 
          ⍺⍺ 1↓⍵⊣ F_Cat escO, ch  
      0: ⍵⍵ 
    }
  ⍝ _Omega:   _Next _Omega ⍵ 
    _Omega←{ wx← '⍵⌷⍨⎕IO+'
        nDig← ⎕D NSpan ⍵
      0<nDig: ⍺⍺ nDig↓⍵⊣ F_Cat '(',wx,pW,')'⊣ omCtr⊢← ⊃⌽⎕VFI pW← nDig↑⍵
        omCtr+← 1 ⋄ ⍺⍺ ⍵⊣ F_Cat '(',wx,')',⍨ ⍕omCtr        
    }
  ⍝ F_: Managing output flds
    F_Cat← { ⍺←⍵ ⋄ fld_lit fld ,← ⍺ ⍵ ⋄ ⍬  }
    F_Done←{
        ⍺←1
        CondQtsE← {
          ~⍺: ∊⍵
            lns← ∊' ',⍨¨sqC,¨sqC,⍨¨⍵
          1<≢⍵: '(↑,¨',')',⍨,lns ⋄ lns  
        } 
        SplitQStr←{ nlC(≠⊆⊢) ⍵/⍨1+⍺∧⍵=sqC }
      0=≢fld: ⍵ 
        flds,← ⊂⍺ CondQtsE ⍺ SplitQStr fld  
        ⍵⊣ fld fld_lit⊢← ⊂'' 
    }
    F_Clear← { (fld fld_lit⊢← ⊂'')⊢fld }
⍝ Main Processing...
⍝ T_: Text Fields (default):   '...'
    T_Next←{
       0=≢⍵: opts2 flds ⊣ F_Done ⍬    ⍝ <== RETURN from EXECUTIVE
       ch← ⊃⍵ 
       escO= ch: T_Esc 1↓⍵
       lbC = ch: C_or_Sp_Scan 1↓⍵
       T_Next 1↓⍵⊣ F_Cat ch 
    }
    Executive← T_Next 
  ⍝ T_Esc: Escapes within text sequences:  `⋄ ``  `{ `} 
    T_Esc← T_Next _ScanEsc_ 0 
  ⍝ C_or_Sp_: Code or Space fields  { code }  or {  } 
    C_or_Sp_Scan←{
        _← F_Done ⍬
        isSpF← rbC= 1↑ ⍵↓⍨ nSp←NSpan ⍵  
      isSpF∧ nSp=0: T_Next F_Done 1↓⍵ 
      isSpF: T_Next 0 F_Done ⍵↓⍨ 1+nSp ⊣ F_Cat  '(', '⍴'''')',⍨ ⍕nSp 
        1 C_Scan ⍵  
    }
  ⍝ C_: Code Fields { code }
    C_Scan←{
      ⍝ C_S: Code String Subfields  { ... "xxx" ...} or { ... '...' ...}
        C_S_Scan←{  
            C_S_EndQt← { ch← ⊃⍵
              ch≠ myQt: C_Next ⍵⊣ F_Cat sqC 
                C_S_Next 1↓⍵⊣ F_Cat ch⍴⍨1+ch=sqC 
            }
          0= ≢⍵: Ê qStrÊ
            myQt← ⍺ ⋄ ch← ⊃⍵   
            C_S_Next← myQt∘∇ 
          ⍝ C_S_Esc: Escapes within code strings `⋄ `` `{ `}
            C_S_Esc← C_S_Next _ScanEsc_ 0

          ch= myQt:  C_S_EndQt 1↓⍵
          ch= sqC:  C_S_Next 1↓⍵⊣ F_Cat 2⍴ ch 
          ch=escO:  C_S_Esc 1↓⍵ 
            C_S_Next 1↓⍵⊣ F_Cat ch 
        } ⍝ C_S_Scan
      ⍝ _Omega: Code Omega Sequence (only outside quotes)  ⍹[ddd]? `⍵[ddd]? `⍹[ddd]?
      ⍝ See _Omega above 
      ⍝ C_SelfDoc: Code Self-documenting expressions; { ... →} and { ... %} plus { ... ↓}.
        C_SelfDoc← { brLvl ch←⍺ 
            isInfx← (1=brLvl)⍲ rbC= ⊃⍵↓⍨ nSp← NSpan ⍵
            opts2∨← o← ch≠ raC 
          isInfx: C_Next ⍵⊣ ch F_Cat (ch ' ⍙ⓄⓋⓇ '⊃⍨ ch= ovrC) 
            lch← sdArrows⊃⍨ o ⋄ fld_lit,← lch, nSp↑⍵  
            pre←   '(⍙ⒸⒽⓃ'  '(' ⊃⍨ o
            f← ⊂pre,(EnQt fld_lit),(o⊃'' ' ⍙ⓄⓋⓇ ' ),'({',fld,'}⍵))'  
            T_Next ⍵↓⍨ nSp+1⊣ flds,← f ⊣ F_Clear⍬
        }

      ⍝ C_Scan Executive  
        C_Next← ⍺∘C_Scan 
      ⍝ C_Esc: Code Escape Sequence  `` `{ `} `⍵[ddd]? `⍹[ddd]?
        C_Esc← C_Next _ScanEsc_ 1

      ⍺≤0: T_Next 0 F_Done ⍵⊣ fld⊢← '({','⍵)',⍨fld
      0= ≢⍵: Ê brcÊ           
        ch← ⊃⍵
      lbC rbC∊⍨ ch: (⍺+-/ch= lbC rbC) C_Scan 1↓⍵ ⊣ F_Cat ch 
      sqC dqC∊⍨ ch: ch C_S_Scan 1↓⍵⊣ F_Cat sqC
      spC=  ch:      C_Next nSp↓⍵⊣ (nSp↑⍵) F_Cat spC⊣ nSp← NSpan ⍵
      escO= ch:      C_Esc 1↓⍵ 
      omUC= ch:      C_Next _Omega  1↓⍵
      fmtC= ch:      C_Next 1↓⍵ ⊣ ch F_Cat ' ⎕FMT '
      raC ovrC dnC∊⍨ ch: ⍺ ch C_SelfDoc 1↓⍵ 
                     C_Next 1↓⍵ ⊣ F_Cat ch 
    } ⍝ End C_Scan
    
⍝ ---------------------------
⍝ ---------------------------
⍝⍝⍝ MAIN: 
⍝   Options and Variables (non-constants)
      (modO boxO) escO←(2↑⍺)(⊃'`',⍨2↓⍺)                        ⍝ Set/validate options 
      fStr←⊃⊆⍵                                                 ⍝ fStr: The format string (⍹0)
    ((2>⍴∘⍴)⍱(0=80|⎕DR))fStr: Ê fStrÊ                          ⍝       Must be simple char vec/scalars 
    modO(~∊) ¯2 ¯1 0 1:       Ê opt0Ê                               
    boxO(~∊) 0 1:             Ê opt1Ê ⋄ boxO≠0: 11 ⎕SIGNAL⍨'Box option not implemented'
    escO∊ lbC spC cmC:        Ê opt2Ê                          ⍝ Invalid escape char?  
⍝ ---------------------------
⍝⍝⍝ MAIN:
⍝   Run STAGE I: Process format string and pass resulting string/s to STAGE II
    flds fld fld_lit opts2 omCtr ← ⍬ '' '' 0 0  
    Executive fStr                     
  }⍵

}
