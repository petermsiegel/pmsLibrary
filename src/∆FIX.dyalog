∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝ Syntax is as for ⎕FIX, except for 
  ⍝    a) '-nof[ix]' option, which shows the translated lines.
  ⍝    b) tolerates a missing :file// prefix when loading from a file.
    ⎕IO ⎕ML←0 1   
    DEBUG←0  ⋄   DO_FULLSCAN DO_CONTROLSCAN←1 1 
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
      ⎕SE.⍙PTR←{(ns←⎕NS '').∆DO←⍺⍺ ⋄ ns⊣ns.⎕DF '[⍙PTR]'}
      1
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via Encode below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{⍺←0
        AddPar← '('∘,∘⊢,∘')' 
      ⍝ ---- MACROS
        mac.K←mac.V←⍬ ⊣  mac←⎕NS ''
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
      ⍝ val ← key (flag MacSet) val
      ⍝   flag=0:  Sets macro <key> to have value <val>, a string.         See :DEF
      ⍝   flag=1:  Sets macro <key> to have value '(',<val>,')', a string. See :DEFL
      ⍝            Special case: If <val> is a nullstring, value is <val> alone (no parentheses).
        MacSet←{v←{'(',⍵,')'}⍣(⍺⍺∧0≠≢⍵)⊣⍵ 
           (≢mac.K)>p←mac.K⍳kk←⊂⍙K ⍺: ⍵⊣mac.V[p]←⊂v ⋄ mac.K,←kk ⋄ mac.V,←⊂v ⋄ v
        }  
        ⍝ MacSet←MacSet ('MacScan' ∆TRACE)
        MacGet←{0=≢⍵: ⍵ ⋄ p←mac.K⍳⊂⍙K ⍵ ⋄ p≥≢mac.K: ⍵ ⋄ 1:p⊃mac.V}
        pMac←{
            APL_LET←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜÌÍÎÏÐÇÑ∆⍙_#'
            pVarName← '(?i)[',APL_LET,'][⎕.\d',APL_LET,']*'
            pMac←'[]:⎕]?',pVarName
            pMac
        } ⍬
      ⍝ ------END MACROS

      ⍝ Encode: ⍺: 
      ⍝ Output format: options '[clsvm]'.   
      ⍝    'r' carriage returns for linends (def); 'l' LF for linends; 's' spaces replace linends 
      ⍝    'v' vector of vectors;    'm' APL matrix;    
      ⍝ Escape option. Works with any one above. 
      ⍝    'e' backslash (\) escape followed by eol => single space. Otherwise, as above.
      ⍝    'c' string is a comment to treat in toto as a blank.
      ⍝ indent: >0, use as is for indent of lines; <0, use indent of left-most line for indent; 0, as is.
        Encode←{ ⍺←'' ⋄ indent←⍺⍺  
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
        DTB←{⍵↓⍨-+/∧\' '=⌽⍵}                           ⍝ Delete trailing blanks from one line
        DLB←{⍵↓⍨ +/∧\' '= ⍵}                           ⍝ Delete leading blanks...
        UnDQ←{ s/⍨1+SQ=s←s/⍨~(2⍴DQ)⍷s←d↓⍵↓⍨-d←DQ=1↑⍵ } ⍝ Remove surrounding DQs and APL-escaped DQs. Double SQs  
        Execute←CALR∘{⎕PP←34 ⋄ 0:: ⍵,' ∘err∘'
            res2←⎕FMT res←⍺⍎⍵ ⋄ 0≠80|⎕DR res: 1↓∊CR,res2 ⋄  ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
        }
        FullLn←{'(?xi) ^',⍵,'$\r'}
    ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
    ⍝ These are required to match an entire line each...
        ControlScan←{ 
          ~DO_CONTROLSCAN: ⍵
              pNOCOM←'(?<NOCOM>(?:[^⍝''"\r]+|(?:''[^'']*'')+|(?:"[^"]*")+)(?&NOCOM)*)'
          pIf    ←FullLn'\h* :: IF         \b \h* (\N+) '
          pElIf  ←FullLn'\h* :: ELSEIF     \b \h* (\N+) '
          pEl    ←FullLn'\h* :: ELSE       \b      \h*  '
          pEndIf ←FullLn'\h* :: END(?:IF)? \b      \h*  '
          pDef   ←FullLn'\h* :: def  \h+ ([^\h←]+) \h* ←  (',pNOCOM,'|) \N* ' 
          pEvl   ←FullLn'\h* :: eval \h+ ([^\h←]+) \h* ←  (',pNOCOM,'|) \N* '   
          pDefL  ←FullLn'\h* :: defl \h+ ([^\h←]+) \h* ←  (\N*) '  
        ⍝ '::DEF name'  ==>  '::DEFL name←name'.  Same for '::DEFL' or '::EVAL'. Equiv to Undefining <name>.   
          pUndef ←FullLn'\h* :: (?:defl?|eval) \h+ ([^\h]+) \h* ' 
          pErr   ←FullLn'\h* :(defl?|eval) \b \N* '
          pDebug ←FullLn'\h* ::debug \b \h*  (ON|OFF|) \h* '
          pOther ←FullLn'\N*'   
          controlScanPats←pIf pElIf pEl pEndIf pDef pEvl pDefL pUndef pErr pDebug pOther
                      iIf iElIf iEl iEndIf iDef iEvl iDefL iUndef iErr iDebug iOther←⍳≢controlScanPats
          stack←,⊂ON OFF⊣ SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇' '↓' '↑'
          Eval←{0:: ¯1  ⋄ (,0)≡v←,⍎⍵: 0 ⋄ (0≠≢v)}
          Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 
               11 ⎕SIGNAL⍨'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0
          }  
          ControlScanAction←{F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                CASE←⍵.PatternNum∘∊  
                SendState←{DEBUG: '⍝',(STATES⊃⍨1+⊃∊⍵),'⍝ ',(F 0) ⋄ ''
                }
              ⍝ Format for SendDef:   /::SysDefø <name> value/ with the name /[^\h]+/ and single spaces as shown.
                SendDef←{(SendState ON),'::SysDefø ',(F 1),'←',⍵,CR }    
                notIfGrp←⍵.PatternNum>iEndIf 
                CASE iErr: (¯1↓F 0),' ○ Error: invalid directive. Prefix :: expected. ○',CR
              ⍝ ON...
                ON=⊃⊃⌽stack: {  
                    CASE iOther:     F 0
                    CASE iUndef:     SendDef (F 1) (0 MacSet) F 1 
                    CASE iDef:       SendDef (F 1) (1 MacSet)⊣val←FullScan DTB F 2    
                    CASE iEvl:       SendDef (F 1) (0 MacSet)⊣val←Execute FullScan DTB F 2  
                    CASE iDefL:      SendDef (F 1) (0 MacSet)⊣val←DTB F 2   
                    CASE iIf:        SendState stack,←⊂s (s=1) ⊣ s←Eval MacScan F 1
                    CASE iElIf iEl:  SendState (⊃⊃⌽stack)←SKIP 
                    CASE iEndIf:     SendState Pop ⍵
                    CASE iDebug:     ''⊣DEBUG∘←'off'≢⎕C F 1 
                    ∘UNREACHABLE∘
                }ON
              ⍝ OFF or SKIP for iDef, iEvl, IDefL, iOther
              notIfGrp: SendState SKIP 
              ⍝ OFF...     
                OFF=⊃⊃⌽stack: {
                    CASE iIf:    SendState stack,←⊂SKIP OFF
                    CASE iElIf:  SendState (⊃⊃⌽stack)←s ⊣ (⊃⌽⊃⌽stack)∨←s=1 ⊣ s←Eval MacScan F 1
                    CASE iEl:    SendState (⊃⊃⌽stack)←ON
                    CASE iEndIf: SendState Pop ⍵ 1⊃⍨⊃⌽⊃⌽stack 
                    ∘UNREACHABLE∘ 
                }OFF
              ⍝ SKIP...
                {   CASE iIf:       SendState ⍵ ⊣ stack,←⊂SKIP OFF
                    CASE iElIf iEl: SendState ⍵
                    CASE iEndIf:    SendState Pop ⍵ 1⊃⍨⊃⌽⊃⌽stack 
                } SKIP
                ∘Unreachable∘
          }
          save←mac.(K V) DEBUG                          ⍝ Save macros
            res←Pop controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣⍵     ⍝ Scan- stack must be empty after Pop
          mac.(K V) DEBUG← save                            ⍝ Restore macros
          res
        } 
        pSysDefX ← FullLn'^::SysDefø \h ([^←]+) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
        pDebug   ← FullLn'\h* ::debug (?|  \h+ (ON|OFF) | () ) \h*'
        pTrpQ    ← '"""\h*\R(.*?)\R(\h*)"""([a-z]*)'    ⋄  pDblQ   ← '(?i)((?:"[^"]*")+)([a-z]*)'
        pSkip    ← '(?:''[^'']*'')+|⍝\N*$'              ⋄  pDots   ← '(?:\.{2,3}|…)\h*\r\h*'
        pPAR pBRC ←GenBracePat¨'()'  '{}'               ⋄  pWRD    ← '[\w∆⍙_#\.⎕]+'
        pPtr     ← ∊'(?ix) \$ \h* (' pPAR '|' pBRC '|' pWRD ')'
            pHMID←'( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
      ⍝ Here-strings and Multiline ("Here-string"-style) comments 
        pHere    ← ∊'(?x)       ::: \h*   'pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
        pHCom   ← FullLn∊'\h* ::: \h* ⍝ 'pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '
  
        fullScanPats← pSysDefX pDebug pTrpQ pDblQ pSkip pDots pHere pHCom pPtr pMac 
                      iSysDefX iDebug iTrpQ iDblQ iSkip iDots iHere iHCom iPtr iMac←⍳≢fullScanPats
        FullScan←{
            ~DO_FULLSCAN: ⍵    
            fullScanPats ⎕R{  
                ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                ⋄ CASE←⍵.PatternNum∘∊                      
                CASE iTrpQ: (F 3) ((≢F 2) Encode) F 1               
                CASE iDblQ: (F 2) (0 Encode) UnDQ F 1                
                CASE iDots: ' '                                
                CASE iPtr:  AddPar  (FullScan F 1),' ⎕SE.⍙PTR 0'⊣SaveRunTime 0
                CASE iSkip: F 0                
              ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts   ← :c :l :v :m :s
              ⍝     F 3: body of here_doc, F 2: opns,  4: spaces before end_token, 5: code after end-token 
                CASE iHere: {  
                  opt← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Get option after each :
                  l1←  opt ((≢F 4 ) Encode)  F 3
                  l1 {0=≢⍵~' ':⍺ ⋄ ⍺, CR, FullScan ⍵} F 5     ⍝ If no code after endToken, do nothing more...
                }0   
                CASE iHCom: (F 2){kp←0≠≢⍺   0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR} DLB F 5 
                CASE iMac:  ⊢MacScan MacGet F 0                     
                CASE iSysDefX: ''⊣ (F 1) (0 MacSet) F 2   ⍝ :DEF name (everything before) ⍝ a comment!
                CASE iDebug: ''⊣DEBUG∘←'off'≢⎕C F 1    ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                ∘Unreachable∘
            }⍠reOPTS⊣⍵
        }
      ⍝ >>> PREDEFINED MACROS BEGIN
        _←'⎕F'   (0 MacSet) '∆FMT' 
        _←':COM' (0 MacSet) '⍝COM⍝'    ⍝ <== :DEFL :COM ⍝COM⍝
      ⍝ <<< PREDEFINED MACROS END 

      ⍝ Add (and remove) an extra line so every internal line has a linend at each stage...
        ¯1↓ FullScan ControlScan DTB¨(⊆⍵),⊂'⍝EXTRA⍝'
    }  
    ⍺←⊢  ⋄ fix←0=≢'-nof'⎕S 3⊣(⍕⍺),''    ⍝ Secret -nofix option...
    ⍺ CALR.⎕FIX⍣fix⊣ Executive LoadLines ⍵ 
}