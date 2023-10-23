∆F←{
⍝H ∆F: Simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝! For documentation, see ⍝H comments below.
⍝ ⍺ OPTIONS
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
 'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
  0 1003/⍨ 1:: ⎕SIGNAL ⊂⎕DMX.(('EM',⍥⊂'∆F ',EM)('Message' Message),⊂'EN',⍥⊂ EN 999⊃⍨1000≤EN)
⍝ ---------------------------
  (⊃⍺) ((⊃⎕RSI){ ⍝ dyadic operator: ⍺=1 (mode 1): ⍵ contains executable atom '⍵⍵'
⍝ STAGE II: Execute/Display code from Stage I
      1=⍺:  ⍺⍺⍎ ⍵ ⋄ ¯2≠⍺: ⍵ ⋄ ⎕SE.Dyalog.Utils.disp ⍪⍵  
      ∘∘unreachable∘∘ ⍵⍵ 
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
    logÊ←  ('EM'      'LOGIC ERROR: UNREACHABLE')    ('EN' 99) 
    BrkÊ← logÊ∘{  ⍝ => logÊ only, once changes are unlikely.
      _← '" not in "FastBrk", but has no local logic!'
      ⍺,⊂'Message' ('Pfx "',(⊃⍵),_)
    }
      
  ⍝ ...Cod:  Two choices presented: Actual code (if modO≥0) and pseudo-code (otherwise).
    chnCod←  '⊃,/((⌈/≢¨)↑¨⊢)⎕FMT' '⍙ⒸⒽⓃ'                       ⍝ ⍙ⒸⒽⓃ aligns & catenates arrays 
    boxCod←  '∘⎕SE.Dyalog.Utils.display' '∘⍙ⒷⓄⓍ'               ⍝ ⍙ⒷⓄⓍ¨ calls dfns.display (boxO=1)
  ⍝ ovrCod: See ovrÇ (%) and irt (include runtime code) logic  ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
    ovrCod←  (⊂'⍙ⓄⓋⓇ←'),¨ '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄'  '{...}⋄' 
  ⍝ Constants ...C
  ⍝ ␠   '   "   ⋄     ⍝  :                                     ⍝ Constants. See also escO option.
    spÇ sqÇ dqÇ eosÇ cmÇ clnÇ← ' ''"⋄⍝:'                     
  ⍝ {   }   $    %    ⍵   ⍹    →                               ⍝ Constants.
    lbÇ rbÇ fmtÇ ovrÇ omÇ omUÇ raÇ← '{}$%⍵⍹→'                  
    nlÇ← ⎕UCS 13                                               ⍝ newline: carriage return [sic!]
    inQt inTF inCF← 0 1 2                                      ⍝ See ProcEscs. 
⍝ ---------------------------
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"
    String← (2>⍴∘⍴)∧(0=80|⎕DR)                                 ⍝ Scal-Vec and Char only 
 ⍝ Match, Non-match, Match Quoted String, etc.
    Any←  ⊃∊      ⍝ Approx same perf. as  (∊⍨∘⊃)⍨              ⍝ Is (⊃⍺) ∊ ⍵?                                  ⍝ Is (⊃⍺) ∊    ⍵?
    NotAny← ~Any                                               ⍝ Is (⊃⍺) (~∊) ⍵?
    AnyQS←{       ⍝ Match (dbl- or single-)quoted string ⍵, with starting quote symbol ⊃⍵ 
      ⍝ ⍵ NotAny sqÇ dqÇ:  Ê logÊ     ⍝ Be sure ((⊃⍵)∊sqÇ dqÇ) is confirmed in caller. 
        qt← ⊃⍵
        ''{
          0=≢⍵: (QS2Cod ⍺) (SkipSp ⍵ )                         ⍝ → RETURN
          qt∧.∊⍨ 2↑⍵: (⍺,qt) ∇ 2↓⍵                             ⍝ qt-qt? (internal quote char)
          ⍵  Any qt:  (QS2Cod ⍺) (SkipSp 1↓⍵)                  ⍝ qt? → RETURN
          ⍵ NotAny escO: (⍺, ⊃⍵)  ∇ 1↓⍵                        ⍝ Not escaped char? Process.
            w← 1↓⍵
          w  Any eosÇ: (⍺, nlÇ)  ∇ 1↓w                         ⍝ escO + ⋄
          w  Any escO:  s ⍺ (∇ ProcEscs inQt) w                ⍝ escO + escO 
            (⍺,⊃⍵)∇ w                                          ⍝ escO+ anything else
        }1↓⍵
    }
    AnyOmega← {                                                ⍝ Handle ⍹1, ⍹, `⍵1, `⍵1, etÇ.
      ⍵ NotAny omUÇ omÇ: '' ⍵  ⋄ w← 1↓⍵                        ⍝ Not ⍹0 etc? Return ('' ⍵)
      dig← w↑⍨+/∧\w∊⎕D                                         ⍝ We're pointing right after ⍹/⍵ 
      0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipSp w     )  ⊣ omIx+← 1
              ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipSp w↓⍨≢dig) ⊣ omIx⊢← ⊃⌽⎕VFI dig  
    }
    ProcEscs← { env← ⍵⍵    ⍝  env∊ inCf inQt inTF
      ⍵ NotAny escO:    Ê logÊ                                 ⍝ DEBUG ONLY
      w← 1↓⍵                                                   ⍝ Skip past escO   
      w Any eosÇ:    (⍺, nlÇ      )⍺⍺ 1↓w
      w Any escO:    (⍺, ⊃⍵      )⍺⍺ 1↓w
        e← escO/⍨ inQt=env 
      w Any lbÇ rbÇ: (⍺, e, ⊃⍵   )⍺⍺ 1↓w 
      inCF≠env:      (⍺, escO, ⊃⍵ )⍺⍺ 1↓w                      ⍝ inSF, inQt? → RETURN
          o w← AnyOmega w                                      ⍝ ↓↓↓ inCF only
      ×≢o:           (⍺, Par o   )⍺⍺ w      
                     (⍺, escO, ⊃⍵ )⍺⍺ 1↓w                                          
    } 
⍝ Skip__: Skip (and ignore) leading char, chars, or patterns.  ⍝ Skip leading...
    SkipSp← { ⍵↓⍨  +/∧\ ⍵= spÇ }                               ⍝ ... spaces
    SkipCS← { ⍵↓⍨  +/∧\ ⍵∊ clnÇ spÇ }                          ⍝ ... runs of (clnÇ spÇ)
    SkipCm← {                                                  ⍝ ... '⍝' and subseq. comment
        cmÇ≠⊃⍵: ⍵ 
        {
          0=≢⍵: ⍵                                              ⍝ → RETURN
          ⍵    Any rbÇ eosÇ: ⍵                                 ⍝ → RETURN
          ⍵ NotAny escO: ∇ 1↓⍵
              w← 1↓⍵                                           ⍝ Check 1 past escO
          w    Any rbÇ eosÇ: ∇ 1↓w                             ⍝ Ignore rbÇ|eosÇ after escO 
              ∇ w                                              ⍝ Keep other char after escO  
        }1↓⍵
    }
  ⍝ Brk: Break past s, 0 or more leading chars NOT in ⍵, 
  ⍝      returning:   (s  <rest of str>)
  ⍝      If ALL leading chars are in ⍺, return (⍵ ''); if none, return ('' ⍵). 
    Brk← { 0=p← +/∧\~⍵∊ ⍺: '' ⍵ ⋄ ( p↑⍵ ) (p↓⍵) }
  ⍝ Miscellaneous
    Par← '(',,∘')'
    Trunc←  { ⍺←50 ⋄ ⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨0⌈⍺-4 }               ⍝ For DEBUG modes.
  ⍝ Span: Return # leading chars of ⍵ in ⍺.
    Span←   { +/∧\ ⍵∊ ⍺ }
    SpanSp← ' '∘Span
    T2QS← { sqÇ, sqÇ,⍨ ⍵/⍨ 1+sqÇ= ⍵ }                          ⍝ Text to Executable Quote String 
    QS2Cod←{                                                   ⍝ Outputs ⎕ML-independent code
        r← ⎕FMT r/⍨ 1+sqÇ= r←⍵      ⍝ Handles internal SQs     ⍝   Use ⎕FMT to handle newlines
      1=≢r: spÇ,sqÇ,(∊r),sqÇ,spÇ                               ⍝   Single row (i.e. no newlines)
        Par (sqÇ,sqÇ,⍨∊r),'⍴⍨', ⍕⍴r                            ⍝   Multiple rows. Add SQs...
    }
⍝ ---------------------------
⍝ Major Field Fns: TF, CF, and SF 
  ⍝ TF: Text Fields   
  ⍝     Returns: (code rest)
    TF← {                                                      ⍝ TF: Text Fields
      0=≢⍵: ''
      FastBrk← lbÇ escO ∘Brk                                             
      tf w← ''{
        0=≢⍵: ⍺ ⍵
        ×≢t⊣ t w← FastBrk ⍵ : (⍺, t) ∇ w                       ⍝ Fast process chars not matched below.
        ⍵ Any lbÇ:   ⍺ ⍵
        ⍵ Any escO:  ⍺ (∇ ProcEscs inTF) ⍵  
           Ê BrkÊ ⍵      
      } ⍵
      (QS2Cod tf) w
    } ⍝ End TF
  ⍝ CF: Code Fields
  ⍝     Returns: (code rest)
    CF← {                                                      ⍝ CF: Code Fields
      sdStr sdOvr← '' 0                                        ⍝ See also, sdOff← 1
      0=≢⍵: '' ⍵ 
      FastBrk← lbÇ rbÇ sqÇ dqÇ escO fmtÇ ovrÇ omUÇ cmÇ raÇ ∘Brk ⍝ Proc as much of ⍵ not matched.          
      brcLvl← 1                                                ⍝ Brace {} depth
      r w←'{'{
          0=≢⍵: ⍺ ⍵                                            ⍝ Terminate. Missing closing brace? APL handles
          ⍵ Any spÇ: (⍺, p↑⍵) ∇ p↓⍵ ⊣ p← SpanSp ⍵              ⍝ This is for aesthetics only...
          ×≢t⊣ t w← FastBrk ⍵ : (⍺, t) ∇ w                     ⍝ Fast process chars not matched below
  
          ⍵ Any lbÇ: (⍺, ⊃⍵) ∇ 1↓⍵ ⊣ brcLvl+← 1 
          ⍵ Any rbÇ: ⍺ ∇{ brcLvl-← 1  
            brcLvl≤0: (⍺, ⊃⍵) (1↓⍵)                            ⍝ Terminate! 
            (⍺, ⊃⍵) ⍺⍺ (1↓⍵)                     
          } ⍵
          ⍵ Any sqÇ dqÇ: (⍺, q) ∇ w⊣ q w← AnyQS ⍵
          ⍵ Any escO:     ⍺ (∇ ProcEscs inCF) ⍵   
          ⍵ Any fmtÇ:    (⍺,' ⎕FMT '↓⍨spÇ=⊃⌽⍺) ∇ SkipSp 1↓⍵
        ⍝ {...%} Self-documenting code expressions (VERTICAL SELF-DOC EXPR '%')
          ⍵ Any ovrÇ:    ⍺ ∇ {
            suf← ⍵↓⍨ 1+ p← SpanSp 1↓⍵
          suf NotAny rbÇ cmÇ: (⍺,' ⍙ⓄⓋⓇ '↓⍨spÇ=⊃⌽⍺ ) ⍺⍺ suf ⊣ irt∘← 1  ⍝ SkipSp 1↓⍵
            sdStr⊢← T2QS (1↓⍺), (⊃⍵), p⍴ spÇ 
            sdOvr⊢← 1 
            ((1↑⍺),(SkipSp 1↓⍺)) ⍺⍺ suf
          } ⍵ 
        ⍝ {...→} Self-documenting code expressions (HORIZONTAL SELF-DOC EXPR '→')
          ⍵ Any raÇ:      ⍺ ∇ {  
            suf← ⍵↓⍨ 1+ p← SpanSp 1↓⍵
            suf NotAny rbÇ cmÇ: Ê fStrÊ
              sdStr⊢← T2QS (1↓⍺), (⊃⍵), p⍴ spÇ                                          
             ((1↑⍺),(SkipSp 1↓⍺)) ⍺⍺ suf
          } ⍵  
          ⍵ Any cmÇ: ⍺ ∇ SkipCm ⍵ 
          o w← AnyOmega ⍵       
          ×≢o : (⍺, Par o ) ∇ w  
            Ê BrkÊ ⍵     
      } SkipSp⍣0⊢ 1↓⍵            ⍝ ⍣0 - ignore SkipSp for aesthetic reasons.
      0= ≢sdStr:   (Par r, '⍵') w   
      sdOvr: (Par sdStr, '⍙ⓄⓋⓇ', (Par r, '⍵')  ) w ⊣ irt∨← sdOvr 
             ((Par r, '⍵'), spÇ, sdStr          ) w ⊣ sdOff⊢← 0  
    } ⍝ End CF
  ⍝ SF: Space Fields
  ⍝ Returns:  (isSF code rest)
  ⍝   F0: `?⍵ddd | ⍹ddd | ⍹  | ddd | '    '
  ⍝   F1:    ddd |  ddd | '' | ddd | '    '    
  ⍝    isSF:   1 if ⍵ starts a Space Field   |  0 otherwise: if 0, ⍵ starts a Code Field.
  ⍝    code:   code for Space Field          |  ''
  ⍝    rest:   text after Space Field        |  ⍵
    ⋄ sCod← sqÇ,sqÇ,'⍴⍨' 
    ⋄ spMax← 5                                                 ⍝ If >spMax spaces, generate at run-time  
    ⋄ Skip2EOS← { w Any rbÇ ⊣ w← SkipCS ⍵: 1↓w ⋄ Ê fStrÊ } 
    ⋄ SCommon← { ⍝ ⍺: length of space field (≥0)
            ⍺= 0:     1 '' (Skip2EOS ⍵)                        ⍝ If 0-len SF, field => null.
            ⍺≤ spMax: 1 s  (Skip2EOS ⍵) ⊣ s← Par (','/⍨ boxO∧1=⍺), sqÇ,sqÇ,⍨ ⍺⍴ spÇ
                      1 s  (Skip2EOS ⍵) ⊣ s← Par sCod, ⍕⍺ 
      }
    SF← {          
        isCF ← 0 '' ⍵
        w← ⍵↓⍨ 1+ p←   SpanSp 1↓⍵                              ⍝ Grab leading blanks
      w  Any rbÇ:       p SCommon w                            ⍝ Fast path: {}
      w NotAny clnÇ:  isCF                                     ⍝ Not { } or { :...[:] }? See if CF
        w← SkipCS 1↓w 
      w  Any rbÇ:       0 SCommon w                            ⍝ Allow degenerate { : } { :: }                                      
        o w← AnyOmega w↓⍨e← w Any escO                         ⍝ escO ⍵ <==> ⍵
      ×≢o:             1 (Par sCod, o) (Skip2EOS w)    
      e:               isCF           
        ok num← ⎕VFI w↑⍨ p←⎕D Span w 
      1≢⍥, ok:         isCF                                    ⍝ Not exactly 1 valid number
        w← SkipCS p↓ w 
      w Any rbÇ:        num SCommon w 
                       isCF                
    } ⍝ End SF
⍝ ---------------------------
⍝ Primary Executive Fns:  Analyse, Assemble 
    Analyse← {                                                 ⍝ Convert <fStr> to executable fields
      ×≢ff←⍬{  
        0=≢⍵: '⊂'{⊂⍺,⊃⍵}⍣ (sdOff∧1=≢⍺)⊢ ⍺                      ⍝ Done: →RETURN field (enclosed str.)
              isTF← ⍵ NotAny lbÇ                                ⍝ TF?
        isTF: w ∇⍨ ⍺, ⊂⍣(×≢tf)⊢ tf ⊣tf w← TF ⍵                 ⍝ Is TF. Proc TF and next
              isSF sf w←SF ⍵                                   ⍝ SF? Else CF.
        isSF: w ∇⍨ ⍺, ⊂⍣(×≢sf)⊢sf                              ⍝ Is SF. Proc SF and next
              w ∇⍨ ⍺, ⊂⍣(×≢cf)⊢cf ⊣ cf w← CF ⍵                 ⍝ Is CF. Proc CF and next
      }fStr: ⌽ff ⋄ ⊂'⊂⍬'                                       ⍝ Handle 0 fields (edge case)
    }
    Assemble← {                                                ⍝ Assemble code + needed defs 
          pfx← '¨⌽',⍨ ∊ irt 1 boxO/ ovrCod chnCod boxCod ⊃⍨¨ modO<0 
      1=modO: '{',  pfx, (∊⍵), '}⍵⍵'
      0=modO: '{{', pfx, (∊⍵), '}', (T2QS fStr),',⍥⊆⍵}'
          (⊂'{{', pfx),  ⍵, ⊂'}', (T2QS 25∘Trunc fStr),',⍥⊆⍵}⍵'
    } 
⍝ ---------------------------
⍝⍝⍝ MAIN: 
⍝   Options and Variables (non-constants)
      (modO boxO) escO←(2↑⍺)(⊃'`',⍨2↓⍺)                        ⍝ Set/validate options 
      fStr←⊃⊆⍵                                                 ⍝ fStr: The format string (⍹0)
    ~String fStr:      Ê fStrÊ                                 ⍝       Must be simple char vec/scalars 
    modO(~∊) ¯2 ¯1 0 1: Ê opt0Ê                               
    boxO(~∊) 0 1:       Ê opt1Ê
    escO∊ lbÇ spÇ cmÇ:     Ê opt2Ê                                ⍝ Invalid escape char?  
      irt←0                                                    ⍝ irt: include runtime code? See CF
      omIx←0                                                   ⍝ omIx: omega index. See AnyOmega 
      sdOff←1                                                  ⍝ See self-documenting code expressions
⍝ ---------------------------
⍝⍝⍝ MAIN:
⍝   Run STAGE I: Process format string and pass resulting string/s to STAGE II
    Assemble Analyse ⍬                                     
  }⍵
