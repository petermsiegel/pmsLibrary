 ns←opts ∆OPTS source
 ;findName;getNums;getString;setVar
 ;_;fpat;npat;pats;spat
 ;DEBUG;VALID_TYPES

 DEBUG←0    ⍝ If 1, ⎕SIGNALs will interrupt in place.

 ⍝H   opts←(name1 def1 type1) ... (nameN defN typeN)
 ⍝H   nameN:   a name (to be preceded by a hyphen). Some names beginning with ∆ are reserved.
 ⍝H            A name may not begin with a digit.
 ⍝H   defN:    default. Need not be of the type set by <types>, e.g. ⎕NULL could be used to check if set.
 ⍝H   typeN:   one of types below
 ⍝H
 ⍝H   type    designation    declaration                 meaning                    notes
 ⍝H   Flag    'F'            -MyFlag                     ns.MyFlag←1
 ⍝H                          -noMyFlag                   ns.MyFlag←0                prefix lower-case 'no'
 ⍝H   String  'S'            -Name "414 Smith Ln"        ns.Name←'414 Smith Ln'     handles internal quotes (single or dbl)
 ⍝H                          -Name John_Jacob            ns.Name←'John_Jacob'       any non-blank text '[^\s]+'
 ⍝H   Numeric 'N'            -Coord 25 -34 17.2 ¯.5      ns.Coord←25 ¯34 17.2 ¯.5   hyphen converted to high-minus
 ⍝H
 ⍝H   Returns a namespace
 ⍝H     ns.Rainbow   gives the current value of option 'Rainbow' (default, if not otherwise set)
 ⍝H     ns.∆NAMES    is the list of names of options. These are sorted with longer names first.
 ⍝H     ns.∆ARGS     is the final string components that remain after all options removed...
 ⍝H     ns.∆SOURCE   is the original string passed.
 ⍝H     ns.∆VALUES   is the list of current values
 ⍝H     ns.∆DEFAULTS is the list of defaults for the names.
 ⍝H
 ⍝H  Sample <opts>
 ⍝H           name    default  type                               flag -Debug:   ns.Debug←1
 ⍝H           ↓       ↓        ↓                                  ↓    -noDebug: ns.Debug←0
 ⍝H    opts← ('Nums'  (45 55)  'N')   ('Name'  'john smith' 'S')  ('Debug' 1 'F')   ('Alpha'  ⎕A 'S')

 ⍝   PMSLIB Utilities
 ⍝ ∆F:  Find a pcre field by name or field number


 ∆F←{N O B L←⍺.(Names Offsets Block Lengths)
     def←'' ⋄ isN←0≠⍬⍴0⍴⍵
     p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
     B[O[p]+⍳L[p]]
 }
 ⍝ End PMSLIB Utilities

 VALID_TYPES←'FSN'

    ⍝ Patterns
 numsP←'(?x) ^ \h* ((?<num> [-¯]? \.? \d [^\h]*) (\h+ (?&num))*)'
 stringP←'(?x) ^ \h* ( (?:"[^"]*")+ | (?:''[^'']*'')+ | [^\h]+ )'
    ⍝ Error msgs
 optE←'Each option spec must include 3 items: name default type.'
 unknownE←'Unknown option: -'
 badNumE←'Invalid numeric option: -'

 :Trap 0⍴⍨~DEBUG
      ⍝ Utilities
     getNums←{nm←⍺ ⋄ src←⍵ ⋄ numStr←''
         src←numsP ⎕R{ ⋄ ''⊣numStr∘←⍵ ∆F 1}src
         valid nums←⎕VFI'¯'@('-'∘=)⊣numStr
         0∊valid:11 ⎕SIGNAL⍨badNumE,nm,' ',numStr
         nums src
     }
     getString←{nm←⍺ ⋄ src←⍵ ⋄ str←''
         SQ DQ←'''' '"'
         deQuote←{f←⊃⍵ ⋄ f(~∊)SQ DQ:⍵ ⋄ w←1↓¯1↓⍵ ⋄ f∊SQ:w ⋄ w/⍨~(DQ DQ)⍷w}
         str(stringP ⎕R{''⊣str∘←deQuote ⍵ ∆F 1}⊣src)
     }
     findName←{nm←⍵ ⋄ nms←⍺.∆NAMES ⋄ max←≢nms
         max>p←nms⍳⊂nm:nm p 1
         'no'≢2↑⍵:11 ⎕SIGNAL⍨unknownE,nm
         p←nms⍳⊂nm2←2↓⍵ ⋄ t←'F'=p⊃⍺.∆TYPES
         t∧max>p:nm2 p 0
         11 ⎕SIGNAL⍨unknownE,(t⊃nm nm2)
     }
     is←{(,⍺)≡,⍵}
     in←{(⊂⍺)∊⊆⍵}
     skipBlanks←{⍵↓⍨+/∧\' '=⍵}

      ⍝ -------------------------------------------------------
      ⍝ EXECUTIVE
      ⍝ -------------------------------------------------------

     ns←⎕NS'' ⋄ setVar←ns.{1:⍎⍺,'←⍵'}

     optE ⎕SIGNAL 11/⍨0∊3=≢¨opts
     ns.(∆NAMES ∆DEFAULTS ∆TYPES)←↓⍉↑opts
     ns.∆NAMES setVar¨ns.∆DEFAULTS   ⍝ Set defaults
      ⍝ Walk left to right through source string, looking for options and associated value tokens
     ns.∆ARGS←{src←skipBlanks ⍵
         0=≢src:src
         '-'≠1↑src:src ⋄ src↓⍨←1
         nm←src↑⍨p←src⍳' ' ⋄ src↓⍨←p
         nm is'-':src                 ⍝ Flag '--' ends scan
         nm p flagV←ns findName nm
         case←(p⊃ns.∆TYPES)∘=
         case'F':∇ src⊣nm setVar flagV              ⍝ set var to 1 (-Opt) or 0 (-noOpt)
         case'N':∇ src⊣nm setVar nums⊣nums src←nm getNums src
         case'S':∇ src⊣nm setVar str⊣str src←nm getString src
         11 ⎕SIGNAL⍨'∆OPTS: Invalid type: "','"',p⊃ns.∆TYPES
     }ns.∆SOURCE←source
     ns.∆VALUES←ns⍎¨ns.∆NAMES
 :Else
     ⎕SIGNAL/⎕DMX.(EM EN)
 :EndTrap
⍝∇⍣§./∆OPTSNew2.dyalog§0§ 2020 9 19 12 57 57 258 §ÅtSZK§0
