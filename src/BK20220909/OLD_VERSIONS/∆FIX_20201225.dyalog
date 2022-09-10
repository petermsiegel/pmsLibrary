∇ {res}←{fOpts} ∆FIX linesIn
;⎕IO                                                 ⍝ ⎕- Sys
;cmd;ending;style;enlist;err;hereLns;indent;line  ⍝ userVariables
;hereDocActive;len;linesOut;hOpts;pfx;trim;var       ⍝ ...
;pEndHere;pHERE                                      ⍝ p- Regex pats*
;rHERE                                               ⍝ r- Regex replacements*
;eUnknown;ePREFIX;eSCRIPT                            ⍝ e- Error text*    
;∆SerialFlat;EFormat;Error                           ⍝ Fns   (∆Pseudo-Sys, User)          
⍝                                                      * formats: eVars eCONSTS, so for p-, r- objects
⍝                                                                 Funcs

⍝ ∆FIX:    fix_result  ←   [⍺]  ∇  ⍵
⍝ Descr:   ambivalent fn which implements :HERE docs (if any) and calls ⎕FIX, following ⎕FIX syntax.
⍝ Summary: [⍺] ∆FIX ⍵, where ⍵ contains standard arguments to Dyalog ⎕FIX,
⍝          except that code included within lines of ⍵ or within the contents of file name ⍵, as in 'file://⍵',
⍝          may include here-documents, initiated via a :HERE ... :ENDHERE sequence.
⍝ 
⍝          :HERE var_name   [:STD | :MX | :STR | :CR | :LF] [:TRIM | :NOTRIM] [[:END|:UNTIL] token]  [⍝ Comment]
⍝                            ¯¯¯¯                     ¯¯¯¯¯            
⍝               var_name: a user varname, excluding # or ⎕SE, of the variable to be assigned the here-doc
⍝               token:    a sequence of non-blank chars excluding comments (⍝...)
⍝               :STD      the here-doc will be a vector of char vectors
⍝               :STR                           a char string with no line separators, via enlist(∊)
⍝               :MX                            a char matrix (per mix ↑)    
⍝               :CR                            a char string with CRs (⎕UCS 13) separating lines. Most useful in APL.
⍝               :LF                            a char string with LFs (⎕UCS 10) separating lines. Typically useful in Unixes.
⍝               :TRIM     the first here-doc line will have its leading blanks trimmed;
⍝                         all subsequent lines will be indented relative to  the first;
⍝                         extented subsequent lines will be aligned with the first (not truncated ever).
⍝               :NOTRIM   leading blanks of the here-doc lines are unchanged.
⍝               :END token | :UNTIL token   
⍝                      If omitted (default):     :END[HERE]           ends the here-doc.
⍝                      If specified:             :END[HERE] token     ends the here-doc.
⍝                      :UNTIL  is an alias for the :END option.
⍝           Defaults:   :STD :NOTRIM.
⍝
⍝  Returns:  Shyly returns the return value from the call to ⍺ ⎕FIX ⍵. 
⍝            ⍺ is as passed by the user.
⍝            ⍵ is as passed by the user as modified to handle :HERE directives.
⍝            See ⎕FIX for call syntax.
⍝  -----------------------------------------------------------------------------------------------
⍝     Sequencefor Here Documents 
⍝        :HERE var_name options  [:END token]   [⍝ Comment]
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

⎕IO←0
∆SerialFlat←∊⎕SE.Link.Serialise
Error← ⎕SIGNAL∘11
EFormat←{Msg←⍵.Message ⋄ OS←⊃⌽⍵.OSError ⋄ (⍵.EM,((0≠≢Msg)/' ',Msg),((0≠≢OS)/' ("',OS,'")')) ⍵.EN}
⍝ pHERE: matches :HERE plus any valid local relative user-defined name: not ⎕SE.a.b or  #.a.b 
⍝ [\w∆⍙_.] is \w for APL chars (with ⍠'UCP' 1); (?![\w∆⍙_.]) is \b.
pHERE rHERE←'(?i)^(\h*):HERE(?|\h+([\w∆⍙_.#⎕]+)(?![\w∆⍙_.#⎕])\h*([^⍝]*)|()())' 'x\1;\2;\3'  ⍝ See below fof x
eSCRIPT←   'DOMAIN ERROR: There were errors processing the script '
ePREFIX←   'DOMAIN ERROR: The prefix "file://" was expected'
eUNKNOWN←  'DOMAIN ERROR: There were errors processing script (unknown :HERE option "'

