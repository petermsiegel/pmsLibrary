 ∆OPTS←{⍺←''
     ⎕IO←0
     err←⎕SIGNAL∘11
   ⍝ ns ← declSpecs ∇ callSpecs
   ⍝   declSpecs: declaration specifications (options and flags)
   ⍝   callSpecs: "user" calling options and arguments
   ⍝ Description:
   ⍝    "Based on a set of options in declScan,
   ⍝     decode a set of 0 or more function call arguments, each a separate scalar.
   ⍝     Allow <-option arg> pairs where arg can be a scalar of any type."
   ⍝ See ∆OPTS.help for information.

   ⍝ try2Num: Optionally, return parts of ⍵ that look like numbers as numeric vector..
     try2Num←{⍺←1
         ~⍺:⍵ 0 ⋄ 2≠⎕NC'⍵':⍵ 0 ⋄ 0≠80|⎕DR ⍵:⍵ 0 ⋄ ~1∊⊃v2←⎕VFI ⍵:⍵ 0
         1=≢n←//v2:(⍬⍴n)1 ⋄ (∊n)1
     }
   ⍝ simple: ⍵ → scalar (1-elem vectors converted to simple scalars).
     simple←{(1=≢⍵)∧2≥|≡⍵:⍬⍴⍵ ⋄ ⊂⍵}

   ⍝ I. declScan - scan declarations (⍺) for option names and values
     declScan←{∆←∇
       ⍝ Here, req (required) is 1 for required options.
         ⍺←{⍵⊣⍵.(names←vals←mins←req←isNum←⍬)}⎕NS''
         0=≢⍵:⍺
         name←⊃⍵
         '⍠'=1↑name:⍺{
            ⍝ ⍠L/EFT vs ⎕A/LL (default)
            ⍝ ⍠LEFT: For calls (⍵), options (-likeThis) after first std arg treated as args.
            ⍝ ⍠ALL:  Accept all options anywhere in call list.
             '⍠L'≡2↑name:⍺ ∆ 1↓⍵⊣leftOnly∘←1 ⋄ '⍠A'≡2↑name:⍺ ∆ 1↓⍵⊣leftOnly∘←0
            ⍝ ⎕S/TRING=1 (default 0):
            ⍝   If call vector (⍵) is a single string, split on blanks.
            ⍝   Otherwise. signal an error.
             '⍠S'≡2↑name:⍺ ∆ 1↓⍵⊣stringOK∘←1
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
         ⍺.(names vals mins req isNum),←(⊂name)(simple val)min req isNum
         ⍺ ∆ skip↓⍵
     }
   ⍝ II. callScan - scan call words for run-time options and arguments
     callScan←{
         ~stringOK:callScan2⊆⍵
         (0=80|⎕DR ⍵)∧1≥⍴⍴⍵:callScan2' '(≠⊆⊢)⍵
         err'opts: Call argument (⍵) must be simple string (⍠STRING specified).'
     }
     callScan2←{⍺←declNs⊣declNs.ARGS←⍬ ⋄ ∆←∇
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
         ⍺.vals[ptr]←simple⊃⍺.isNum[ptr]try2Num val ⋄ ⍺.req[ptr]←0
         ⍺ ∆ 1↓⍵
     }
   ⍝ III. setNamesFrom: Set option namespace, option values, and ARGS.
     setNamesFrom←{
         2::err'opts: Invalid option name: ',⍺
         ⍺⍺⍎⍵⍵.⍺,'←⍵'
     }

     leftOnly←stringOK←0
     declNs←declScan⊆⍺                                         ⍝   I
     declNs←callScan ⍵                                         ⍝  II
   ⍝ Error if any required names weren't set.
     1∊declNs.req:err'opts: Required options not set:',∊' ',¨declNs.(req/names)

     optsNs←⎕NS'' ⋄ optsNs.(ARGS DECL)←declNs.ARGS declNs
     _←declNs.names(optsNs setNamesFrom declNs)¨declNs.vals    ⍝ III
     optsNs
 }
