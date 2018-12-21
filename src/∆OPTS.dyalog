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
   ⍝ See ∆OPTS.help for specific syntax and related information.

   ⍝ try2Num: If ⍵ is solely numbers, return a numeric vector; else return char string.
     try2Num←{⍺←1 ⋄ ~⍺:⍵ 0 ⋄ 0::⍵ 0 ⋄ s n←⎕VFI ⍵ ⋄ (0=≢s)∨0∊s:⍵ 0 ⋄ n 1}
   ⍝ scalify: Treat 1-element vector or scalar as scalar; otherwise enclose.
     scalify←{1=≢⍵:⍬⍴⍵ ⋄ ⊂⍵}

   ⍝ I. declScan - scan declarations (⍺) for option names and values
     declScan←{∆←∇
       ⍝ Here, isReq (required) is 1 for required options.
         ⍺←{⍵⊣⍵.(names←vals←mins←isReq←isNum←isFlag←⍬)}⎕NS''
         0=≢⍵:⍺
         name←⊃⍵
         0≠80|⎕DR name:err'At least one declared option (⍺) not a string.'
         '⍠'=1↑name:⍺{case←{⍵≡name↑⍨≢⍵}
            ⍝ ⍠L/EFT vs ⎕A/LL (default)
            ⍝ ⍠LEFT: For calls (⍵), options (-likeThis) after first std arg treated as args.
            ⍝ ⍠ALL:  Accept all options anywhere in call list.
             case'⍠L':⍺ ∆ 1↓⍵⊣leftOnly∘←1
             case'⍠A':⍺ ∆ 1↓⍵⊣leftOnly∘←0
            ⍝ ⍠T/EXT=1 (default 0):
            ⍝   If call vector (⍵) is a single string, split on blanks.
            ⍝   Otherwise. signal an error.
             case'⍠T':⍺ ∆ 1↓⍵⊣stringArgs∘←1
            ⍝ ⍠STRICT=1 (default 0). No abbrev
             case'⍠STRICT':⍺ ∆1↓⍵⊣strict∘←1
            ⍝ Unknown metaflag, i.e. ∆OPTS-internal flag.
             err'opts: Unknown metaflag: ',name
         }⍵
         name↓⍨←+/∧\'-'=name
       ⍝ By default, any option's isMin abbrev is 1 char, unless of form opt(ion or opt(ion).
       ⍝   'test' 1    |    'te(st)' 2    |   'test()' 4 [no abbrev]
       ⍝ If options clash, this will be flagged at when decoding ⍵ at callScan.
         ptr←name(⌊/⍳)'=:' ⋄ isMin←1⌈{⍵≥ptr:1 ⋄ ⍵}(ptr↑name)⍳'('
       ⍝ name, i.e. a user flag.
       ⍝ We distinguish flags from other options in callScan2.
       ⍝ If a flag has a ! prefix or suffix (!name or name!), make its default 1, not 0.
       ⍝ In callScan below, a '-no' prefix will set the flag's value to 0.
         ptr≥≢name:⍺{
             val isReq isNum isFlag←('!'∊name)0 1 1
             name←name~'()!'
             ⍺.(names vals mins isReq isNum isFlag),←(⊂name)(val)isMin isReq isNum isFlag
             ⍺ ∆ 1↓⍵
         }⍵
       ⍝ Option declarations...
       ⍝ Format                Default declared?          User MUST set option in call?
       ⍝ A. name=    | name:      NO                             YES
       ⍝ B. name=val | name:val   YES (char)                     NO
       ⍝    val must be 1 or more characters (even blanks)
       ⍝ C. name==   | name::     YES (arb type, next arg)       NO
       ⍝    e.g. 'xVals::' (⍳10)
         name val←((ptr↑name)~'()')(name↓⍨ptr+1)
         val skip←{(⊂val)∊,¨'=:':(1↑1↓⍵)2 ⋄ val 1}⍵   ⍝ name== declaration
         isReq←0=≢val ⋄ isFlag←0
         (⊂name)∊⍺.names:err'opts: Option appears more than once: ',name
         val isNum←try2Num val
         ⍺.(names vals mins isReq isNum isFlag),←(⊂name)(scalify val)isMin isReq isNum isFlag
         ⍺ ∆ skip↓⍵
     }
   ⍝ II. callScan - scan call words for run-time options and arguments
     callScan←{
         ~stringArgs:callScan2⊆⍵
         (0=80|⎕DR ⍵)∧1≥⍴⍴⍵:callScan2' '(≠⊆⊢)⍵
         err'opts: Call argument (⍵) must be a simple string (⍠STRING specified).'
     }
     callScan2←{⍺←declNs⊣declNs.ARGS←⍬ ⋄ ∆←∇
         0=≢⍵:⍺
         nonOpt←{(1<|≡⍵)∨(1<⍴⍴⍵)∨(0≠80|⎕DR ⍵):1 ⋄ '-'≠1↑⍵}
         nonOpt⊃⍵:⍺{
             leftOnly:⍺⊣⍺.ARGS,←⍵    ⍝ ⎕LEFT flag set and we see a non-option: Done!
             ⍺ ∆ 1↓⍵⊣⍺.ARGS,←1↑⍵     ⍝ 1↑⍵ is an arg. Continue scan...
         }⍵
         name←⊃⍵
         '-'≠1↑name:⍺ skip ⍵                        ⍝ No hyphen, skip as user arg.
         '--'≡name:⍺⊣⍺.ARGS,←1↓⍵                    ⍝ '--'? Rest are user args.
         name↓⍨←+/∧\'-'=name                        ⍝ Ignore extra hyphens.
         p←name(⌊/⍳)'=:'
         name eq val←(p↑name)(p<≢name)(name↓⍨p+1)   ⍝ eq: 1 if there is = or :
         findName←{
             len←≢⍵
             shortList←⍺.names/⍨(len↑¨⍺.names)∊⊂⍵
             0=≢shortList:0('opts: Unknown option: ',⍵)
             match←len≥⍺.mins[ptr←⍸⍺.names∊shortList]
             0∊match:0('opts: Option not declared: ',⍵)
             1≠+/match:0('opts: Option ambiguous: ',⍵)
             1 ptr
         }
       ⍝ Search for option <name>.
       ⍝   ∘ respecting case
       ⍝   ∘ ignoring hyphens beyond the first
       ⍝   ∘ allowing abbreviations down to one character; or more if declared.
       ⍝   ∘ for flags only, we will respect -noname as equiv. to -name=0,
       ⍝     unless -noname is already defined as an option/flag.
       ⍝     (E.g. '-notes' will be viewed as option 'notes', rather than 'no'+'tes'.
         ptr name flagVal←⍺{lc←819⌶                      ⍝ Action \    Set flagVal to ...
             ⊃ok p←⍺ findName ⍵:p ⍵ 1                    ⍝ Find name ⍵.                1
             'no'≢lc 2↑⍵:err'opts: unknown option: ',⍵   ⍝ Do we have no prefix?      err
             ⊃ok p←⍺ findName 2↓⍵:p(2↓⍵)0                ⍝ Find ⍵ sans 'no'.           0
             err p                                       ⍝ Not found...               err
         }name
         0=≢val:⍺{
           ⍝ If a non-required option is present, but not a flag, treat here as required.
             isReq←⍺.isReq[ptr]∨~⍺.isFlag[ptr]           ⍝ -opt=/required?
             ⍺.isReq[ptr]←0
             eq⍱isReq:⍺ ∆ 1↓⍵⊣⍺.vals[ptr]←flagVal        ⍝ See flagVal setting above.
             2>≢⍵:err'opts: explicit value require for option: ',name
             ⍺ ∆ 2↓⍵⊣⍺.vals[ptr]←1↑1↓⍵
         }⍵
       ⍝ Has a value... Allow even for flags; disallow, if strict is set.
         ⋄ _←'opts: with strict ⍠S set, explicit value not allowed for flag: '
         strict∧⍺.isFlag[ptr]:err _,name
         ⍺.vals[ptr]←scalify⊃⍺.isNum[ptr]try2Num val ⋄ ⍺.isReq[ptr]←0
         ⍺ ∆ 1↓⍵
     }
   ⍝ III. setNamesFrom: In optsNs, set  names ←  values.
     setNamesFrom←{
         2::err'opts: Invalid option name: ',⍺
         ⍺⍺⍎⍵⍵.⍺,'←⍵'
     }

   ⍝ ----------------------------------------
   ⍝ EXECUTIVE  - I, II, III
   ⍝ ----------------------------------------
     leftOnly←stringArgs←strict←0
     declNs←declScan⊆⍺                                         ⍝   I
     declNs←callScan ⍵                                         ⍝  II
   ⍝ Error if any required names weren't set.
     1∊declNs.isReq:err'opts: Required options not set:',∊' ',¨declNs.(isReq/names)
   ⍝ optsNs contains:
   ⍝    ∘ each declared option name in full with default or user-set values
   ⍝    ∘ the list of remaining args (ARGS) and
   ⍝    ∘ a copy of original declarations (DECL).
     optsNs←⎕NS'' ⋄ optsNs.(ARGS DECL)←declNs.ARGS declNs
     _←declNs.names(optsNs setNamesFrom declNs)¨declNs.vals    ⍝ III
     optsNs
 }
