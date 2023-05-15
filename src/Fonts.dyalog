Fonts←{ 
  ⍝ Fonts:
  ⍝ strings2← [⍺] ∇ strings
  ⍝     ⍺= 0: [default] do not normalize strings first, simply honor shift chars (see below).
  ⍝     ⍺= 1: normalizes all strings to plain ⎕A,⎕C⎕A chars before processing shift, superscripts, etc. (see below).
  ⍝           strings: one or more char vectors.
  ⍝     ⍺=¯1: convert a shifted string back to one with explicit shift chars.
  ⍝ Returns strings2, same as strings, but with characters translated as specified below.
  ⍝ 
  ⍝ Shifts:
  ⍝   Text between n asterisks or underscores is shifted as follows:
  ⍝    n=↓                    n=↓                         n=↓
  ⍝      1 * (ital serif),      1 _ (ital sans serif)       1 ` (monospace font)
  ⍝      2 * (bold serif),      2 _ (bold sans serif)
  ⍝      3 * (ital-bold serif), 3 _ (ital-bold san serif)
  ⍝    
  ⍝ Escapes:  \*, \_, \` 
  ⍝   Literal text:  2 or more ` (``); four or more * (****) or _ (____).
  ⍝
  ⍝ Superscripts: ^nnn, ∧nnn; ∨nnn
  ⍝   ^ or ∧ followed by one or more digits produces a superscript number.
  ⍝        ∨ followed by one or more digits produces a subscript number.
  ⍝
  ⍝ Load via 2 ⎕FIX 'file://Fonts.dyalog'
  
    ⍺← 1 ⋄ ⎕IO←0 
    fNorm←⍺    ⍝ If 1 (default), force input string alphabetic chars to standard font before processing shifts.

  ⍝ MapFonts:
  ⍝   string2← [⍺← mode style] ∇ string1
  ⍝       ⍺:    (mode←0),(style←0)
  ⍝       0=≢⍺: Return string1
  ⍝         mode:   0=normalize, i.e. revert shifted chars to the standard ⎕A font.
  ⍝                 1=italics,  2=bold,  3=bold italics,             
  ⍝         style:  0=use serif font, 1=use sans serif font, 2=use monospace font
  ⍝   Returns string2: string1 with chars mapped per mode above and serif/sans serif/monospace fonts
    lenFont← ≢stdFont← (1500⌶) ⎕A,⎕C ⎕A                  ⍝ std font:      UC,LC not contiguous 
    altFonts← (1500⌶) ∊⎕UCS (⎕UCS '𝐴𝐀𝑨𝘈𝗔𝘼𝙰') ∘.+ ⍳52     ⍝ shifted fonts: UC,LC contiguous
    MapFonts←{ 
        ⍺← 0 0 ⋄ 0=≢⍺: ⍵ ⋄ mode style← 2↑⍺
        mode=0: { stdFont[  lenFont| altFonts⍳ ⍵ ] }@ ( ⍸⍵∊ altFonts )⊣ ⍵
      3:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂ EM EN)
        fontsA←   ↑'𝐴𝐀𝑨' '𝘈𝗔𝘼' '𝙰'                       ⍝ Serif As: 𝐴𝐀𝑨, Sans As: 𝘈𝗔𝘼, Monospace A: 𝙰
        fontA←    fontsA[ style; ¯1+mode]
        thisFont← ⎕UCS (⎕UCS fontA)+ ⍳lenFont   
        { thisFont[ stdFont⍳ ⍵ ] } @ ( ⍸⍵∊ stdFont )⊢ ⍵
    } 

    superZ subZ←8304 8320 
    InvertAll←{   
        ⍝ Import: superZ subZ
          _InvertScripts← {
              fld0←  ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block} 0
              PCase← ⍵.PatternNum∘∊
              PCase 0 1:     fld0
              PCase 2:   '\',fld0
              PCase 3:   '^', ⎕D[ (superZ +⍳9)⍳ ⎕UCS fld0 ] ⍝ map superscript digits to ⎕D
              PCase 4:   '∨', ⎕D[ (subZ   +⍳9)⍳ ⎕UCS fld0 ] ⍝ map subscript     "     " " 
          }
          _InvertFonts←{ 
              (sV fV) lines← ⍺ ⍵
              lines⊣ sV{ z← ⎕UCS 51+ ⎕UCS A←⍵  ⋄ shift←⍺   
                ⍝ fontP: only these letters plus (anything NOT a letter EXCEPT *, _, `)
                ⋄ Az← A,'-',z  
                ⋄ specials←  '\P{L}'                       ⍝ '\p{Z}\p{N}\p{P}\p{S}\p{M}' 
                ⋄ except← '(?<![*_`])'                     
                fontP← '[',Az,']([',Az,specials,']',except,')*'  
                0⊣ lines∘← fontP ⎕R {
                  Fld← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block}  
                  shift,shift,⍨ MapFonts Fld 0
                }⊢lines
              }¨fV
          } 
            lit4P←   '[\*_]{4,}' 
            lit2P←   '`{2,}' 
            escP←    '[*_`]' 
            superP←  '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS superZ+ 0 9
            subP←    '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS subZ+   0 9
          lines← lit4P lit2P escP superP subP ⎕R _InvertScripts ⍵
            fontV← '𝐴𝐀𝑨𝘈𝗔𝘼𝙰' 
            shiftV← '*' '**' '***' '_' '__' '___' '`' 
          shiftV fontV _InvertFonts lines
    }     

  ⍝ SuperScan: Prefixed numeric superscripts ^123, ∧123 and subscripts ∨123 inside or outside shifts.
    superPV← '\\([\^∧∨])' '([\^∧∨])([0-9]+)'             ⍝ ^∧ can be confused. Both are allowed as superscript prefixes.
    SuperScan← superPV ⎕R {
      ⍝ Import: superZ subZ
        Fld← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block}  
      ⍵.PatternNum=0: Fld 1                              ⍝ Escaped: Skip
        ucs0← superZ superZ subZ/⍨ '^∧∨'= ⊃Fld 1         ⍝ Select unicode starting at super/sub-script 0
        ∊⎕UCS ucs0+ ⎕D⍳ Fld 2                            ⍝ Map from ⎕D to super or subscript range
    }

  ⍝ ShiftScan: Handle the various fonts based on the shift using asterisks and underscores (see above).
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
      Case monoI:   1 2 MapFonts Fld 2                   ⍝ monospace (2)
          nshift←   6-⍵.PatternNum             ⍝ Else... ⍝ # of shift symbols (1=ital, 2=bold, 3=bold ital)                  
          sans← '_'=⍬⍴Fld 1                              ⍝ sans shift (1) or serif (0)?
          nshift sans MapFonts Fld 3 
    }

  ⍝ If fNorm (⍺) is 1, map all special fonts to std (⎕A,⎕C⎕A) BEFORE processing shifts.
    PreNormalize← MapFonts¨⍣fNorm

    DeVV← {⊃⍣(1=≢⍵)⊢⍵ }                                  ⍝ If one string, convert to simple vector

  ⍝ EXECUTIVE...
    ¯1=fNorm: DeVV InvertAll ⊆⍵
              DeVV ShiftScan SuperScan PreNormalize ⊆⍵
}