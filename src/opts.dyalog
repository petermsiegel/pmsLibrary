 opts←{⍺←''
     ⎕IO←0
     err←⎕SIGNAL∘11
   ⍝ ns ← declSpecs ∇ callSpecs
   ⍝   declSpecs: declaration parameters (options and flags)
   ⍝   callSpecs: calling parameters (options and arguments)
   ⍝ Description:
   ⍝    "Based on a set of options in declScan,
   ⍝     decode a set of 0 or more function call arguments, each a separate scalar.
   ⍝     Allow <-option arg> pairs where arg can be a scalar of any type."
   ⍝ See opts.help for information.

   ⍝ try2Num: Optionally, return parts of ⍵ that look like numbers as numeric vector.
   ⍝ If ⍺ is 1: If ⍵ is a string of 1 or more numbers, return (numbers 1).
   ⍝            Else return (⍵ 0).
   ⍝ Else:      Return (⍵ 0).
     try2Num←{⍺←1 ⋄ ~⍺:⍵ 0 ⋄ 2≠⎕NC'⍵':⍵ 0
         v2←⎕VFI ⍵ ⋄ ~1∊⊃v2:⍵ 0
         1=≢n←//v2:(⍬⍴n)1 ⋄ (∊n)1
     }
   ⍝ simplest: Treat 1-elem vectors or scalars as scalars. Enclose everything else.
     simplest←{(1=≢⍵)∧2≥|≡⍵:⍬⍴⍵ ⋄ ⊂⍵}

   ⍝ I. declScan - scan declarations (⍺) for option names and values
     declScan←{∆←declScan
       ⍝ Here, req (required) is 1 for required options.
         ⍺←{⍵⊣⍵.(names←vals←mins←req←isNum←⍬)}⎕NS''
         0=≢⍵:⍺
         name←⊃⍵
         '⎕'=1↑name:⍺{
            ⍝ ⎕L: LEFT options. Once first non-option seen, treat rest as regular args.
             '⎕L'≡2↑name:⍺ ∆ 1↓⍵⊣leftOnly∘←1
            ⍝ ⎕A: ALL options. In calls, allow options to left and right of args.
             '⎕A'≡2↑name:⍺ ∆ 1↓⍵⊣leftOnly∘←0
            ⍝ Unknown flag.
             err'opts: Unknown option flag: ',name
         }⍵
         name←name↓⍨'-'=⊃name
         ptr←name(⌊/⍳)'=:' ⋄ min←1⌈{⍵≥ptr:1 ⋄ ⍵}(ptr↑name)⍳'('
       ⍝ name
         ptr≥≢name:⍺{
             name←name~'()' ⋄ val←0 ⋄ req←0 ⋄ isNum←1
             ⍺.(names vals mins req isNum),←(⊂name)(val)min req isNum
             ⍺ ∆ 1↓⍵
         }⍵
       ⍝ name= or name: or name== or name::
         name val←((ptr↑name)~'()')(name↓⍨ptr+1) ⋄ req←0=≢val
         val skip←{(⊂val)∊,¨':=':(1↑1↓⍵)2 ⋄ val 1}⍵   ⍝ name== declaration
         (⊂name)∊⍺.names:err'opts: Option appears more than once: ',name
         val isNum←try2Num val
         ⍺.(names vals mins req isNum),←(⊂name)(simplest val)min req isNum
         ⍺ ∆ skip↓⍵
     }
   ⍝ II. callScan - scan call words for run-time options and arguments
     callScan←{⍺←declNs⊣declNs.ARGS←⍬ ⋄ ∆←callScan
         0=≢⍵:⍺
         nonOpt←{(1<|≡⍵)∨(1<⍴⍴⍵)∨(0≠80|⎕DR ⍵):1 ⋄ '-'≠1↑⍵}
         nonOpt⊃⍵:⍺{
             leftOnly:⍺⊣⍺.ARGS,←⍵    ⍝ ⎕LEFT flag set and we see a non-option: Done!
             ⍺ ∆ 1↓⍵⊣⍺.ARGS,←1↑⍵  ⍝ 1↑⍵ is an arg. Continue scan...
         }⍵
         name←⊃⍵
         '-'≠1↑name:⍺ skip ⍵
         '--'≡name:⍺⊣⍺.ARGS,←1↓⍵     ⍝ Done. Rest are args...
       ⍝ eq: 1 if there is = or :
         p←name(⌊/⍳)'=:'
         name eq val←(1↓p↑name)(p<≢name)(name↓⍨p+1)
         len←≢name
         poss←⍺.names/⍨(len↑¨⍺.names)∊⊂name
         0=≢poss:err'opts: Unknown option: ',name
         match←len≥⍺.mins[ptr←⍸⍺.names∊poss]

         0∊match:err'opts: Option not declared: ',name
         1≠+/match:err'opts: Option ambiguous: ',name
         0=≢val:⍺{
             req(⍺.req[ptr])←(⍺.req[ptr])0            ⍝ -opt=/required?
             eq⍱req:⍺ ∆ 1↓⍵⊣⍺.vals[ptr]←1          ⍝  */0           Set to 1.
             2>≢⍵:err'opts: Option ',name,' requires explicit value.'
             ⍺ ∆ 2↓⍵⊣⍺.vals[ptr]←1↑1↓⍵             ⍝  */1           Set to next item.
         }⍵
       ⍝ Has a value...
         ⍺.vals[ptr]←simplest⊃⍺.isNum[ptr]try2Num val ⋄ ⍺.req[ptr]←0
         ⍺ ∆ 1↓⍵
     }
   ⍝ III. setNamesFrom: Set option namespace, option values, and ARGS.
     setNamesFrom←{
         2::err'opts: Invalid option name: ',⍺
         ⍺⍺⍎⍵⍵.⍺,'←⍵'
     }

     leftOnly←0
     declNs←declScan⊆⍺                                        ⍝   I
     declNs←callScan⊆⍵                                        ⍝  II

     1∊declNs.req:err{ ⍝ Error if any required names weren't set.
         'opts: Required options not set:',∊' ',¨⍵
     }declNs.(req/names)
     opts←⎕NS'' ⋄ opts.(ARGS DECL)←declNs.ARGS declNs
     _←declNs.names(opts setNamesFrom declNs)¨declNs.vals     ⍝ III
     opts
 }
