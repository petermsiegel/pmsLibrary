∆F←{
⍝H ∆F: Simple formatting  function in APL "array" style, inspired by Python f-strings.
⍝! For documentation, see ⍝H comments below.
⍝ ⍺ OPTIONS
  ⍺←1 0 '`'
  0=≢⍺: 1 0⍴''
 'help'≡⎕C⍺: ⎕ED⍠ 'ReadOnly' 1⊢ 'help'⊣help←↑'^\h*⍝H(.*)' ⎕S '\1'⊢⎕NR ⊃⎕XSI  
  0 1003:: ⎕SIGNAL ⊂⎕DMX.(('EM',⍥⊂'∆F ',EM)('Message' Message),⊂'EN',⍥⊂ EN 999⊃⍨1000≤EN)
⍝ ---------------------------
⍝ STAGE II: Execute/Display code from Stage I
  (⊃⍺) ((⊃⎕RSI){ ⍝ dyadic operator: ⍺=1 (mode 1): ⍵ contains executable atom '⍵⍵'
      1=⍺:  ⍺⍺⍎ ⍵ ⋄ ¯2≠⍺: ⍵ ⋄ ⎕SE.Dyalog.Utils.disp ⍪⍵  
      ∘∘unreachable∘∘ ⍵⍵ 
⍝ ---------------------------
⍝ STAGE I: Analyse fmt string, pass code equivalent to Stage II above to execute or display
  }(⊆⍵))⍺{                                                     ⍝ ⊆⍵: original f-string
⍝ --------------------------- 
⍝ CONSTANTS     
⍝               
    ⎕io ⎕ml←0 1                  
  ⍝ ...Ê: Error messages. See Ê below.               
    opt0Ê← ('Message' 'Invalid option (mode)')       ('EN' 11) 
    opt1Ê← ('Message' 'Invalid option (box)')        ('EN' 11)        
    opt2Ê← ('Message' 'Invalid option (escape char)')('EN' 11) 
    fStrÊ← ('Message' 'Invalid right arg (f-string)')('EN' 11) 
    logÊ←  ('EM'      'LOGIC ERROR: UNREACHABLE')    ('EN' 99)    
  ⍝ ...Cod:  We'll select ...[0] when mod<0, [1] otherwise.
    chnCod←  '⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨' '⍙ⒸⒽⓃ'                      ⍝ ⍙ⒸⒽⓃ aligns & catenates arrays 
    boxCod←  '⎕SE.Dyalog.Utils.display¨' '⍙ⒷⓄⓍ¨'               ⍝ ⍙ⒷⓄⓍ¨ calls dfns.display 
  ⍝ ovrCod: See ovr and irt (include runtime code) logic       ⍝ ⍙ⓄⓋⓇ aligns, centers, & catenates arrays
    ovrCod←  (⊂'⍙ⓄⓋⓇ←'),¨ '{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}⋄'  '{...}⋄' 
  ⍝ ␠  '  "  ⋄   ⍝  :   {  }  $   %   ⍵  ⍹                     ⍝ ⍹: omega underbar                              
    sp sq dq eos cm cln lb rb fmt ovr om omU ra da← ' ''"⋄⍝:{}$%⍵⍹→↓'  ⍝ Constants, unlike ¨esc¨    
    lp rp← '()'
    clnsp← cln sp 
    nl← ⎕UCS 13                                                ⍝ newline: carriage return [sic!]
    inQt inTF inCF← 0 1 2                                      ⍝ See MEsc. 
⍝ ---------------------------
⍝ SUPPORT FNS
    Ê← {⍎'⎕SIGNAL⊂⍵' }                                         ⍝ Error signalled in its own "capsule"
    String← (2>⍴∘⍴)∧(0=80|⎕DR)                                 ⍝ Scal-Vec and Char only 
 ⍝ Match, Non-match, Match Quoted String, etc.
    M←  ⊃∊      ⍝ Approx same perf. as  (∊⍨∘⊃)⍨                ⍝ Is (⊃⍺) ∊ ⍵?                                  ⍝ Is (⊃⍺) ∊    ⍵?
    NM← ~M                                                     ⍝ Is (⊃⍺) (~∊) ⍵?
    MQS←{       ⍝ Match (dbl- or single-)quoted string ⍵, with starting quote symbol ⊃⍵ 
        ⍵ NM sq dq:  Ê logÊ     ⍝D DEBUG only                  ⍝ Requires (⊃⍵)∊sq dq
        qt← ⊃⍵
        ''{
          0=≢⍵: (QS2Cod ⍺) (SkipSp ⍵ )                         ⍝ → RETURN
          qt∧.∊⍨ 2↑⍵: (⍺,qt) ∇ 2↓⍵                             ⍝ qt-qt? (internal quote char)
          ⍵  M qt:  (QS2Cod ⍺) (SkipSp 1↓⍵)                    ⍝ qt? → RETURN
          ⍵ NM esc: (⍺, ⊃⍵)  ∇ 1↓⍵                             ⍝ Not escaped char? Process.
            w← 1↓⍵
          w  M eos: (⍺, nl)  ∇ 1↓w                             ⍝ esc + ⋄
          w  M esc:  s ⍺ (∇ MEsc inQt) w                       ⍝ esc + esc 
            (⍺,⊃⍵)∇ w                                          ⍝ esc+ anything else
        }1↓⍵
    }
    MOmega← {                                                  ⍝ Handle ⍹1, ⍹, `⍵1, `⍵1, etc.
      ⍵ NM omU om: '' ⍵  ⋄ w← 1↓⍵                              ⍝ Not ⍹0 etc? Return ('' ⍵)
      dig← w↑⍨+/∧\w∊⎕D                                         ⍝ We're pointing right after ⍹/⍵ 
      0=≢dig: ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipSp w     )  ⊣ omIx+← 1
              ('⍵⊃⍨⎕IO+',(⍕omIx)) (SkipSp w↓⍨≢dig) ⊣ omIx⊢← ⊃⌽⎕VFI dig  
    }
    MEsc← { env← ⍵⍵ 
      ⍵ NM esc:      Ê logÊ                                    ⍝ DEBUG ONLY
      w← 1↓⍵                                                   ⍝ Skip past esc   
      w M eos:       (⍺, nl      )⍺⍺ 1↓w
      w M esc:       (⍺, ⊃⍵      )⍺⍺ 1↓w
        e← esc/⍨ inQt=env 
      w M lb rb:     (⍺, e, ⊃⍵   )⍺⍺ 1↓w 
      inCF≠env:      (⍺, esc, ⊃⍵ )⍺⍺ 1↓w                       ⍝ inSF, inQt? → RETURN
          o w← MOmega w                                        ⍝ ↓↓↓ inCF only
      ×≢o:           (⍺, Par o   )⍺⍺ w      
                     (⍺, esc, ⊃⍵ )⍺⍺ 1↓w                                          
    } 
⍝ Skip__: Skip (and ignore) leading char, chars, or patterns.  ⍝ Skip leading...
    SkipSp← { ⍵↓⍨  +/∧\ ⍵= sp }                                ⍝ ... spaces
    SkipCS← { ⍵↓⍨  +/∧\ ⍵∊ clnsp }                             ⍝ ... runs of (cln sp)
    SkipCm← {                                                  ⍝ ... '⍝' and subseq. comment
        cm≠⊃⍵: ⍵ 
        {
          0=≢⍵: ⍵                                              ⍝ → RETURN
          ⍵  M rb eos: ⍵                                       ⍝ → RETURN
          ⍵ NM esc: ∇ 1↓⍵
              w← 1↓⍵                                           ⍝ Check 1 past esc
          w  M rb eos: ∇ 1↓w                                   ⍝ Ignore rb|eos after esc 
              ∇ w                                              ⍝ Keep other char after esc  
        }1↓⍵
    }
⍝ Brk: Break past s, 0 or more leading chars NOT in ⍵, returning (s  <rest of str>)
⍝      If ALL leading chars in ⍺, return (⍵ ''); if none, return ('' ⍵). 
    Brk← { 0=p← +/∧\~⍵∊ ⍺: '' ⍵ ⋄ ( p↑⍵ ) (p↓⍵) }
  ⍝ Miscellaneous
    Par← '(',,∘')'
    Trunc←  { ⍺←50 ⋄ ⍺≥≢⍵: ⍵ ⋄ '...',⍨⍵↑⍨0⌈⍺-4 }               ⍝ For DEBUG modes.
    Span←   { +/∧\ ⍵∊ ⍺ }
    SpanSp← ' '∘Span
    T2Q← { sq, sq,⍨ ⍵/⍨ 1+sq= ⍵ }                              ⍝ Text to Executable Quote String 
    QS2Cod←{                                                   ⍝ Outputs ⎕ML-independent code
        r← ⎕FMT r/⍨ 1+sq= r←⍵      ⍝ Handle internal SQs       ⍝   Use ⎕FMT to handle newlines
      1=≢r: sp,sq,(∊r),sq,sp                                   ⍝   Single row (i.e. no newlines)
        Par (sq,sq,⍨∊r),'⍴⍨', ⍕⍴r                              ⍝   Multiple rows. Add SQs...
    }
⍝ ---------------------------
⍝ Major Field Fns: TF, CF, and SF 
  ⍝ TF: Text Fields
    TF← {                                                      ⍝ TF: Text Fields
      0=≢⍵: ''
      FastBrk← lb esc ∘Brk                                                 
      tf w← ''{
        0=≢⍵: ⍺ ⍵
        t w← FastBrk ⍵ ⋄ ×≢t: (⍺, t) ∇ w                      ⍝ Fast process chars not matched below.
        ⍵ M lb:   ⍺ ⍵
        ⍵ M esc:  ⍺ (∇ MEsc inTF) ⍵   
            Ê logÊ       
      } ⍵
      (QS2Cod tf) w
    }
  ⍝ CF: Code Fields
    CF← {                                                      ⍝ CF: Code Fields
      sdStr sdOvr←'' 0  
      0=≢⍵: '' ⍵ 
      FastBrk← lb rb sq dq fmt ovr omU cm esc ra da ∘Brk          ⍝ Proc as much of ⍵ not ∊fast          
      brcLvl← 1                                                ⍝ Brace {} depth
      r w←'{'{
          0=≢⍵: ⍺ ⍵                                            ⍝ Terminate. Missing closing brace? APL handles
          t w← FastBrk ⍵ ⋄ ×≢t: (⍺, t) ∇ w                     ⍝ Fast process chars not matched below
  
          ⍵ M lb: (⍺, ⊃⍵) ∇ 1↓⍵ ⊣ brcLvl+← 1 
          ⍵ M rb: ⍺ ∇{ brcLvl-← 1  
            brcLvl≤0: (⍺, ⊃⍵) (1↓⍵)                            ⍝ Terminate! 
            (⍺, ⊃⍵) ⍺⍺ (1↓⍵)                     
          } ⍵
          ⍵ M sq dq:   (⍺, q           ) ∇ w⊣ q w← MQS ⍵
          ⍵ M esc:      ⍺ (∇ MEsc inCF) ⍵   
          ⍵ M fmt:     (⍺,' ⎕FMT '↓⍨sp=⊃⌽⍺ ) ∇ SkipSp 1↓⍵
          ⍵ M ovr:     ⍺ ∇ {
            suf← ⍵↓⍨ 1+ p← SpanSp 1↓⍵
            suf NM rb cm: (⍺,' ⍙ⓄⓋⓇ '↓⍨sp=⊃⌽⍺ ) ⍺⍺ suf ⊣ irt∘← 1  ⍝ SkipSp 1↓⍵
          ⍝ Self-documenting code expressions (VERTICAL SELF-DOC EXPR '%')
            sdStr⊢← T2Q (1↓⍺), (⊃⍵), p⍴ sp 
            sdOvr⊢← 1 
            ((1↑⍺),(SkipSp 1↓⍺)) ⍺⍺ suf
          } ⍵ 
        ⍝ Self-documenting code expressions (HORIZONTAL SELF-DOC EXPR '→')
          ⍵ M ra: ⍺ ∇ {  
            suf← ⍵↓⍨ 1+ p← SpanSp 1↓⍵
            suf NM rb cm: Ê fStrÊ
              sdStr⊢← T2Q (1↓⍺), (⊃⍵), p⍴ sp                                          
             ((1↑⍺),(SkipSp 1↓⍺)) ⍺⍺ suf
          } ⍵  
          ⍵ M cm:            ⍺            ∇ SkipCm ⍵ 
          o w← MOmega ⍵       
          ×≢o : (⍺, Par o ) ∇ w  
            Ê logÊ              
      } SkipSp 1↓⍵ 
      0= ≢sdStr:   (Par r, '⍵') w   
      sdOvr: (Par sdStr, '⍙ⓄⓋⓇ', (Par r, '⍵')  ) w ⊣ irt∨← sdOvr 
             ((Par r, '⍵'), sp, sdStr          ) w ⊣ sdOff⊢← 0  
    }
  ⍝ SFQ: Space Fields
  ⍝   F0: `?⍵ddd | ⍹ddd | ⍹  | ddd | '    '
  ⍝   F1:    ddd |  ddd | '' | ddd | '    '      
    SFQ← 0∘{ ⍺: SFQ_RE ⍵ ⋄ SFQ_APL ⍵ }
    sCod← sq,sq,'⍴⍨' ⋄ spMax← 5 ⍝ If >spMax spaces, generate at run-time             
  ⍝ SFQ Option 1: SFQ_RE
    ⋄ sfP← '^\{(\h*)\}' '^\{\h*:\h*(\d*)(?:\h*:)?\h*\}' '^\{\h*:\h*`?[⍵⍹](\d*)(?:\h*:)?\h*\}'
    SFQ_RE← {   ⍝ If >spMax spaces, generate at run-time 
        match←'' ⋄ skipFlag←1
        rest← sfP ⎕R { C← ⍵.PatternNum∘= ⋄ f1← ⍵.(Lengths[1]↑Offsets[1]↓Block)
            skipFlag∘← 0
            C 0: ''⊣  match∘← (0=≢f1){  
              ⍺: '' ⋄  ⍵: '''',f1,'''' ⋄ '(',')',⍨sCod,⍕≢f1
            } spMax≥≢f1 
            C 1: ''⊣  match∘← (0=≢i1){ 
              ⍺: '' ⋄ ⍵: '''',(i1⍴ ' '),'''' ⋄ '(',')',⍨ sCod,f1
            } spMax≥ i1← ⊃⌽⎕VFI f1
            C 2: ''⊣  match∘← { 
              ⍵: '(', ')',⍨ sCod, '⍵⊃⍨⎕IO+', ⍕omIx⊣ omIx+← 1 
                 '(', ')',⍨ sCod, '⍵⊃⍨⎕IO+', f1⊣ ⍕omIx∘← ⊃⌽⎕VFI f1
            }0=≢f1 
            ∘∘∘⎕←'unreachable'
        }⍵
      skipFlag: 0 '' ⍵
        1 match rest 
    }
  ⍝ SFQ Option 2: SFQ_APL
    ⋄ Skip2EOS← { w M rb ⊣ w← SkipCS ⍵: 1↓w ⋄ Ê fStrÊ } 
    ⋄ SCommon← { ⍝ ⍺: length of space field (≥0)
            ⍺= 0:     1 '' (Skip2EOS ⍵)                        ⍝ If 0-len SF, field => null.
            ⍺≤ spMax: 1 s  (Skip2EOS ⍵) ⊣ s← Par (','/⍨ box∧1=⍺), sq,sq,⍨ ⍺⍴ sp
                      1 s  (Skip2EOS ⍵) ⊣ s← Par sCod, ⍕⍺ 
      }
    SFQ_APL← {          
        tryCF ← 0 '' ⍵
        w← ⍵↓⍨ 1+ p←   SpanSp 1↓⍵                                ⍝ Grab leading blanks
      w  M rb:         p SCommon w                             ⍝ Fast path: {}
      w NM cln:        tryCF                                   ⍝ Not { } or { :...[:] }? See if CF
        w← SkipCS 1↓w 
      w  M rb:         0 SCommon w                             ⍝ Allow degenerate { : } { :: }                                      
        o w← MOmega w↓⍨e← w M esc                              ⍝ esc ⍵ <==> ⍵
      ×≢o:             1 (Par sCod, o) (Skip2EOS w)    
      e:               tryCF           
        ok num← ⎕VFI w↑⍨ p←⎕D Span w 
      1≢⍥, ok:         tryCF                                   ⍝ Not exactly 1 valid number
        w← SkipCS p↓ w 
      w M rb:          num SCommon w 
                       tryCF                
    }
