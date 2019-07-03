∆PRE←{⎕IO ⎕ML←0 1
    ⍝ Alternative to ∆FIX...

    ⍺←0 ⋄ DEBUG←⍺   ⍝ If 1, the preproc file created __<name>__ is not deleted.
    {
        1=0⊃⍵:(⎕EX⍣(~DEBUG)⊣2⊃⍵)⊢⍵{' '=1↑0⍴⍵:⍵
            11 ⎕SIGNAL⍨'preprocessor error fixing ',(1⊃⍺),' on line ',⍕2⊃⍺
        }⎕FX⍎2⊃⍵
        _←⎕EX⍣(~DEBUG)⊣2⊃⍵
        11 ⎕SIGNAL⍨'preprocessor error  in ',(1⊃⍵),' on line ',⍕(2⊃⍵)
    }{~3 4∊⍨(0⊃⎕RSI).⎕NC ⍵:11 ⎕SIGNAL⍨'preproc: right arg must be funNm of existing fun or op'

        NL←⎕UCS 10 ⋄ PASSTHRU←⎕UCS 1                      ⍝ PASSTHRU as 1st char in vector signals
                                                          ⍝ a line to pass through to target user function
        ∆FLD←{
            ns def←2↑⍺,⊂''
            ' '=1↑0⍴⍵:⍺ ∇ ns.Names⍳⊂⍵
            ⍵=0:ns.Match                                  ⍝ Fast way to get whole match
            ⍵≥≢ns.Lengths:def                             ⍝ Field not defined AT ALL → ''
            ns.Lengths[⍵]=¯1:def                          ⍝ Defined field, but not used HERE (within this submatch) → ''
            ns.(Lengths[⍵]↑Offsets[⍵]↓Block)              ⍝ Simple match
        }
        ∆MAP←{  '⍎\w+' ⎕R  {⍎1↓⍵ ∆FLD 0}⊣⍵}

        ∆QT←{'''',⍵,''''}
        ∆QTX←{∆QT ⍵/⍨1+⍵=''''}                            ⍝ Quote each line, "escaping" each quote char.
        h2d←{                                             ⍝ Decimal from hexadecimal
            11::'h2d: number too large'⎕SIGNAL 11         ⍝ number too big.
            16⊥16|a⍳⍵∩a←'0123456789abcdef0123456789ABCDEF'⍝ Permissive-- ignores non-hex chars!
        }


      ⍝ Append literal strings ⍵:SV.                      ⍝ res@B(←⍺) ← ⍺@B←1 appendRaw ⍵:SV
        appendRaw←{⍺←1 ⋄ ⍺⊣dataFinal,←⍵}
      ⍝ Append quoted string                              ⍝ res@B ←  ⍺@B←1 appendCond ⍵:SV
        appendCond←{ PASSTHRU=1↑⍵:appendRaw⊂'⍙,←⊂',∆QTX 1↓⍵  ⋄   0 appendRaw⊂⍵ }¨
      ⍝ Pad str ⍵ to at least ⍺ (15) chars.
        padx←{⍺←15 ⋄ ⍺<≢⍵:⍵ ⋄ ⍺↑⍵}
      ⍝ get function '⍵' or its char. source '⍵_src', if defined.
        getDataIn←{
            0=⎕NC srcNm:{(0⊃⎕RSI,#)⍎srcNm,'∘←⍵'}⎕NR funNm
            ⎕←'For fn/op "',funNm,'" has a source file "',srcNm,'"'
            in←1↑' '~⍨⍞↓⍨≢⍞←'Use [s] source to recompile, [f] function body, or [q] quit? [source] '
            in∊'q':909 ⎕SIGNAL⍨'preproc terminated by user for fun/op "',funNm,'"'
            in∊'s ':{
                0::909 ⎕SIGNAL⍨'preproc: user source is not valid'
                3 4∊⍨⎕NC ⍵:⎕NR ⍵
                ↓⍣(2≠|≡∆)⊣∆←⎕OR ⍵
            }srcNm
            in∊'f':⎕NR funNm
        }

      ⍝ MACRO (NAME) PROCESSING
      ⍝ FUNCTIONS
        put←{n v←⍵ ⋄ n~←' ' ⋄ names,⍨←⊂n ⋄ vals,⍨←⊂v ⋄ 1:⍵}  ⍝ add name val
        get←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ p⊃vals}
        del←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ names vals⊢←(⊂p≠⍳≢names)/¨names vals ⋄ n}
        def←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:0 ⋄ 1}
        expand←{
             else←⊢
           ⍝ Concise variant on dfns:to, allowing start [incr] to end
           ⍝     1 1.5 to 5     →   1 1.5 2 2.5 3 3.5 4 4.5 5
           ⍝ expanded to allow simply (homogeneous) Unicode chars
           ⍝     'ac' to 'g'    →   'aceg'
            ∆TO←{⎕IO←0 ⋄ 0=80|⎕DR ⍬⍴⍺:⎕UCS⊃∇/⎕UCS¨⍺ ⍵ ⋄ f s←1 ¯1×-\2↑⍺,⍺+×⍵-⍺ ⋄ f+s×⍳0⌈1+⌊(⍵-f)÷s+s=0}
            ∆TOcode←'{⎕IO←0 ⋄ 0=80|⎕DR ⍬⍴⍺:⎕UCS⊃∇/⎕UCS¨⍺ ⍵ ⋄ f s←1 ¯1×-\2↑⍺,⍺+×⍵-⍺ ⋄ f+s×⍳0⌈1+⌊(⍵-f)÷s+s=0}'
           str←⍵
           str←{⍺←MAX_EXPAND       ⍝ If 0, macros including hex, bigInt, etc. are NOT expanded!!!
               strIn←str←⍵
               0≥⍺:⍵
             ⍝ Match/Expand...
             ⍝ [1] pLNe: long names,
              str←pQe pCe pLNe ⎕R{
              f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊

               case 2:get f0
               else f0
               }⍠'UCP' 1⊣str

              ⍝ [2] pSNe: short names (even within found long names)
              ⍝     pIe: Hexadecimals and bigInts
              cQe cCe cSNe cIe←0 1 2 3
              str←pQe pCe pSNe pIe ⎕R{
                 f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊

                 case cIe:{⍵∊'xX':h2d f0 ⋄ 'BI(',(∆QT ¯1↓f0),')'}¯1↑f0
                 case cSNe:get f0
                 else f0
                }⍠'UCP' 1⊣str
            str≢strIn: (⍺-1) ∇ str    ⍝ expand is recursive, but only initial MAX_EXPAND times.
            str
          }str
         ⍝  Ellipses - constants (pE1e) and variable (pE2e)
         ⍝  Check only after all substitutions, so ellipses with macros that resolve to numeric constants
         ⍝  are optimized.
            str←pQe pCe pE1e pE2e ⎕R{
              case←⍵.PatternNum∘∊
                case 0 1: ⍵ ∆FLD 0 ⋄
                case 2: ⍕⍎f1,' ∆TO ',f2⊣f1 f2←⍵ ∆FLD¨1 2    ⍝  num [num] .. num
                case 3: ∆TOcode                             ⍝  .. preceded or followed by non-constants⋄
            }⍠'UCP' 1⊣str
            str
        }

      ⍝ passCommment:   S ←  passComment ⍵:S, where ⍵ starts with /[⍝ ]/
      ⍝    Send (commented ⍵) through to user function, removing "extra" [⍝ ] symbols at start
      ⍝    Each returned commentis marked with a lightbulb...
        passComment←{⍺←'⍝ ' ⋄ PASSTHRU,'⍝💡 ',⍵↓⍨+/∧\⍵∊⍺}   ⍝ Trim '⍝ ' chars, prefix with '⍝💡 '

      ⍝ -------------------------------------------------------------------------
      ⍝ PATTERNS
      ⍝ [1] DEFINITIONS
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------

      ⍝ -------------------------------------------------------------------------
      ⍝ [1] DEFINITIONS
      ⍝ -------------------------------------------------------------------------
        _CTR_←0 ⋄ patternList←⍬
        reg←{⍺←'(?xi)' ⋄ patternList,←⊂∆MAP ⍺,⍵ ⋄ (_CTR_+←1)⊢_CTR_}
        ⋄ ppBegin←'^[⍝\h]* :: '
        cIFDEF←reg'    ⍎ppBegin (IFN?DEF)                    \h+(.*)                     $'
        cIF_STMT←reg'  ⍎ppBegin (IF\h+ | ELSE(?:IF\h+)? | END(?:IF(?:N?DEF)?)?) \b (.*)  $'
        ⋄ ppName←'\h* ([^←]+) \h*'
        ⋄ ppArr← '(?:←\h*(.*))?'
        cDEF←reg'     ⍎ppBegin  DEF    ⍎ppName   ⍎ppArr    $'
        cCOND←reg'    ⍎ppBegin  COND   ⍎ppName   ⍎ppArr    $'
        cUNDEF←reg'   ⍎ppBegin  UNDEF  ⍎ppName             $'
        cCODE←reg'    ⍎ppBegin  CODE   \h*        (.*)     $'
        cOTHER←reg'   ^                            .*      $'

      ⍝ patterns for expand fn
        pQe←'(?x)    (''[^'']*'')+'
        pCe←'(?x)      ⍝\s*$'
        ppNum ← ' (?: ¯?  (?: \d+ (?: \.\d* )? | \.\d+ ) (?: [eE]¯?\d+ )?  )' ⍝ Non-complex numbers...
        pE1e←∆MAP  '(?x)  ( ⍎ppNum (?: \h+ ⍎ppNum)* ) \h* \.{2,} \h* ((?1))'
        pE2e←'(?x)   \.{2,}'

      ⍝ names include ⎕WA, :IF
      ⍝ pLNe Long names are of the form #.a or a.b.c
      ⍝ pSNe Short names are of the form a or b or c in a.b.c
      ⍝ pIe: Allows both bigInt format and hex format
      ⍝       This is permissive (allows illegal options to be handled by APL),
      ⍝       but also VALID bigInts like 12.34E10 which is equiv to 123400000000
      ⍝       Exponents are invalid for hexadecimals, because the exponential range
      ⍝       is not defined/allowed.
        pIe←'(?xi)  (?<![\dA-F\.])  ¯? [\.\d]  (?: [\d\.]* (?:E\d+)? I | [\dA-F]* X)'
        pLNe←'(?x)   [⎕:]?([\pL∆⍙_][\pL∆⍙_0-9]+)(\.(?1))*'
        pSNe←'(?x)  [⎕:]?([\pL∆⍙_][\pL∆⍙_0-9]*)'

      ⍝ -------------------------------------------------------------------------
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------
        processPatterns←{
            f0 f1 f2←⍵ ∆FLD¨0 1 2
            case←⍵.PatternNum∘∊
            case cOTHER:PASSTHRU,expand f0
          ⍝ ：：IFDEF name
          ⍝ ：：END[IF[DEF]]
            case cIFDEF:{
                not←'~'↑⍨1∊'nN'∊f1
                ':IF ',not,⍕def f2
            }0
          ⍝ ：：IF cond
          ⍝ ：：ELSEIF cond
          ⍝ ：：ELSE
          ⍝ ：：END[IF]
            case cIF_STMT:{                        ⍝ IF, ELSEIF, ELSE, END, ENDIF, ENDIFDEF
                ':',f1,expand f2
            }0
          ⍝ ：：DEF name ← val    ==>  name ← 'val'
          ⍝ ：：DEF name          ==>  name ← 'name'
          ⍝ ：：DEF name ← ⊢      ==>  name ← '⊢'     Make name a NOP
          ⍝ ：：DEF name ← ⍝...      ==>  name ← '⍝...'
          ⍝ Define name as val, unconditionally.
            case cDEF:{
                f2←f1{0=≢⍵:∆QT ⍺ ⋄ expand ⍵}f2
                _←put f1 f2
                ⎕←' ',(padx f1),' ← ',f2
                passComment f0
            }0
          ⍝ ：：COND name ← val      ==>  name ← 'val'
          ⍝ ：：COND name            ==>  name ← 'name'
          ⍝  etc.
          ⍝ Set name to val only if name not already defined.
            case cCOND:{
                defd ←def f1
                status←'  ',defd⊃'(ACTIVE)' '(INACTIVE)'
                ⎕←'  ',(padx f1),' ← ',f2,status
                ln←passComment f0,status
                defd:ln
                f2←f1{0=≢⍵:∆QT ⍺ ⋄ expand ⍵}f2
                _←put f1 f2
                ln
            }0
          ⍝ ：：CODE code string
          ⍝ Pass through code to the preprocessor phase (to pass to user fn, simply enter it!!!)
            case cCODE:{
                ln←f1,'⍝ ::CODE ...'
                ln,NL,passComment f0
            }0
          ⍝ ：：UNSET name  ==> shadow 'name'
          ⍝ Warns if <name> was not set!
            case cUNDEF{
                _←del f1⊣{def ⍵:'' ⋄ ⊢⎕←'UNDEFining an undefined name: ',⍵}f1
                ⎕←' ',(padx f1),'   UNDEF'
                passComment f0
            }0
        }

      ⍝ --------------------------------------------------------------------------------
      ⍝ EXECUTIVE
      ⍝ --------------------------------------------------------------------------------
        MAX_EXPAND←5  ⍝ Maximum times to expand macros (if 0, none are expanded!)
        funNm←⍵
        tmpNm←'__',funNm,'__'
        srcNm←funNm,'_src'

        dataIn←getDataIn 0
        dataFinal←⍬

        _←appendRaw('⍙←',tmpNm)('⍝ Preprocessor for ',funNm)'⍙←⍬'

        names←vals←⍬
        _←appendCond patternList ⎕R processPatterns⍠'UCP' 1⊣dataIn
        fx∆←⎕FX dataFinal
        ' '=1↑0⍴fx∆:1 funNm fx∆   ⍝ f∆ usually is tmpNm
        0 funNm fx∆
    }⍵
⍝∇⍣§./preproc.dyalog§0§ 2019 6 28 21 17 38 542 §dòéMØå§0
}
