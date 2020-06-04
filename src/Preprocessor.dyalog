:namespace Preprocessor
  ⍝ NOTE: All namespace names beginning of the form _xxx are ephemeral, erased at the end of the namespace load.
  ⍝  
  ⍝ RUNTIME_ASSIST: If 1, instead of constant functions or variables, ⎕SE.⍙xxx variable names are defined for run-time use.
  ⍝                 If 0, each occurrence of special functions is emitted as a single-line dfn of possibly moderate length.
    RUNTIME_ASSIST←1           
    ⎕IO←0
    DEBUG←0   

    SQ←'''' ⋄ DQ←'"' ⋄ DQ2←2⍴DQ
    PARENS←LPAREN RPAREN←'()'
    BRACES←LBRACE RBRACE←'{}'
    ⍝ optsMulti: Warning: Uses DOTALL, so '.' matches \n; 
    ⍝ \N matches everything except \R (\n, \r\n, NEL, etc).
    ⍝ \X (match extended grapheme cluster)can be used to match anything, but it may be slower.
    ⍝ We don't normalize all newlines-- we accept what APL divides into separate vectors...
    ⍝ We use CR since that's what APL formats nicely internally.
    optsMulti←   ('Mode' 'M')('EOL' 'CR')('NEOL' 0)('UCP' 1)('DotAll' 1)   
    optsSingle←              ('EOL' 'CR')('NEOL' 0)('UCP' 1)
    CR←⎕UCS 13

    ∆DLB←  {⍵↓⍨+/∧\' '=⍵}                 ⍝ Delete leading blanks
    ∆DTB←  {⍵↓⍨-+/∧\' '=⌽⍵}               ⍝ Delete trailing blanks
    Affix← {L R←⍺ ⋄ L,⍵,R}                ⍝ Surround ⍵ with prefix and suffix in ⍺
    Chop←  {1↓¯1↓⍵}                       ⍝ Remove matching parens, quotes, etc. from start/end of string ⍵ [no checks here]
 
  ⍝ str2 ←  NormalizeString str
  ⍝ Take a string of form "any_chars" and normalizes it into the form 'any_chars', 
  ⍝    doubling any internal single quotes and halving internal double-quotes.
  ⍝       "I can't, ""he"" said."   ==>     'I can''t, "he" said.'
  ⍝ If string is of form  'any_chars', it is passed through unchanged.
  ⍝                       Append SQs
  ⍝                       ↓          Double internal single-quotes
  ⍝                                  ↓             Convert doubled double-quotes to single
  ⍝                                                ↓              Drop pre-/post-DQ    
  ⍝                                                               ↓          If   DQ is prefix.                                    
    NormalizeString ← { ( SQ∘Affix ∘ {⍵/⍨1+⍵=SQ} ∘ {⍵/⍨~DQ2⍷⍵}  ∘ Chop )     ⍣  ( DQ=⍬⍴⍵ )       ⊣ ⍵  }
   

    ∇ {rta}←_USE_RUNTIME_ASSIST rta;fpAsgn;fpCode 
    fpAsgn←'⍙FNPTR←'
    fpCode← '{n←(⊃⎕RSI).⎕NS ⍬⋄n.fn←⍺⍺⋄n⊣n.⎕DF''[FnPtr '',(⍕⍵),'']''}'
    :If rta 
       ⎕SE            ⍎fpAsgn, fpCode
       ⎕SE.⍙CR←       ⎕UCS 13
       FN_PTR_STR←    '⎕SE.⍙FNPTR'
       SQ_CR_SQ←      SQ,',⎕SE.⍙CR,',SQ 
    :Else 
       FN_PTR_STR←    fpCode
       SQ_CR_SQ←      SQ,',(⎕UCS 13),',SQ
    :EndIf 
    ∇
    _USE_RUNTIME_ASSIST RUNTIME_ASSIST

    ⍝ strings ← ns ∆FLD fieldIDs
    ⍝   ns:        The namespace passed to the right operand of ⎕R or ⎕S (as ⍵)
    ⍝   fieldIDs:  One or more identifiers for regexp fields, each
    ⍝              a string field name (@S) or integer field number (@I), or 0 for the entire match.
    ⍝   If a field is non-existent or currently has no value, a null string '' is returned (without complaint).
      errMissingLeftArg ← '∆FLD left arg (a regexp ns) is missing'
      ∆FLD←{
          0=⎕NC'⍺':⎕SIGNAL/errMissingLeftArg 11
          0=80|⎕DR ⍵:⍺ ∇⊂⍵                          ⍝ If ⍵ is a single string vector, enclose.
          ns←⍺ ⋄ sngl←⍬⍴0=⍴⍴⍵                       ⍝ ns: the namespace passed to a ⎕R right-hand-side function as ⍵.
          ⊃⍣sngl⊣{                                  ⍝ If ⍵ is a single item, disclose the string result.
              ' '=1↑0⍴⍵:ns ∇ ns.Names⍳⊂,⍵
              ⍵=0:ns.Match                          ⍝ Fast way to get whole match
              ⍵≥≢ns.Lengths:''                      ⍝ Field not defined AT ALL. Return ''
              ns.Lengths[⍵]=¯1:''                   ⍝ Field is defined, but not active within current submatch. Return ''
              ns.Lengths[⍵]↑ns.Offsets[⍵]↓ns.Block  ⍝ [⍵] origin must be our ⎕IO, not ns.⎕IO
          }¨⍵
      }
    
      ⍝  string2 ← [ environment?caller_ns [errOnNull?1]] ∆MAP string1
      ⍝  string1:⍵, a string containing text including 0 or more...
      ⍝      nameStrings of the form:
      ⍝                  ⍎name or ⍎name1.name2... and
      ⍝      valueStrings of the form of APL code in braces, but excluding internal braces:
      ⍝                  ⍎{any text except internal braces}, e.g. ⍎{16⍴⎕A} or ⍎{var1, var2, var3}
      ⍝          but NOT 
      ⍝                  ⍎⍎ followed by anything, 
      ⍝          i.e. each ⍎⍎ pair is mapped on output to a single unaltered '⍎'
      ⍝  environment:  namespace (reference) from which to retrieve the values of the variables or code in the name or value-String constructions.
      ⍝     caller_ns: By default, use the namespace (ref) ∆MAP was called from: 0⊃⎕RSI
      ⍝  errOnNull:  If 1, any error in evaluating a nameString or valueString in <string1> will result in a DOMAIN ERROR. (DEFAULT)
      ⍝              If 0, any nameString or valueString in <string1> which can't be executed (⍎) will be replaced quietly by the input string!
      ⍝  Returns
      ⍝    string2:  string1 with all name- or value-Strings replaced by their values as executed (see errOnNull).
      ⍝  Internal:
      ⍝    _map_tries:  ∆MAP will recursively-- to this many tries-- replace ⍎XXX strings with values until there are no more changes.
      ⍝               The reason for the _map_tries limit:
      ⍝                     to prevent runaway chains:  a←'⍎b' b←'⍎c' ... z←'⍎a'. If not reached, costs no overhead.
    errMap←'∆MAP: Invalid call' ⋄ _map_tries←10
    ∆MAP←{
          ⍺←0⊃⎕RSI ⋄ where errOnNull←2↑⍺,1 ⋄ skip←⎕UCS 0 
          _map_tries{
              curTries←⍺
              post←'⍎⍎' '⍎(?|(([\w_∆⍙⎕\#]+)(\.(?-1))*)|\{(\N*?)\})'⎕R{
                  0/⍨DEBUG⍲errOnNull::⍵ ∆FLD 0⊣errMap ⎕SIGNAL errOnNull/11
                  0=⍵.PatternNum:'⍎',skip
                  0≠≢f1←⍵ ∆FLD 1:⍕where⍎f1 
              }⍠optsSingle⊣pre←⍵
              (curTries>0)∧post≢pre:(curTries-1)∇ post
              post~skip
          }⍵
    }
  ⍝ Set SHOW_BLANKS_IN_PATS to 1 if you want to pass 'xx' option to ⎕R so it ignores actual blanks. If 0, actual blanks are removed via APLL
  ⍝ (Useful for troubleshooting to see all original blanks in patterns generated).
    SHOW_BLANKS_IN_PATS ← 0
    NoBlanks←SHOW_BLANKS_IN_PATS∘{0=⍺: ⍵~' ' ⋄ preL←'\Q','\E',⍨pre←'(?xx)' ⋄ pre, preL ⎕R ''⊣⍵}  
    Map←NoBlanks ⎕THIS∘∆MAP

    ⍝ ∆RX:   "Replace patterns pat in string ⍵ with {target}, EXCEPT within quoted strings or comments, 
    ⍝         as long as each pat does not explicitly match prior to and including any part of a single-quoted string ('...') or comment (⍝...)."
     ⍝    strings2 ←   [multi/⍺: 1]  pats/⍺⍺  ∆RX  targs/⍵⍵ ⊣ strings/⍵
    ⍝         opts:     optsMulti (default) or whatever options you want.
    ⍝         pats:     One or more strings
    ⍝         targs:    Either a function or replacement string(s) compatible with the pattern strings (pats).
    ⍝                   If a function, PatternNum will be as expected (hiding internal patterns for matching quoted strings and comments).
    ⍝         strings:  The source strings, consisting of one or more string vectors
    ⍝         strings2: The result strings.
    ⍝
      skipP← ,⊂ NoBlanks '(?: '' [^'']* '')+ | ⍝ \N*  '  
      ∆RX←{⍺←optsMulti ⋄ opts←⍺
        ww←⍵⍵ ⋄ nSkip←≢skipP ⋄ skipR←nSkip⍴⊆'\0'
        pats←(skipP,⊆⍺⍺) 
        2=⎕NC 'ww': pats ⎕R repl ⍠opts⊣⍵  ⊣repl←skipR,((≢⊆⍺⍺))⍴⊆ww
        pats ⎕R { ⍵.PatternNum∊⍳nSkip: ⍵ ∆FLD 0 ⋄ ⍵.PatternNum-←nSkip ⋄ ⍵.Case← ⍵.PatternNum∘∊ ⋄ ww ⍵ }⍠opts⊣⍵
      }

 ⍝  pXXXXX : Regexp Patterns; _pXXXXX: temporary/local RegExp Patterns 
 ⍝  Match recursive balanced {}, [], (), including multilines (with Mode M), sq strings 'just so', dq strings "just so", and comments ⍝ just so
 ⍝  "Uses up" ??? fields.
    _pMatchedPunct←'(?: (?J) (?<NAME> LB  (?> [^LBRB''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&NAME)* )+ RB))'
    ⍝ noB: If ⍺=1, remove blanks; if ⍺=0, prefix '(?X)' to ignore blanks everywhere!
    pBrace←NoBlanks 'NAME' 'LB' 'RB' ⎕R 'brace' '\\{' '\\}'⊣_pMatchedPunct
    pBrack←NoBlanks 'NAME' 'LB' 'RB' ⎕R 'brack' '\\[' '\\]'⊣_pMatchedPunct
    pParen←NoBlanks 'NAME' 'LB' 'RB' ⎕R 'paren' '\\(' '\\)'⊣_pMatchedPunct

    pFauxZilde←          '\(\h*\)'
    pName ←   NoBlanks   '(?: ( [\pL_∆⍙⎕#⍺⍵] [\w_∆⍙⎕#⍺⍵]*) (?: \. (?-1) )* )'
    pNum  ←   NoBlanks   '(?i) ¯? ( \d | \.  (?=\d))  [\d\.EJ¯]* '    ⍝ Good:  .5  5   5.0 .5E¯2    Bad:  .  .E¯2
    pSQuote←  NoBlanks   '(?: '' [^'']* '')+ '
    pDQuote←  NoBlanks   '(?: " [^"]*    ")+ '    ⍝ All double quote strings are handled at <Process>
  ⍝ pDQuotePlus:  If suffix <TYPE> is any of vVmMsS it's accepted. Any other suffix is treated as (part of) the following token and TYPE is ''.
    pDQuotePlus←Map      '(⍎pDQuote)(?<TYPE>[vVmMsS]?)'         
    pComment← NoBlanks   ' ⍝ \N* $'
    pAtomSimple←         '( (?| ⍎pName | ⍎pNum | ⍎pSQuote)  (?: \s* (?| ⍎pName | ⍎pNum | ⍎pSQuote) )* ) '
    pGroup←Map           '(?: ⍎pName | ⍎pBrace | ⍎pParen | ⍎pNum )'

  ⍝ if then else:    name ← (cond) :TH {action} :EL {action}
    pIfThenElse←Map '(?<IF>⍎pGroup) \h*:TH\h* (?<THEN>⍎pGroup) (?| \h*:EL\h* (?<ELSE>⍎pGroup) | (?<ELSE>) )'

    _aListP←'(?:⍎pGroup) (?:\h* ⍎pGroup)*'
    _aQuoteP←'`{1,}'
    _aArrowP←'→{1,}'
    _atomMonad← Map'(⍎_aQuoteP \s* ( ⍎pAtomSimple | ⍎pBrace | ⍎pParen ))'
    _atomDyad←  Map'(( ⍎pAtomSimple | ⍎pBrace | ⍎pParen)  \s* ⍎_aArrowP )'
    pAtom←      Map'(⍎_atomMonad | ⍎_atomDyad) '

    pLeftArrow ← NoBlanks ' (?<= ^|[[(:⋄] ) (\s* ← )'

  ⍝ Scan4Atoms scans zero or more lines for ALIST and MAP expressions and converts them into std APL.
  ⍝ Syntax:
  ⍝       Scan4Atoms line1 line2 ... 
  ⍝ Action: 
  ⍝       ○   converts each name in an atomic expression to a quoted string.
  ⍝           INPUT:  ` jack 'ted  ' 25j3 #.my.name.is ⎕IO  
  ⍝           RESULT:  'jack' 'ted  ' 25j3 '#.myname.is' '⎕IO'  
  ⍝       ○   converts each code specification into a namespace, which will contain a single name 'fn' which when executed calls the
  ⍝           code specification as an ambivalent function.
  ⍝           INPUT:    ⎕← me ← ` {⍺⍳⍵} ⋄  1 2 3 me.fn 2   ⍝ ⎕IO←0
  ⍝           OUTPUT:   [FnPtr 1]                          ⍝ Display form...
  ⍝           RESULT:   1
  ⍝           An ATOMLIST or ALIST (for short: used below) consists of
  ⍝             1)  [value list] a list of names (simple or fully-qualified), numbers, and quoted strings
  ⍝             2)  [code]       a single dfn {}; a train or fn-related code or names inside parens (+.×) or (name1,name2).
  ⍝              ∘    A value list may contain 1 or more items.
  ⍝              ∘    A code specification may contain exactly one dfn, or parenthesized code expression.
  ⍝           An explicit ATOMLIST or ALIST  consists of a backtick followed by an ALIST
  ⍝               ` fred 'mary' ¯45        
  ⍝               ` {⍳⍵}   
  ⍝               ` (+.×)  
  ⍝           A MAP consists of an atomic specification followed by a right arrow, followed by any APL expression:
  ⍝                 ATOMLIST  →  APL_EXPRESSION
  ⍝           e.g.   (name → 'John Q. Smith'), (address → 95), (temp celsius → 12)
  ⍝           An explicit ALIST is a "regular" APL expression, so it may be used to the right of an arrow
  ⍝                  (address home → `123 Main St)
  ⍝           Do not use an explicit ALIST on the left-side of a MAP:
  ⍝             [INVALID]  (` name → 'John Q Smith')
  ⍝           Expressions with a single ` or → always generate a vector result, a value list of 1 or more vectors.
  ⍝           Often, it's convenient to be able to assume you are always handed a list of values...
  ⍝           Sometimes it's useful to generate a scalar, when there is just one item:
  ⍝           Expressions with doubled `` or →→ work exactly like their singular counterparts, except:
  ⍝             An ALIST returned from `` or →→ (LHS only) will be a scalar, unless there are at least 2 items in the list.
  ⍝           Example of single or double `.  
  ⍝             alpha beta←1 2                   ⍝       variables in the ws
  ⍝             Scan4Atoms '⎕NC `alpha'         ⍝       ` statement:  ⎕NC ` alpha
  ⍝           ⎕NC (⊆'alpha')                      ⍝       result is a vector of vectors (depth [≡] 2), even though 1 name.
  ⍝             ⎕NC (⊆'alpha') 
  ⍝           2.1                                 ⍝       ⎕NC on depth 2 returns name class and subclass.
  ⍝             Scan4Atoms '⎕NC `alpha beta'
  ⍝           ⎕NC (⊆'alpha' 'beta')
  ⍝             ⎕NC (⊆'alpha' 'beta')            ⍝       Same as ⎕NC ('alpha' 'beta')
  ⍝           2.1 2.1
  ⍝             Scan4Atoms '⎕NC ``alpha'        ⍝       `` statement:  ⎕NC `` alpha
  ⍝           ⎕NC ('alpha')                       ⍝       result is a simple char vector (depth [≡] 1), when just 1 name.
  ⍝             ⎕NC ('alpha')
  ⍝          2                                   ⍝       ⎕NC on depth 1 string returns simple nameclass.
  ⍝             Scan4Atoms '⎕NC ``alpha beta'
  ⍝          ⎕NC ('alpha' 'beta')
  ⍝             ⎕NC ('alpha' 'beta') 
  ⍝          2.1 2.1
    _atomCtr←0
    SQ_SP_SQ←SQ,' ',SQ  
    TMP_CTR←0 ⋄ '⍙' #.⎕NS ''
    Process←{
          ⍝ types (⍺) for procQuotedNL
          ⍝   "any double_quoted string"type
          ⍝   V/v (default): create vector of string vectors.                     V: Removing leading blanks from all but first line.
          ⍝   M/m          : create a matrix, one line per vector.                M: Ditto
          ⍝   S/s          : create a string with CRs (preferred by Dyalog APL)   S: Ditto
          ⍝ For pDQuotePlus, field 'TYPE' must be ∊ VvMmSs; otherwise, it's ignored and treated as 'v' (lower case).

          MatchVarious← {
              ⍵.Case 0:  '⍬'
              ⍵.Case 1: '#.⍙.T',(⍕TMP_CTR),'←'  ⊣ TMP_CTR+←1 
              type←⍵ ∆FLD 'TYPE'
              procQuotedNL← { type←1↑⍺,'V' 
                  s←NormalizeString ⍵
                  pat← '\R','\s*'/⍨type∊'VMS'
                type∊'Ss': pat ∆RM  SQ_CR_SQ⊣s
                  s←pat ∆RM SQ_SP_SQ⊣s
                type∊'Mm':'↑',s 
                  s
              } 
              PARENS∘Affix type∘procQuotedNL ⍵ ∆FLD 1 
          }
          MatchIfThenElse←{
              if then else←⍵ ∆FLD 'IF' 'THEN' 'ELSE'
              else←'{⎕NULL}' else ⊃⍨ 0≠≢else 
               if,'{⍺:_←',then,'0⋄1:_←',else,'0}0' 
          }
          Scan4Parens ← { outerFn←∇ 
                pParen ∆RX {
                     PARENS∘Affix ⊢ pBrace '\R' ∆RX {⍵.PatternNum = 0: BRACES∘Affix outerFn Chop ⍵ ∆FLD 0 ⋄ ' '}⊣Chop ⍵ ∆FLD 0 
                }⊣⍵
          }
          Scan4Atoms←{
              matchAtoms←{
              pfx←'`' ⋄ sfx←'→'
              procByType←{affix atoms←⍵
                  ' ({'∊⍨1↑atoms:'(',atoms,FN_PTR_STR,'⊣',(⍕_atomCtr),')'⊣_atomCtr⊢←2147483648|_atomCtr+1
                    nitems←0 ⋄ listRequired←1=≢affix
                    s←pSQuote pName pNum ⎕S {
                        f0←⍵ ∆FLD 0
                        isQuote isName isNum←0 1 2=⍵.PatternNum
                        nitems+←1
                        isNum: f0
                        len1←1=(≢f0)-2×isQuote
                        s←SQ{isName: ⍺,⍵,⍺ ⋄ ⍵}f0
                        len1: '(,',s,')'
                        s 
                    }⊣⊆atoms
                    listPfx←',⊂'/⍨listRequired∧nitems=1
                    '(',listPfx,')',⍨¯1↓∊' ',⍨¨s 
              }
              f0←⍵ ∆FLD 0
              n←+/pfx=2↑f0
            ⍝ ` atomList
              0≠n:procByType affix_atoms⊣affix_atoms←(n↑f0)(∆DLB n↓f0)
              n←-+/sfx=¯2↑f0
            ⍝ atomList → apl_code
              0≠n:'(',(procByType affix_atoms),'){⍺⍵}'⊣affix_atoms←(n↑f0)(∆DTB n↓f0)
              ⎕SIGNAL/'Preprocessor: Logic error' 11
              }
              pAtom ⎕R  matchAtoms⍠optsMulti⊣⍵
          }

          s←  pFauxZilde pLeftArrow pDQuotePlus ∆RX    MatchVarious          ⊣⍵
          s←  pIfThenElse ∆RX                          MatchIfThenElse       ⊣s 
          s←                                           Scan4Atoms Scan4Parens s 
          s 
    }

    ∆ASSERT←{⍺←'ASSERTION FAILURE' ⋄ ⍵:0 ⋄ ⍺ ⎕SIGNAL 911}

⍝   Tokenize:  Create a tokenized version of a program <pgm>.
⍝   tokenized_pgm ← [options] Tokenize pgm
⍝    ...
⍝
⍝   Tokenize: DECLARATIONS AND FN DEFINITIONS
      NL_VIS←'\n'   ⋄  SEMI_ALT←'SEMIalt' 
      errExtra       ←'Extra right paren/brace/bracket' 
      errMissingPair ←'Missing right paren/brace/bracket'
      errLogic       ←'Logic error: Invalid token type seen for token '
      IX_TOK IX_TYPE IX_BRAK IX_SPACES←⍳4 ⋄ DUMMY_ENTRY ← ¯1
⍝ 
⍝   Tokenize::ScanInput: key declarations
      pLeftB← '[[({]'
      pRightB←'[])}]'
      pSpaces pAnyNL pStmt pSemi pSymbol←'\h+' '\R' '⋄' ';' '\N' 

      tNm2← tBRKo tBRKc tNL tNLd tNLc tQT tSP tNM tNUM tSEMI tSEMIa tSTMT tSYM←'BRKopen' 'BRKclose' 'NL' 'NLdfn' 'NLcont'  'QT' 'SP' 'NM' 'NUM' 'SEMI' 'SEMIalt' 'STMT' 'SYM'
      typeNames← ((⊂'QT'),¨'VvMmS'),tNm2
   
      patList ← pSQuote pDQuotePlus pSpaces pName  pNum pLeftB pRightB pAnyNL pStmt pSemi pSymbol
                cSQuote cDQuote     cSpaces cName  cNum   cLeftB cRightB cAnyNL cStmt  cSemi  cSymbol  ← ⍳≢patList
      typeList← tQT     tQT         tSP     tNM    tNUM   tBRKo  tBRKc   tNL    tSTMT  tSEMI  tSYM       
      
      ∇r←peekBrak
        :IF 0=≢tkn.brackets ⋄ r←⍬ ⋄ :Else ⋄ r←⊃⌽tkn.brackets ⋄ :ENDIF
      ∇
    
⍝   Tokenize: Tokenize function
⍝   Because of how APL formats, we use CR (13) not NL (10) for the newline token...
    Tokenize←{
    ⍝   Show token typenames:   ⍺ ≡ ¯1   (ignores right argument)
    ⍝   Indicate token number:  ⍺ +← 1   (default: no token number)
    ⍝   Treat space as token :  ⍺ +← 2   (default: # spaces is field[3] for each preceding token)
    ⍝   Display fancily:        ⍺ +← 4   (Honors all other flags)  (NL token (CR char) will be replaced by text '\n')
    ⍝   Return just tokens   :  ⍺ =  8   (All other flags are ignored)
    
        ⍺←0 
      ⍝ 8           4       2       1
        ¯1≡⍺: {(⊂⍋⍵)⌷⍵}typeNames   ⍝ Shows all token typenames
        fJustTokens fPretty fSpaces fAddTokenNum←2 2 2 2⊤⍺          ⍝ f___: Flags

        tkn←⎕NS ''
        tkn.table←,⊂' '  'SP' 0 DUMMY_ENTRY          ⍝ Assume 1st token consists of leading spaces of length ¯1, i.e. a dummy (removed below unless updated)
        tkn.brackets←⍬ 
        tkn.add←tkn.{ ∆ASSERT 3 4∊⍨≢⍵: ⋄ ''⊣ table,←⊂ 4↑ ⍵ , 0 }  
    
      ⍝ ScanInput: key subfunctions
        ScanRightB←{
          0=≢⍵: errExtra ⎕SIGNAL 11
          ⍺≠'})]?'⌷⍨'{(['⍳(⍵ IX_TOK⊃tkn.table): 11 ⎕SIGNAL⍨ wrongE,⍺ 
          (⍵ IX_BRAK⊃tkn.table)⊢←⍬⍴≢tkn.table 
          tkn.brackets↓⍨←¯1  
          ⍵   
        }
        ScanSemi←{ std alt←⍺ 
          0=≢⍵: alt ⋄ '['=1↑⍵ IX_TOK⊃tkn.table: std ⋄ alt
        }
        ScanDQType←{~CR∊⍺: '' ⋄ t←1↑⍵,'v' ⋄  'Logic Error' ∆ASSERT t∊'VvMmSs': ⋄ t }
        ScanNLType←{0=≢⍵: 'NL' ⋄  gov← ⍬⍴⍵ IX_TOK⊃tkn.table ⋄ '{'≡gov: tNLd ⋄ gov∊'([': tNLc ⋄ tNL }  ⍝ Is NL a linesep in dfns (handled by APL) or in an "extension"
 
      ⍝ ScanInput:  main
        ScanInput←{
               tkn.table ⊣ patList ⎕R {
                case←⍵.PatternNum∘∊
                type←⍵.PatternNum⊃typeList
                f0←⍵ ∆FLD 0    
              ⍝                        tok   type  current  nspaces
              ⍝                                    bracket      
                etcC←cSQuote cName cSymbol cStmt  
                case etcC:    tkn.add  f0    type  peekBrak        
                case cSpaces: {
                  fSpaces: tkn.add     f0    type  peekBrak (≢f0) 
                              ''                                 ⊣ (IX_SPACES⊃⊃⌽tkn.table)←≢f0  
                }⍬                                                
                case cDQuote: tkn.add  df0   type  peekBrak      ⊣ df0← NormalizeString f1 ⊣ type,←f1 ScanDQType subtype⊣(f1 subtype)←⍵ ∆FLD 1 'TYPE'
                case cNum:    tkn.add  vfi   type  peekBrak      ⊣ vfi ← (⊃⌽⎕VFI f0)
                case cLeftB:  tkn.add  f0    type  peekBrak      ⊣ tkn.brackets,← ≢tkn.table     ⍝ Will show right bracket...
                case cRightB: tkn.add  f0    type  curIx         ⊣ curIx← f0 ScanRightB peekBrak
                case cSemi:   tkn.add  f0    type  peekBrak      ⊣ f0 type←(f0  type) (f0 SEMI_ALT) ScanSemi peekBrak                                                  
                case cAnyNL:  tkn.add  tNl   nlTyp peekBrak      ⊣ nlTyp←ScanNLType peekBrak    ⊣ tNl← fPretty ⊃ CR NL_VIS
                11 ⎕SIGNAL⍨errLogic '"',f0,'"'
              }⍠optsMulti⊣ ⍵
        }
  
        FormatResults←{ ⍝ ⍵: tkn.table
            firstEmpty←DUMMY_ENTRY=IX_SPACES⊃⊃tkn.table
            tt←firstEmpty↓⍵                                     ⍝ If leading entry is an empty (dummy) token, omit it.
            DUMMY_ENTRY∊IX_BRAK⊃¨tt: errMissingPair ⎕SIGNAL 11  ⍝ If any left bracket is not paired with a right bracket, signal an error!
            (IX_BRAK⊃¨tt)-←firstEmpty                           ⍝ If leading dummy token is removed, update governing bracket indices.
            fJustTokens: IX_TOK⊃¨tt
            tt←{fAddTokenNum: ⍵,⍨¨⍳≢⍵ ⋄ ⍵}tt

            headings← (↑'tokn' ' id') (↑'tokn' 'text') (↑'' 'type')   (↑'brkt' 'indx') (↑'trail' 'space')
            fPretty:(headings↑⍨-≢⊃tt) ⍪ ↑tt
            tt 
        }
      ⍝  Executive 
        FormatResults ScanInput ⊆⍵
    }

  ⍝ Delete "temporary" names (prefixed with _) from final namespace
    ⎕EX  '_' ⎕NL 2 3

:Endnamespace
