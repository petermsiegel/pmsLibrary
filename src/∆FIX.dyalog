∇ out←∆FIX lines
;⎕IO
;ending;eMsg;encoding;here;indent;line;out;pfx;pEndHere;pHere;opts;rHere;trim;hereDocActive;var
;eDOMAIN

⍝ ∆FIX -- implements :HERE
⎕IO←0
pHere rHere←'(?i)^(\h*):HERE(?|\h+([\w∆⍙_.]+)(?![\w∆⍙_.])\h*([^⍝]*)|()())' 'x\1;\2;\3'
eDOMAIN←'DOMAIN ERROR: There were errors processing the script '
:IF 1≥|≡lines
     pfx←':file//'
    :IF pfx≢lines↑⍨≢pfx ⋄ 11 ⎕SIGNAL⍨'DOMAIN ERROR: The prefix "file://" was expected' ⋄ :ENDIF
    lines←⎕NREAD l↓lines
:ENDIF 
hereDocActive←0  ⋄ out←⍬
     
:IF 0=≢'(?i)^\h*:HERE\b' ⎕S 0⊣lines     ⍝ If no :HERE lines, exit now...
    out←lines
    :RETURN
:ENDIF

:FOR line :in lines 
     :IF ~hereDocActive
          :IF ×≢args←';'(≠⊆⊢)⊣⊃ pHere ⎕S rHere⊣line 
                hereDocActive←1
                here←⍬
                pEndHere←'(?i)^\h*:end(here)?\b' 
                ending←''  ⋄ encoding←'STD' ⋄ trim←'NOTRIM'
                :SELECT ≢args
                  :CASE 1
                     11 ⎕SIGNAL⍨ eDOMAIN,'(:HERE variable invalid or missing)'
                  :CASE 2
                    indent var←args
                  :CASE 3  
                   indent var opts←args 
                   ⍝ Process opts
                    opts←' '(≠⊆⊢)⊣opts
                    :WHILE ×≢opts
                      :SELECT 1 ⎕C ⊃opts
                          :CASELIST ':ENDS' ':UNTIL'
                              opts←1↓opts  ⍝ Move to next arg (:ends ending)
                              ending←⊃opts 
                              pEndHere←'(?i)^\h*:end(here)?(?-i)\h+\Q',ending,'\E(?![\w∆⍙_.])' 
                          :CASELIST ':LF' ':CR' ':STD'
                              encoding←1↓⊃opts
                          :CASELIST ':TRIM' ':NOTRIM'
                              trim← 1↓⊃opts
                          :ELSE 
                              eMsg←'DOMAIN ERROR: There were errors processing script (unknown :HERE option "'
                              11 ⎕SIGNAL⍨eMsg,(⊃opts),'")'
                      :ENDSELECT
                       opts←1↓opts
                    :ENDWHILE
                :ENDSELECT
                ⎕←'end str "',ending,'"'
                ⎕←'encoding ',encoding
                ⎕←'trim     ',trim
                indent←1↓indent     ⍝ Remove extra "x" 
                out,← ⊂'⍝',line↓⍨1⌊≢indent)    ⍝ Align if space-initial
          :ELSE 
                out,← ⊂line
          :ENDIF
      :ELSE
          :IF ×≢(pEndHere ⎕S 0 ⍠'UCP' 1) line
              hereDocActive←0
            ⍝ process multiline here doc <here>
              ('>>> :here "',var,'"')(↑here)
              out,← ⊂indent,'      ',var,'←''simulated'' ''here doc'''
              out,← ⊂'⍝',line↓⍨1⌊≢indent     
          :ELSE 
              here,← ⊂line 
          :ENDIF 
      :ENDIF
  :ENDFOR
  :IF hereDocActive
      11 ⎕SIGNAL⍨eDOMAIN,'(:HERE document did not terminate)'
  :ENDIF

∇