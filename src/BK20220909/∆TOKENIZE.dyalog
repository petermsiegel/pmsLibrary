 tokenize←{⎕IO ⎕ML←0 1
     NL CR←⎕UCS 10 13
     opts←('Mode' 'M')('EOL' 'LF')('UCP' 1)('NEOL' 1)
     lines←{2=⍴⍴⍵:↓⍵ ⋄ 1≥|≡⍵:NL(≠⊆⊢),⍵ ⋄ ⍵}⍵
     lines←{⍵↓⍨-+/∧\' '=⌽⍵}¨lines

     DQp←'("[^"]*")+'
     SQp←'(''[^'']*'')+'
     NUMp←'(?xi)(?<REAL> ¯?(\d+(\.(\d*))?|\.\d+) (E¯?\d+)? )  (J(?&REAL))?'
     COMp←'⍝.*$'
     NAMEp←'(?xi) ( ⎕?[\w∆⍙#]+ (\. ⎕?[\w∆⍙#]+)* | :[\w∆⍙]+ )'
     SPACEp←'\h+'
     ANYp←'.'
     NLp←'\n'


     typeList←'DQ' 'SQ' 'NUM' 'COM' 'NAM' 'SP' 'ANY' 'NL'
     anyIn←,¨'←[]();' ⋄ anyOut←'ASGN' 'LBRK' 'RBRK' 'LPAR' 'RPAR' 'SEMI' 'FN'
     types←⍬ ⋄ setType←{types,←⍵}
     escape←{∊(⊂'\n')@(NL∘=)⊣∊(⊂'\\')@('\'∘=)⊣⍵}
     tokens←DQp SQp NUMp COMp NAMEp SPACEp ANYp NLp ⎕R{
         pat←⍵.PatternNum
         f0←escape ⍵.Match
         pat=6:f0,NL⊣setType⊂anyOut⊃⍨anyIn⍳⊂f0    ⍝ ANY
         f0,NL⊣setType typeList[pat]               ⍝ Everything else
     }⍠opts⊣⊆⍵

     types,[¯0.1]tokens
 }
