Fonts←{ 
  ⍝ Fonts:
  ⍝ strings2← [fNorm←0] ∇ strings
  ⍝   fNorm
  ⍝     fNorm= 1: normalizes all strings to plain ⎕A,⎕C⎕A chars BEFORE processing shift, superscripts, etc. (see below).
  ⍝               Otherwise, shifted characters are not impacted by shifts chars *, _, and `.
  ⍝     fNorm= 0: [default] do not normalize strings first, simply honor shift chars (see below).
  ⍝     fNorm=¯1: convert a shifted string back to one with explicit shift chars.
  ⍝   strings
  ⍝     one or more char vectors.
  ⍝   Returns:
  ⍝     strings2: same format as strings, but with characters translated per shift and escape characters.
  ⍝               If there is one string (char vector), it is returned as a simple vector.
  ⍝               Otherwise, a vector of vectors is returned.
  ⍝ 
  ⍝ Font shifts:
  ⍝   Text between n asterisks or underscores is shifted as follows:
  ⍝      n=↓                    n=↓                         n=↓
  ⍝        1 * (ital serif)       1 _ (ital sans serif)       1 ` (monospace font)
  ⍝        2 * (bold serif)       2 _ (bold sans serif)
  ⍝        3 * (ital-bold serif)  3 _ (ital-bold san serif)
  ⍝    
  ⍝ Escapes
  ⍝    \*, \_, \` 
  ⍝
  ⍝ Literal Text (when not matched by a closing shift)
  ⍝    2 or more ` (``); four or more * (****) or _ (____).
  ⍝    Note:   '*abc***def**' is  '*abc*' followed by '**def**'.
  ⍝
  ⍝ Superscript/subscript shifts: ^nnn, ∧nnn; ∨nnn
  ⍝   ^ or ∧ followed by one or more digits produces a superscript number.
  ⍝        ∨ followed by one or more digits produces a subscript number.
  ⍝
  ⍝ Load via 2 ⎕FIX 'file://Fonts.dyalog'
  
  0:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ EM EN Message)
    ⍺← 1 ⋄ ⎕IO←0 
    fNorm←⍺                                                ⍝ ∊1 0 ¯1

    fontStyles← ,¨'𝐴𝐀𝑨' '𝘈𝗔𝘼' '𝙰' 
    shiftStyles← '*' '**' '***' '_' '__' '___' '`' 
    lenFont← ≢stdFont← (1500⌶) ⎕A,⎕C ⎕A                    ⍝ std font:      UC,LC not contiguous 
    altFonts← (1500⌶) ∊⎕UCS (⎕UCS ∊fontStyles) ∘.+ ⍳52     ⍝ shifted fonts: UC,LC contiguous
    ssUCS←8304 8320                                        ⍝ Unicode for superscript (𝒙⁰) and subscript 0 (𝒙₀).
 
  ⍝ FontMap:
  ⍝   string2← [⍺← mode style] ∇ string1
  ⍝       ⍺:    (mode←0),(style←0)
  ⍝       0=≢⍺: Return string1
  ⍝         mode:   0=normalize, i.e. revert shifted chars to the standard ⎕A font.
  ⍝                 1=italics,  2=bold,  3=bold italics,             
  ⍝         style:  0=use serif font, 1=use sans serif font, 2=use monospace font
  ⍝   Returns string2: string1 with chars mapped per mode above and serif/sans serif/monospace fonts   
    FontMap←{ 
        ⍺← 0 0 ⋄ 0=≢⍺: ⍵ ⋄ mode style← 2↑⍺
        mode=0: { stdFont[  lenFont| altFonts⍳ ⍵ ] }@ ( ⍸⍵∊ altFonts )⊣ ⍵
        fontNum← ⎕UCS style (¯1+mode)⊃ fontStyles
        thisFont← ⎕UCS fontNum+ ⍳lenFont   
        { thisFont[ stdFont⍳ ⍵ ] } @ ( ⍸⍵∊ stdFont )⊢ ⍵
    } 

  ⍝ InvertAll: "The inverse of 1 Fonts ...
    InvertAll←{   
        ⍝ Import: ssUCS 
          ScriptInvert← {
              Fld←   ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block} 
              PCase← ⍵.PatternNum∘∊
              PCase 0 1:     Fld 0
              PCase 2:   '\',Fld 0
              PCase 3:   '^', ⎕D[ (ssUCS[0]+ ⍳9)⍳ ⎕UCS Fld 0 ] ⍝ map superscript digits to ⎕D
              PCase 4:   '∨', ⎕D[ (ssUCS[1]+ ⍳9)⍳ ⎕UCS Fld 0 ] ⍝ map subscript     "     " " 
          }
          FontInvert←{ 
              (sV fV) lines← ⍺ ⍵
            ⍝ Invert one font at a time, per fV...
              lines⊣ sV{ z← ⎕UCS 51+ ⎕UCS A←⍵  ⋄ shift←⍺   
                ⍝ fontP: only these letters plus (anything NOT a letter EXCEPT *, _, `)
                ⋄ Az← A,'-',z  
                ⋄ specials←  '\P{L}'                       ⍝ '\p{Z}\p{N}\p{P}\p{S}\p{M}' 
                ⋄ except← '(?<![*_`])'                     
                fontP← '[',Az,']([',Az,specials,']',except,')*'  
                0⊣ lines∘← fontP ⎕R {
                  Fld← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block}  
                  FlipSp← ⊢(↓,⍥⊂↑)⍨ (-+/⍤(∧\ ' '=⌽))       ⍝ Put closing shift BEFORE trailing spaces
                  f0 trail← FlipSp Fld 0  
                  trail,⍨ shift, shift,⍨ FontMap f0 
                }⊢lines
              }¨fV
          } 
          ⋄  lit4P←   '[\*_]{4,}' 
          ⋄  lit2P←   '`{2,}' 
          ⋄  escP←    '[*_`]' 
          ⋄  superP←  '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS ssUCS[0]+ 0 9
          ⋄  subP←    '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS ssUCS[1]+ 0 9
          lines← lit4P lit2P escP superP subP ⎕R ScriptInvert ⍵
          shiftStyles (∊fontStyles) FontInvert lines
    }     

  ⍝ SuperScan: Prefixes for numeric superscripts ^123, ∧123 and subscripts ∨123 inside or outside shifts.
    superPV← '\\([\^∧∨])' '([\^∧∨])([0-9]+)'             ⍝ ^∧ can be confused. Both are allowed as superscript prefixes.
    SuperScan← superPV ⎕R {
      ⍝ Import: ssUCS  
        Fld← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block}  
      ⍵.PatternNum=0: Fld 1                              ⍝ Escaped: Skip
        ucs0← ssUCS[0 0 1]/⍨ '^∧∨'= ⊃Fld 1               ⍝ Select unicode starting at super/sub-script 0
        ∊⎕UCS ucs0+ ⎕D⍳ Fld 2                            ⍝ Map from ⎕D to super or subscript range
    }

  ⍝ ShiftScan: Select mode and font based on the shift using asterisks, underscores, and back ticks (see above).
    escP←  '\\([*_`])'                                   ⍝ escape shift
    litP←  '(\*{4,}|_{4,}|`{2,})'                        ⍝ shift literals
    monoP← '(`)((\\`|.)*?)`'                             ⍝ monospace shift
    multiPV←  {                                          ⍝ multiple shifts ***, ___, etc.
      '(([*_])\2{','})((\\\2|.)*?)\1',⍨⍕¯1+⍵ 
    }¨3 2 1                   
    ShiftScan← (escP litP monoP, multiPV) ⎕R {
          Case← ⍵.PatternNum∘∊
          escI litI monoI← 0 1 2
          Fld ← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block }
      Case escI litI: Fld 1                              ⍝ escapes, literals
      Case monoI:   1 2 FontMap Fld 2                    ⍝ monospace (2)
          nshift← 6-⍵.PatternNum               ⍝ Else... ⍝ # of shift symbols (1=ital, 2=bold, 3=bold ital)                  
          sans← '_'=⍬⍴Fld 1                              ⍝ sans shift (1) or serif (0)?
          nshift sans FontMap Fld 3 
    }

  ⍝ If fNorm (⍺) is 1, map all special fonts to std (⎕A,⎕C⎕A) BEFORE processing shifts.
    PreNormalize← FontMap¨⍣(×fNorm)

    DeVV← {⊃⍣(1=≢⍵)⊢⍵ }                                  ⍝ If one string, convert to simple vector

  ⍝ EXECUTIVE...
    ¯1=fNorm: DeVV InvertAll ⊆⍵
              DeVV ShiftScan SuperScan PreNormalize ⊆⍵
}