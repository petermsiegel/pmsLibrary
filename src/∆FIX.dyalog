∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝ Syntax is as for ⎕FIX, except for 
  ⍝    a) "secret" options:
  ⍝       -nof[ix]  Return the translated lines without then ⎕FIXing them.
  ⍝       -e[dit]   Enter an editing environment to test various code sequences and 
  ⍝                 view the translated lines. Creates:
  ⍝                 ∘ a char var #.FIX_FN_SRC with the current test code, and
  ⍝                 ∘ an executable #.FIX_FN, if successfully ∆FIXed.
  ⍝    b) tolerates a missing :file// prefix (required by ⎕FIX) when ∆FIX's right arg ⍵ is a single vector fileid.

    ⎕IO ⎕ML←0 1    
    DEBUG←1 ⋄   DO_MAINSCAN DO_CONTROLSCAN←1 1 
  ⍝ For CR_HIDDEN, see also \x01 in Pattern Defs (below).
    SQ DQ←'''"' ⋄ CR CR_HIDDEN←⎕UCS 13 01 ⋄  CR_VISIBLE←'◈'  
    CALR←0⊃⎕RSI
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
  ⍝ Add CR to last line to make Regex patterns simpler...
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }

  ⍝+--------------------------------------------------+
  ⍝ BEGIN Pattern Definitions   (organized by scan)   +
  ⍝+--------------------------------------------------+
  ⍝ Pattern-related Utilities                         +
  ⍝+--------------------------------------------------+
    GenBracePat←{⎕IO←0 ⋄ ⍺←⎕A[,⍉26⊥⍣¯1⊢ ⎕UCS ⍵] ⋄ Nm←⍺  ⍝ ⍺ a generated unique name based on ⍵
          Lb Rb←⍵,⍨¨⊂'\\'                     
          pM←'(?: (?J) (?<Nm> Lb  (?> [^LbRb''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&Nm)* )+ Rb))'~' '
          'Nm' 'Lb' 'Rb'⎕R Nm Lb Rb⊣pM
    }
    ∆Anchor←{'(?xi) ^',⍵,'$\r'}
  ⍝+--------------------------------------------------+
  ⍝ A. MULTIPLE SCANS                                 +
  ⍝+--------------------------------------------------+
    pDots  ←'(?:\.{2,3}|…)\h*(⍝[^\r\x01]*)?\r\h*'
    pDQ    ← '("[^"]*")+'
    pSQ    ← '(?:''[^''\r\x01]*'')+' 
    pDQSQ  ← pDQ,'|',pSQ
    pCom   ←'⍝[^\r\x01]*$' 
    pBrak  ←GenBracePat'{}'
  ⍝+--------------------------------------------------+
  ⍝ B.CONTROL SCANS                                   +
  ⍝+--------------------------------------------------+
  ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
  ⍝ These are required to match a SINGLE line each in its entirety OR a line continued explicitly using dot format.
  ⍝ BUG: Does not allow continuation via parens, braces, double quotes, etc.

  ⍝ control CR Family: Multi-line dfns and strings on ::directives. 
  ⍝ \r is carriage return, \x01 is the faux carriage return, 
  ⍝ ◈ is a visible rendering for display purposes distinct from ⋄.
    pCrFamily← '\r\z'  '[\r\x01]'  ⋄ actCrFamily←  '\0' CR_VISIBLE
  ⍝⍝⍝ NB. Changed ?: to ?> here  ↓            
    pMULTI_NOCOM ←∊'(?x) (?<NOC> (?> [^\{⍝''"\r]+ | (?:''[^'']*'')+ | (?:"[^"]*")+ | ' pBrak            ') (?&NOC)*)'
    pMULTI_COM   ←∊'(?x) (?<ANY> (?> [^\{⍝''"\r]+ | (?:''[^'']*'')+ | (?:"[^"]*")+ | ' pBrak ' | ' pCom ') (?&ANY)*)'
    pIf          ← ∆Anchor'\h* :: IF         \b \h* (\N+) '
    pElIf        ← ∆Anchor'\h* :: ELSEIF     \b \h* (\N+) '
    pEl          ← ∆Anchor'\h* :: ELSE       \b      \h*  '
    pEndIf       ← ∆Anchor'\h* :: END(?:IF)? \b      \h*  '
  ⍝ For ::DEF (define) of the form  ::DEF name ← value, match after the control word:
  ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
  ⍝ where name* is a sequence of chars except spaces, ←, or CR.
  ⍝ The value will be enclosed in parentheses, limiting surprising side effects.
    pDef1        ← ∆Anchor'\h* :: def  \h+ ((?>[^\h←\r]+)) \h* ← \h*  (',pMULTI_NOCOM,'+|) \N* ' 
  ⍝ ::EVAL or synonym ::DEFE 
  ⍝ For ::EVAL (evaluate string value) of form ::EVAL name ← value, match after the control word:
  ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
  ⍝ where name* is a sequence of chars except spaces, ←, or CR. 
  ⍝ The value stored will be determined in the calling namespace CALR as
  ⍝     CALR ⍎ value
    pEvl         ← ∆Anchor'\h* :: (?:eval|defe) \h+ ((?>[^\h←\r]+)) \h* ← \h? (',pMULTI_NOCOM,'+|) \N* '   
  ⍝ For ::DEFL (literal) of the form ::DEFL name ← value, match after the ctl word: 
  ⍝      blanks, word*, blanks, ← optional blank, value*
  ⍝ where word* defined as above and value* includes everything up to the EOL, including leading and internal blanks.
  ⍝ The value will not be enclosed in parentheses.
    pDefL        ← ∆Anchor'\h* :: defl \h+ ((?>[^\h←\r]+)) \h* ← \h? (',pMULTI_COM,'|) '  
  ⍝ For ::DEF of forms:   
  ⍝     ::DEF name    OR    ::def name value  
  ⍝ we match after the ctl word:
  ⍝ I.     blanks, name*  which is translated to: ::DEF name1* ← name1*
  ⍝    where name* and name1* defined as name* above, name1* the same in both cases.
  ⍝    This is equivalent to undefining name*, i.e. replacing it with itself.
  ⍝ II.    blanks, name*, blanks, value
  ⍝    where name* as above and value* consists of all text to the end of the line, excluding leading blanks.
  ⍝    This is equivalent to ::def name ← value above.
    pDef2       ← ∆Anchor'\h* :: (?:def) \h+ ((?>[^\h←\r]+)) \h*? ( [^\h\r]* )'
  ⍝ :DEF, :DEFL (literal), :EVAL (:DEFE, def and eval)  are errors.
    pErr        ← ∆Anchor'\h* :(def[el]?|eval) \b \N* '
    pDebug      ← ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
    pC_UCmd     ← ∆Anchor '\h*::(\]{1,2})\h*(\N+)'            ⍝ ::]user_commands or  ::]var←user_commands
    pOther      ← ∆Anchor'\N*' 
  ⍝+--------------------------------------------------+
  ⍝ C. MAIN SCAN PATTERNS   / ATOM SCAN PATTERNS      +  
  ⍝+--------------------------------------------------+
    pSysDef     ←  ∆Anchor'^::SysDefø \h ([^←]+?) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
    pUCmd       ← '^\h*(\]{1,2})\h*(\N+)$'                    ⍝ ]user_commands or  ]var←user_commands
    pDebug      ← ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
    pTrpQ       ← '"""\h*\R(.*?)\R(\h*)"""([a-z]*)'    ⋄  pDQPlus ← '(?i)',pDQ,'([a-z]*)'
    pSkip       ← pSQ,'|',pCom                         ⍝  pDots   ← See Above
    pParen      ← GenBracePat '()'                     ⋄  pWord   ← '[\w∆⍙_#.⎕]+'
    pPtr        ← ∊'(?ix) \$ \h* (' pParen '|' pBrak '|' pWord ')'
    _pHMID      ← '( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
  ⍝ Here-strings and Multiline ("Here-string"-style) comments 
    pHere       ← ∊'(?x)       ::: \h*   '_pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
    pHCom       ← ∆Anchor∊'\h* ::: \h* ⍝ '_pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '
    pNumBase    ← '(?xi) 0 [xbo] [\w_]+'
    pNum        ← '(?xi) (?<!\d)   (¯? (?: \d\w+ (?: \.\w* )? | \.\w+ ) )  (j (?1))?'
    pMacro      ← {
        APL_LET1←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜÌÍÎÏÐÇÑ∆⍙_#'
        _pVarName← '(?i)[',APL_LET1,'][⎕.\d',APL_LET1,']*'
        _pMac←'(?:[]⎕]|:{1,2}|)',_pVarName     ⍝ OK: ::NAME, ⎕NAME, ]NAME
        _pMac
    }⍬
  ⍝ Atomlist Pattern:    (` | ``) item, where item: word | number | "quote" | 'quote'
  ⍝                       `: Ensures atom list is always a vector, no matter how many atoms.
  ⍝                      ``: Encodes a single atom as a scalar; multiple atoms as a list. E.g. for ⎕NC ``item.
  ⍝                      Each char atom will be encoded as an enclosed vector (even if an APL scalar `x).
  ⍝                      Each numeric atom will be encoded as a simple scalar. 
  ⍝ Uses 1: To allow objects to be defined using ::DEFs, yet presented to fns and ops as quoted strings.
  ⍝          ::IF format=='in_color'
  ⍝               ::DEF MYFUN← GetColors
  ⍝          ::ELSE
  ⍝               ::DEF MYFUN← GetBlackWhite
  ⍝          ::ENDIF 
  ⍝          ⎕FX ``MYFUN
  ⍝ Uses 2: To allow enumerations or word-based classes.
  ⍝         colors←`red orange yellow green
  ⍝         mycolor←`red 
  ⍝         :IF mycolor ∊ colors  ⍝ Is my color valid?
  ⍝         ...                                         
  ⍝ pAtomVec: "[\w∆⍙_#\.⎕¯]+" includes pWord chars plus '¯'
    pAtomVec     ← ∊'(?x) (`{1,2})  \h* ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ )'          

  ⍝+--------------------------------------------------+
  ⍝ END Pattern Definitions                           +
  ⍝+--------------------------------------------------+

  ⍝+--------------------------------------------------+
  ⍝ Utilities, Miscellaneous                          +
  ⍝+--------------------------------------------------+
    DTB←{⍵↓⍨-+/∧\' '=⌽⍵}                           ⍝ Delete trailing blanks from one line
    DLB←{⍵↓⍨ +/∧\' '= ⍵}                           ⍝ Delete leading blanks...
    AddPar← {'(',⍵,')'}
    DblSQ←  {⍺←0 ⋄ s←⍵/⍨1+⍵=SQ ⋄ ⍺=0: s ⋄ SQ,s,SQ }  ⍝ Double single quotes. If ⍺=1, add outer quotes.
    UnDQ←{ s/⍨~(2⍴DQ)⍷s←d↓⍵↓⍨-d←DQ=1↑⍵ } ⍝ Remove surrounding DQs and APL-escaped DQs. Double SQs   
  ⍝ ∆DEC: 
  ⍝ Read hex, binary, octal numbers (e.g. 0x09DF, 0b0111, and 0o0137), converting to decimal.
  ⍝ Converts up to 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF (28 hex digits) as integer strings.
  ⍝ Returns right arg (⍵) if  
  ⍝      (a) not a known base (b|o|x) (b: 2, o: 8, x: 16); (b) number is negative, or (c) digits are out of range,
  ⍝ or if it can't represent in an integer of 34 decimal digits...
    ∆DEC←{⎕PP ⎕FR←34 1287  ⍝ Ensures largest # of decimal digits.
        canon←⎕C ⍵ 
        0=base←2 8 16 0['box'⍳1↑1↓canon]: ⍵    ⋄ '0'≠⊃canon: ⍵
        res←(base↑'0123456789abcdef')⍳2↓canon  ⋄ ∨/res≥base: ⍵
        'E'∊res←⍕base⊥res: ⍵ ⋄ res
    }
  ⍝ SaveRunTime:  SaveRunTime ['FORCE' | 'NOFORCE']
  ⍝ Save Run-time Utilities in ⎕SE if not already...
  ⍝     ⎕SE.⍙PTR
  ⍝ CALR.⎕PATH←1↓∊' ',¨∪'⎕SE',' '(≠⊆⊢)CALR.⎕PATH
    SaveRunTime←{utils utype←↓⍉↑('⍙PTR' 4) ('∆TO' 3) 
        (~DEBUG)∧(⍵≡'FORCE')∧utype∧.=⎕SE.⎕NC ↑utils: 0 
        2/⍨~DEBUG:: 11 ⎕SIGNAL⍨'∆FIX: Unable to set utilities: ⎕SE.(',utils,')'
      ⍝  Runtime Ptr. See $ Ptr prefix: ${operand}, $(operand), $operand_name...
      ⍝     ptr← ⍺⍺:operand ⎕SE.⍙PTR ⍵:0
      ⍝          ⍺⍺:operand: Function to "turn into" a pointer, accessed via ptr.Run
      ⍝           ⍵:debug:   If 0, display form is '[⍙PTR]' (fast).
      ⍝                      If 1, display form is an abridged version of the nested 
      ⍝                      representation of <operand>, up to 30 chars (slower).
      ⍝
      ⍝ Was: ⎕SE.⍙PTR←{(ns←⎕NS '').Run←⍺⍺ ⋄ ns⊣ns.⎕DF '[⍙PTR]'}
        ⎕SE.⍙PTR←{ ⍝ Place in ⎕SE, with CALR as ⎕THIS namespace
            0::'$ POINTER DOMAIN ERROR'⎕SIGNAL 11 
            MAXL←30
            (ns←⎕NS'').Run←⍺⍺ ⋄ _←ns.⎕FX 'r←Exec' 'r←Run ⍬'
            0=⍵: ns⊣ns.⎕DF'[$⍙PTR]'
            Fit←MAXL∘{⍺>≢⍵:⍵ ⋄ '⋯',⍨⍵↑⍨⍺-1}    
            Shrink←{'^Run←' '\{⋄' '⋄\}' '\h+⋄\h+'⎕R'' '{' '}' '⋄'⊣¯1↓∊'⋄',⍨¨⍵} 
            Dlb←{⍵↓⍨+/∧\' '=⍵}¨  ⋄ Sane←{0<≢⍵: ⍵ ⋄ err∘}     
            ns⊣ns.⎕DF '[$', (Fit Shrink Dlb Sane⊆ns.⎕NR 'Run'), ']'
        }
        ⍝ range ← start [next]  ∆TO  end [step]   
        ⍝         start: starting numeric value.
        ⍝         next: first element after <start> used to calculate <step>. 
        ⍝               If omitted*, next is (start+×end-start), unless <step> is specified.
        ⍝         end:  ending numeric value.
        ⍝         step: in-/decrement start first value to next. 
        ⍝               If omitted*, (×end-start) is assumed, unless <next> is specified. 
        ⍝               The sign of <step> passed is ignored and the signum (×end-start) is used.
        ⍝ ________________________________
        ⍝ * Specifying both <next> and <step> is an error.  
        ⍝   If next is specified, the actual step is (×end-start)×|next-start.    
        ⎕SE.∆TO←{⎕IO←0
            eTo←'⎕TO: range ← start [next] ∆TO end [step=1]. Do not include both ¨next¨ and ¨step¨.'
            start end←1↑¨⍺ ⍵  ⋄ 2∧.≤≢¨⍺ ⍵: eTo ⎕SIGNAL 11  
            step←(×end-start)×|1↑1↓⍵,(start-1↑1↓⍺)
            start+step×⍳0⌈1+⌊(end-start)÷step+step=0     
        }
        1
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via Fmt2Code below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{⍺←0   ⍝ If 1, Edit for input...
    
      ⍝ ---- MACROS
        mâc.K←mâc.V←⍬ ⊣  mâc←⎕NS ''
        MacScan←{
          ⍺←5    ⍝ Max of total times to scan entire line (prevents runaway replacements)
          ⍺≤0: ⍵  
          pList←pSQ pCom pDQ pMacro
                iSQ iCom iDQ iMacro←⍳≢pList
          str←pList ⎕R { F0← ⍵.Match ⋄ CASE←⍵.PatternNum∘∊ 
              CASE iMacro: MacGet F0 ⋄ CASE iDQ: SQ,SQ,⍨UnDQ F0  ⋄ F0 } ⍵
          ⍵≢str: (⍺-1) ∇ str ⋄ str        ⍝ If any changes, scan again up to <⍺> times.
        }
      ⍝ Note: macro names whose last component starts with ⎕ or :  are case-insensitive.
      ⍝       E.g. ⎕NaMe, :myIF, or a.b.⎕NaMe 
      ⍝ val ← ⍙K key, key: a string.
        ⍙K←{ ~'⎕:'∊⍨⊃⊃⌽k←'.'(≠⊆⊢)⍵ :⍵  ⋄ k⊣(⊃⌽k)←⎕C ⊃k }  ⍝ Case ignored for ⎕xxx and :xxx
      ⍝ val ← key (flag _MacSet) val
      ⍝   flag=0:  Sets macro <key> to have value <val>, a string.         See :DEF
      ⍝   flag=1:  Sets macro <key> to have value '(',<val>,')', a string. See :DEFL
      ⍝            Special case: If <val> is a nullstring, value is <val> alone (no parentheses).
        DQScan←{
           pDQPlus pSQ pCom ⎕R { 
              F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}  
              0≠⍵.PatternNum: F 0            ⍝ Skip...
              (F 2) (0 Fmt2Code) UnDQ F 1    ⍝ Convert double quotes.
            }⍠reOPTS⊣⍵
        }
      ⍝ ⍺ (⍺⍺ _MacSet) ⍵. Set key <⍺> to have value <⍵>, or ⍺ if key <⍺> doesn't exit.
      ⍝ If ⍺≡⍵, delete key <⍺>.
      ⍝ If ⍺⍺=1, put ⍵ in parens, unless ⍵ is a non-simple "expression" 
      ⍝          i.e. neither an APL user/system name, number, or null.
      ⍝ NonSimple: returns 0 for ⍵: FrEd, #.JaCk, FrEd.Jack, ⎕SE, 12345J45 123.45J¯4 ⎕IO 
      ⍝                             "Fred Jack"  "1 2"   "3 PI R"
      ⍝            returns 1 for ⍵: "",  "FRED+JACK", ":DIRECTIVE"
        NonSimple←{¯1=⎕NC ⊂'X',⍵~'⎕#.¯ '}  
        _MacSet←{ 
            val←AddPar⍣(⍺⍺∧(NonSimple ⍵))⊣⍵ 
            nKV←≢mâc.K ⋄ p←mâc.K⍳⊂key←⍙K ⍺       
            p<nKV: val⊣ { ⍵: mâc.V[p]←⊂val ⋄ 1: mâc.(K V)/⍨¨←⊂p≠⍳nKV }⍺≢⍵
            ⍺≡⍵: val ⋄ mâc.(K V),← ⊂¨key val ⋄   val
        }  
        MacGet←{0=≢⍵: ⍵ ⋄ p←mâc.K⍳⊂⍙K ⍵ ⋄ p<≢mâc.K: p⊃mâc.V ⋄ ⍵ }
      ⍝ ------END MACROS

      ⍝ Fmt2Code: ⍺: 
      ⍝     Convert possibly multiline strings to the requested format and return as an APL code string.
      ⍝ Output format: options '[clsvm]'.   
      ⍝    'r' carriage returns for linends (def); 'l' LF for linends; 's' spaces replace linends 
      ⍝    'v' vector of vectors;    'm' APL matrix;    
      ⍝ Escape option. Works with any one above. 
      ⍝    'e' backslash (\) escape followed by eol => single space. Otherwise, as above.
      ⍝    'c' string is a comment to treat in toto as a blank.
      ⍝ indent: >0, use as is for indent of lines; <0, use indent of left-most line for indent; 0, as is.
        Fmt2Code←{ ⍺←'' ⋄ indent←⍺⍺  
          ⍝ options--   o1 (options1) (r|l|s|v|m); o2 (options2): [ec]; od(efault): 'r'.
            o1 o2 od ←'rlsvm' 'ec' 'r'  ⋄ o←(o1{1∊⍵∊⍺⍺: ⍵ ⋄ ⍵⍵,⍵}od) ⎕C ⍺
            R L S V M E C←o∊⍨∊o1 o2
            0≠≢err←o~∊o1 o2: 11 ⎕SIGNAL⍨'∆FIX: Invalid option "',err,'"' 
            C: ' '
            SlashScan←  { '\\(\r|$)'⎕R' '⍠reOPTS⊣⍵ }  ⍝ backsl + EOL  => space given e (escape) mode.
            S2Vv←      { 2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵ }                        
            TrimL←     { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\' '=↑⍵  ⋄  ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺ }   
            FormatPerOpt← {
             ⍝  0=≢⍵: 2⍴SQ
              AddSQ←SQ∘,∘⊢,∘SQ 
              V∨M: (M/'↑') ,¯1↓∊' ',⍨∘AddSQ¨ ⍵ ⋄  S: AddSQ 1↓∊' ',¨⍵ 
              R∨L: AddSQ ∊{⍺,nlc,⍵}/⍵ ⊣ nlc←SQ,',(⎕UCS ',(⍕R⊃10 13 ),'),',SQ  
              ∘Unreachable∘  
            }
            0=≢⍵: 2⍴SQ
            nl←≢lines←S2Vv ⍵  ⍝ Don't add parens, if just one line...
            AddPar⍣((nl>1)∧~V)⊣FormatPerOpt (SlashScan⍣E)DblSQ¨ indent∘TrimL lines
        }
      ⍝ pat ← GenBracePat ⍵, where ⍵ is a pair of braces: ⍵='()', '[]', or '{}'.  
      ⍝ Generates a pattern to match unquoted balanced braces across newlines, skipping
      ⍝   (a) comments to the end of the current line, (b) quoted strings (single or double).
      ⍝ Uses a name based on the braces and the ?J option, so PCRE functions properly[*].
      ⍝    * Any repeat definitions of these names MUST be identical.
    
      ⍝ Eval2Str: Execute and return a string rep.
        Eval2Str←CALR∘{⎕FR ⎕PP←1287 34 ⋄ 0:: ⍵,' ∘err∘'
            res2←⎕FMT res←⍺⍎'⋄' DFnScanOut ⍵ ⋄ 0≠80|⎕DR res: 1↓∊CR,res2 ⋄  ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
        }
      ⍝ Eval2Bool: Execute and return 1 True, 0 False, ¯1 Error.
        Eval2Bool←CALR∘{0:: ¯1  ⋄ (,0)≡v←,⍺⍎'⋄' DFnScanOut ⍵: 0 ⋄  (0≠≢v)}    

        ControlScan←{ 
            ~DO_CONTROLSCAN: ⍵
            controlScanPats←pIf pElIf pEl pEndIf pDef1 pDef2 pEvl pDefL pErr pDebug pC_UCmd pOther
                            iIf iElIf iEl iEndIf iDef1 iDef2 iEvl iDefL iErr iDebug iC_UCmd iOther←⍳≢controlScanPats
            SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇' '↓' '↑'
            Poke←{ ⍵⊣(⊃⌽stack)←⍵ ((⍵=1)∨⊃⌽⊃⌽stack)}
            Push←{ ⍵⊣stack,←⊂⍵ (⍵=1)}
            Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 ⋄ 11 ⎕SIGNAL⍨'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0 }  
            Peek←{(⊃⌽⊃⌽stack)⊃⍵ 1}
            CurStateIs←{⍵∊⍨⊃⊃⌽stack}
            stack←,⊂ON ON
            ControlScanAction←{
                  F←⍵.{0:: '' ⋄ Lengths[⍵]↑Offsets[⍵]↓Block}
                  CASE←⍵.PatternNum∘∊ 
                  PassState←{ ⍺←0 ⋄ ~DEBUG: ''  
                    ⍝ ControlScan: Keep final CR; otherwise: CR and CR_HIDDEN become display_CR 
                    ⍝ See:  pCrFamily,  actCrFamily above.
                     '⍝', (STATES⊃⍨1+⊃∊⍵), pCrFamily ⎕R actCrFamily ⍠reOPTS⊣F 0  
                  }
                ⍝ Format for PassDef:   /::SysDefø name←value/ with the name /[^←]+/ and single spaces as shown.
                  PassDef←{(PassState ON),'::SysDefø ',(F 1),'←',⍵,CR }    

                  CASE iErr: (¯1↓F 0),'○○○ ⍝ ERR: ⍝ Invalid directive. Prefix :: expected.',CR
                ⍝ ON...
                  CurStateIs ON: {  
                      CASE iOther:      F 0  
                      CASE iDef1:       PassDef (F 1)  (1 _MacSet)⊣val←MainScan DTB F 2   
                      CASE iDef2:       PassDef (F 1)  (fVal _MacSet) F 1+fVal←0≠≢F 2 
                      CASE iEvl:        PassDef (F 1)  (1 _MacSet)⊣val←Eval2Str MainScan DTB F 2  
                      CASE iDefL:       PassDef (F 1)  (0 _MacSet)⊣val←DQScan DTB F 2      
                      CASE iIf:         PassState Push Eval2Bool MacScan F 1
                      CASE iElIf iEl:   PassState Poke SKIP  
                      CASE iEndIf:      PassState Pop ⍵
                      CASE iDebug:      (F 0),PassState ON⊣DEBUG∘←'off'≢⎕C F 1 
                      CASE iC_UCmd:     (PassState ON),{
                                           0=≢⍵:'' ⋄ '⍝> ',CR,⍨⍵
                                        }Eval2Str'⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2    
                      ∘UNREACHABLE∘
                  }ON
                ⍝ When (CurStateIs OFF or SKIP) for iDef1, iEvl, IDefL, iOther
                  ⍵.PatternNum>iEndIf : PassState SKIP    
                  CurStateIs OFF: {
                      CASE iIf:    PassState Push SKIP  
                      CASE iElIf:  PassState Poke Eval2Bool MacScan F 1
                      CASE iEl:    PassState Poke ON
                      CASE iEndIf: PassState Pop Peek ⍵
                      ∘UNREACHABLE∘ 
                  }OFF
                  1: {⍝ CurStateIs SKIP:
                      CASE iIf:       PassState Push SKIP
                      CASE iElIf iEl: PassState SKIP
                      CASE iEndIf:    PassState Pop Peek ⍵
                  }SKIP
                  ∘UNREACHABLE∘
            } ⍝ ControlScanAction
            save←mâc.(K V) DEBUG                          ⍝ Save macros
              lines←pDQSQ pDots ⎕R '\0' ' ' ⍠reOPTS⊣⍵     ⍝ Simple continuation lines in Ctl directives...
              res←Pop controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣lines     ⍝ Scan- stack must be empty after Pop
            mâc.(K V) DEBUG← save                            ⍝ Restore macros
            res
        } ⍝ ControlScan 
  
        mainScanPats← pSysDef pUCmd pDebug pTrpQ pDQPlus pSkip pDots pHere pHCom pPtr pMacro pNumBase pNum 
                      iSysDef iUCmd iDebug iTrpQ iDQPlus iSkip iDots iHere iHCom iPtr iMacro iNumBase iNum←⍳≢mainScanPats
        MainScan←{
            ~DO_MAINSCAN: ⍵  
            MainScan1←{  
                mainScanPats ⎕R{  
                    ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                    ⋄ CASE←⍵.PatternNum∘∊                 
                    CASE iTrpQ: (F 3) ((≢F 2) Fmt2Code) F 1               
                    CASE iDQPlus: (F 2) (0 Fmt2Code) UnDQ F 1                
                    CASE iDots: ' '   ⍝ Keep: this seems redundant, but can be reached when used inside MainScan                             
                    CASE iPtr:  AddPar  (MainScan F 1),' ⎕SE.⍙PTR ',(⍕DEBUG)⊣SaveRunTime 'NOFORCE' ⊣⎕←'<',(MainScan F 1),'>' 
                    CASE iSkip: F 0                
                  ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts   ← :c :l :v :m :s
                  ⍝     F 3: body of here_doc, F 2: opns,  4: spaces before end_token, 5: code after end-token 
                    CASE iHere: {  
                      opt← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Get option after each :
                      l1←  opt ((≢F 4 ) Fmt2Code)  F 3
                      l1 {0=≢⍵~' ':⍺ ⋄ ⍺, CR, MainScan ⍵} F 5     ⍝ If no code after endToken, do nothing more...
                    }0   
                    CASE iHCom: (F 2){
                      kp←0≠≢⍺  ⋄ 0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR
                    } DLB F 5 
                    CASE iMacro:  ⊢MacScan MacGet F 0                     
                    CASE iSysDef: ''⊣ (F 1) (0 _MacSet) F 2                ⍝ SysDef: ::DEF, ::DEFL, ::EVAL on 2nd pass
                    CASE iDebug:  ''⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                  ⍝ CASE iDebug:  (DEBUG/'⍝2⍝ ',F 0)⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                    CASE iNumBase: ∆DEC (F 0)~'_'
                    CASE iNum:     (F 0)~'_'
                    CASE iUCmd:     '⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2    
                    ∘UNREACHABLE∘
                }⍠reOPTS⊣⍵
            }
            AtomScan←{ ⍝ [` or ``] (var | number | 'qt' | "qt")+
                pAtomVec pCom pSQ  ⎕R  { F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} 
                  0≠⍵.PatternNum: F 0
                  force←1=≢F 1    ⍝ If the ` is single (`), treat a single atom as a one-element list.
                  pAtomEach← pSQ '[¯\d\.]\H*' '\H+' 
                             iSQ iNum         iLet←⍳≢pAtomEach
                  count←0 ⋄ allNum←1 ⋄ atomErr←0  
                  list←pAtomEach ⎕R {oneStr←1=≢⍵ ⋄  F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ CASE←⍵.PatternNum∘∊
                      F0← F 0 ⋄ count+←1
                      CASE iSQ:   {3=≢⍵: AddPar ',', ⍵ ⋄ ⍵} F0 
                      CASE iNum:  {(,1)≡⊃⎕VFI ⍵: ⍵ ⋄ atomErr∘←1 ⋄ ⍵⊣⎕←'∆FIX Warning: Invalid numeric atom'} F 0
                      CASE iLet:  {3=≢⍵: AddPar ',' , ⍵ ⋄  ⍵} SQ,F0,SQ 
                      ∘UNREACHABLE∘
                  }⊣F 2 
                  atomErr: F 0
                  AddPar (',⊂'/⍨force∧1=count), list
              }⍠reOPTS⊣⍵
            }
             AtomScan MainScan1  ⍵
        } ⍝ End MainScan 

      ⍝ >>> PREDEFINED MACROS BEGIN             ⍝ Usage / Info
        mâc.⍙DEF← mâc.{(≢K)>K⍳⊂⍵}              ⍝   mâc: macro internal namespace
        mâc.⍙DUMP← mâc.{K,[-0.2]V}
        macro←(0 _MacSet)
        _←'⎕F'     macro '∆F'                   ⍝   APL-ified Python-reminiscent format function
        _←'⎕TO'    macro '⎕SE.∆TO'              ⍝   1 ⎕TO 20 2   "One to 20 by twos'
        _←'::DEF'  macro 'mâc.⍙DEF'             ⍝   ::IF ::DEF "name"is 1 if name is defined...
      ⍝ <<< PREDEFINED MACROS END 

      DFnScanIn←{ pBrak pSQ pDQ pCom ⎕R { 
          F0←⍵.Match ⋄  0≠⍵.PatternNum: F0 ⋄ {CR_HIDDEN@ (CR∘=)⊢⍵}¨F0 
      }⍠reOPTS⊣⍵ }
      DFnScanOut←{⍺←CR ⋄ ⍺{ ⍺@ (CR_HIDDEN∘=)⊢⍵ }¨⍵}
      FullScan←{¯1↓ DFnScanOut MainScan ControlScan DFnScanIn (DTB¨⊆⍵),⊂'⍝EXTRA⍝'}

      UserEdit←{
          ⍝ 0:: ↑(⊂'⍝ '),¨(⊂'Processing terminated due to error.'),⎕DMX.DM
          _←'∊' ⎕ED 'inp' ⊣ inp←⊆⍵ 
          inp≡⍵: {0:: 'User Edit complete. Unable to fix. See variable #.FIX_FN_SRC.' 
            #.FIX_FN_SRC←(⊂'ok←FIX_FN'),(⊂'ok←''>>> FIX_FN done.'''),⍨'^⍝>' '^\h*(?!⍝)' ⎕R '' '⍝' ⊣⍵
            0=1↑0⍴rc←#.⎕FX #.FIX_FN_SRC: ∘err∘
            'User Edit complete. See function #.',rc,'.'
          }⍵
          inp←'^⍝>.*$\R?' '^⍝(.*)$'  ⎕R '' '⍝>⍝\1' ⍠('Mode' 'M')⊣inp
          sep←⊂'⍝>⍝',30⍴' -'
          ∇ inp ,sep,'^ *⍝'  '^' ⎕R  '\0'  '⍝> '⊣FullScan inp
      }
    ⍝ If ⍺=1, UserEdit for rt arg; otherwise simply use ⍵.
      ⍺: UserEdit '⍝ Enter ESC to exit with changes (if any)' '⍝ Enter CTL-ESC to exit without changes' 
    ⍝ Add (and remove) an extra line so every internal line has a linend at each stage...
        FullScan ⍵
    }  

  ⍝ "Secret" options -e (edit), -nof (do not fix)
    ⍺←⊢  ⋄  oEdit noFix←'-e' '-nof'≡¨2 4↑¨⊂⍕⍺,''
    oEdit: 1 Executive ⍬
    ⍺ CALR.⎕FIX⍣(~noFix)⊣Executive LoadLines ⍵ 
}