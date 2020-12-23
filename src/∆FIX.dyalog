∇ {res}←{fOpts} ∆FIX linesIn
;⎕IO                                                 ⍝ ⎕- Sys
;cmd;ending;encoding;err;here;indent;line            ⍝ userVariables
;hereDocActive;linesOut;hOpts;pfx;trim;var;_         ⍝ ...
;pEndHere;pHERE                                      ⍝ p- Regex pats*
;rHERE                                               ⍝ r- Regex replacements*
;eMsg;ePREFIX;eSCRIPT                                ⍝ e- Error text*    
;∆Serial;Error                                       ⍝ Fns   (∆Pseudo-Sys, User)          
⍝                                                      * formats: eVars eCONSTS, so for p-, r- objects
⍝                                                                 Funcs

⍝ ∆FIX -- implements :HERE
⎕IO←0
∆Serial←⎕SE.Link.Serialise
Error← ⎕SIGNAL∘11
⍝ pHERE: matches :HERE plus any valid local relative user-defined name: not ⎕SE.a.b or  #.a.b 
pHERE rHERE←'(?i)^(\h*):HERE(?|\h+([\w∆⍙_.]+)(?![\w∆⍙_.])\h*([^⍝]*)|()())' 'x\1;\2;\3'
eSCRIPT←'DOMAIN ERROR: There were errors processing the script '
ePREFIX←'DOMAIN ERROR: The prefix "file://" was expected'

:IF 900⌶⍬  ⋄ fOpts←⊢ ⋄ :ENDIF
:IF 1≥|≡linesIn
     _←≢pfx←'file://'
    :IF pfx≢_↑linesIn ⋄ Error ePREFIX ⋄ :ENDIF
    linesIn←⊃⎕NGET (_↓linesIn) 1
:ENDIF 
hereDocActive←0  ⋄ linesOut←⍬
     
:IF 0=≢'(?i)^\h*:HERE\b' ⎕S 0⊣linesIn     ⍝ If no :HERE lines, exit now...
    →FINISH_UP ⊣ linesOut←linesIn         ⍝ Sorry-- it works...
:ENDIF

:FOR line :in linesIn 
     :IF ~hereDocActive
          :IF ×≢args←';'(≠⊆⊢)⊣⊃ pHERE ⎕S rHERE⊣line 
                hereDocActive←1
                here←⍬
                pEndHere←'(?i)^\h*:end(here)?\b'     ⍝ may change to search for token...
                ending←''  ⋄ encoding←':STD' ⋄ trim←':TRIM'
                :SELECT ≢args
                  :CASE 1
                     Error  eSCRIPT,'(:HERE variable invalid or missing)'
                  :CASE 2
                    indent var←args
                  :CASE 3  
                   indent var hOpts←args 
                   ⍝ Process hOpts
                    hOpts←' '(≠⊆⊢)⊣hOpts
                    :WHILE ×≢hOpts
                      :SELECT cmd←1 ⎕C ⊃hOpts
                          :CASELIST ':ENDS' ':UNTIL'
                          ⍝ :ENDS text, :UNTIL word  (synonyms)
                          ⍝          here doc won't end until before line :END word or :ENDHERE word
                          ⍝ Default: ends before line :END or :ENDHERE
                              hOpts←1↓hOpts  ⍝ Move to next arg (:ends ending)
                              ending←⊃hOpts 
                              pEndHere←'(?i)^\h*:end(here)?(?-i)\h+\Q',ending,'\E(?![\w∆⍙_.])' 
                          :CASELIST ':LF' ':CR' ':STD' ':MX'
                          ⍝ :LF - vec string with Unicode 10 separating lines
                          ⍝ :CR - vec string with Unicode 13 separating lines-- more useful in Dyalog
                          ⍝ :STD- vector of char vectors (default)
                          ⍝ :MX-  matrix of chars (via APL mix ↑). 
                              encoding←cmd
                          :CASELIST ':TRIM' ':NOTRIM'
                          ⍝ :TRIM -  remove leading blanks of subsequent lines to # of 
                          ⍝          first here doc line, but never truncates those exdented (default)
                          ⍝ :NOTRIM- leave leading blanks as entered.
                              trim←cmd
                          :ELSE 
                              eMsg←'DOMAIN ERROR: There were errors processing script (unknown :HERE option "'
                              Error eMsg,cmd,'")'
                      :ENDSELECT
                       hOpts←1↓hOpts      ⍝ Scan the next option
                    :ENDWHILE
                :ENDSELECT
                ⍝D ⎕←'end str "',ending,'"'
                ⍝D ⎕←'encoding ',encoding
                ⍝D ⎕←'trim     ',trim
                indent←1↓indent     ⍝ Remove extra "x" 
                linesOut,← ⊂'⍝',line↓⍨1⌊≢indent    ⍝ Align if space-initial
          :ELSE 
                linesOut,← ⊂line
          :ENDIF
      :ELSE
          :IF ×≢(pEndHere ⎕S 0 ⍠'UCP' 1) line
              hereDocActive←0
            ⍝ process multiline here doc <here>
              :IF trim≡':TRIM'
                  here←{
                      pfx←+/∧\[1]' '=↑⍵
                      0=⊃pfx:⍵
                      pfx←(⊃pfx)⌊pfx
                      pfx↓¨⍵
                  }here
              :ENDIF
              :IF ':LF' ':CR'∊⍨⊂ encoding
                    here←(encoding≡':LF'){
                      eol←⎕UCS ⍺⊃13 10 ⋄  1↓∊eol,¨⍵
                    }here
                    HERE←here
              :ENDIF 
              linesOut,← ⊂indent,'      ',var,'←',('↑'/⍨encoding≡':MX'),∊∆Serial here
              ⍝D ('>>> :here "',var,'"')(∊here)
              linesOut,← ⊂'⍝',line↓⍨1⌊≢indent    
          :ELSE 
              here,← ⊂line 
          :ENDIF 
      :ENDIF
  :ENDFOR
  :IF hereDocActive
      Error eSCRIPT,'(:HERE document did not terminate)'
  :ENDIF

FINISH_UP: 
  ⍝D ⎕←'--------------------'  ⋄ ⎕←↑#.LINESOUT←linesOut    ⋄ ⎕←'--------------------'
  :TRAP ⍬
      res←fOpts (⊃⎕RSI).⎕FIX linesOut     ⍝ Call from caller's env...
  :ELSE 
      Error eSCRIPT
  :ENDTRAP
∇