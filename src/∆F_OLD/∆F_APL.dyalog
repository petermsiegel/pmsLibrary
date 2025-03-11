:Namespace ∆F_APL
⎕IO ⎕ML←0 1 
CR CR_VIS← (⎕UCS 13) '␍'
∇ out← {opts} ∆FA args 
  :IF 900⌶0  
      opts← ⍬
  :ElseIf 0=≢opts 
      out← 1 0⍴'' ⋄ :return
  :ElseIf 'help'≡4↑⎕C opts 
      out← opts ⋄ :return
  :EndIf 
  escCh dfn debug box useNs lib← EvalOpts opts
  :IF debug  
      ⎕← 'escCh' escCh ' dfn'dfn 'debug' debug 'box' box 'useNs' useNs 'lib' lib
  :EndIf 

 cur← 0 ⋄ len← ≢fStr← ,⊃args← ⊆args  ⋄ outStr← '' 
 state0 stateTF stateCF0 stateCF← ⍳4
 state←oldState← state0 

⍝ Preamble code string...
  outStr,← '{', (useNs/ '⍺←⎕NS⍬⋄'), ('⎕SE.⍙F.M' '⎕SE.⍙F.B'⊃⍨ ×box), ('⍪'/⍨ box=2), ('⍺{'/⍨ dfn∧ useNs 1)

 tfBreak← '{',escCh     ⍝ "Important" TF chars
 Break← { +/ ∧/⍵ (~∊) ⍺ }

 :While cur < len
    :Select state
    :Case state0 
        :IF fStr[cur]='{'
            state oldState← stateCF0 state
            →more  
        :Else
            state oldState← stateTF state 
            outStr,← ' '''
            :IF ×p← tfBreak Break cur↓ fStr
                outStr,← fStr[cur+⍳p]
            :Else 
               →more 
            :EndIf 
        :EndIf
    :Case stateTF        
        :Select fStr[cur]
        :Case '{'
            :IF IsSF 
            :Else 
                state oldState← stateCF0 state 
                →more 
            :EndIf 
        :Case escCh
            :IF len ≥ cur+1
            :AndIf fStr[cur+1]∊'{}⋄',escCh 
                cur+← 1
                :IF fStr[cur]='⋄'
                    outStr,← debug⊃ CR CR_VIS
                :Else 
                    outStr,← fStr[cur]
                :EndIf 
            :Else
                outStr,← escCh
            :EndIf 
        :Else 
              outStr,← fStr[cur]
        :EndSelect
    :Case stateCF0 
            :IF oldState=stateTF 
                outStr,← ''' '
            :Endif 
            outStr,← '(', (useNs/'⍺'), '{'
            codeStart← cur 
            brackets← 1 
            state oldState← stateCF state
    :Case stateCF 
            :Select fStr[cur]
            :Case '{'
                brackets+←1
                outStr,← fStr[cur]
            :Case '}'
                brackets-← 1
                :IF brackets≤0
                      outStr,← '}⍵)'
                      state oldState← state0 state 
                :Else 
                      outStr,← fStr[cur]
                :EndIf
            :Else 
                outStr,← fStr[cur]
            :EndSelect      
    :else       
      911 ⎕SIGNAL⍨ '∆F_APL: LOGIC ERROR (unknown state)'
    :EndSelect 
    cur+← 1 
  more: 
 :EndWhile 
  
  outStr,← (''''/⍨ state=stateTF),'⍬}' 
  :IF dfn
      outStr,← '(⊂''', (fStr/⍨ 1+ fStr=''''), '''),⍵}'
      out← (⊃⎕RSI)⍎outStr 
  :Else 
      out← outStr (⊃⎕RSI).{ ⍎⍺,'⍵'}args   
  :EndIf  
∇

⍝ Options: Principle opt is dfn (option 1)
⍝ Options are in the style of Dyalog ⍠ (variant) options: (keyword value)... OR (principle_option_value) OR omitted.
  optKeys← ⎕C 'escCh' 'dfn' 'debug' 'box' 'useNs' 'lib'   
  optVals←    '`'      0     0       0     0       1      
  princ←            1 
⍝ Evaluate options. optsOut← ∇ optsIn.  Return individual esCh, dfn, debug, etc.
  EvalOpts← { 
    0=≢⍵:  optVals                           ⍝ Fastest: all default options
    0:: 'DOMAIN ERROR: Invalid option(s)' ⎕SIGNAL 11   
    0≡⊃0⍴⍵: ⍵@princ⊢ optVals                 ⍝ Fast: only principle option is set (via a single integer)
      nK nV← ↓⍉↑ ,∘⊂⍣(2= |≡⍵)⊢ ⍵          
      nV@(optKeys⍳ ⎕C nK)⊣ optVals           ⍝ Slower: all options are set by key-value pairs
  }

  NBlanks← {  +/∧\⍵=' '}

  ∇ b← IsSF
    p← cur+1+NBlanks fStr↓⍨ cur+1
    :IF p≤ len ⋄ :Andif fStr[p]='}'
      outStr,← ''''
      :If ×t← p-cur+1   
          outStr,← '(',(⍕t),'⍴'''')'
      :EndIf 
      state oldState← state0 state 
      cur← p 
      b←1
    :Else 
      b←0 
    :EndIf 
  ∇

:endNamespace