∆F←{
⍝H 
⍝H ∆F: Very simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝H     [opts] ∆F fmt_str

⍝H ⍺ OPTIONS:   modeÔ boxÔ escÔ 
⍝H   modeÔ←1   generate and execute
⍝H   boxÔ←0    [NOT IMPLEMENTED. Leave at 0] don't box each item 
⍝H   escÔ←'`'  escape char
⍝H *** NO OTHER HELP AVAILABLE ***

  ⍺←1 0 '`'
⍝ Fast Path: Make this ∆F call a nop?
  0=≢⍺: 1 0⍴''                                                 
 'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
  1/ 0 1003:: ⎕SIGNAL ⊂⎕DMX.(('EM',⍥⊂'∆F ',EM)('Message' Message),⊂'EN',⍥⊂ EN 999⊃⍨1000≤EN)

⍝ ---------------------------
  (⊃⍺) ((⊃⎕RSI){ 
⍝ STAGE II: Execute/Display code from Stage I
      1=⍺: ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨(⌽⊆⍺⍺⍎'{',(∊⌽⍵),'}⍵⍵')    ⍝ ⍵⍵ contains caller's orig. <⍵>
     ¯2≠⍺: ⍵  
           ⎕SE.Dyalog.Utils.disp ⍪⍵ 
      ∘∘unreachable∘∘ ⍵⍵    ⍝ ⍵⍵: Enable ⍵⍵, used in case (1=⍺) above.
⍝ ---------------------------
  }(⊆⍵))⍺{                                                     ⍝ ⊆⍵: original f-string
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
      
  ⍝ ...Cod:  Two choices presented: Actual code (if modÔ≥0) and pseudo-code (otherwise).
  ⍝ ..C: Constants.
  ⍝ ␠   '   "   ⋄     ⍝  :                                     ⍝1 Constants. See also escÔ option.
    spC sqC dqC eosC cmC clnC← ' ''"⋄⍝:'                     
  ⍝ {   }   $    %    ⍵   ⍹    →                               ⍝2 Constants.
    lbC rbC fmtC ovrC omC omUC raC← '{}$%⍵⍹→'                  
    nlC← ⎕UCS 13                                               ⍝3 newline: carriage return [sic!]
    Cat← { ⍬⊣ field,← ⍵ }
    EndField←{
        ⍺←1
        CondQts← {
          ~⍺: ∊⍵
            lns← ∊' ',⍨¨sqC,¨sqC,⍨¨⍵
          1<≢⍵: '(↑,¨',')',⍨,lns ⋄ lns  
        } 
        SplitStr←{ nlC(≠⊆⊢) ⍵/⍨1+⍺∧⍵=sqC }
      0=≢field: ⍵
        field⊢← ⍺ CondQts ⍺ SplitStr field 
        fields,← ⊂field 
        ⍵⊣ field⊢←'' 
    }

    TopNext←{
       0=≢⍵: fields⊣ EndField ⍬
       ch← ⊃⍵ 
       escÔ= ch: ProcEsc 1↓⍵
       lbC = ch: ProcCodOrSp 1↓⍵
       TopNext 1↓⍵⊣ Cat ch 
    }
    Process← TopNext 

    ProcEsc←{
       ch← ⊃⍵
       eosC= ch: TopNext 1↓⍵⊣ Cat nlC 
       escÔ lbC rbC eosC∊⍨ ch: TopNext 1↓⍵ ⊣ Cat ch 
       TopNext 1↓⍵ ⊣ Cat escÔ, ch 
    }
    ProcCodOrSp←{
      _← EndField ⍬
      p←+/∧\' '=⍵ ⋄ isSp← rbC= 1↑ p↓⍵ 
      isSp∧ p=0: TopNext EndField 1↓⍵ 
      isSp: TopNext 0 EndField ⍵↓⍨ 1+p ⊣ Cat  '(',')',⍨sqC,sqC,'⍴⍨',⍕p
      1 ProcCod ⍵ 
    }
    ProcCod←{
      ProcStr←{  
          ProcEsc← { ch← ⊃⍵ 
            eosC= ch: StrNext 1↓⍵ ⊣ Cat nlC  
            escÔ lbC rbC∊⍨ ch: StrNext 1↓⍵⊣ Cat ch  
              StrNext 1↓⍵⊣ Cat escÔ, ch  
          }
          ProcEndQt← { ch← ⊃⍵
            ch≠ myQt: CodNext ⍵⊣ Cat sqC 
              StrNext 1↓⍵⊣ Cat ch⍴⍨1+ch=sqC 
          }
 
        0= ≢⍵: Ê qStrÊ
          myQt← ⍺ ⋄ ch← ⊃⍵   
          StrNext← myQt∘∇ 
          
        ch= myQt:  ProcEndQt 1↓⍵
        ch= sqC:  StrNext 1↓⍵⊣ Cat 2⍴ ch 
        ch=escÔ:  ProcEsc 1↓⍵ 
          StrNext 1↓⍵⊣ Cat ch 
      } ⍝ ProcStr
      ProcEsc← { ch← ⊃⍵ 
        escÔ lbC rbC∊⍨ ch: CodNext 1↓⍵⊣ Cat ch  
        omC omUC∊⍨ ch: ProcOm 1↓⍵ 
          CodNext 1↓⍵⊣ Cat escÔ, ch  
      }
      ProcOm←{  
        p←+/∧\⍵∊ ⎕D
        0≠p: CodNext p↓⍵⊣ Cat '(⍵⌷⍨⎕IO+',pW,')'⊣ omCtr⊢← ⊃⌽⎕VFI (⎕←pW← p↑⍵)
             omCtr+← 1 ⋄ CodNext ⍵⊣ Cat '(⍵⌷⍨⎕IO+',(⍕omCtr),')'
      }

      CodNext← ⍺∘ProcCod 
      0= ≢⍵: Ê brcÊ           ⍝  TopNext EndField ⍵  
      ch← ⊃⍵
      ⍺≤0: TopNext 0 EndField ⍵⊣ field⊢← '({','⍵)',⍨field
      lbC rbC∊⍨ ch: (⍺+-/ch= lbC rbC) ProcCod 1↓⍵ ⊣ Cat ch 
      sqC dqC∊⍨ ch: ch ProcStr 1↓⍵⊣ Cat sqC
      escÔ=ch:      ProcEsc 1↓⍵ 
      omUC= ch:     ProcOm  1↓⍵
      fmtC= ch:     CodNext 1↓⍵ ⊣ Cat ' ⎕FMT '
      CodNext 1↓⍵ ⊣ Cat ch 
    }
    
⍝ ---------------------------
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"
⍝ ---------------------------
⍝⍝⍝ MAIN: 
⍝   Options and Variables (non-constants)
      (modÔ boxÔ) escÔ←(2↑⍺)(⊃'`',⍨2↓⍺)                        ⍝ Set/validate options 
      fStr←⊃⊆⍵                                                 ⍝ fStr: The format string (⍹0)
    ((2>⍴∘⍴)⍱(0=80|⎕DR))fStr: Ê fStrÊ                          ⍝       Must be simple char vec/scalars 
    modÔ(~∊) ¯2 ¯1 0 1:       Ê opt0Ê                               
    boxÔ(~∊) 0 1:             Ê opt1Ê ⋄ boxÔ≠0: 11 ⎕SIGNAL⍨'Box option not implemented'
    escÔ∊ lbC spC cmC:        Ê opt2Ê                          ⍝ Invalid escape char?  
⍝ ---------------------------
⍝⍝⍝ MAIN:
⍝   Run STAGE I: Process format string and pass resulting string/s to STAGE II
    fields field omCtr← ⍬ '' 0
    Process fStr                       
  }⍵

}
