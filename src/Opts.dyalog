 Opts←{ 0:: ⎕SIGNAL ⎕EN ⋄ ⎕IO ⎕ML←0 1 ⋄ ns←⎕NS⍬  
    Set← { ns⍎⍺,'←⍵' }/ ⋄ KeepLast← { {o[⊃⌽⍵]}⌸⊃¨o←⍵ } ⋄ Nest1← { ⊂⍣(' '≡⊃⊃0⍴⍵)⊢⍵ }    
    ns⊣ Set¨ KeepLast ⍺,⍥Nest1 ⍵ 
 }
