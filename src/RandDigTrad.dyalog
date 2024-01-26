res←{gen} RandDigTrad nDig
;fName;tie;in;bufG;bufSize
;GetDig

⍝ Use entropy from /dev/random to generate a char string representation of a <count>-digit number.
⍝     RandDig <count>
⍝
:Trap 0
    ⎕IO ⎕PP←0 34
    GetDig←{
      ⎕←'Getting Digits...'
        tie nD←⍺ ⍵
        asInt←323
        nD≤ ≢bufG: d⊣ bufG∘← nD↓bufG⊣ d←nD↑bufG 
        ⎕←'Getting entropy...'
        bufG,←' '~⍨⍕|⎕NREAD tie asInt bufSize ¯1
        tie ∇ nD
    }

    fName←'/dev/random'
    bufSize←⌈1024÷9
    bufG←''
    tie←fName ⎕NTIE 0

    :IF 0=⎕NC 'gen'  
       ⎕←' Simulating Yield. Enter #digits per item or 0 to terminate.'
       gen← ⎕NS⍬ ⋄ gen.Yield← { ⎕←⍵ ⋄ ⎕ } 
    :ENDIF 

    :IF 0≠⊃0⍴nDig ⋄ 'Invalid right arg.' ⎕SIGNAL 11 ⋄ :ENDIF 
    :While 0≢in←gen.Yield tie GetDig nDig
        :If 0=⊃0⍴in ⋄ ⎕←nDig←in ⋄ 'Set nDig to',nDig ⋄ :EndIf
    :EndWhile

    ⎕NUNTIE tie
    res←1
:Else
    'Something bad happened'
    res←0
:EndTrap
