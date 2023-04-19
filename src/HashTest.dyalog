HashTest
  ;FORCE; I; D; L; T ; V; X 

:TRAP 1000
      FORCE←1
      :IF FORCE∨~×⎕SE.⎕NC '∆DICT' 
          UCMD 'LOAD -target=⎕SE ∆DICT'
      :ENDIF 
      :IF ~×⎕NC 'cmpx'
        'cmpx' ⎕CY 'dfns'
      :ENDIF 

      :IF KEEP←0
          cmpx 'D←∆DICT ⍬'   
          :FOR L :IN  1 100 1000 100000
              X← (⍳L)(○⍳L)
              ⎕←'X←(⍳L)(○⍳L): ',⍕L
              cmpx ⎕←'D←∆DICT X' 
          :ENDFOR 
          :FOR L :IN  50 100 1000  
              X← (⍕¨⍳L)(○⍳L)
              ⍞←'X←(⍕¨⍳L)(○⍳L): ',L
              cmpx ⎕←'D←∆DICT X' 
          :ENDFOR 
      :ENDIF 

      :IF KEEP←0
        ⎕←↑⊂'NUM KEYS'
        X← (⍳500)(○⍳500)
        ⎕←'X← (⍳500)(○⍳500)'
        ⎕←
        D←∆DICT X  
        :FOR L :IN  50 100 1000  
            :FOR K :IN 1 2 5×L
              V←○L⍴K
              ⎕←'KN: ?L⍴K, where ','L=',L,' K=',K
              KN← ?L⍴K
              D.Set KN V ⋄ T.Set KN V
              ⍝ cmpx ⎕←'D.Set KN V' 'T.Set KN V' 
              cmpx ⎕←'D.Get KN V'  
            :ENDFOR
        :ENDFOR

        ⎕←↑⊂'CHAR KEYS'
        X← (⍕¨⍳500)(○⍳500)
        ⎕←'X← (⍕¨⍳500)(○⍳500)'
        D←∆DICT X  
        ⎕←
        :FOR L :IN  50 100 1000  
            :FOR K :IN 1 2 5×L
              V←○L⍴K
              ⎕←'KT: ⍕¨?L⍴K, where ','L=',L,' K=',K
              KT← ⍕¨?L⍴K
              D.Set KT V ⋄ 
              ⍝ cmpx ⎕←'D.Set KT V'  
              cmpx ⎕←'D.Get KT V'  
            :ENDFOR
        :ENDFOR
      :ENDIF 

      :IF KEEP←1 
        ⎕←↑2⍴⊂'Numeric keys'
        X← (⍳500)(○⍳500)
        D←∆DICT X  
        :FOR L :IN   50 100 1000 
            :FOR K :IN 1 2 5×L
                ⎕←'KN: (?L⍴K),   where L=',L,' K=',K
                V←○L⍴K ⋄ KN←?L⍴K   
                cmpx ⎕←'KN D.Set1¨(V)'  
                cmpx ⎕←'D.Get KN' 
            :ENDFOR
        :ENDFOR

        ⎕←↑2⍴⊂'Character keys'
        X← (⍕¨⍳500)(○⍳500)
        D←∆DICT X
        :FOR L :IN   50 100 1000 
            :FOR K :IN 1 2 5×L
                ⎕←'KT: (⍕¨?L⍴K), where L=',L,' K=',K
                V←○L⍴K ⋄ KT← ⍕¨?L⍴K  
                cmpx ⎕←'KT D.Set1¨(V)'  
                cmpx ⎕←'D.Get KT'  
            :ENDFOR
        :ENDFOR
    :ENDIF 


:ELSE 
      ⎕←'HashTest terminated by user...'
:ENdTrap 
'Done'
      