GetOpts←{
    hOpts←⍵  
    0=≢hOpts: ⍬
    cmd←1 ⎕C ⊃hOpts ⋄  CASE←(⊂cmd)∘∊  
    NEXT←∇{style trim pEndHere ⍺⍺ 1↓⍵}                       
    CASE ':ENDS' ':UNTIL':{
        ⍝ :ENDS text, :UNTIL word  (synonyms)
        ⍝          here doc won't end until before line :END word or :ENDHERE word
        ⍝ Default: ends before line :END or :ENDHERE
            hOpts←1↓hOpts           ⍝ Move to next arg (:ends ending)
            0=≢hOpts: Error ':HERE DOMAIN ERROR: option :ENDS or :UNTIL seen, but no token follows'
            ending←⊃hOpts
            pEndHere∘←'(?i)^\h*:end(here)?(?-i)\h+\Q',ending,'\E\h*(?:⍝|$)' 
            NEXT hOpts
      }⍬
      ⍝ :STD - vector of char vectors (default).
      ⍝ :MX  - matrix of chars (via APL mix ↑). 
      ⍝ :LF  - vec string with Unicode 10 separating lines
      ⍝ :CR  - vec string with Unicode 13 separating lines-- more useful in Dyalog
      ⍝ :STR - single vec string without line separators, as if enlist (∊) of :STD vectors.
    CASE ':STD' ':MX' ':LF' ':CR'  ':STR':{
            style∘←cmd 
            NEXT hOpts 
    }⍬
      ⍝ :TRIM -  remove leading blanks of subsequent lines to # of 
      ⍝          first here doc line, but never truncates those exdented (default)
      ⍝ :NOTRIM- leave leading blanks as entered.
    CASE ':TRIM' ':NOTRIM':{
            trim∘←cmd≡':TRIM'
            NEXT hOpts
    }⍬
    Error eUNKNOWN,cmd,'")'
}

:IF 900⌶⍬  ⋄ fOpts←⊢ ⋄ :ENDIF
:IF 1≥|≡linesIn                                   ⍝ It must be a single file id.
    :IF pfx≢linesIn↑⍨len←≢pfx←'file://' ⋄ Error ePREFIX ⋄ :ENDIF    ⍝ Emulate ⎕FIX requirements
    :TRAP 0 ⋄ linesIn←⊃⎕NGET (len↓linesIn) 1 ⋄ :Else ⋄ ⎕SIGNAL/EFormat ⎕DMX ⋄ :ENDTRAP
:ENDIF 
     
:IF 0=≢'(?i)^\h*:HERE\b' ⎕S 0⍠'UCP' 1⊣linesIn     ⍝ If no :HERE lines, ⎕FIX as is...
    →FINISH_UP ⊣ linesOut←linesIn                 ⍝ Sorry-- it works...
:ENDIF

hereDocActive←0  ⋄ linesOut←⍬

