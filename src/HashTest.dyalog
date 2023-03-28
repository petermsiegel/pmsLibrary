HashTest
  ;C;Old;New
  ;v;cc;nn;_t
  ;FORCE

:TRAP 1000
      FORCE←1
      :IF FORCE∨~×⎕SE.⎕NC '∆DICT0' 
          UCMD 'LOAD -target=⎕SE ∆DICT0'
      :ENDIF 
      :IF FORCE∨~×⎕SE.⎕NC '∆DICT' 
          UCMD 'LOAD -target=⎕SE ∆DICT'
      :ENDIF 
      :IF ~×⎕NC 'cmpx'
        'cmpx' ⎕CY 'dfns'
      :ENDIF 

      Old←∆DICT0
      New←∆DICT

      C←{⍺←1 ⋄ (⍕¨⍵?⌊⍺×⍵)(○⍳⍵)}
      N←{⍺←1 ⋄ (⍵?⌊⍺×⍵)(○⍳⍵)}

      ⎕SHADOW 'TEST1' 'TEST2' 'TEST3' 'TEST4'
      TEST1←TEST2←TEST3←0
      TEST4←1 

       ⎕←'>>> Create Empty Dicts.'
      :IF TEST1 
          cmpx ⌽'Old ⍬' 'New ⍬'
      :ENDIF 
      ⎕←' '

      ⎕← '>>> Create Dicts. with items' 
      :IF TEST2
      :FOR _t :IN (1.1 N¨10 50 100 500 1000)(1.1 C¨10 50 100 500 1000)
        :FOR v :IN _t
            ⎕← '    Arr. Size= ',(≢⊃v),' Type= ',(0=⊃0⍴⊃⊃v)⊃'Character' 'Numeric'
            cmpx ⌽'Old v' 'New v'
        :EndFor 
      :EndFor 
      :ENDIF
      ⎕←' '

      ⎕← '>>> Set items'
      :IF TEST3
      :FOR _t :IN (1.1 N¨10 50 100 500 1000)(1.1 C¨10 50 100 500 1000)
        :FOR v :IN _t
            ⎕← '    Arr. Size= ',(≢⊃v),' Type= ',(0=⊃0⍴⊃⊃v)⊃'Character' 'Numeric'
            o←0 Old ⍬ ⋄ n←0 New ⍬
            cmpx⌽ 'o.Set v'  'n.Set v'
        :EndFor 
      :EndFor 
      :ENDIF
      ⎕←' '

      ⎕← '>>> Get Mixed (50:50) items'
      :IF TEST4  
      :FOR _t :IN (1.1 N¨10 50 100 500 1000)(1.1 C¨10 50 100 500 1000)
        :FOR v :IN _t
            ⎕← '    Arr. Size= ',(≢⊃v),' Type= ',(0=⊃0⍴⊃⊃v)⊃'Character' 'Numeric'
            o←0 Old ⍬ ⋄ n←0 New ⍬
            o.Set v ⋄ n.Set v 
            v←(v,≢v)[(≢v)⌊?(≢v)⍴2×≢v]    ⍝ Random selection about 50% from the existing <v>
            cmpx⌽ 'o.Get v'  'n.Get v'
        :EndFor 
      :EndFor 
      :ENDIF
:ELSE 
      ⎕←'HashTest terminated by user...'
:ENdTrap 
      





