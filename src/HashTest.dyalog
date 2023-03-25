HashTest
  ;_; keysG
  ;Check; Do; Set 

  ⎕FX'Do thing' '⍎thing' 'Check thing'
     _←  'Check msg;s'  '⎕←msg'  ':SELECT 1(1500⌶)keysG'
     _,←⊂' :CASE 2 ⋄ ⎕←''  2 Active'''
     _,←⊂' :CASE 1⋄  ⎕←''  1 Enabled'' '
     _,←⊂' :Else⋄ ⎕←''  0 Inactive: Re/setting'' ⋄ keysG←(1500⌶)keysG ⋄ {}keysG⍳2 ⋄ :END'
  ⎕FX _ 
  ⎕FX 'Reset' 'keysG←1500⌶ keysG' 'Check ''Resetting Hashing'''

  Do 'keysG←  ,⊂⍬' 
  Do 'keysG,← 1 2' 

  Do 'keysG,←  4'
  Do 'keysG,← ,¨1 2' 
  
  Do 'keysG,← ,¨3 4'

  Do 'keysG,← (1 2 3)(5 6)'

  Do 'keysG,←  ''one'' ''two'' '

  Do 'keysG,← 12.2'
  Do 'keysG,← 13.2'
  Do 'keysG,← 13.2'

  Do 'keysG←  ,0'
  Do 'keysG,← 12.2'
  Do 'keysG,← 13.2'
  Do 'keysG,← 13.2'