⍝ ---------------------------
⍝ Primary Executive Fns:  Analyse, Assemble 
    Analyse← {                                                 ⍝ Convert <fStr> to executable fields
      ×≢ff←⍬{  
        0=≢⍵: '⊂'{⊂⍺,⊃⍵}⍣ (sdOff∧1=≢⍺)⊢ ⍺                      ⍝ Done: →RETURN field (enclosed str.)
              isTF← ⍵ NM lb                                    ⍝ TF?
        isTF: w ∇⍨ ⍺, ⊂⍣(×≢tf)⊢ tf ⊣tf w← TF ⍵                 ⍝ Is TF. Proc TF and next
              isSF sf w←SFQ ⍵                                  ⍝ SF? Else CF.
        isSF: w ∇⍨ ⍺, ⊂⍣(×≢sf)⊢sf                              ⍝ Is SF. Proc SF and next
              w ∇⍨ ⍺, ⊂⍣(×≢cf)⊢cf ⊣ cf w← CF ⍵                 ⍝ Is CF. Proc CF and next
      }fStr: ⌽ff ⋄ ⊂'⊂⍬'                                       ⍝ Handle 0 fields (edge case)
    }
    Assemble← {                                                ⍝ Assemble code + needed defs 
          pfx←  '⌽',⍨ ∊ irt 1 box/ ovrCod chnCod boxCod ⊃⍨¨ mod<0 
      1=mod: '{',  pfx, (∊⍵), '}⍵⍵'
      0=mod: '{{', pfx, (∊⍵), '}', (T2Q fStr),',⍥⊆⍵}'
          (⊂'{{', pfx),  ⍵, ⊂'}', (T2Q 25∘Trunc fStr),',⍥⊆⍵}⍵'
    } 