:FOR line :in linesIn 
     :IF ~hereDocActive
          :IF ×≢args←';'(≠⊆⊢)⊣⊃ pHERE ⎕S rHERE ⍠'UCP' 1⊣line 
                hereDocActive←1 ⋄ hereLns←⍬
                pEndHere←'(?i)^\h*:end(here)?\h*(?:⍝|$)'       ⍝ See ':ENDS' for change to search for token...
                ending←''  ⋄ style←':STD' ⋄ trim←1
                :SELECT ≢args
                  :CASE 1
                    Error  eSCRIPT,'(:HERE variable invalid or missing)'
                  :CASE 2
                    indent var←args
                  :CASE 3  
                    indent var hOpts←args 
                  ⍝ Process hOpts options...
                    hOpts←' '(≠⊆⊢)⊣hOpts
                    _←GetOpts hOpts
                    ⍝ :WHILE ×≢hOpts
                    ⍝     :SELECT cmd←1 ⎕C ⊃hOpts
                    ⍝         :CASELIST ':ENDS' ':UNTIL'
                    ⍝         ⍝ :ENDS text, :UNTIL word  (synonyms)
                    ⍝         ⍝          here doc won't end until before line :END word or :ENDHERE word
                    ⍝         ⍝ Default: ends before line :END or :ENDHERE
                    ⍝             hOpts←1↓hOpts           ⍝ Move to next arg (:ends ending)
                    ⍝             :IF 0=≢hOpts  
                    ⍝                 Error ':HERE DOMAIN ERROR: option :ENDS or :UNTIL seen, but no token follows'
                    ⍝             :ENDIF
                    ⍝             ending←⊃hOpts
                    ⍝             pEndHere←'(?i)^\h*:end(here)?(?-i)\h+\Q',ending,'\E\h*(?:⍝|$)' 
                    ⍝       ⍝ :STD - vector of char vectors (default).
                    ⍝       ⍝ :MX  - matrix of chars (via APL mix ↑). 
                    ⍝       ⍝ :LF  - vec string with Unicode 10 separating lines
                    ⍝       ⍝ :CR  - vec string with Unicode 13 separating lines-- more useful in Dyalog
                    ⍝       ⍝ :STR - single vec string without line separators, as if enlist (∊) of :STD vectors.
                    ⍝         :CASELIST ':STD' ':MX' ':LF' ':CR'  ':STR'
                    ⍝             style←cmd  
                    ⍝       ⍝ :TRIM -  remove leading blanks of subsequent lines to # of 
                    ⍝       ⍝          first here doc line, but never truncates those exdented (default)
                    ⍝       ⍝ :NOTRIM- leave leading blanks as entered.
                    ⍝         :CASELIST ':TRIM' ':NOTRIM'
                    ⍝             trim←cmd≡':TRIM'
                    ⍝         :ELSE 
                    ⍝             Error eUNKNOWN,cmd,'")'
                    ⍝     :ENDSELECT
                    ⍝     hOpts←1↓hOpts              ⍝ Scan the next option
                    ⍝ :ENDWHILE
                :ENDSELECT
                indent←1↓indent                    ⍝ Remove extra "x" from ⎕S match: even no indent returns a (null) field
                linesOut,← ⊂'⍝',line↓⍨1⌊≢indent    ⍝ Align if space-initial
          :ELSE 
                linesOut,← ⊂line
          :ENDIF
      :ELSE
          :IF ×≢(pEndHere ⎕S 0 ⍠'UCP' 1) line      ⍝ Matching :END(HERE) seen...
              hereDocActive←0
            ⍝ If :TRIM, remove leading blanks (lb) from lines only up to the # of lb for the first line passed.
              hereLns{  
                  ~⍵:    ⍺
                  0=≢⍺:  ⍺ ⋄ lb←+/∧\[1]' '=↑⍺ 
                  0=⊃lb: ⍺ ⋄ ⍺↓⍨¨lb⌊⊃lb   
              }←trim
            ⍝ :STR, :LF, :CR styles?  (:STD- as is; :MX- handled below for performance reasons)
              hereLns {
                  ':STR'≡⍵: ∊⍺ ⋄ eol←':LF' ':CR'≡¨⊂ ⍵ 
                  ⍱/eol:     ⍺ ⋄ 1↓∊⍺,⍨¨⎕UCS eol/13 10  
              }←style
              linesOut,← ⊂indent,'      ',var,'←',('↑'/⍨':MX'≡style),∆SerialFlat hereLns
              linesOut,← ⊂'⍝',line↓⍨1⌊≢indent    
          :ELSE 
              hereLns,← ⊂line 
          :ENDIF 
      :ENDIF
  :ENDFOR
  :IF hereDocActive
      Error eSCRIPT,'(:HERE document had no matching :END[HERE])'
  :ENDIF

FINISH_UP: 
  :TRAP 0
      res←fOpts (⊃⎕RSI).⎕FIX linesOut     ⍝ Call from caller's env...
  :ELSE 
      Error eSCRIPT
  :ENDTRAP
∇