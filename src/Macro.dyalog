Macro←{
   wP← '[\pL⍙∆][\pL⍙∆\d]*'
   cP← '\h*⍝.*$'
   spP← '\h+'
   qP← '(?:''[^'']*'')+'
   lbP←'\['
   xP← '.'
   wP cP spP qP xP lbP ⎕R '<\0>'⊣⍵ 
}