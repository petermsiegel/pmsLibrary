strOut← {opts} ∆FX strIn
    ; ch; csLvl; nDrop; multiTS; p; strTS
    ; AddTF; Escape; LP; NL; QT; RP; SP

NL←  ⎕UCS 10
LP RP QT SP←  '()'' '
spMax← 5

AddTF← { 
    strTS multiTS∘←'' 0 ⋄ 1: _←⍵ 
} { 
    0< ≢strTS: LP, ('↑,¨'/⍨ ×multiTS), QT, strTS, QT RP  ⋄ '' 
}
AddSF1← spMax∘{  
    ⍵=0: ''
    ⍵> ⍺: LP, RP,⍨  '⍴''''',⍨ (⍕⍵)
    LP, RP,⍨ QT, QT,⍨ ⍕⍵⍴''
}
AddSF2←{ 
    badE← 'Invalid Space Field' 11
    Skip← { ⍵↓⍨ +/∧\ ⍵∊ ⍺} 
    Span← { ⍵↑⍨ +/∧\ ⍵∊ ⍺} 

    ok n← ⎕VFI ⎕D Span ⍵
    ⊃ok: AddSF1 n 
    str← ' `' Skip ⍵
    '⍵⍹'∊⍨ ⊃str: { 
      ok num← ⎕VFI ⎕D Span ⍵ 
      ⊃ok: '(',')',⍨ '''''⍴⍨⍵⊃⍨⎕IO+',⍕omIx⊢←num  
      '(',')',⍨ '''''⍴⍨⍵⊃⍨⎕IO+',⍕omIx ⊣ omIx+← 1 
    } 1↓str 
    ⎕SIGNAL/badE 
}
Escape←{  Case← ⍵∘=
  Case '⋄': QT,SP,QT ⊣ nDrop⊢← 2 ⊣ multiTS+←1
  Case '\': '\'      ⊣ nDrop⊢← 2
  Case '{': '{'      ⊣ nDrop⊢← 2
  Case '}': '}'      ⊣ nDrop⊢← 2
            '\' 
}

omIx←0 
csLvl← 0
nDrop←0 
strOut← '{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨'
strTS← '' ⋄ multiTS←0 

:WHILE 0≠ ≢strIn←nDrop↓ strIn
    ch← ⊃strIn
    nDrop← 1
    :IF csLvl=0   ⍝ In a text field
        :SELECT ch 
        :CASE '\' 
            strTS,← Escape ⊃1↓strIn
        :CASE '{'   ⍝ Entering a Space Field or Code Field 
            strOut,← AddTF ⍬
            ch← ⊃strIn↓⍨ 1+ p← +/∧\' '=1↓strIn
            :IF '}'= ch 
                strOut,← AddTF ⍬
                strOut,← AddSF1 p 
                nDrop← 2+p
            :ELSEIF ':'= ch
                strOut,← AddTF ⍬
                close← q+ 1+ r← '}'⍳⍨ strIn↓⍨ q← 2+p 
                strOut,← AddSF2 r↑ strIn↓⍨ 2+p  
                nDrop← close  
            :ELSE 
                strOut,← '({'  
                csLvl← 1
            :ENDIF 
        :CASE QT  ⋄ strTS,← 2⍴QT 
        :ELSE     ⋄ strTS,← ch
        :ENDSELECT 
    :ELSE ⍝ In a Code Field
        :SELECT ch
        :CASE '{' 
            csLvl +← 1
            strOut,← '{'  
        :CASE '}' 
            csLvl-← 1
            :IF csLvl=0 ⋄ strOut,←'}⍵)' 
            :ELSE       ⋄ strOut,← '}' ⋄ :ENDIF
        :ELSE 
            strOut,← ch
        :ENDSELECT
    :ENDIF
:ENDWHILE

strOut,← AddTF ⍬
strOut,← '}'

 
