∇ {result}←{fOpts} ∆FIX linesIn
;⎕IO;⎕ML;⎕TRAP                                       ⍝ ⎕- Sys
;args;hereLines;î;line;linesOut                      ⍝ general pgm vars  (î- ignore result)
;fEndTok;fHereActive;fIndent;fStyle                  ⍝ f- flags
;fTrim;fVarName                    
;pEndHere;pHERE                                      ⍝ p- Regex pats*
;rHERE                                               ⍝ r- Regex replacements or response*
;eUNKNOWN;ePREFIX;eSCRIPT                            ⍝ e- Error text*    
;GetOpts;∆SerialFlat;Error                           ⍝ Fns   (∆Pseudo-Sys, User)          
⍝                                                      * formats: eVars eCONSTS, so for p-, r- objects

⍝ ∆FIX:    fix_result  ←   [⍺]  ∇  ⍵
⍝ Descr:   Extension to ⎕FIX with extension for HERE-strings in lines passed directly or in files, 
⍝          allowing variables to be set verbatim from embedded multiline string literals, with variants including
⍝          maintaining absolute or relative indentation, trimming indentation, appending carriage returns
⍝          or linefeeds, or reformatting as equivalent matrices or vectors of vectors.
⍝          Finally, allows even (APL) directives to be embedded, through the use of unique pattern terminators.    
⍝ See:     https://en.wikipedia.org/wiki/Here_document
⍝ Summary: [⍺] ∆FIX ⍵, where ⍵ contains standard arguments to Dyalog ⎕FIX,
⍝          except that code included within lines of ⍵ or within the contents of file name ⍵, as in 'file://⍵',
⍝          may include here-strings, initiated via a :HERE ... :ENDHERE sequence.
⍝ 
⍝          :HERE var_name[,]   [:STD* | :MX | :STR | :CR | :LF] [:TRIM* | :NOTRIM] [[:ENDS|:UNTIL] token] 
⍝                                                                        [:FILE file_id]**   [⍝ Comment]
⍝                     Note: * indicates default option; ** indicates 0 or more options may be specified.      
⍝               var_name: the name of a user variable to be assigned the value of the here-string;
⍝                         To append to var_name (which  must then exist), append a comma to var_name:  var_name,
⍝               ∘ Options [:STD | :MX | :STR | :CR | :LF] 
⍝                           The here-string will consist of ...
⍝                 :STD      ... a vector of char vectors
⍝                 :STR      ... a simple char vec [string] with spaces "separating" lines 
⍝                 :CR       ... a simple char vec with CRs (⎕UCS 13) separating lines. Most useful in APL.
⍝                 :LF       ... a simple char vec with LFs (⎕UCS 10) separating lines. Typically useful in Unixes.
⍝                 :MX       ... a simple char matrix (converted from :STD per mix ↑)    
⍝               ∘ Options [:TRIM | :NOTRIM]
⍝                 :TRIM     here-variable lines will be indented relative to  the left-most line, 
⍝                           which will be left-justified.
⍝                 :NOTRIM   leading blanks of the here-file lines are unchanged.
⍝               ∘ Options [:ENDS | :UNTIL] token
⍝                 :ENDS token | :UNTIL token  
⍝                      token:  a sequence of non-blank chars excluding comments (⍝...)
⍝                      ∘ If omitted (default):     :END[HERE]           ends the here-string.
⍝                      ∘ If specified:             :END[HERE] token     ends the here-string.
⍝                 :UNTIL token  is an alias for :ENDS token.
⍝               ∘ Options [:FILE file_id]  [ [:FILE file_id] ...]
⍝                      file_id: a file_id specified as a sequence of non-blank characters excluding comments (⍝...)
⍝                      ∘ Identifies one or more files whose lines are to be prepended to the here-document
⍝                        as if entered into the here-string argument or file.
⍝                      ∘ Any number of :FILE file_id sequences may be specified, to be incorporated in sequence.
⍝                      ∘ If the :HERE directive is immediately followed by an :ENDHERE, 
⍝                        no internal here-string lines are catenated and no error is generated.
⍝                      ∘ If the file_id is not found, an error is signalled.
⍝                      ∘ Using multiple :HERE statements to append to the same variable "VAR_NAME,"
⍝                        should only be done using the default :STD option. Otherwise, you may need
⍝                        to manually prepend the appropriate CR or NL before all but the first...
⍝           Defaults:   :STD :NOTRIM.
⍝
⍝  Returns:  Shyly returns the return value from the call to ⍺ ⎕FIX ⍵. 
⍝            ⍺ is as passed by the user.
⍝            ⍵ is as passed by the user as modified to handle :HERE directives.
⍝            See ⎕FIX for call syntax.
⍝  -----------------------------------------------------------------------------------------------
⍝     Sequencefor Here Variables 
⍝        :HERE var_name[,] options  [:ENDS token]   [⍝ Comment]
⍝             any lines of text (including blank lines) not matching lines starting (after optional blanks) with: 
⍝                   (i)  :ENDHERE or :END, if no :END or :UNTIL token was specified.
⍝                   (ii) :ENDHERE token  or :END token, otherwise.
⍝        :ENDHERE [token]                       [⍝ Comment]
⍝     Notes:
⍝      ∘ :HERE... and :END[HERE] must be the first non-blank tokens on a code line...
⍝      ∘ After a :HERE or :ENDHERE expression, only white space and comments (⍝...) are allowed
⍝      ∘ A simple :HERE (with no expression :ENDS token or :UNTIL token) is matched only by :ENDTOKEN or :END;
⍝        it will never be matched by an ":ENDHERE token" sequence.
⍝      ∘ The case of Directives and options is ignored, EXCEPT AS BELOW
⍝        ∘ var_name and tokens have their case respected and 
⍝        ∘ should include only APL compound variable letters, i.e. 'aàá-zAÀÁ-Z∆⍙_' etc., '0-9', and '.#⎕'.
⎕IO ⎕ML←0 1 ⋄ ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)' 

