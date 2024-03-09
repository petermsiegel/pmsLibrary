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
  1/ 0 1003:: ⎕SIGNAL ⊂⎕DMX.(('EM',⍥⊂'∆F ',EM)('Message' Message),⊂'EN',⍥⊂ EN 999⊃⍨1000≤EN)

⍝ ---------------------------
  (⊃⍺) ((⊃⎕RSI){ 
⍝ STAGE II: Execute/Display code from Stage I
         ⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵} 
      1=⍺: ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨(⌽⊆⍺⍺⍎'{',(∊⌽⊃⌽⍵),'}⍵⍵')     
      0=⍺: ∊'{{',(⊃⍵),'⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⌽',(∊⌽⊃⌽⍵),'}',({ s,s,⍨ ⍵/⍨ 1+⍵=s←''''}⊃⍵⍵),',⍥⊆⍵}'
     ¯1=⍺: ⊃⌽⍵ 
     ¯2=⍺: ⎕SE.Dyalog.Utils.disp⍪ ⊃⌽⍵ 
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
      
  ⍝ ...Cod:  Two choices presented: Actual code (if modO≥0) and pseudo-code (otherwise).
  ⍝ ..C: Constants.
  ⍝ ␠   '   "   ⋄     ⍝  :                                     ⍝1 Constants. See also escO option.
    spC sqC dqC eosC cmC clnC← ' ''"⋄⍝:'                     
  ⍝ {   }   $    %    ⍵   ⍹    →                               ⍝2 Constants.
    lbC rbC fmtC ovrC omC omUC raC← '{}$%⍵⍹→'                  
    nlC← ⎕UCS 13                                               ⍝3 newline: carriage return [sic!]
  ⍝ ovrCod: See ovrÇ (%) and irt (include runtime code) logic  ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
    ovrCod←  '⍙ⓄⓋⓇ←{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄'   
 
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"    
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
⍝ Main Processing...
    preamble← ⍬
    ScanNext←{
       0=≢⍵: preamble fields ⊣ EndField ⍬    ⍝ <== RETURN from EXECUTIVE
       ch← ⊃⍵ 
       escO= ch: ScanEsc 1↓⍵
       lbC = ch: ScanCodOrSp 1↓⍵
       ScanNext 1↓⍵⊣ Cat ch 
    }
    Executive← ScanNext 
    ScanEsc←{
       ch← ⊃⍵
       eosC= ch: ScanNext 1↓⍵⊣ Cat nlC 
       escO lbC rbC eosC∊⍨ ch: ScanNext 1↓⍵ ⊣ Cat ch 
       ScanNext 1↓⍵ ⊣ Cat escO, ch 
    }
    ScanCodOrSp←{
      _← EndField ⍬
      p←+/∧\' '=⍵ ⋄ isSp← rbC= 1↑ p↓⍵ 
      isSp∧ p=0: ScanNext EndField 1↓⍵ 
      isSp: ScanNext 0 EndField ⍵↓⍨ 1+p ⊣ Cat  '(',')',⍨sqC,sqC,'⍴⍨',⍕p
      1 ScanCod p↓⍵ 
    }
    ScanCod←{
        ScanStr←{  
            StrEsc← { ch← ⊃⍵ 
              eosC= ch: StrNext 1↓⍵ ⊣ Cat nlC  
              escO lbC rbC∊⍨ ch: StrNext 1↓⍵⊣ Cat ch  
                StrNext 1↓⍵⊣ Cat escO, ch  
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
          ch=escO:  StrEsc 1↓⍵ 
            StrNext 1↓⍵⊣ Cat ch 
        } ⍝ ScanStr
        ScanCodEsc← { ch← ⊃⍵ 
          escO lbC rbC∊⍨ ch: CodNext 1↓⍵⊣ Cat ch  
          omC omUC∊⍨ ch: ScanCodOm 1↓⍵ 
            CodNext 1↓⍵⊣ Cat escO, ch  
        }
        ScanCodOm←{ wx← '⍵⌷⍨⎕IO+'
          p←+/∧\⍵∊ ⎕D
          0<p: CodNext p↓⍵⊣ Cat '(',wx,pW,')'⊣ omCtr⊢← ⊃⌽⎕VFI pW← p↑⍵
               omCtr+← 1 ⋄ CodNext ⍵⊣ Cat '(',wx,')',⍨ ⍕omCtr        
        }

      ⍝ ScanCod Executive  
        CodNext← ⍺∘ScanCod 
      0= ≢⍵: Ê brcÊ           
        ch← ⊃⍵
      ⍺≤0: ScanNext 0 EndField ⍵⊣ field⊢← '({','⍵)',⍨field
      lbC rbC∊⍨ ch: (⍺+-/ch= lbC rbC) ScanCod 1↓⍵ ⊣ Cat ch 
      sqC dqC∊⍨ ch: ch ScanStr 1↓⍵⊣ Cat sqC
      spC=  ch:     CodNext p↓⍵⊣ Cat spC⊣ p← +/∧\⍵= spC 
      escO= ch:     ScanCodEsc 1↓⍵ 
      omUC= ch:     ScanCodOm  1↓⍵
      fmtC= ch:     CodNext 1↓⍵ ⊣ Cat ' ⎕FMT '
      ovrC raC∊⍨ ch: CodNext 1↓⍵⊣ ⍺{ 
            typ2← (1=⍺)∧ rbC= ⊃⍵↓⍨ p←+/∧\⍵= spC
            preamble⊢← preamble ovrCod⊃⍨ o←ch=ovrC 
          ~typ2: CodNext 1↓⍵⊣ Cat (o⊃ch ' ⍙ⓄⓋⓇ ') 
            f← ⊂'((',(sqC,sqC,⍨ field/⍨ 1+field=sqC),')',(o⊃'' ' ⍙ⓄⓋⓇ ' ),'({',field,'}⍵))'  
            ScanNext p↓⍵⊣ fields,← f ⊣ field⊢←'' 
      }1↓⍵ 
                    CodNext 1↓⍵ ⊣ Cat ch 
    } ⍝ End ScanCod
    
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
    fields field omCtr ← ⍬ '' 0  
    Executive fStr                     
  }⍵

}