⍝ ---------------------------
⍝⍝⍝ MAIN: 
⍝   Options and Variables (non-constants)
      (mod box) esc←(2↑⍺)(⊃'`',⍨2↓⍺)                           ⍝ Set/validate options 
      fStr←⊃⊆⍵                                                 ⍝ fStr: The format string (⍹0)
    ~String fStr:      Ê fStrÊ                                 ⍝       Must be simple char vec/scalars 
    mod(~∊) ¯2 ¯1 0 1: Ê opt0Ê                               
    box(~∊) 0 1:       Ê opt1Ê
    esc∊ lb sp cm:     Ê opt2Ê                                 ⍝ Invalid escape char?  
      irt←0                                                    ⍝ irt: include runtime code? See CF
      omIx←0                                                   ⍝ omIx: omega index. See MOmega 
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
⍝H          →  Horizontal Self-Documenting Expressions
⍝H             If a code expression {...} ends with a right arrow (→) preceded and/or followed by
⍝H             0 or more spaces (and an optional comment), it is treated as a horizontal 
⍝H             self-documenting code expression.
⍝H             That is, its value (on execution) will be preceded by the text of the code
⍝H             expression. That text will be followed by that same right arrow and spaces
⍝H             as input:
⍝H ⍎               ∆F '1. {⍪⍳2→}, 2. {⍪⍳2 → }.'
⍝H ⎕           1. ⍪⍳2→0, 2. ⍪⍳2 → 0. 
⍝H ⎕                  1           1 
⍝H          %  Vertical Self-Documenting Expressions
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
⍝H     d. Shortcuts (aliases): 
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
⍝H      d. Limited comments in Code Fields: 
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
⍝H 2. Space fields:  {}, {   }, { :5: }  { :⍹1: } { :⍹: } { :`⍵: } { :`⍵1: }  
⍝H     # spaces      0     3       5       1⊃⍵    next ⍵    next ⍵    1⊃⍵
⍝H    a. By example: a brace with 0 or more blanks, representing the # of blanks on output.
⍝H       a1. Braces with 1 or more blanks separate other fields.
⍝H           1 blank: { }, 2 blanks: {  }, etc.
⍝H       a2. Null Fields: brace with 0 blanks is a Null Space Field, useful for separating OTHER fields.
⍝H       ∘ Examples of space fields (with multiline text fields-- see below):
⍝H ⍎           ∆F 'a`⋄cow{}a`⋄bell'            ∆F 'a`⋄cow{ }a`⋄bell'
⍝H ⎕        a  a                            a   a
⍝H ⎕        cowbell                         cow bell
⍝H    b. By number: a number between colons (the trailing colon is optional) indicates the # of blanks on output.
⍝H          { :5: }    <== 5 blanks on output!
⍝H    c. By ⍹-expression: an expression ⍹2 between colons (:⍹2:) means
⍝H          take the value of (⎕IO+2⊃⍵) as the # of blanks on output.
⍝H       An expression of simple ⍹ between colons (:⍹:) means: 
⍝H          increase the index of the last ⍵ expression to the left (or (⎕IO+1⊃⍨⍵) as the # of blanks on output.
⍝H       These parenthesized expressions are the same in this context:
⍝H ⍎            a b c← (∆F'{:5:}') (∆F'{:⍹1:}' 5) (∆F'{:`⍵1:}' 5)
⍝H ⍎            (a≡b)∧(b≡c)
⍝H ⎕         1
⍝H     ∘ Comments are NOT allowed in space fields.
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
