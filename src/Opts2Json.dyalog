 Opts2Json←{
     ns← ⎕NS⍬
     S← { ⍺{ ns⍎⍺,'←⍵'}{1≥p←1 0⍳⊂⍵:p⊃⊂¨'false' 'true' ⋄ ⍵}⍵ }
     _←S/¨↑⍉↓⍵
     ⎕JSON⍠('Dialect' 'JSON5')⊢ns
 }
