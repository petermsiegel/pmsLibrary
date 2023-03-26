HashTest
  ;C;Old;New
  ;v;cc;nn;_t
  

  :IF ~×⎕SE.⎕NC '∆DICT0' 
      UCMD 'LOAD -target=⎕SE ∆DICT0'
  :ENDIF 
  :IF ~×⎕NC 'cmpx'
     'cmpx' ⎕CY 'dfns'
  :ENDIF 

  Old←∆DICT0
  New←∆DICT

  C←{⍺←1 ⋄ (⍕¨⍵?⌊⍺×⍵)(○⍳⍵)}
  N←{⍺←1 ⋄ (⍵?⌊⍺×⍵)(○⍳⍵)}

  '>>> Create Empty Dicts.'
  cmpx 'Old ⍬' 'New ⍬'

  :FOR _t :IN (1.1 N¨10 50 100 500 1000)(1.1 C¨10 50 100 500 1000)
    :FOR v :IN _t
        ⎕← '>>> Create Dicts. with items'
        ⎕← '    Arr. Size= ',(≢⊃v),' Type= ',(0=⊃0⍴⊃⊃v)⊃'Character' 'Numeric'
        cmpx ⌽'Old v' 'New v'
    :EndFor 
  :EndFor 
  ⎕←' '
  :FOR _t :IN (1.1 N¨10 50 100 500 1000)(1.1 C¨10 50 100 500 1000)
    :FOR v :IN _t
        ⎕← '>>> Set items'
        ⎕← '    Arr. Size= ',(≢⊃v),' Type= ',(0=⊃0⍴⊃⊃v)⊃'Character' 'Numeric'
        o←0 Old ⍬ ⋄ n←0 New ⍬
        cmpx⌽ 'o.Set v'  'n.Set v'
    :EndFor 
  :EndFor 
      





