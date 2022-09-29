∇ {result}←{fOpts} ∆FIX linesIn
;⎕IO;⎕ML;⎕TRAP                                       ⍝ ⎕- Sys
;args;hereLines;î;line;linesOut                      ⍝ general pgm vars  (î- ignore result)
;fHereActive;fIndent;fStyle                          ⍝ f- flags
;fDef;fTrim;fVarName                    
;pEndHere;pHERE;pHERE_WIKI                           ⍝ p- Regex pats*
;rHERE                                               ⍝ r- Regex replacements or response*
;eUNKNOWN;ePREFIX;eSCRIPT                            ⍝ e- Error text*    
;GetOpts;Set_pEndHere;SpecialQuote2APL;∆Encode;Error ⍝ Fns   (∆Pseudo-Sys, User)          
⍝                                                      * formats: eVars eCONSTS, so for p-, r- objects

⍝ ∆FIX:    [⎕FIX options] ∇  <⎕FIX code lines or fileid>
⍝ An extension of ⎕FIX that handles here-strings and -documents.
⍝ For DESCRIPTION and detailed INFORMATION, see bottom of this function

⍝ Variable Definitions ------------------------------------------------------------------------------------
  ⎕IO ⎕ML←0 1 ⋄ ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)' 

⍝ STYLES for formatting here-string lines. Variable fStyle. See also fTrim
⍝   :STD - vector of char vectors (default).
⍝   :MX  - matrix of chars (via APL mix ↑). 
⍝   :LF  - vec string with Unicode 10 separating lines
⍝   :CR  - vec string with Unicode 13 separating lines-- more useful in Dyalog
⍝   :STR - single vec string without line separators, as if enlist (∊) of :STD vectors.
  STYLES←':STD' ':MX' ':LF' ':CR'  ':STR'

⍝ pHERE: matches :HERE plus any valid local relative user-defined variable name: not ⎕SE.a.b or  #.a.b 
⍝ [\w∆⍙_etc.] is \w for APL chars (with ⍠'UCP' 1). 
⍝ The variable name  may have a single appended comma (,) to indicate it is being appended to.  
  pHERE←       '(?xi) ^ (\h*) ⍝? ( : (?: HERE|STRING|DEF ) ) '   ⍝ <==  ⍝:HERE matches.  ⍝ :HERE does not.
  pHERE,←            '(?| \h+ ([\w∆⍙_.#⎕]+,?) (?![\w∆⍙_.#⎕]) \h* ([^⍝]*) | ()()())' 
  rHERE←       'x\1;\2;\3;\4'  ⍝ See below for format...
  pHERE_WIKI← '(?i)^\h*⍝?(?::(?:HERE|STRING|DEF))\b'
⍝ pEndHere     See Set_pEndHere
  eSCRIPT←     'DOMAIN ERROR: There were errors processing the script '
  ePREFIX←     'DOMAIN ERROR: The prefix "file://" was expected'
  eUNKNOWN←    'DOMAIN ERROR: There were errors processing script (unknown :HERE option "'

  :IF 900⌶⍬  ⋄ fOpts←⊢ ⋄ :ENDIF
⍝ Fast-Path  -------------------------------------------------------------------------------------------
⍝ Fast-path out if nothing that looks like a :HERE directive    
  :IF 0=≢ pHERE_WIKI ⎕S 0⍠('UCP' 1)('Mode' 'M' )('ML' 1)⊣linesIn     ⍝ If no :HERE lines, ⎕FIX as is...
      →FINISH_UP ⊣ linesOut←linesIn            ⍝ Sorry-- it works...
  :ENDIF

⍝ Utility Functions ------------------------------------------------------------------------------------
  Error← {⍺←1 ⋄ ⍺=1: ⍵ ⎕SIGNAL 11   ⋄ 1: î←0}
  Set_pEndHere←{
      0=≢⍵: '(?xi) ^\h* ⍝? :END (?: HERE|STRING|DEF )? \h*                     (?:⍝|$)' 
            '(?xi) ^\h* ⍝? :END (?: HERE|STRING|DEF )? \h+ (?-i) \Q',⍵,'\E \h* (?:⍝|$)' 
  }
