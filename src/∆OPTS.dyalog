 ∆OPTS←{
 ⍝ If no left arg, provides HELP information...
 ⍝ See ⍝H prefixed lines below for HELP info.
 0=⎕NC '⍺':⎕ED⍠('ReadOnly' 1)&'__∆OPTS_HELP'⊣__∆OPTS_HELP∘←{3↓¨⍵/⍨( ⊂'⍝H')≡¨2↑¨1↓¨⍵}⎕NR '∆OPTS'

 opts source←⍺ ⍵
 DEBUG←0    ⍝ If 1, ⎕SIGNALs will not be trapped...
 0⍴⍨~DEBUG: ⎕SIGNAL/⎕DMX.(EM EN)

 ⍝   PMSLIB Utilities
 ⍝ ∆F:  Find a pcre field by name or field number
 ∆F←{N O B L←⍺.(Names Offsets Block Lengths)
     def←'' ⋄ isN←0≠⍬⍴0⍴⍵
     p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
     B[O[p]+⍳L[p]]
 }
 ⍝ End PMSLIB Utilities

⍝ Initializations
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

     0∊3=≢¨opts: optE ⎕SIGNAL 11
     ns.(∆NAMES ∆DEFAULTS ∆TYPES)←↓⍉↑opts
     _←ns.∆NAMES setVar¨ns.∆DEFAULTS   ⍝ Set defaults
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
     1: ns

 ⍝H   ns ←  opts ∆OPTS source
 ⍝H   Descr: Processes <source> from left to right, scanning for options of two forms:
 ⍝H          -Flag or -Option value.
 ⍝H   For options of type 'F' (Flag)
 ⍝H      E.g. ('Flag' 1 'F') defines a flag named 'Flag' with a default of 1 (set).
 ⍝H      If -Flag is seen in Source, it sets ns.Flag←1.
 ⍝H      If -noFlag is seen, it sets ns.Flag←0.
 ⍝H   For an option <Option> of type 'S' (String) or 'N' (Numeric)
 ⍝H     E.g. ('Name' '' 'S') defines an option named 'Name' whose default is a null string which can be set to a string.
 ⍝H     E.g. ('Coord' ⎕NULL 'N') defines 'Coord' which can be defined as a numeric vector, but defaulting to ⎕NULL.
 ⍝H          If <Source> contains '-Coord 15 -24 12.3j¯45 -Name "Baton Rouge"'
 ⍝H          ns.Coord←15 ¯24 12.3J¯45 and ns.Name←'Baton Rouge'
 ⍝H     -Option num1 num2...
 ⍝H     -Option "string one"  OR   -Option ''string #2''   OR  -option string3
 ⍝H        sets ns.Option ← value.
 ⍝H        If Numeric, value will be a numeric vector (not a string).
 ⍝H        If String, value will have quotes (single or double) removed and adjusted for any APL-style internal doubling.
 ⍝H        If not quoted, a string value begins with the first non-blank char and ends at the last contiguous non-blank char.
 ⍝H
 ⍝H    --  Option '-' is a special option that terminates option scanning. Everything following --
 ⍝H        is treated as part of the (non-option) arguments <∆ARGS>.
 ⍝H 
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
 ⍝H  Sample <opts>
 ⍝H           name    default  type                               flag -Debug:   ns.Debug←1
 ⍝H           ↓       ↓        ↓                                  ↓    -noDebug: ns.Debug←0
 ⍝H    opts← ('Nums'  (45 55)  'N')   ('Name'  'john smith' 'S')  ('Debug' 1 'F')   ('Alpha'  ⎕A 'S')
 ⍝H
 ⍝H -------------------------------------------------------------------------------------------------------
 ⍝H   Example
 ⍝H        opts←('Rainbow' (?5⍴0)) 'N') ('Ponies' 'My Little Pony?' 'S')('Optimize' 0 'F')
 ⍝H        opts ∆OPTS '-Optimize -Rainbow -1J5 test one two'
 ⍝H   Returns a namespace <ns> with a value for each option and definitions for ∆NAMES, ∆ARGS, etc. as below:
 ⍝H       ns.Rainbow   gives the current value of option 'Rainbow' (default, if not otherwise set)
 ⍝H                    ns.Rainbow←¯1J5
 ⍝H       ns.Ponies    gives the current value of option 'Ponies' (default, if not otherwise set).
 ⍝H                    ns.Ponies←'My Little Pony?'
 ⍝H       ns.Optimize  ditto
 ⍝H                    ns.Optimize←1
 ⍝H       ------------
 ⍝H       ns.∆NAMES    is the list of names of options. These are in the order entered:
 ⍝H                    'Rainbow' 'Ponies' 'Optimize'
 ⍝H       ns.∆SOURCE   is the original string passed.
 ⍝H                    '-Optimize -Rainbow -1J5 test one two'
 ⍝H       ns.∆ARGS     is the string that remain after all options removed or option -- processed.
 ⍝H                    'test one two'
 ⍝H       ns.∆DEFAULTS is the list of defaults for the names in order. Defaults may have any type.
 ⍝H                    (0.4344 0.4343443 ...) ('My Little Pony?') (0)
 ⍝H       ns.∆VALUES   is the list of final values for each option; if changed, has the type determined by the option flag.
 ⍝H                    (¯1J5) ('My Little Pony?') (1)
 ⍝H
⍝∇⍣§./∆OPTSNew2.dyalog§0§ 2020 9 19 12 57 57 258 §ÅtSZK§0
 }