⍝ Help information follows (⍝H prefix)
⍝H ∆F Utility Function
⍝H ∆F Utility Function
⍝H    ∆F is a function that uses simple input string expressions, f-strings, to dynamically build 
⍝H    2-dimensional output from variables and dfn-style code, shortcuts for numerical formatting, 
⍝H    titles, and more. To support an idiomatic APL style, ∆F uses the concept of fields to organize the
⍝H    display of vector and multidimensional objects using building blocks (like ⎕FMT) that already exist
⍝H    in the Dyalog implementation. (∆F is reminiscent of f-string support in Python, but in an APL style.)
⍝H Quick example:
⍝H ⍎      ∆F 'The current temp is{1⍕⍪1↓⍵}°C or{1⍕⍪32+(9÷5)×1↓⍵}°F.' 20 30 40 50
⍝H ⎕   The current temp is 20.0°C or  68.0°F.
⍝H ⎕                       30.0       86.0   
⍝H ⎕                       40.0      104.0   
⍝H ⎕                       50.0      122.0   
⍝H Syntax: 
⍝H     [mode←1 box←0 escCh←'`' | ⍬ | 'help'] ∆F f-string  args 
⍝H 
⍝H     ⍵← f-string [[⍵1 ⍵2...]]
⍝H        f-string: char vector with formatting specifications.
⍝H               See below.
⍝H        args:  arguments visible to all f-string code expressions (0⌷⍵ is the f-string itself). 
⍝H     ⍺← 1 0 '`'   = mode box escCh
⍝H        mode:  1= generate code, execute, and display result [default].
⍝H                  Fields are executed left to right, as if APL statements separated by ⋄.
⍝H               0= emit code you can execute or convert to a dfn via ⍎, e.g. dfn←⍎0 ∆F '...'. 
⍝H              ¯1= generate pseudo code right-to-left with each field a separate character vector.
⍝H                  (For pedagogical or debugging purposes).
⍝H              ¯2= same as for mode=¯1, except displaying fields boxed in table (⍪) form.
⍝H                  (For pedagogical or debugging purposes).
⍝H                  Tip: Use ¯2 ∆F "..." to see the code generated for the fields you specify.
⍝H              Note for modes 0, ¯1, ¯2: 
⍝H                 L-to-R code fields appear in reverse order (right-to-left),
⍝H                 but will always display left-to-right (i.e., in modes 0 1).
⍝H        -------
⍝H        box:   1= display each field in a box ("display" from dfns).
⍝H               0= display each field as is [default].
⍝H        -------
⍝H        escCh: escape character, used to ensure or suppress special behavior.
⍝H               ∘ default is '`'. A common alternative is '\'.
⍝H               ∘ suppresses special behavior of {, }, `.
⍝H               ∘ enables special behavior of `⋄ and `⍵.
⍝H        -------
⍝H        ⍬:     causes ∆F to do absolutely nothing, but quickly, returning shy
⍝H                  1 0⍴''
⍝H               E.g. To execute & display {⎕DL toggle}, ONLY if toggle<10:
⍝H ⍎                (1/⍨toggle<10) ∆F 'Delay of {toggle} seconds: {⎕DL `⍵1}'(toggle←?15)
⍝H ⎕              Delay of 5 seconds: 5.109345
⍝H        -------
⍝H         'help': shows this help information.
⍝H        -------
⍝H    Returns: Per mode above (see mode)
⍝H       [1]  A matrix.
⍝H       [0]  A char vector (executable)
⍝H       [¯1] vector of char. vectors
⍝H       [¯2] A matrix (raveled, box vector of char. vectors)
⍝H    or, if ⍺≡⍬:
⍝H       1 0⍴''
⍝H
⍝H The f-string
⍝H ○ The f-string is a character vector defining 0 or more 2-D (char matrix) "fields," 
⍝H   which are executed as if separate statements (the left-most field "executed" first)
⍝H   and assembled into a single matrix (with fields displayed left-to-right, top-aligned, 
⍝H   and padded with blank rows as required). 
⍝H ○ The f-string is available to Code Fields (below) verbatim as (0⌷⍵), 
⍝H   or the shortcut" variable ⍹0 or, equivalently, `⍵0. See Omega Expressions below.
⍝H
⍝H There are 3 types of fields generated: 
⍝H    1. Code Fields, 2. Space Fields, and 3. Text Fields.
⍝H 
⍝H 1. Code fields:   { any APL code }
⍝H    Additions:
⍝H     a. Omega Expressions:  ⍹[ddd] or its escape-based equivalent, `⍵[ddd]. ddd is any non-neg integer.
⍝H        These index into the "arguments" passed to ∆F as elements of ⍵, 
⍝H        including the f-string itself as the 0-th element of ⍵ (⍹0), independent of the user-space ⎕IO.
⍝H        The elements referred to MUST exist at run-time, else an error is signalled.
⍝H             ∘ ⍹1:   1st arg after f-string, 
⍝H               ⍹2:   2nd,
⍝H               ⍹99:  the 99th arg after the f-string;
⍝H               ⍹0:   the f-string itself.
⍝H               ⍹:    (⍹ alone) the "next" arg left to right in ⍵, indexed after a (bare) ⍹ or a numeric ⍹1, etc.
⍝H                     If ⍹5 is the first ⍹-expression to its left, then ⍹ refers to ⍹6.
⍝H                     If there is no ⍹-expression to its left, ⍹ refers to ⍹1. Simple ⍹ never refers to ⍹0.
⍝H             ∘ `⍵ is a synonym to ⍹ in code fields (outside strings)
⍝H               `⍵ is equivalent to ⍹; `⍵2 is the same as ⍹2, etc.:
⍝H ⍎                    ∆F'{ `⍵2⍴ `⍵1  ⍝  same as ⍹2⍴ ⍹1 }' 'hello ' 11
⍝H ⎕                hello hello             ⍝ ⍝== Length is 11!
⍝H             ∘ In text fields or quotes, ⍹ and ⍵ have no special significance.
⍝H             ∘ ⍹ is the unicode char ⎕UCS 9081.
⍝H     b. Double quote strings in Code Fields. Like APL single-quoted strings '...' (also supported),
⍝H        ∆F allows strings of the form "..." in Code Fields. 
⍝H        To include a double quote itself, simply double a double quote, as you would for single-quoted strings.
⍝H ⍎               ∆F '<{"John ""is"" here"}>'    
⍝H ⎕          <John "is" here>             
⍝H        A newline may be indicated in a double-quoted string, as in a Text Field (below), using `⋄
⍝H ⍎               ∆F '{ "This is`⋄ a cat`⋄ ¯ ¯¯¯" }'
⍝H ⎕           This is
⍝H ⎕            a cat 
⍝H ⎕            ¯ ¯¯¯ 
⍝H        This has the same output as the following, using % ("Over", shown in pseudo/code as ⍙ⓄⓋⓇ)
⍝H ⍎               ∆F '{ "This is" % " a cat" % " ¯ ¯¯¯" }'
⍝H     c. Self-Documenting Code Expressions
⍝H      1.Horizontal Self-Documenting Expressions
⍝H        { code → }    OR   { code → ⍝ cm }
⍝H             If a code expression {...} ends with a right arrow (→) preceded and/or followed by
⍝H             0 or more spaces (and an optional comment), it is treated as a horizontal 
⍝H             self-documenting code expression.
⍝H             That is, its value (on execution) will be preceded by the text of the code
⍝H             expression. That text will be followed by that same right arrow and spaces
⍝H             as input:
⍝H ⍎               ∆F '1. {⍪⍳2→}, 2. {⍪⍳2 → }.'
⍝H ⎕           1. ⍪⍳2→0, 2. ⍪⍳2 → 0. 
⍝H ⎕                  1           1 
⍝H        2.Vertical Self-Documenting Expressions
⍝H          { code % }    OR   { code % ⍝ cm }
⍝H             If a code expression {...} ends with a pct sign (%) preceded and/or followed by
⍝H             0 or more spaces (and optional comment), it is treated as a vertical 
⍝H             self-documenting code expression.
⍝H             That is, the text of the code expression will be placed above the value of the
⍝H             executed code as a "title". The title text will include that same 
⍝H             percent sign and any preceding or following spaces:
⍝H ⍎              ∆F '1. {⍪⍳2%}, 2. {⍪⍳2 % }.'
⍝H ⎕           1. ⍪⍳2%, 2. ⍪⍳2 % .
⍝H ⎕               0         0    
⍝H ⎕               1         1 
⍝H         Bugs/Features: Self-doc code expressions show the code as it will be executed, so
⍝H           double-quotes, shortcuts (see below) will already be resolved.
⍝H           Comments are not displayed as part of self-documenting code expressions.
⍝H         Compare Python self-documenting expressions {...=}
⍝H     d. Shortcuts (prefixes or infixes [monadic or dyadic pseudo-fns]): 
⍝H          $  $ is equiv. to ⎕FMT. For sanity, use with a left argument in double quotes:
⍝H ⍎               ∆F '{ "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           <0.47805>
⍝H ⎕           <0.46475>
⍝H          %  % prints object ⍺ centered over object ⍵ (itself centered, if the narrower obj.).
⍝H ⍎               ∆F '{ "Random Nums" % "⎕<⎕,F7.5,⎕>⎕" $ ?0 0}'
⍝H ⎕           Random Nums
⍝H ⎕            <0.43528> 
⍝H ⎕            <0.61564> 
⍝H          %  % may also be used monadically to insert a blank line above your output:
⍝H ⍎               ∆F '{⎕DL `⍵ }{%⎕DL `⍵ }{%%⎕DL `⍵ }' 0.1  0.2 0.3
⍝H ⎕           0.107371                          ⍝ ⎕DL 0.1                        
⍝H ⎕                   0.204216                  ⍝ ⎕DL 0.2   
⍝H ⎕                           0.300909          ⍝ ⎕DL 0.3
⍝H         ∘ See also the use of → and % as suffixes for Self-Documenting Code (above)>
⍝H      e. Limited comments in Code Fields: 
⍝H         ∘ Comments in code fields may consist of any characters besides (unescaped)
⍝H            } or ⋄.
⍝H         ∘ Escaped chars `}, `⋄ (and anything else) are allowed (and safely ignored).
⍝H         ∘ A comment field is terminated just before these (unescaped) characters:
⍝H           } or ⋄.  ( '{' is not special within a comment. )
⍝H         ∘ A simple escape character is ok in a comment clause (see 2 prior bullets).
⍝H         Example:
⍝H ⍎             ∆F '{ ⍹1 × ○2 ⍝ ⍹1 is r in 2×pi×r }' 5
⍝H ⎕        31.41592654       
⍝H 
⍝H 2. Space Fields (SF)  
⍝H                {}, {   }, { :5: }, { :⍹1: } { :⍹: }, or aliases { :`⍵1: } { :`⍵: }  
⍝H     # spaces   0     3       5       1⊃⍵     next ⍵                1⊃⍵     next ⍵    
⍝H    a. SF By Example: a brace with 0 or more blanks, representing the # of blanks on output.
⍝H       a1. Braces with 1 or more blanks separate other fields.
⍝H           1 blank: { }, 2 blanks: {  }, etc.
⍝H       a2. Null Fields: brace with 0 blanks is a Null Space Field, useful for separating OTHER fields.
⍝H       ∘ Examples of space fields (with multiline text fields-- see below):
⍝H ⍎           ∆F 'a`⋄cow{}a`⋄bell'            ∆F 'a`⋄cow{ }a`⋄bell'
⍝H ⎕        a  a                            a   a
⍝H ⎕        cowbell                         cow bell
⍝H    b. By Number: a number between colons (the trailing colon is optional) indicates the # of blanks on output.
⍝H          { :5: }    <== 5 blanks on output!
⍝H    c. By ⍹-Expression: an expression ⍹2 between colons (:⍹2:) means
⍝H          take the value of (⎕IO+2⊃⍵) as the # of blanks on output.
⍝H       An expression of simple ⍹ between colons (:⍹:) means: 
⍝H          increase the index of the last ⍵ expression to the left (or (⎕IO+1⊃⍨⍵) as the # of blanks on output.
⍝H       These parenthesized expressions are the same in this context:
⍝H ⍎            a b c← (∆F'{:5:}') (∆F'{:⍹1:}' 5) (∆F'{:`⍵1:}' 5)
⍝H ⍎            (a≡b)∧(b≡c)
⍝H ⎕         1
⍝H     ∘ Comments are NOT allowed in space fields.
⍝H     ∘ Self-documenting Space Fields do NOT exist.
⍝H 
⍝H 3. Text fields: any APL characters at all, except to represent {} and ` (or the current escape char).
⍝H    (If you change the escape character, e.g. to '\', make the appropriate changes in the narrative below).
⍝H    `{ is a literal {
⍝H    `} is a literal }
⍝H     { by itself starts a new code field
⍝H     } by itself ends a code field
⍝H    `⋄ stands for a newline character (⎕UCS 13).
⍝H     ⋄ has no special meaning, unless preceded by the current escape character (`).
⍝H     ` before {, }, or ⋄ must be doubled to have its literal meaning (`` ==> `)
⍝H     ` before other characters has no special meaning (i.e. appears as a literal character, unless escaped).
⍝H    Single quotes must be doubled as usual when typing in APL strings to be evaluated in code or via ⍎. 
⍝H    Double quotes have no special status in a text field (but see Code Fields).
⍝H    ⍹ and `⍵ have no special status in text fields (they are left as is).
⍝H
⍝H For help, execute                                             
⍝H   ∆F⍨'help' ... or see ⍝H "HELP" comments at the bottom of function ∆F.
⍝H 
⍝H Note: fields are not actually evaluated separately, but within a single code string.
⍝H   In practice, this means fields are generated right to left, formatted individually, and then
⍝H   "glued" together in reverse order, so the results appears left-to-right as expected!
⍝H   Try ¯2 ∆F ... to see pseudocode showing how your code is structured. Runtime defs are shown abridged.
⍝H   0 ∆F ... shows the actual code to be executed, with all runtime definitions spelled out in full!
⍝H

}
