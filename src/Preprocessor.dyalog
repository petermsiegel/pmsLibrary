:namespace Preprocessor
  ⍝ NOTE: All namespace names beginning of the form _xxx are ephemeral, erased at the end of the namespace load.
  ⍝
  ⍝ RUNTIME_ASSIST: If 1, instead of constant functions or variables, ⎕SE.⍙xxx variable names are defined for run-time use.
  ⍝                 If 0, each occurrence of special functions is emitted as a single-line dfn of possibly moderate length.
    RUNTIME_ASSIST←1           
    ⎕IO←0
    DEBUG←0  ⍝

    SQ←'''' ⋄ DQ←'"' ⋄ DQ2←2⍴DQ
    LP←'(' ⋄ RP←')'
    optsM←('Mode' 'M')('EOL' 'LF')('NEOL' 1)('UCP' 1)
    optsS←            ('EOL' 'LF')('NEOL' 1)('UCP' 1)

    dlb←{⍵↓⍨+/∧\' '=⍵}            ⍝ Delete leading blanks
    dtb←{⍵↓⍨-+/∧\' '=⌽⍵}          ⍝ Delete trailing blanks
    doubleSQ← {⍵/⍨1+⍵=SQ}         ⍝ Double internal single-quotes
    halveDQ←  {⍵/⍨~DQ2⍷⍵}         ⍝ Convert doubled double-quotes to single
    enParen←{LP,⍵,RP}             ⍝ Put ⍵ in parens
    enQuoteRaw←{SQ,⍵,SQ}          ⍝ Put ⍵ in quotes-- no other processing
    enQuote← enQuoteRaw doubleSQ  ⍝ Put ⍵ in quotes, doubling any single quotes

  ⍝ Regexp constant
    escN_RE←'\x{1}\\n'            ⍝ We replace certain \n newlines into 01X followed by '\n' so most internal patterns can assume a single "line"
                                  ⍝ See canonicalInput and canonicalOutput
  

  ∇ {void}←_USE_RUNTIME_ASSIST
    _fnPtr← '⍙FNPTR←{n←(⊃⎕RSI).⎕NS ⍬⋄n.fn←⍺⍺⋄n⊣n.⎕DF''[fnPtr '',(⍕⍵),'']''}'
    :If void←RUNTIME_ASSIST
       ⎕SE       ⍎_fnPtr
       ⎕SE.⍙CR←  ⎕UCS 13
       fnPtr←    '⎕SE.⍙FNPTR'
       SQcrSQ←   SQ,',⎕SE.⍙CR,',SQ 
    :Else 
       fnPtr←   _fnPtr
       SQcrSQ←  SQ,',(⎕UCS 13),',SQ
    :EndIf 
    ∇
    _USE_RUNTIME_ASSIST

    ⍝ strings ← ns ∆FLD fieldIDs
    ⍝   ns:        The namespace passed to the right operand of ⎕R or ⎕S (as ⍵)
    ⍝   fieldIDs:  One or more identifiers for regexp fields, each
    ⍝              a string field name (@S) or integer field number (@I), or 0 for the entire match.
    ⍝   If a field is non-existent or currently has no value, a null string '' is returned (without complaint).
      ∆FLD←{
          0=⎕NC'⍺':⎕SIGNAL/'∆FLD left arg (a regexp ns) is missing' 11
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
      ⍝    mapTries:  ∆MAP will recursively-- to this many tries-- replace ⍎XXX strings with values until there are no more changes.
      ⍝               The reason for the mapTries limit:
      ⍝                     to prevent runaway chains:  a←'⍎b' b←'⍎c' ... z←'⍎a'. If not reached, costs no overhead.
    mapErr←'∆MAP: Invalid call' ⋄ mapTries←10
      ∆MAP←{
          ⍺←0⊃⎕RSI ⋄ where errOnNull←2↑⍺,1 ⋄ skip←⎕UCS 0 
          mapTries{
              curTries←⍺
              post←'⍎⍎' '⍎(?|(([\w_∆⍙⎕\#]+)(\.(?-1))*)|\{(.*?)\})'⎕R{
                  0/⍨DEBUG⍲errOnNull::⍵ ∆FLD 0⊣mapErr ⎕SIGNAL errOnNull/11
                  0=⍵.PatternNum:'⍎',skip
                  0≠≢f1←⍵ ∆FLD 1:⍕where⍎f1 
              }⍠optsS⊣pre←⍵
              (curTries>0)∧post≢pre:(curTries-1)∇ post
              post~skip
          }⍵
      }
    _noB←0∘{0=⍺: ⍵~' ' ⋄ pre←'(?X)' ⋄ pre≡4↑⍵: ⍵ ⋄ pre,⍵}   ⍝ In regexp patterns, use \s or \h for spaces, never ' '
    _MAP←_noB ⎕THIS∘∆MAP

 ⍝  _____P : Regexp Patterns
 ⍝  Match recursive balanced {}, [], (), including multilines (with Mode M), sq strings 'just so', dq strings "just so", and comments ⍝ just so
 ⍝  "Uses up" ??? fields.
    _matchedP←'(?: (?J) (?<NAME> LB  (?> [^LBRB''"⍝]+ | ⍝.*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&NAME)* )+ RB))'
    ⍝ noB: If ⍺=1, remove blanks; if ⍺=0, prefix '(?X)' to ignore blanks everywhere!
    braceP←_noB 'NAME' 'LB' 'RB' ⎕R 'brace' '\\{' '\\}'⊣_matchedP
    brackP←_noB 'NAME' 'LB' 'RB' ⎕R 'brack' '\\[' '\\]'⊣_matchedP
    parenP←_noB 'NAME' 'LB' 'RB' ⎕R 'paren' '\\(' '\\)'⊣_matchedP

    fauxZildeP←      '\(\h*\)'
    nameP ←   _noB   '(?: ( [\pL_∆⍙⎕#⍺⍵] [\w_∆⍙⎕#⍺⍵]*) (?: \. (?-1) )* )'
    numP  ←   _noB   '(?i) ¯? [\d\.] [\d\.EJ¯]* '
    quoteP←   _noB   '(?: '' [^'']* '')+ '
    dQuoteP←  _noB   '(?: " [^"]*    ")+ '    ⍝ All double quote strings are handled at <canonicalInput>
    dQuotePlusP←_MAP '(⍎dQuoteP)(?<TYPE>\pL?)'
    commentP← _noB   ' ⍝ .* $'
    atomSimpleP←     '( (?| ⍎nameP | ⍎numP | ⍎quoteP)  (?: \s* (?| ⍎nameP | ⍎numP | ⍎quoteP) )* ) '
    groupP←_MAP      '(?: ⍎nameP | ⍎braceP | ⍎parenP | ⍎numP )'

  ⍝ if then else:    name ← (cond) :TH {action} :EL {action}
    ifThenElseP←_MAP '(?<IF>⍎groupP) \h*:TH\h* (?<THEN>⍎groupP) (?| \h*:EL\h* (?<ELSE>⍎groupP) | (?<ELSE>) )'

    _aListP←'(?:⍎groupP) (?:\h* ⍎groupP)*'
    _aQuoteP←'`{1,}'
    _aArrowP←'→{1,}'
    _atomMonad← _MAP'(⍎_aQuoteP \s* ( ⍎atomSimpleP | ⍎braceP | ⍎parenP ))'
    _atomDyad←  _MAP'(( ⍎atomSimpleP | ⍎braceP | ⍎parenP)  \s* ⍎_aArrowP )'
    atomP←      _MAP'(⍎_atomMonad | ⍎_atomDyad) '

      SQspSQ←SQ,' ',SQ  
      canonicalInput←{
          ⍝ types (⍺) for mapQuotedNL
          ⍝   "any double_quoted string"type
          ⍝   V/v (default): create vector of string vectors.                     V: Removing leading blanks from all but first line.
          ⍝   M/m          : create a matrix, one line per vector.                M: Ditto
          ⍝   S/s          : create a string with CRs (preferred by Dyalog APL)   S: Ditto
          mapQuotedNL← { type←1↑⍺,'V' 
              s←enQuote halveDQ 1↓¯1↓⍵
              pat← '\n','\s*'/⍨type∊'VMS'
              type∊'Ss': pat ⎕R  SQcrSQ⍠optsM⊣s
              s←pat ⎕R SQspSQ⍠optsM⊣s
              type∊'Mm':'↑',s 
              s
          } 
          procDQStrings← {
              ⍵.PatternNum=2:  '⍬'
              ⍵.PatternNum≠3:  ⍵ ∆FLD 0  
              type←⍵ ∆FLD 'TYPE'
              enParen type∘mapQuotedNL ⍵ ∆FLD 1 
          }
          procDFns←      { 
              f0←⍵ ∆FLD 0 ⋄ ⍵.PatternNum≠2:  f0 ⋄ '\n'⎕R escN_RE⍠optsM⊣ f0
          }
          procIfThenElse←{
              if then else←⍵ ∆FLD 'IF' 'THEN' 'ELSE'
              else←'{⎕NULL}' else ⊃⍨ 0≠≢else 
               if,'{⍺:_←',then,'0⋄1:_←',else,'0}0' 
          }

          s←quoteP commentP  fauxZildeP dQuotePlusP ⎕R procDQStrings⍠optsM⊣⍵
          s←ifThenElseP ⎕R  procIfThenElse⊣s 
          quoteP commentP braceP ⎕R procDFns⍠optsM⊣s
      }
      canonicalOutput←{  
           escN_RE ⎕R '\n'⍠optsM⊣⊆⍵
      }

  ⍝ An ATOMLIST or ALIST (for short: used below) consists of
  ⍝    1)  [value list] a list of names (simple or fully-qualified), numbers, and quoted strings
  ⍝    2)  [code]       a single dfn {}; a train or fn-related code or names inside parens (+.×) or (name1,name2).
  ⍝    ∘    A value list may contain 1 or more items.
  ⍝    ∘    A code specification may contain exactly one dfn, or parenthesized code expression.
  ⍝ An explicit ATOMLIST or ALIST  consists of a backtick followed by an ALIST
  ⍝         ` fred 'mary' ¯45        
  ⍝         ` {⍳⍵}   
  ⍝         ` (+.×)  
  ⍝ A MAP consists of an atomic specification followed by a right arrow, followed by any APL expression:
  ⍝           ATOMLIST  →  APL_EXPRESSION
  ⍝ e.g.   (name → 'John Q. Smith'), (address → 95), (temp celsius → 12)
  ⍝ An explicit ALIST is a "regular" APL expression, so it may be used to the right of an arrow
  ⍝            (address home → `123 Main St)
  ⍝ Do not use an explicit ALIST on the left-side of a MAP:
  ⍝       [INVALID]  (` name → 'John Q Smith')
  ⍝ 
  ⍝ Expressions with a single ` or → always generate a vector result, a value list of 1 or more vectors.
  ⍝ Often, it's convenient to be able to assume you are always handed a list of values...
  ⍝ Sometimes it's useful to generate a scalar, when there is just one item:
  ⍝ Expressions with doubled `` or →→ work exactly like their singular counterparts, except:
  ⍝       An ALIST returned from `` or →→ (LHS only) will be a scalar, unless there are at least 2 items in the list.
  ⍝ Example of single or double `.  
  ⍝       alpha beta←1 2                   ⍝ variables in the ws
  ⍝       procAtoms '⎕NC `alpha'         ⍝ ` statement:  ⎕NC ` alpha
  ⍝    ⎕NC (⊆'alpha')                      ⍝ result is a vector of vectors (depth [≡] 2), even though 1 name.
  ⍝       ⎕NC (⊆'alpha') 
  ⍝    2.1                                 ⍝ ⎕NC on depth 2 returns name class and subclass.
  ⍝       procAtoms '⎕NC `alpha beta'
  ⍝    ⎕NC (⊆'alpha' 'beta')
  ⍝       ⎕NC (⊆'alpha' 'beta')            ⍝ Same as ⎕NC ('alpha' 'beta')
  ⍝    2.1 2.1
  ⍝       procAtoms '⎕NC ``alpha'        ⍝ `` statement:  ⎕NC `` alpha
  ⍝    ⎕NC ('alpha')                       ⍝ result is a simple char vector (depth [≡] 1), when just 1 name.
  ⍝       ⎕NC ('alpha')
  ⍝    2                                   ⍝ ⎕NC on depth 1 string returns simple nameclass.
  ⍝       procAtoms '⎕NC ``alpha beta'
  ⍝    ⎕NC ('alpha' 'beta')
  ⍝       ⎕NC ('alpha' 'beta') 
  ⍝    2.1 2.1
 
  ⍝ procAtoms scans zero or more lines for ALIST and MAP expressions and converts them into std APL.
  ⍝ Syntax:
  ⍝       procAtoms line1 line2 ... 
  ⍝ Action: 
  ⍝       ○   converts each name in an atomic expression to a quoted string.
  ⍝           INPUT:  ` jack 'ted  ' 25j3 #.my.name.is ⎕IO  
  ⍝           RESULT:  'jack' 'ted  ' 25j3 '#.myname.is' '⎕IO'  
  ⍝       ○   converts each code specification into a namespace, which will contain a single name 'fn' which when executed calls the
  ⍝           code specification as an ambivalent function.
  ⍝           INPUT:    ⎕← me ← ` {⍺⍳⍵} ⋄  1 2 3 me.fn 2   ⍝ ⎕IO←0
  ⍝           OUTPUT:   [fnPtr 1]                          ⍝ Display form...
  ⍝           RESULT:   1
    atomCtr←0

      procAtoms←{
          atomProc←{
              pfx←'`' ⋄ sfx←'→'
              procByType←{affix atoms←⍵
                  '({'∊⍨1↑atoms:'(',atoms,fnPtr,'⊣',(⍕atomCtr),')'⊣atomCtr⊢←2147483648|atomCtr+1
                  nitems←0 ⋄ listRequired←1=≢affix
                  s←quoteP nameP numP ⎕S {
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
              0≠n:procByType affix_atoms⊣affix_atoms←(n↑f0)(dlb n↓f0)
              n←-+/sfx=¯2↑f0
              ⍝ atomList → apl_code
              0≠n:'(',(procByType affix_atoms),'){⍺⍵}'⊣affix_atoms←(n↑f0)(dtb n↓f0)
              ⎕SIGNAL/'Preprocessor: Logic error' 11
          }
          atomP ⎕R atomProc⍠optsM⊣⍵
      }

      process←canonicalOutput procAtoms canonicalInput 

  ⍝ Delete "temporary" names (prefixed with _) from final namespace
    ⎕EX  '_' ⎕NL 2 3

:Endnamespace