Error← {⍺←1 ⋄ ⍺=1: ⍵ ⎕SIGNAL 11   ⋄ 1: î←0}
∆SerialFlat←∊⎕SE.Link.Serialise

⍝ pHERE: matches :HERE plus any valid local relative user-defined variable name: not ⎕SE.a.b or  #.a.b 
⍝ [\w∆⍙_etc.] is \w for APL chars (with ⍠'UCP' 1). 
⍝ The variable name  may have an appended comma (,) to indicate it is being appended to.  
pHERE rHERE←'(?i)^(\h*):HERE(?|\h+([\w∆⍙_.#⎕]+,?)(?![\w∆⍙_.#⎕])\h*([^⍝]*)|()())' 'x\1;\2;\3'  ⍝ See below fof x
eSCRIPT←   'DOMAIN ERROR: There were errors processing the script '
ePREFIX←   'DOMAIN ERROR: The prefix "file://" was expected'
eUNKNOWN←  'DOMAIN ERROR: There were errors processing script (unknown :HERE option "'

GetOpts←{
    hOpts←⍵  
    0=≢hOpts: ⍬
    cmd←1 ⎕C ⊃hOpts ⋄  CASE←(⊂cmd)∘∊  
    NEXT←∇{⍺⍺ 1↓⍵}  
    ⍝ :ENDS text, :UNTIL word  (synonyms)
    ⍝          here string won't end until before line :END word or :ENDHERE word
    ⍝ Default: ends before line :END or :ENDHERE                 
    CASE ':ENDS' ':END' ':UNTIL':{
             hOpts←1↓hOpts           ⍝ Move to next arg (:ends fEndTok)
            (0=≢hOpts) Error ':HERE DOMAIN ERROR: option :ENDS or :UNTIL seen, but no token follows':
            fEndTok←⊃hOpts
            pEndHere∘←'(?i)^\h*:end(here)?(?-i)\h+\Q',fEndTok,'\E\h*(?:⍝|$)' 
            NEXT hOpts
    }⍬
    CASE ⊆':FILE':{  ⍝ File id may not have spaces
          hOpts←1↓hOpts ⋄ fi ← ⊃hOpts  
          (~⎕NEXISTS fi) Error 'FILE NAME ERROR: «:FILE ',fi,'» Unable to find or open file.':
          hereLines,←⊃⎕NGET fi 1
          NEXT hOpts  
    }⍬
    ⍝ :STD - vector of char vectors (default).
    ⍝ :MX  - matrix of chars (via APL mix ↑). 
    ⍝ :LF  - vec string with Unicode 10 separating lines
    ⍝ :CR  - vec string with Unicode 13 separating lines-- more useful in Dyalog
    ⍝ :STR - single vec string without line separators, as if enlist (∊) of :STD vectors.
    CASE ':STD' ':MX' ':LF' ':CR'  ':STR':{
            fStyle∘←cmd 
            NEXT hOpts 
    }⍬
    ⍝ :TRIM -  remove leading blanks of subsequent lines to # of 
    ⍝          first here string line, but never truncates those exdented (default)
    ⍝ :NOTRIM- leave leading blanks as entered.
    CASE ':TRIM' ':NOTRIM':{
            fTrim∘←cmd≡':TRIM'
            NEXT hOpts
    }⍬
    Error eUNKNOWN,cmd,'")'
}

