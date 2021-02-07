∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝ Syntax is as for ⎕FIX, except for 
  ⍝    a) '-nof[ix]' option, which shows the translated lines.
  ⍝    b) tolerates a missing :file// prefix when loading from a file.
    ⎕IO ⎕ML ⎕PP←0 1 34     
    DEBUG←0  ⋄   DO_MAINSCAN DO_CONTROLSCAN←1 1 
    SQ DQ←'''"' ⋄ CR←⎕UCS 13  
    CALR←0⊃⎕RSI
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
  ⍝ Add CR to last line to make Regex patterns simpler...
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }

  ⍝ SaveRunTime:  SaveRunTime [force←0]
  ⍝ Save Run-time Utilities in ⎕SE if not already...
  ⍝     ⎕SE.⍙PTR
  ⍝  CALR.⎕PATH←1↓∊' ',¨∪'⎕SE',' '(≠⊆⊢)CALR.⎕PATH
    SaveRunTime←{⍺←0 ⋄ (~DEBUG)∧(~⍺)∧4=⎕SE.⎕NC '⍙PTR': 0 
        2:: ⎕SIGNAL/'∆FIX: Unable to set utility operator ⎕SE.⍙PTR' 11
      ⍝  Runtime Ptr. See $ Ptr prefix: ${operand}, $(operand), $operand_name...
      ⍝     ptr←(operand ⎕SE.⍙PTR debug]⊣0)
      ⍝          operand: Function to "turn into" a pointer, accessed via ptr.Run
      ⍝          debug:   If 0, display form is '[⍙PTR]' (fast).
      ⍝                   If 1, display form is an abridged version of the nested 
      ⍝                   representation of <operand>, up to 30 chars (slow).
      ⍝ Was: ⎕SE.⍙PTR←{(ns←⎕NS '').Run←⍺⍺ ⋄ ns⊣ns.⎕DF '[⍙PTR]'}
        ⍙PTR←{0::'$ POINTER DOMAIN ERROR'⎕SIGNAL 11
            (ns←⎕NS'').Run←⍺⍺ ⋄ MAXL←30
            0=⍵⍵:ns⊣ns.⎕DF'[⍙PTR]'
               Fit←MAXL∘{⍺>≢⍵:⍵ ⋄ '⋯',⍨⍵↑⍨⍺-1} ⋄ Shrink←{'^Run←' '\{⋄' '⋄\}' '\h+⋄\h+'⎕R'' '{' '}' '⋄'⊣¯1↓∊'⋄',⍨¨⍵} 
               Dlb←{⍵↓⍨+/∧\' '=⍵}¨             ⋄ Sane←{0<≢⍵: ⍵ ⋄ err∘}     
            ns⊣ns.⎕DF '[⍙PTR:', (Fit Shrink Dlb Sane⊆ns.⎕NR 'Run'), ']'
        }
        1
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via _Fmt2CodeStr below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{⍺←0   ⍝ If 1, Edit for input...
        DTB←{⍵↓⍨-+/∧\' '=⌽⍵}                           ⍝ Delete trailing blanks from one line
        DLB←{⍵↓⍨ +/∧\' '= ⍵}                           ⍝ Delete leading blanks...
      ⍝ Read hex, binary, octal numbers (e.g. 0x09DF, 0b0111, and 0o0137), converting to decimal.
      ⍝ Converts up to 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF (28 hex digits) as integers...
      ⍝ Returns right arg (⍵) if not a known base (xbo), number is negative, digits are out of range,
      ⍝ or if it can't represent in an integer of 34 decimal digits...
        ∆DEC←{ ⎕PP ⎕FR←34 1287  ⍝ Ensures largest # of decimal digits.
            nstr←⎕C ⍵ ⋄ base←2 8 16 0['box'⍳1↑1↓nstr] ⋄ ('0'≠1↑nstr)∨0=base: ⍵ 
            n←(base↑'0123456789abcdef')⍳2↓nstr ⋄ ∨/n≥base:  ⍵ 
            'E'∊res←⍕base⊥n: ⍵ ⋄ res  
        }
      ⍝ range ← from [next=from±1] To end [incr=1]. Sign of increment is ignored.
      ⍝         Specify one of [next] and [incr].
      ⍝         Sign of ¨next¨ and ¨incr¨ are ignored,  determined by ¨from¨ and ¨end¨.
      ⍝ ⎕IO←0
        ⎕SE.∆TO←{
            eTo←'⎕TO: range ← from [next=from+1] To end [incr=1]. Do not include both ¨next¨ and ¨incr¨.'
            from end←1↑¨⍺ ⍵  ⋄ 2∧.≤≢¨⍺ ⍵: eTo ⎕SIGNAL 11  
            step←(×end-from)×|1↑1↓⍵,(from-1↑1↓⍺)
            from+step×⍳0⌈1+⌊(end-from)÷step+step=0     
        }
        AddPar← '('∘,∘⊢,∘')' 
      ⍝ ---- MACROS
        mâc.K←mâc.V←⍬ ⊣  mâc←⎕NS ''
        MacScan←{
          ⍺←5    ⍝ Max of total times to scan entire line (prevents runaway replacements)
          ⍺≤0: ⍵  
          str←pSkip '("[^"]*")+' pMac ⎕R { F0← ⍵.Match ⋄ p←⍵.PatternNum 
              p=2: MacGet F0 ⋄ p=1: SQ,SQ,⍨UnDQ F0  ⋄ F0 } ⍵
          ⍵≢str: (⍺-1) ∇ str ⋄ str        ⍝ If any changes, scan again up to <⍺> times.
        }
        ⍝MacScan←MacScan ∆TRACE 'MacScan'
      ⍝ Note: macro names whose last component starts with ⎕ or :  are case-insensitive.
      ⍝       E.g. ⎕NaMe, :myIF, or a.b.⎕NaMe 
      ⍝ val ← ⍙K key, key: a string.
        ⍙K←{ ~'⎕:'∊⍨⊃⊃⌽k←'.'(≠⊆⊢)⍵ :⍵  ⋄ k⊣(⊃⌽k)←⎕C ⊃k }  ⍝ Case ignored for ⎕xxx and :xxx
      ⍝ val ← key (flag _MacSet) val
      ⍝   flag=0:  Sets macro <key> to have value <val>, a string.         See :DEF
      ⍝   flag=1:  Sets macro <key> to have value '(',<val>,')', a string. See :DEFL
      ⍝            Special case: If <val> is a nullstring, value is <val> alone (no parentheses).
        _MacSet←{v←{'(',⍵,')'}⍣(⍺⍺∧0≠≢⍵)⊣⍵ 
           (≢mâc.K)>p←mâc.K⍳kk←⊂⍙K ⍺: ⍵⊣mâc.V[p]←⊂v ⋄ mâc.K,←kk ⋄ mâc.V,←⊂v ⋄ v
        }  
        MacGet←{0=≢⍵: ⍵ ⋄ p←mâc.K⍳⊂⍙K ⍵ ⋄ p≥≢mâc.K: ⍵ ⋄ 1:p⊃mâc.V}
        pMac←{
            APL_LET←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜÌÍÎÏÐÇÑ∆⍙_#'
            pVarName← '(?i)[',APL_LET,'][⎕.\d',APL_LET,']*'
            pMac←'(?:[]⎕]|:{1,2}|)',pVarName     ⍝ OK: ::NAME, ⎕NAME, ]NAME
            pMac
        } ⍬
      ⍝ ------END MACROS

      ⍝ _Fmt2CodeStr: ⍺: 
      ⍝     Convert possibly multiline strings to the requested format and return as an APL code string.
      ⍝ Output format: options '[clsvm]'.   
      ⍝    'r' carriage returns for linends (def); 'l' LF for linends; 's' spaces replace linends 
      ⍝    'v' vector of vectors;    'm' APL matrix;    
      ⍝ Escape option. Works with any one above. 
      ⍝    'e' backslash (\) escape followed by eol => single space. Otherwise, as above.
      ⍝    'c' string is a comment to treat in toto as a blank.
      ⍝ indent: >0, use as is for indent of lines; <0, use indent of left-most line for indent; 0, as is.
        _Fmt2CodeStr←{ ⍺←'' ⋄ indent←⍺⍺  
          ⍝ options--   o1 (options1) (r|l|s|v|m); o2 (options2): [ec]; od(efault): 'r'.
            o1 o2 od ←'rlsvm' 'ec' 'r'  ⋄ o←(o1{1∊⍵∊⍺⍺: ⍵ ⋄ ⍵⍵,⍵}od) ⎕C ⍺
            R L S V M E C←o∊⍨∊o1 o2
            0≠≢err←o~∊o1 o2: 11 ⎕SIGNAL⍨'∆FIX: Invalid option "',err,'"'
            C: ' '
            SlashScan←  { '\\(\r|$)'⎕R' '⍠reOPTS⊣⍵ }  ⍝ backsl + EOL  => space given e (escape) mode.
            S2Vv←      { 2=|≡⍵:⍵ ⋄ CR(≠⊆⊢)⊢⍵ }                        
            TrimL←     { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\' '=↑⍵  ⋄  ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺ }
            DblSQ←     { ⍵/⍨1+⍵=SQ }¨    
            FormatPerOpt← {
             ⍝  0=≢⍵: 2⍴SQ
              AddSQ←SQ∘,∘⊢,∘SQ 
              V∨M: (M/'↑') ,¯1↓∊' ',⍨∘AddSQ¨ ⍵ ⋄  S: AddSQ 1↓∊' ',¨⍵ 
              R∨L: AddSQ ∊{⍺,nlc,⍵}/⍵ ⊣ nlc←SQ,',(⎕UCS ',(⍕R⊃10 13 ),'),',SQ  
              ∘Unreachable∘  
            }
            0=≢⍵: 2⍴SQ
            AddPar⍣(~V)⊣FormatPerOpt (SlashScan⍣E)DblSQ indent∘TrimL S2Vv ⍵
        }
      ⍝ pat ← GenBracePat ⍵, where ⍵ is a pair of braces: ⍵='()', '[]', or '{}'.  
      ⍝ Generates a pattern to match unquoted balanced braces across newlines, skipping
      ⍝   (a) comments to the end of the current line, (b) quoted strings (single or double).
      ⍝ Uses a name based on the braces and the ?J option, so PCRE functions properly[*].
      ⍝    * Any repeat definitions of these names MUST be identical.
        GenBracePat←{⎕IO←0 ⋄ ⍺←⎕A[,⍉26⊥⍣¯1⊢ ⎕UCS ⍵] ⋄ Nm←⍺  ⍝ ⍺ a generated unique name based on ⍵
          Lb Rb←⍵,⍨¨⊂'\\'
          pM←'(?: (?J) (?<Nm> Lb  (?> [^LbRb''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&Nm)* )+ Rb))'~' '
          'Nm' 'Lb' 'Rb'⎕R Nm Lb Rb⊣pM
        }
        UnDQ←{ s/⍨1+SQ=s←s/⍨~(2⍴DQ)⍷s←d↓⍵↓⍨-d←DQ=1↑⍵ } ⍝ Remove surrounding DQs and APL-escaped DQs. Double SQs  
        Execute←CALR∘{⎕PP←34 ⋄ 0:: ⍵,' ∘err∘'
            res2←⎕FMT res←⍺⍎⍵ ⋄ 0≠80|⎕DR res: 1↓∊CR,res2 ⋄  ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
        }
        RE⍙Line←{'(?xi) ^',⍵,'$\r'}

      ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
      ⍝ These are required to match an entire line each...
        pNOCOM←'(?<NOCOM>(?:[^⍝''"\r]+|(?:''[^'']*'')+|(?:"[^"]*")+)(?&NOCOM)*)'
        pIf    ←RE⍙Line'\h* :: IF         \b \h* (\N+) '
        pElIf  ←RE⍙Line'\h* :: ELSEIF     \b \h* (\N+) '
        pEl    ←RE⍙Line'\h* :: ELSE       \b      \h*  '
        pEndIf ←RE⍙Line'\h* :: END(?:IF)? \b      \h*  '
      ⍝ For ::DEF (define) of the form  ::DEF name ← value, match after the control word:
      ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
      ⍝ where name* is a sequence of chars except spaces, ←, or CR.
      ⍝ The value will be enclosed in parentheses, limiting surprising side effects.
        pDef1   ←RE⍙Line'\h* :: def  \h+ ((?>[^\h←\r]+)) \h* ← \h*  (',pNOCOM,'|) \N* ' 
      ⍝ ::EVAL or synonym ::DEFE 
      ⍝ For ::EVAL (evaluate string value) of form ::EVAL name ← value, match after the control word:
      ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
      ⍝ where name* is a sequence of chars except spaces, ←, or CR. 
      ⍝ The value stored will be determined in the calling namespace CALR as
      ⍝     CALR ⍎ value
        pEvl   ←RE⍙Line'\h* :: (?:eval|defe) \h+ ((?>[^\h←\r]+)) \h* ← \h? (',pNOCOM,'|) \N* '   
      ⍝ For ::DEFL (literal) of the form ::DEFL name ← value, match after the ctl word: 
      ⍝      blanks, word*, blanks, ← optional blank, value*
      ⍝ where word* defined as above and value* includes everything up to the EOL, including leading and internal blanks.
      ⍝ The value will not be enclosed in parentheses.
        pDefL  ←RE⍙Line'\h* :: defl \h+ ((?>[^\h←\r]+)) \h* ← \h? (\N*) '  
      ⍝ For ::DEF of forms:   
      ⍝     ::DEF name    OR    ::def name value  
      ⍝ we match after the ctl word:
      ⍝ I.     blanks, name*  which is translated to: ::DEF name1* ← name1*
      ⍝    where name* and name1* defined as name* above, name1* the same in both cases.
      ⍝    This is equivalent to undefining name*, i.e. replacing it with itself.
      ⍝ II.    blanks, name*, blanks, value
      ⍝    where name* as above and value* consists of all text to the end of the line, excluding leading blanks.
      ⍝    This is equivalent to ::def name ← value above.
        pDef2 ←RE⍙Line'\h* :: (?:def) \h+ ((?>[^\h←\r]+)) \h*? ( [^\h\r]* )'
      ⍝ :DEF, :DEFL, :EVAL  are errors.
        pErr   ←RE⍙Line'\h* :(def[el]?|eval) \b \N* '
        pDebug ←RE⍙Line'\h* ::debug \b \h*  (ON|OFF|) \h* '
        pOther ←RE⍙Line'\N*'  

        ControlScan←{ 
            ~DO_CONTROLSCAN: ⍵
            controlScanPats←pIf pElIf pEl pEndIf pDef1 pDef2 pEvl pDefL pErr pDebug pOther
                            iIf iElIf iEl iEndIf iDef1 iDef2 iEvl iDefL iErr iDebug iOther←⍳≢controlScanPats
            SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇' '↓' '↑'
            BoolElseErr←{0:: ¯1  ⋄ (,0)≡v←,⍎⍵: 0 ⋄  (0≠≢v)}    ⍝ True 1, False 0, Error ¯1
            Poke←{ ⍵⊣(⊃⌽stack)←⍵ ((⍵=1)∨⊃⌽⊃⌽stack)}
            Push←{ ⍵⊣stack,←⊂⍵ (⍵=1)}
            Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 ⋄ 11 ⎕SIGNAL⍨'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0 }  
            Peek←{(⊃⌽⊃⌽stack)⊃⍵ 1}
            CurStateIs←{⍵∊⍨⊃⊃⌽stack}
            
            stack←,⊂ON ON
            ControlScanAction←{F←⍵.{0:: '' ⋄ Lengths[⍵]↑Offsets[⍵]↓Block}
                  CASE←⍵.PatternNum∘∊ 
                  SendState←{~DEBUG: '' ⋄ stateIx←1+⊃∊⍵ ⋄ '⍝',(stateIx⊃STATES),'⍝ ',(F 0) }
                ⍝ Format for SendDef:   /::SysDefø name←value/ with the name /[^←]+/ and single spaces as shown.
                  SendDef←{(SendState ON),'::SysDefø ',(F 1),'←',⍵,CR }    

                  CASE iErr: (¯1↓F 0),' ○ Error: invalid directive. Prefix :: expected. ○',CR
                ⍝ ON...
                  CurStateIs ON: {  
                      CASE iOther:     F 0  
                      CASE iDef1:      SendDef (F 1) (1 _MacSet)⊣val←MainScan DTB F 2   
                      CASE iDef2:      {SendDef (F 1) (⍵ _MacSet) F 1+⍵}0≠≢F 2 
                      CASE iEvl:       SendDef (F 1) (1 _MacSet)⊣val←Execute MainScan DTB F 2  
                      CASE iDefL:      SendDef (F 1) (0 _MacSet)⊣val←DTB F 2   
                      CASE iIf:        SendState Push BoolElseErr MacScan F 1
                      CASE iElIf iEl:  SendState Poke SKIP  
                      CASE iEndIf:     SendState Pop ⍵
                      CASE iDebug:     (F 0),SendState ON⊣DEBUG∘←'off'≢⎕C F 1 
                      ∘UNREACHABLE∘
                  }ON
                ⍝ When (CurStateIs OFF or SKIP) for iDef1, iEvl, IDefL, iOther
                  ⍵.PatternNum>iEndIf : SendState SKIP    
                  CurStateIs OFF: {
                      CASE iIf:    SendState Push SKIP  
                      CASE iElIf:  SendState Poke BoolElseErr MacScan F 1
                      CASE iEl:    SendState Poke ON
                      CASE iEndIf: SendState Pop Peek ⍵
                      ∘UNREACHABLE∘ 
                  }OFF
                ⍝ CurStateIs SKIP:
                  {   CASE iIf:       SendState Push SKIP
                      CASE iElIf iEl: SendState SKIP
                      CASE iEndIf:    SendState Pop Peek ⍵
                  } SKIP
                  ∘UNREACHABLE∘
            }
            save←mâc.(K V) DEBUG                          ⍝ Save macros
              res←Pop controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣⍵     ⍝ Scan- stack must be empty after Pop
            mâc.(K V) DEBUG← save                            ⍝ Restore macros
            res
        } 
        pSysDef ←  RE⍙Line'^::SysDefø \h ([^←]+?) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
        pDebug   ← RE⍙Line'\h* ::debug \b \h*  (ON|OFF|) \h* '
        pTrpQ    ← '"""\h*\R(.*?)\R(\h*)"""([a-z]*)'    ⋄  pDblQ   ← '(?i)((?:"[^"]*")+)([a-z]*)'
        pSkip    ← '(?:''[^'']*'')+|⍝\N*$'              ⋄  pDots   ← '(?:\.{2,3}|…)\h*(⍝\N*)?\r\h*'
        pPAR pBRC ←GenBracePat¨'()'  '{}'               ⋄  pWRD    ← '[\w∆⍙_#\.⎕]+'
        pPtr     ← ∊'(?ix) \$ \h* (' pPAR '|' pBRC '|' pWRD ')'
            pHMID←'( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
      ⍝ Here-strings and Multiline ("Here-string"-style) comments 
        pHere    ← ∊'(?x)       ::: \h*   'pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
        pHCom    ← RE⍙Line∊'\h* ::: \h* ⍝ 'pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '
        pBase    ← '(?xi) 0 [xbo] \w+'
  
        mainScanPats← pSysDef pDebug pTrpQ pDblQ pSkip pDots pHere pHCom pPtr pMac pBase   
                      iSysDef iDebug iTrpQ iDblQ iSkip iDots iHere iHCom iPtr iMac iBase ←⍳≢mainScanPats
        MainScan←{
            ~DO_MAINSCAN: ⍵  
            MainScan1←{  
                mainScanPats ⎕R{  
                    ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                    ⋄ CASE←⍵.PatternNum∘∊                 
                    CASE iTrpQ: (F 3) ((≢F 2) _Fmt2CodeStr) F 1               
                    CASE iDblQ: (F 2) (0 _Fmt2CodeStr) UnDQ F 1                
                    CASE iDots: ' '                                
                    CASE iPtr:  AddPar  (MainScan F 1),' ⎕SE.⍙PTR ',(⍕DEBUG),'⊣ 0'⊣SaveRunTime 0  
                    CASE iSkip: F 0                
                  ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts   ← :c :l :v :m :s
                  ⍝     F 3: body of here_doc, F 2: opns,  4: spaces before end_token, 5: code after end-token 
                    CASE iHere: {  
                      opt← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Get option after each :
                      l1←  opt ((≢F 4 ) _Fmt2CodeStr)  F 3
                      l1 {0=≢⍵~' ':⍺ ⋄ ⍺, CR, MainScan ⍵} F 5     ⍝ If no code after endToken, do nothing more...
                    }0   
                    CASE iHCom: (F 2){kp←0≠≢⍺   0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR} DLB F 5 
                    CASE iMac:  ⊢MacScan MacGet F 0                     
                    CASE iSysDef: ''⊣ (F 1) (0 _MacSet) F 2                ⍝ SysDef: ::DEF, ::DEFL, ::EVAL on 2nd pass
                    CASE iDebug:  ''⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                  ⍝ CASE iDebug:  (DEBUG/'⍝2⍝ ',F 0)⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                    CASE iBase:    ∆DEC F 0
                    ∘Unreachable∘
                }⍠reOPTS⊣⍵
            }
            MainScan2←{
                pAtoms ← '`\h*(["'']?)([\w∆⍙_#\.⎕¯ ]+)\1'          ⍝ ` (var | number)
                pAtomErr←'`\h*(?>[^\h]+)'    
                pSkip pAtoms pAtomErr ⎕R  {CASE←⍵.PatternNum∘∊
                  F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                  CASE 0 2: F 0                 ⍝ If an error, let APL handle (???)
                  AddPar {ch←1 ⋄ wds←1↓∊{1=⍬⍴⊃⎕VFI ⍵: ' ',⍵⊣ch∘←0 ⋄ ' ',SQ,SQ,⍨⍵}¨⍵ ⋄ ch∧1=≢⍵: '⊂,',wds ⋄ wds}' ' (≠⊆⊢) MacScan F 2
                }⍠reOPTS⊣⍵
            }
            MainScan2 MainScan1 ⍵
        }
      ⍝ >>> PREDEFINED MACROS BEGIN             ⍝ Usage / Info
         mâc.⍙DEF← mâc.{(≢K)>K⍳⊂⍵}              ⍝   mâc: macro internal namespace
         mâc.⍙DUMP← mâc.{K,[-0.2]V}
         macro←(0 _MacSet)
        _←'⎕F'     macro '∆F'                   ⍝   APL-ified Python-reminiscent format function
        _←'⎕TO'    macro '⎕SE.∆TO'              ⍝   1 ⎕TO 20 2   "One to 20 by twos'
        _←'::DEF'  macro 'mâc.⍙DEF'             ⍝   ::IF ::DEF "name"is 1 if name is defined...
      ⍝ <<< PREDEFINED MACROS END 

      FullScan←{¯1↓ MainScan ControlScan (DTB¨⊆⍵),⊂'⍝EXTRA⍝'}

      UserEd←{
          0:: ↑(⊂'⍝ '),¨(⊂'Processing terminated due to error.'),⎕DMX.DM
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
    ⍝ If ⍺=1, UserEd for rt arg; otherwise simply use ⍵.
      ⍺: UserEd '⍝ Enter ESC to exit with changes (if any)' '⍝ Enter CTL-ESC to exit without changes' 
    ⍝ Add (and remove) an extra line so every internal line has a linend at each stage...
        FullScan ⍵
    }  

  ⍝ "Secret" options -e (edit), -nof (do not fix)
    ⍺←⊢  ⋄  oEdit noFix←'-e' '-nof'≡¨2 4↑¨⊂⍕⍺,''
    oEdit: 1 Executive ⍬
    ⍺ CALR.⎕FIX⍣(~noFix)⊣Executive LoadLines ⍵ 
}