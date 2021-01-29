∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝ Syntax is as for ⎕FIX, except for 
  ⍝    a) '-nof[ix]' option, which shows the translated lines.
  ⍝    b) tolerates a missing :file// prefix when loading from a file.
    ⎕IO ⎕ML←0 1   
    DEBUG←0 ⋄ DSAY←{⍺←''⋄ DEBUG: ⍵⊣⎕←⍺,(': '/⍨0≠≢⍺),⍵ ⋄ 1: _←⍵}
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }

    ∆TRACE←{⍺←⊢
      res←⍺ ⍺⍺ ⍵ ⋄  name←⍺⍺
      0≢⍺ 0: res⊣⎕←(name,':')('⍺:'⍺) ('⍵:' ⍵ 'res:' res)
      res⊣(name,':')('⍵:' ⍵) ('res:' res)
    }
  ⍝ SaveRunTime:  SaveRunTime [force←0]
  ⍝ Save Run-time Utilities in ⎕SE if not already...
  ⍝     ⎕SE.⍙PTR
    SaveRunTime←{⍺←0 ⋄ (~⍺)∧4=⎕SE.⎕NC '⍙PTR': 0 
      2:: ⎕SIGNAL/'∆FIX: Unable to set utility operator ⎕SE.⍙PTR' 11
      ⎕SE.⍙PTR←{(ns←⎕NS '').∆FN←⍺⍺ ⋄ ns⊣ns.⎕DF '[⍙PTR]'} ⋄ 1 
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via Encode below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{⍺←0
        SQ DQ←'''"' ⋄ CR←⎕UCS 13  
        AddPar← '('∘,∘⊢,∘')' 

      ⍝ ---- MACROS
        mac.K←mac.V←⍬ ⊣  mac←⎕NS ''
        MacScan←{
          ⍺←5    ⍝ Max of total times to scan entire line (prevents runaway replacements)
          ⍺≤0: ⍵  
          str←pSkip '("[^"]*")+' pMac ⎕R { F0← ⍵.Match ⋄ p←⍵.PatternNum ⋄ p=2: MacGet F0 ⋄  F0  }⍵
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
        MacSet←{v←⊂{'(',⍵,')'}⍣(⍺⍺∧0≠≢⍵)⊣⍵ 
           (≢mac.K)>p←mac.K⍳kk←⊂⍙K ⍺: ⍵⊣mac.V[p]←v ⋄ mac.K,←kk ⋄ mac.V,←v ⋄ ⍵
        }  
        ⍝ MacSet←MacSet ('MacScan' ∆TRACE)
        MacGet←{0=≢⍵: ⍵ ⋄ p←mac.K⍳⊂⍙K ⍵ ⋄ p≥≢mac.K: ⍵ ⋄ p⊃mac.V}
       pMac←{
            APL_LET←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜÌÍÎÏÐÇÑ∆⍙_#'
            pVarName← '(?i)[',APL_LET,'][⎕.\d',APL_LET,']*'
            pMac←'[]:⎕]?',pVarName
            pMac
        } ⍬
        ⍝ >>> PREDEFINED MACROS BEGIN
            _←'⎕F'   (0 MacSet) '∆FMT' 
            _←':COM' (0 MacSet) '⍝COM⍝'    ⍝ <== :DEFL :COM ⍝COM⍝
        ⍝ <<< PREDEFINED MACROS END 
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
        EvalStmt←{⎕PP←34 ⋄ 0:: ⍵,' ∘err∘'
           res2←⎕FMT res←(⊃⎕RSI)⍎⍵ ⋄ 0≠80|⎕DR res: 1↓∊CR,res2 ⋄  ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
        }

        ⍝ May require input line to be trimmed. 
             pNOCOM←'(?<NOCOM>(?:[^⍝''"\r]+|(?:''[^'']*'')+|(?:"[^"]*")+)(?&NOCOM)*)'
        pDef  ←'(?xi)^ \h* ::def  \h+ (',pMac,') \h? (',pNOCOM,'|)' 
        pEvl  ←'(?xi)^ \h* ::eval \h+ (',pMac,') \h? (',pNOCOM,'|)'   
        pDefL ←'(?xi)^ \h* ::defl \h+ (',pMac,') \h? (\N*)$'  
        pDebg ←'(?xi)^ \h* ::debug (?|  \h+ (ON|OFF) | () ) \h*\R'
        pTrpQ ←  '"""\h*\R(.*?)\R(\h*)"""([a-z]*)'    ⋄  pDblQ ←  '(?i)((?:"[^"]*")+)([a-z]*)'
        pSkip ←  '(?:''[^'']*'')+|⍝\N*$'              ⋄  pDots   ← '(?:\.{2,3}|…)\h*\r\h*'
        pPAR pBRC ←GenBracePat¨'()'  '{}'             ⋄  pWRD    ← '[\w∆⍙_#\.⎕]+'
        pPtr    ← ∊'(?ix) \$ \h* (' pPAR '|' pBRC '|' pWRD ')'
        pHMID←'( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
      ⍝ Here-strings and Multiline ("Here-string"-style) comments 
        pHere←∊'(?x)       ::: \h*   'pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
        pHCom←∊'(?x) ^ \h* ::: \h* ⍝ 'pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) \R?' ⍝ Consume newline (none on last line)
      ⍝ pMac defined above 
        pIfEl←'(?xi)^ \h* ::  (?|  (IF|ELSEIF) \h* (\N+) | (ELSE|END(?:IF)?) \N*) $' 
        mainPatterns← pDef pEvl pDefL pDebg pTrpQ pDblQ pSkip pDots pHere pHCom pPtr pMac pIfEl
                      iDef iEvl iDefL iDebg iTrpQ iDblQ iSkip iDots iHere iHCom iPtr iMac iIfEl←⍳≢mainPatterns
        FullScan←{    
            mainPatterns ⎕R{  
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
                CASE iHCom: (F 2){kp←0≠≢⍺ ⋄ 0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR} DLB F 5 
                CASE iMac:  ⊢MacScan MacGet F 0                     
                CASE iDef:  '⍝ ',F 0 ⊣ (F 1) (1 MacSet) FullScan DTB F 2   ⍝ :DEF name (everything before) ⍝ a comment!
                CASE iEvl:  '⍝ ',F 0 ⊣ (F 1) (0 MacSet) EvalStmt FullScan DTB F 2  
                CASE iDefL: '⍝ ',F 0 ⊣ (F 1) (0 MacSet) DTB F 2            ⍝ :DEF name everything that follows
                CASE iDebg: ''⊣DEBUG∘←'off'≢⎕C F 1    ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                CASE iIfEl: { dir←1 ⎕C F 1  ⋄ CASE←(⊂dir)∘∊∘⊆
                  CASE 'IF' 'ELSEIF': {
                     val←⍕{ 0:: '⎕NULL' ⋄ (,0)≢v←,⍎⍵: 0 ⋄ 0≠≢v}code2←MacScan ⊢code←⍵
                    '::',dir,' ',val,' ←',code2,' ←',code
                  }DTB F 2 
                  CASE 'END': '::ENDIF' 
                  '::',dir 
                }0
                ∘Unreachable∘
            }⍠reOPTS⊣⍵
        }
        FullScan DTB¨⊆⍵
    }  
    ⍺←⊢  ⋄ fix←0=≢'-nof'⎕S 3⊣(⍕⍺),''    ⍝ Secret -nofix option...
    ⍺(⊃⎕RSI).⎕FIX⍣fix⊣ Executive LoadLines ⍵  
}