:IF 900⌶⍬  ⋄ fOpts←⊢ ⋄ :ENDIF
:IF 1≥|≡linesIn                                        ⍝ It must be a single file id.
    linesIn←{ 
          0::'Whoops'
          0:: ⎕SIGNAL/{
            Msg←⍵.Message ⋄ OS←⊃⌽⍵.OSError ⋄ (⍵.EM,((0≠≢Msg)/' ',Msg),((0≠≢OS)/' ("',OS,'")')) ⍵.EN
          }⎕DMX 
          (pfx≢⍵↑⍨len←≢pfx←'file://') Error ePREFIX:   ⍝ Emulate ⎕FIX requirements
          ⊃⎕NGET (len↓⍵) 1
    },linesIn  
:ENDIF 
     
:IF 0=≢'(?i)^\h*:HERE\b' ⎕S 0⍠'UCP' 1⊣linesIn     ⍝ If no :HERE lines, ⎕FIX as is...
    →FINISH_UP ⊣ linesOut←linesIn                 ⍝ Sorry-- it works...
:ENDIF

fHereActive←0 ⋄ linesOut←⍬  

:FOR line :IN linesIn
      :IF 0=fHereActive
          args←';'(≠⊆⊢)⊣⊃ pHERE ⎕S rHERE ⍠'UCP' 1⊣line   ⍝ Matching :HERE directive...
          :IF 0=≢args
                linesOut,← ⊂line
          :ELSE 
                fHereActive←1 ⋄ hereLines←⍬
                pEndHere←'(?i)^\h*:end(here)?\h*(?:⍝|$)'       ⍝ See ':ENDS' for change to search for token...
                fEndTok←'' ⋄ fStyle←':STD' ⋄ fTrim←1
                (2>≢args) Error eSCRIPT,'(:HERE variable invalid or missing)'  
                fVarName←1⊃args
                fIndent←¯1+≢0⊃args                 ⍝ Ignore extra "x" from ⎕S match: even no indent returns a (null) field
                :IF 3=≢args ⍝ Process here string options <hereOpts>... 
                    î←GetOpts ' '(≠⊆⊢)⊣2⊃args
                :ENDIF 
                linesOut,← ⊂'⍝',line↓⍨1⌊fIndent    ⍝ Align if space-initial
          :ENDIF
      :ELSE
          :IF 0=≢pEndHere ⎕S 0 ⍠'UCP' 1⊣line      ⍝ Matching :END(HERE) directive...
              hereLines,← ⊂line 
          :ELSE 
              fHereActive←0
            ⍝ If :TRIM set, remove leading blanks (lb) from lines only up to the # of lb for the left-most line passed.
              hereLines{  
                  ~⍵: ⍺ ⋄ 0=≢⍺: ⍺     
                  0=min←⌊/lb←+/⊃∧\¨' '=⍺: ⍺ ⋄ ⍺↓⍨¨lb⌊min   
              }←fTrim
            ⍝ :STR, :LF, :CR styles?  (:STD- as is; :MX- handled below for performance reasons)
            ⍝ Experimental: if  fVarName has a ',' suffix, don't delete prefixed CR, LF or space
              hereLines {eol←':STR' ':LF' ':CR'≡¨⊂ ⍵
                  keepEol←','≠⊃⌽fVarName
                  ∨/eol: 1↓⍣keepEol⊣∊⍺,⍨¨⎕UCS eol/32 10 13 ⋄ ⍺    
              }←fStyle
              linesOut,← ⊂(' '⍴⍨fIndent+6),fVarName,'←',('↑'/⍨':MX'≡fStyle),∆SerialFlat hereLines
              linesOut,← ⊂'⍝',line↓⍨1⌊fIndent    
         :ENDIF 
      :ENDIF
:ENDFOR

fHereActive Error eSCRIPT,'(:HERE directive found, but no matching :END[HERE])'

FINISH_UP: 
  result←(⊃⎕RSI){
      0:: Error eSCRIPT
      fOpts ⍺.⎕FIX ⍵     ⍝ Call from caller's env...
  }linesOut
∇