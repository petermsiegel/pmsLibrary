Fonts←{ 
  ⍝ Fonts:   
  ⍝   A silly fn that maps unicode alphabetic characters onto unicode-specific alternate
  ⍝   modes (italics, bold, bold italics) and fonts (serif, sans serif, and monospace), using
  ⍝   shift "quotes" consisting of asterisks (*), underscores (_), and backticks (`), 
  ⍝   as well as caret (^, or logical and ∧) and logical or (∨) for superscripts and subscripts.
  ⍝   Includes options for clearing alternate modes (1) AND for inverting a shifted text back to
  ⍝   unshifted text with shift quote characters (¯1).
  ⍝
  ⍝ strings2← [action←1] ∇ strings
  ⍝   action
  ⍝     action= 1: [default] Normalizes ("clears") all strings to plain ⎕A,⎕C⎕A chars BEFORE processing shift, 
  ⍝                superscripts, etc. (see below). Map plain alph characters to alt chars per shift sequences, 
  ⍝                map superscripts, subscripts, etc.
  ⍝     action= 0: Does NOT normalize strings first, simply honor shift sequences when mapping plain chars (see below). 
  ⍝                Map plain alph characters to alt chars per shift sequences, map superscripts, subscripts, etc.
  ⍝                Alph chars already mapped to alt chars will be left as is.
  ⍝     action=¯1: inverse of (1 ∇):
  ⍝                Converts a shifted string back to one with regular alphabetic text AND explicit shift chars.
  ⍝   strings
  ⍝     one or more char vectors.
  ⍝   Returns:
  ⍝     strings2: same format as strings, but with characters translated per shift and escape characters.
  ⍝               If there is one string (char vector), it is returned as a simple vector.
  ⍝               Otherwise, a vector of vectors is returned.
  ⍝ 
  ⍝ Font shifts:
  ⍝   Text between n asterisks or underscores is shifted as follows:
  ⍝        1 *   (ital serif)       1 _   (ital sans serif)     1 ` (monospace font)
  ⍝        2 **  (bold serif)       2 __  (bold sans serif)
  ⍝        3 *** (ital-bold serif)  3 ___ (ital-bold san serif)
  ⍝    
  ⍝ Superscript/subscript shifts: ^nnn, ∧nnn; ∨nnn
  ⍝   ^ or ∧ followed by one or more digits produces a superscript number.
  ⍝        ∨ followed by one or more digits produces a subscript number.
  ⍝
  ⍝ Escapes
  ⍝    \*, \_, \` 
  ⍝
  ⍝ Literal Text (when an opening shift is not matched by a balancing, closing shift)
  ⍝    2 or more ` (``); four or more * (****) or _ (____).
  ⍝    Note:   '*abc***def**' is  '*abc*' followed by '**def**'.
  ⍝
  ⍝ Load via 2 ⎕FIX 'file://Fonts.dyalog'
  
 ⍝ 0:: ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ EM EN Message)
    ⍺← 1 ⋄ ⎕IO←0 
    action←⍺                                                ⍝ ∊1 0 ¯1

    fontStyles← ,¨'𝐴𝐀𝑨' '𝘈𝗔𝘼' '𝙰' 
    shiftStyles← '*' '**' '***' '_' '__' '___' '`' 
    stdFont← (1500⌶) ⎕A,⎕C ⎕A                              ⍝ std font:      UC,LC not contiguous 
    lenFont← ≢stdFont
    altFonts← (1500⌶) ∊⎕UCS (⎕UCS ∊fontStyles) ∘.+ ⍳52     ⍝ shifted fonts: UC,LC contiguous
    ss0_uni← ⎕UCS '⁰₀'                                     ⍝ Unicode for superscript/subscript 0 (8304 8320).  
 
  ⍝ MapF:
  ⍝   string2← [⍺← mode style] (refFont ∇) string1 
  ⍝       ⍺:    (mode←0),(style←0)
  ⍝       0=≢⍺: Return string1
  ⍝         mode:   0=normalize, i.e. revert shifted chars to the standard ⎕A font.
  ⍝                 1=italics,  2=bold,  3=bold italics,             
  ⍝         style:  0=use serif font, 1=use sans serif font, 2=use monospace font
  ⍝   Returns string2: string1 with chars mapped per mode above and serif/sans serif/monospace fonts   
    MapF←{ 
        refFont← stdFont
        ⍺← 0 0 ⋄ 0=≢⍺: ⍵ ⋄ mode style← 2↑⍺
        mode=0: { refFont[  lenFont| altFonts⍳ ⍵ ] }@ ( ⍸⍵∊ altFonts )⊣ ⍵
        fontNum← ⎕UCS fontStyles⊃⍨ style (¯1+mode) 
        thisFont← ⎕UCS fontNum+ ⍳lenFont   
        { thisFont[ refFont⍳ ⍵ ] } @ ( ⍸⍵∊ refFont )⊢ ⍵
    }

  ⍝ Invert: 
  ⍝    Transform strings mapped onto Unicode fonts back to one with regular alphabetic text 
  ⍝    AND explicit shift and prefix chars.
  ⍝    strings← ∇ strings
  ⍝
    Invert←{   
      ⍝ Import: ss0_uni 
        ⋄  lit4P←   '[\*_]{4,}' 
        ⋄  lit2P←   '`{2,}' 
        ⋄  escP←    '[*_`]' 
        ⋄  superP←  '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS ss0_uni[0]+ 0 9
        ⋄  subP←    '[',sa,'-',sz,']+' ⊣ sa sz← ⎕UCS ss0_uni[1]+ 0 9
        RestoreMisc← lit4P lit2P escP superP subP ⎕R {
            lit4I lit2I escI superI subI← 0 1 2 3 4
            Fld←   ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block} 
            PCase← ⍵.PatternNum∘∊
            PCase lit4I lit2I: Fld 0
            PCase escI:    '\',Fld 0
            PCase superI:  '^', ⎕D[ (ss0_uni[0]+ ⍳9)⍳ ⎕UCS Fld 0 ] ⍝ map superscript digits to ⎕D
            PCase subI:    '∨', ⎕D[ (ss0_uni[1]+ ⍳9)⍳ ⎕UCS Fld 0 ] ⍝ map subscript     "     " " 
        }         
        RestoreShifts← shiftStyles (∊fontStyles)∘ { 
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
                trail,⍨ shift, shift,⍨ MapF f0 
              }⊢lines
            }¨fV
        } 
        RestoreShifts RestoreMisc ⍵
    }     

  ⍝ Convert:
  ⍝    Convert fonts, superscripts, etc., based on shifts and prefixes.
  ⍝    See ConvertSupSub, ConvertShifts
  ⍝ strings← ∇ strings
  ⍝ 
    Convert← {
    ⍝ ConvertSupSub: Prefixes for numeric superscripts ^123, ∧123 and subscripts ∨123 inside or outside shifts.
      sSPV← '\\([\^∧∨])' '([\^∧∨])([0-9]+)'                ⍝ ^∧ can be confused. Both are allowed as superscript prefixes.
      ConvertSupSub← sSPV ⎕R {
        ⍝ Import: ss0_uni  
          Fld← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block}  
        ⍵.PatternNum=0: Fld 1                              ⍝ Escaped: Skip
          ucs0← ss0_uni[0 0 1]/⍨ '^∧∨'= ⊃Fld 1             ⍝ Select unicode starting at super/sub-script 0
          ∊⎕UCS ucs0+ ⎕D⍳ Fld 2                            ⍝ Map from ⎕D to super or subscript range
      }

    ⍝ ConvertShifts: Select mode and font based on the shift using asterisks, underscores, and back ticks (see above).
      escP←  '\\([*_`])'                                   ⍝ escape shift
      litP←  '(\*{4,}|_{4,}|`{2,})'                        ⍝ shift literals
      monoP← '(`)((\\`|.)*?)`'                             ⍝ monospace shift
      boldItalP boldP italP← {                             ⍝ multiple shifts ***, ___, etc.
          '(([*_])\2{','})((\\\2|.)*?)\1',⍨⍕¯1+⍵ 
      }¨3 2 1     
      shiftPV←  escP litP monoP boldItalP boldP italP             
      ConvertShifts← shiftPV ⎕R {
            Case← ⍵.PatternNum∘∊
            escI litI monoI boldItalI boldItal italI← ⍳6
            Fld ← ⍵.{ Lengths[⍵]↑Offsets[⍵]↓Block }
        Case escI litI: Fld 1                              ⍝ escapes, literals
        Case monoI:   1 2 MapF Fld 2                    ⍝ monospace (2)
      ⍝ Else...
            nshift← 6-⍵.PatternNum                         ⍝ # of shift symbols (1=ital, 2=bold, 3=bold ital)                  
            sans← '_'=⍬⍴Fld 1                              ⍝ sans shift (1) or serif (0)?
            nshift sans MapF Fld 3  
      } 
      ConvertShifts ConvertSupSub ⍵ 
    }                    
 
    DeVV← { ⊃⍣(1=≢⍵)⊢⍵ }                                 ⍝ If one string, convert to simple vector

  ⍝ EXECUTIVE...
    ¯1=action: DeVV Invert  ⊆⍵
     0=action: DeVV Convert ⊆⍵                          
     1=action: DeVV Convert MapF¨ ⊆⍵                  ⍝ action? Map alt fonts to std BEFORE processing.
     ⎕SIGNAL 11
}