⍝ ∆Encode: line ← (style  prependEOL) ∆Encode lines
⍝ Convert here-string lines to the several styles...
⍝    style:      The current style by name
⍝    prependEOL: If 1, the EOL char set by <style>  will ALSO be prepended to the string (useful catenating to existing val).
⍝ Returns a long char string consisting of executable code-- APL functions and quoted text.
  ∆Encode←{ ⍝ Extern: STYLES
      style prependEOL←⍺    
      ∆EnPar←{0=≢⍵: ⍵ ⋄ '(',')',⍨⍵} ⋄ ∆EnQt←{SQ←'''' ⋄ SQ,SQ,⍨(1+⍵=SQ)/⍵} ⋄ ∆2Vec←⍵∘{1=≢⍺: ',',⍵ ⋄ ⍵}
      SELECT←(STYLES⍳⊂style)∘=         ⍝ STYLES← ':STD' ':MX' ':LF' ':CR'  ':STR'
      sSTD sMX sLF sCR sSTR←⍳5
      ∆Enc1←{preEOL postEOL←⍺
          ∨/SELECT sSTD sMX: ∆EnPar ∆2Vec ∆EnQt ⍵
          SELECT sSTR: ∆EnPar ∆EnQt (preEOL/' '),⍵,postEOL/' '
        ⍝ if preEOL is 1, insert an end-of-line char before FIRST entry (as well as later)...
          eol←∊',⎕UCS ','10' '13'/⍨SELECT sLF sCR  
          ∊∆EnPar(∆EnPar preEOL/eol),(∆EnQt ⍵,' '/⍨SELECT sSTR),postEOL/eol
      }
      pfx← '⊆' '⎕FMT↑' '∊' '∊' '∊'/⍨ SELECT sSTD sMX sLF sCR sSTR
      0=≢⍵: '⍬'  
      ⍝ EOL only appear between here lines
      ∊pfx,(prependEOL (¯1+≢⍵) ⍵){ pre last args←⍺⍺
          (pre×⍵=0) (⍵<last) ∆Enc1 ⍵⊃args
      }¨⍳≢⍵
  }  
  GetOpts←{
      hOpts←⍵  
      0=≢hOpts: ⍬
      cmd←1 ⎕C ⊃hOpts ⋄  CASE←(⊂cmd)∘∊⊆  
      NEXT←∇{⍺⍺ 1↓⍵}    ⍝ Recursively call GetOpts to handle each option...
      ⍝ :ENDS text, :UNTIL word  (synonyms)
      ⍝          here string won't end until before line :END word or :ENDHERE word
      ⍝ Default: ends before line :END or :ENDHERE                 
      CASE ':ENDS' ':END' ':UNTIL':{
          hOpts←1↓hOpts           ⍝ Move to next arg (:ends fEndTok)
          (0=≢hOpts) Error ':HERE DOMAIN ERROR: option :ENDS or :UNTIL seen, but no token follows':
          pEndHere∘←Set_pEndHere ⊃hOpts
          NEXT hOpts
      }⍬
      CASE ':FILE':{  ⍝ File id may not have spaces
          hOpts←1↓hOpts ⋄ fi ← ⊃hOpts  
          (~⎕NEXISTS fi) Error 'FILE NAME ERROR: «:FILE ',fi,'» Unable to find or open file.':
          hereLines,←⊃⎕NGET fi 1
          NEXT hOpts  
      }⍬
      CASE STYLES: { 
          fStyle∘←cmd    ⋄ NEXT hOpts 
      }⍬
      CASE ':SP':{  ⍝ :SP undocumented alias for :STR 
          fStyle∘←':STR' ⋄ NEXT hOpts 
      }⍬
      ⍝ :TRIM -  remove leading blanks of subsequent lines to # of 
      ⍝          first here string line, but never truncates those exdented (default)
      ⍝ :NOTRIM- leave leading blanks as entered.
      CASE ':TRIM' ':NOTRIM':{
          fTrim∘←cmd≡':TRIM' ⋄ NEXT hOpts 
      }⍬
      CASE ':DEF':{     ⍝ Alternate method for doing a :DEF 
        fStyle∘←':STD'  ⋄  fDef∘←1
        NEXT hOpts 
      }⍬
      Error eUNKNOWN,cmd,'")'
  }

⍝ SpecialQuote2APL: Find all """...""" and "..." strings, which may span one or more lines. 
  SpecialQuote2APL←{⍺←0
      ⋄ SQ DQ←'''"' ⋄ CR←⎕UCS 13 ⋄ CRcode←⊂SQ,(⎕UCS 13),SQ  
      DTBC←⍺∘{⍺:⍵↓⍨-+/∧\' '=⌽⍵ ⋄ ⍵}¨                          ⍝ Delete trailing blanks conditionally: if ⍺=1
      UnDQ←{DQ2←2⍴DQ ⋄ ⍺: s/⍨1+SQ=s←s/⍨~DQ2⍷s←1↓¯1↓⍵ ⋄ ⍵}     ⍝ <"abc"" isn't"> ==> <abc" isn''t>, w/o '...'.

      ⍝ 0: """..\n.."""   1: "..\n.."     2: '...'           3: ⍝ ..\n
      '"{3}(.*?)"{3}?'  '((?:"[^"]*")+)' '((?:''[^'']*'')+)' '(⍝\N*$)'⎕R{
          SKIP←⍵.PatternNum(~∊)0 1  
          IS_DQ1←⍵.PatternNum=1                        ⍝ "..." requires DQ escaping (""); """...""" does not.
          field1←⍵.Lengths[1]↑⍵.Offsets[1]↓⍵.Block
          SKIP: field1
          str←IS_DQ1 UnDQ field1
          str←∊CRcode@(CR∘=)⊢{⍵/⍨1+⍵=SQ}str
          '(',SQ,str,SQ,')'
      }⍠('Mode' 'M')('DotAll' 1)('EOL' 'CR')⊢DTBC ⍵
  }


⍝ EXECUTIVE ------------------------------------------------------------------------------------------------
  :IF 1≥|≡linesIn                         ⍝ If a single line, must be a fileid.
      linesIn←{
          pl←≢p←'file://'                 ⍝ ⎕FIX requires file:// prefix
          (p≢pl↑⍵):⊃⎕NGET (pl↓⍵) 1        ⍝ ⎕NGET doesn't allow it!
          Error ePREFIX                                
      }linesIn  
  :ENDIF 

  fHereActive←0 ⋄ linesOut←⍬  
  :FOR line :IN linesIn
      :IF 0=fHereActive
          args← ⊃pHERE ⎕S rHERE ⍠'UCP' 1⊣line   ⍝ MATCH HERE-STRING?
          :IF 0=≢args                           ⍝ NO!  SIMPLY APPEND NON-HERE-STRING LINE
              linesOut,← ⊂line
          :ELSE ⋄ fHereActive←1 ⋄ hereLines←⍬   ⍝ YES. START HERE-STRING PROCESSING
              args←';'(≠⊆⊢)⊣args ⋄  (3>≢args) Error eSCRIPT,'(:HERE variable invalid or missing)'  
            ⍝ +-------------------------------------------------------------+
            ⍝ |  INITIALIZE ALL KEY state information for this here-string  |
            ⍝ +-------------------------------------------------------------+
              fStyle←':STD' ⋄ fTrim←1           
              fDef←':DEF'≡4↑1⊃args               ⍝ Major keyword :DEF triggers fStyle←':STD' and fDef←1 
              fVarName←2⊃args
              fIndent←¯1+≢0⊃args                 ⍝ Ignore extra "x" from ⎕S match: even no indent returns a (null) field
              pEndHere←Set_pEndHere ⍬  
              :IF 4=≢args                        ⍝ Options?  
                  î←GetOpts ' '(≠⊆⊢)⊣3⊃args      ⍝ YES. 
              :ENDIF 
              linesOut,← ⊂'⍝',line↓⍨1⌊fIndent    ⍝ Align if space-initial
          :ENDIF
      :ELSE ⍝ 1=fHereActive
          :IF 0=≢pEndHere ⎕S 0 ⍠'UCP' 1⊣line     ⍝ TERMINATING HERE-STRING?   
              hereLines,← ⊂line                  ⍝ NO!
          :ELSE ⋄ fHereActive←0                  ⍝ YES. PROCESS THIS HERE-STRING.
              hereLines←{(-+/∧\⌽⍵∊' ')↓⍵}¨hereLines
            ⍝ If :TRIM, normalize leading blanks (lb) such that the line with the fewest has indentation of 0.
              hereLines{  
                  ~⍵: ⍺ ⋄ 0=≢⍺: ⍺     
                  0=min←⌊/lb←+/⊃∧\¨' '=⍺: ⍺ ⋄ ⍺↓⍨¨lb⌊min   
              }←fTrim
            ⍝ Encode hereLines according to current style and add to linesOut.
              linesOut{ 
                  fPrepend←','=¯1↑fVarName  ⍝ fPrepend? Don't delete prefixed CR, LF or space
                  asign←(' '⍴⍨fIndent+6),fVarName,'←'
                  asign,←fDef/ '⎕SE.Link.Deserialise '   ⍝ KLUDGE - EXPERIMENTAL
                  encode←fStyle fPrepend ∆Encode hereLines
                  ⍺,(⊂asign,encode),⊂'⍝',line↓⍨1⌊fIndent
              }←fStyle    
          :ENDIF 
      :ENDIF
  :ENDFOR
  fHereActive Error eSCRIPT,'(:HERE directive found, but no matching :END[HERE])'

FINISH_UP: 
    linesOut←1 SpecialQuote2APL linesOut   ⍝ Bugs-- :HERE docs and """...""" quotes should not mix...
    result←(⊃⎕RSI){
        0:: Error eSCRIPT
        fOpts ⍺.⎕FIX ⍵     ⍝ Call from caller's env...
    }linesOut
:RETURN

⍝:HERE FIX_DOCUMENTATION :ENDS _DOC_ 
⍝ Function Documentation --------------------------------------------------------------------------------------
⍝ ∆FIX FUNCTION   «  »
⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝ ∆FIX:    fix_result  ←   [⎕FIX options]  ∇  «⎕FIX lines or fn id»
⍝ Descr:   Extension to ⎕FIX formatting HERE-strings in lines passed directly or in files. 
⍝          ∘ Allows variables to be set verbatim from multiline string literals, with options including
⍝          maintaining absolute indentation, trimming indentation, appending carriage returns,
⍝          linefeeds, or spaces, formatting as equivalent matrices, or returning as vectors of vectors.
⍝          ∘ Also handles special double-quote strings and triple-quotes, using """ OR ''' equivalently.
⍝             - Double-quoted strings work like STD APL single-quoted strings, except that they can 
⍝               span multiple lines; double-quotes in the text must be "escaped" by repetition.
⍝             - Triple-quotes start and end with THREE double-quotes """ and may span multiple lines.
⍝               No special escaping is honored.
⍝          Finally, allows arbitrary data to be embedded, through the use of unique pattern terminators.    
⍝ See:     https://en.wikipedia.org/wiki/Here_document
⍝
⍝ Summary: [⍺] ∆FIX ⍵, where ⍵ contains standard arguments to Dyalog ⎕FIX,
⍝          except that code included within lines of ⍵ or within the contents of file name ⍵, as in 'file://⍵',
⍝          may include here-strings, initiated via a :HERE ... :ENDHERE sequence.
⍝ 
⍝     |    :HERE var_name[,]  [OPTIONS]     [⍝ Comment]
⍝     |    ... here strings ---
⍝     |    :ENDHERE 
⍝
⍝          OPTIONS: 
⍝          [:STD* | :MX | :STR | :CR | :LF] [:TRIM* | :NOTRIM] [[:ENDS|:UNTIL] end_token] [:FILE file_id]**   [⍝ Comment]
⍝                     Note: * indicates default option; ** indicates 0 or more options may be specified.      
⍝               var_name: the name of a user variable to be assigned the value of the here-string;
⍝                         To append to var_name (which  must then exist), append a comma to var_name:  var_name,
⍝                         OK: my_data, my.data, ⎕SE.my.data, dfns.mydata, #.my.data, ⎕. 
⍝                        BAD: my_data[2 3], ⎕IO, (2⊃my.data)
⍝               ∘ Options  [:STD | :MX | :STR | :CR | :LF] 
⍝                   shape   @SV    @SM   @S     @S    @S
⍝                           The here-string will consist of ...
⍝                 :STD      ... a vector of char vectors
⍝                 :STR      ... a simple char vec [string] with spaces "separating" (input) lines.  :SP is an alias for :STR. 
⍝                 :CR       ... a simple char vec with CRs (⎕UCS 13) separating lines. Most useful in APL, e.g. with ⎕FMT.
⍝                 :LF       ... a simple char vec with LFs (⎕UCS 10) separating lines. Typically useful in Unixes.
⍝                 :MX       ... a simple char matrix (converted from :STD per mix ↑)    
⍝               ∘ Options [:TRIM | :NOTRIM]
⍝                 :TRIM     here-string lines will be indented relative to  the left-most line, 
⍝                           which will be left-justified. Default.
⍝                 :NOTRIM   leading blanks on here-string lines are unchanged.
⍝               ∘ Specs with :ENDS  (alias :UNTIL)  
⍝                 :ENDS end_token  
⍝                      end_token:  a sequence of non-blank chars excluding comment symbol(⍝...)
⍝                      ∘ If omitted (default):     :END[HERE]               ends the here-string.
⍝                      ∘ If specified:             :END[HERE] end_token     ends the here-string.
⍝                 :UNTIL _endtoken  is an alias for :ENDS end_token.
⍝               ∘ Options [:FILE file_id]  [ [:FILE file_id] ...]
⍝                      file_id: a file identifier (BUG: ids with spaces not supported)
⍝                      ∘ Each :FILE spec identifies a file whose lines are to be prepended to the here-document
⍝                        as if entered into the here-string argument or file.
⍝                      ∘ Any number of :FILE specs may be specified, to be incorporated in sequence.
⍝                      ∘ If the line immed. following a :HERE directive is an :ENDHERE, 
⍝                        no internal here-string lines are catenated and no error is generated.
⍝                      ∘ If the file_id is not found, an error is signalled.
⍝                      ∘ Using multiple :HERE statements to append to the same variable «VAR_NAME,».
⍝                        may lead to surprise formats or APL errors (e.g. with :MX). The :STD option is always safe!
⍝           Defaults:   :STD :NOTRIM.
⍝
⍝  Returns:  Shyly returns the return value from the call to «⍺ ⎕FIX ⍵». 
⍝            ⍺ is as passed by the user.
⍝            ⍵ is vector of strings passed by the user, modified to encode :HERE directives.
⍝            See ⎕FIX documentation for its specs.
⍝  -----------------------------------------------------------------------------------------------
⍝     Sequence for Here Variables 
⍝        :HERE var_name[,] options  [:ENDS end_token]   [⍝ Comment ok here]
⍝             any lines of text, including blank or comment lines,
⍝             as long as they don't end with: 
⍝                   (i)  :ENDHERE or :END, if no :END or :UNTIL end_token was specified.
⍝                   (ii) :ENDHERE end_token  or :END end_token, otherwise.
⍝        :ENDHERE [end_token]                           [⍝ Comment ok here]
⍝ -----------------------------------------------------------------------------------------------
⍝  Notes:
⍝      ∘ :HERE... and :ENDHERE (or :END) must be the first non-blank tokens on a code line...
⍝      ∘ ⍝:HERE and ⍝:ENDHERE will also be processed. Useful sometimes...  [EXPERIMENTAL]
⍝      ∘ After a :HERE or :ENDHERE expression, only white space and comments (⍝...) are allowed
⍝      ∘ A simple :HERE (with no :ENDS token specified) is matched only by :ENDTOKEN or :END;
⍝        it will never be matched by an «:ENDHERE end_token» sequence.
⍝        An :ENDHERE token only matches a :HERE expression with an «:END end_token»subexpression.
⍝      ∘ The case of Directives and options is ignored, EXCEPT in a var_name or end_token word.
⍝        ∘ A var_name or end_token has its  case respected, and 
⍝        ∘ should include only APL compound variable letters, i.e. 'aàá-zAÀÁ-Z∆⍙_0-9.#⎕'.
⍝      ∘ We quietly allow «:STRING ... :ENDSTRING» as a synonym for «:HERE ... :ENDHERE».
⍝ Secret Feature:
⍝      ∆FIX also matches :DEF obj ... :END(DEF), allowing other options like :ENDS/:UNTIL
⍝      This sets the style to :MX and option :DEF, to emit a call to ⎕SE.Link.Deserialise,
⍝      using the test / demo version of Dyalog's new literal notation for arrays and namespaces.
⍝              :DEF fred                             :DEF fred :UNTIL derf
⍝                   { zero: 0  ⋄ one: 1                   { zero: 0  ⋄ one: 1
⍝                     two:  ⍳2 ⋄ three: 3 3⍴3               two:  ⍳2 ⋄ three: 3 3⍴3
⍝                   }                                     }
⍝             :ENDDEF                                :ENDDEF derf
⍝:ENDHERE _DOC_
∇