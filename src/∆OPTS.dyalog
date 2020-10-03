 ∆OPTS←{
    DEBUG←0   ⍝ If 1, ⎕SIGNALs will not be trapped. intermediate alias table ns.⍙ALIAS will be preserved.
    0⍴⍨~DEBUG::⎕SIGNAL/⎕DMX.(EM EN)

⍝ PMSLIB Utilities
  ⍝ ∆F:  Find a pcre field by name or field number
    ∆F←{N O B L←⍺.(Names Offsets Block Lengths)
        def←'' ⋄ isN←0≠⍬⍴0⍴⍵
        p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
        B[O[p]+⍳L[p]]
    }
⍝ End PMSLIB Utilities

⍝ Initializations
  ⍝ Patterns
    numsP←'(?x) ^ \h* ((?<num> [-¯]? \.? \d [^\h]*) (\h+ (?&num))*)'     ⍝ Selects tokens that start like numbers...
    stringP←'(?x) ^ \h* ( (?:"[^"]*")+ | (?:''[^'']*'')+ | [^\h]+ )'     ⍝ Selects "...", '...' or tokens w/o blanks

  ⍝ Error msgs
    badSpecE←'Each option spec must include 3 items: ''name'' (default) ''type''.'
    badOptE←'Unknown option: -'
    badNumE←'Invalid numeric option: -'
    badPrefixE←'∆OPTS: un- or no- prefix invalid with non-flag option: -'
    badTypeE←'∆OPTS: unknown type specified for option: -'  
    badExecE←'∆OPTS: unable to evaluate code option: -' 

⍝ Executive Routines
  ⍝ Help: If ⍺ undefined, provide Help information (⍵ is ignored).
  ⍝ See ⍝H-prefixed lines below for HELP info.
    Help←{
      ⎕ED⍠('ReadOnly' 1)&'__∆OPTS_HELP'⊣__∆OPTS_HELP∘←{3↓¨⍵/⍨(⊂'⍝H')≡¨2↑¨1↓¨⍵}⎕NR ⍵
    }
  ⍝ MapAliases:  (amap opts′)← ∇ opts
  ⍝               amap: (A1@SV A2@IV), the map from aliases to indices-to-names.
  ⍝ Map each name in <opts>, aliases or otherwise,  onto an index pointing to an option name in ∆OPTS, else ¯1. 
  ⍝ Aliases in opts are removed from opts′.
  ⍝ opts are canonicalized: names → vectors, aliases are removed.
    MapAliases←{  
      (⊃¨O)←,∘⊃¨O←⍵ ⋄ A1←A2←0⊃¨O ⋄ a←'A'=2⊃¨O ⋄  O∆←(~a)/O ⋄ (a/A2)←a/1⊃¨O ⋄  A2←(0⊃¨O∆)IotaN A2 
      (A1 A2) O∆
    }
⍝  GetNums:   (nums@N[] src′@S) ← nm@S ∇ src@S 
    GetNums←{nm←⍺ ⋄ src←⍵ ⋄ numStr←''
        src←numsP ⎕R{''⊣numStr∘←⍵ ∆F 1}src
        valid nums←⎕VFI'¯'@('-'∘=)⊣numStr
        0∊valid:11 ⎕SIGNAL⍨badNumE,nm,' ',numStr
        nums src
    }
  ⍝  GetString: (str@S src′@S) ← nm@S ∇ src@S
     GetString←{nm←⍺ ⋄ src←⍵ ⋄ str←''
         SQ DQ←'''' '"'
         deQuote←{f←⊃⍵ ⋄ f(~∊)SQ DQ:⍵ ⋄ w←1↓¯1↓⍵ ⋄ f∊SQ:w ⋄ w/⍨~(DQ DQ)⍷w}
         str(stringP ⎕R{''⊣str∘←deQuote ⍵ ∆F 1}⊣src)
     }
  ⍝  ResolveNm:  (index@I toggle@B)← ns@NS ∇ nm@S
  ⍝  Resolve names: 1st, exact matches; 2nd: abbrevs; a) for flags (type=F), positive or negative, matching "^(no|un)".
  ⍝  Returns (index toggle): index, the index in ∆NAMES to the name, with aliases resolved; toggle, 1 if positive, else 0.
     ResolveNm←{ns←⍺ ⋄ nm←⍵ ⋄ nms←ns.∆NAMES ⋄ A0 A1←ns.⍙ALIAS ⋄ L←≢A0 
            p pn←{¯1=q←{¯1=r←A0 IotaN ⊂⍵: (A0↑¨⍨≢⍵) IotaN ⊂⍵ ⋄ r}⍵: ¯1 ⋄ q⊃A1 }¨nm (2↓nm)
            ¯1≠p:  p 1 
            'no' 'un'(~∊⍨)⊂2↑nm: 11 ⎕SIGNAL⍨badTypeE,nm    ⍝ Not un- or no- prefix on option.
            ¯1≠pn: pn 0       ⋄  11 ⎕SIGNAL⍨badOptE,nm     ⍝ Was an option found with un- or no- prefix?
     }
     SkipBlanks←{⍵↓⍨+/∧\' '=⍵}
     IotaN←{¯1@((≢⍺)∘≤)⊣⍺⍳⍵}    ⍝ dyadic iota, returning ¯1 for missing items

   ⍝ -------------------------------------------------------
   ⍝ EXECUTIVE
   ⍝ -------------------------------------------------------
    0=⎕NC'⍺':Help ⊃⎕SI 
    opts source←,¨⍺ ⍵
    0∊3=≢¨opts: badSpecE ⎕SIGNAL 11

    ns←#.⎕NS'' ⋄ _←ns.⎕DF '[options]' 
    SetVar←ns.{1:⍎⍺,'←⍵'}
    EvalCode←(0⊃⎕RSI)∘{0:: 11 ⎕SIGNAL⍨badExecE,⍵ ⋄  0=≢' '~⍨code←ns.⎕OR ⍵: ⍵ SetVar ⍬ ⋄ ⍵ SetVar ⍺.⍎code}¨

    (ns.⍙ALIAS opts)←MapAliases opts 
    ns.(∆NAMES ∆DEFAULTS ∆TYPES)←↓⍉↑opts 
    _←ns.∆NAMES SetVar¨ns.∆DEFAULTS                          ⍝ Set initial value of ∆NAMES.
  ⍝ Walk left to right through source string, looking for options and associated value tokens
    ns.∆ARGS←SkipBlanks{
        src←SkipBlanks ⍵
        0=≢src:src ⋄ '-'≠1↑src:src ⋄ src↓⍨←1                 ⍝ Next token must start with a hyphen. Else done.
        nm←src↑⍨p←src⍳' ' ⋄ src↓⍨←p                          ⍝ nm: Our option, sans - prefix.
        nm≡,'-':src                                          ⍝ Flag '--'?  Done.
        p flagV←ns ResolveNm nm                              ⍝ Resolve aliases, abbrevs and prefixed (-un, -no) options.
        nm←p⊃ns.∆NAMES                                       ⍝ Use resolved name going forward (alias or abbrev ==> resolved).
        ⋄ case←(p⊃ns.∆TYPES)∘∊
        case'F':∇ src⊣nm SetVar flagV                        ⍝ Set flag <Opt> to 1 (-Opt) or 0 (-noOpt or -unOpt)
        ~flagV: 11 ⎕SIGNAL⍨badPrefixE,nm                     ⍝ Non-flag options can't have -un or -no prefix. Bye.
        case'N':∇ src⊣nm SetVar nums⊣nums src←nm GetNums src ⍝ GetNums may grab any # of following numeric tokens.
        case'SC':∇ src⊣nm SetVar str⊣str src←nm GetString src ⍝ GetString may grab a token or anything in "quotes" or 'quotes'.
        11 ⎕SIGNAL⍨badTypeE,nm 
     } ns.∆SOURCE←source
     _←EvalCode ns.(∆NAMES/⍨∆TYPES='C')                      ⍝ Now execute code values (new or default) in the caller namespace.
     ns.(∆VALUES←⍎¨∆NAMES)                                   ⍝ Set value in ∆VALUES for each name in ∆NAMES. 
     _←ns.⎕EX⍣(~DEBUG)⊣'⍙ALIAS'                              ⍝  Done with alias table.
     1: ns 

 ⍝H   ∆OPTS HELP INFORMARTION
 ⍝H   ns ←  opts ∆OPTS source
 ⍝H   Descr: Processes <source> from left to right, scanning for options of these forms: 
 ⍝H            -Flag, -noFlag, -unFlag,
 ⍝H            -StrOpt Word, -StrOpt "String of Words", -NumOpt 123 321E¯5 -25.2 .23, --
 ⍝H          Scanning ends after the last option (starting with --, including -- the null option).
 ⍝H          Invalid options generate ⎕SIGNALs.
 ⍝H          Abbreviations and aliases are supported.
 ⍝H   Returns a namespace ns with each flag named defined (by default or explicitly), e.g. ns.StrOpt,
 ⍝H   and a set of special variables, each beginning with ∆, e.g. ns.∆ARGS (the argument string AFTER all options).
 ⍝H   See SPECIAL VARIABLES below.
 ⍝H
 ⍝H   opts←(name1 def1 type1) ... (nameN defN typeN)
 ⍝H     nameN:   a name (to be preceded by a hyphen). Some names beginning with ∆ are reserved.
 ⍝H            A name may not begin with a digit.
 ⍝H     defN:    default. Need not be of the type set by <types>, e.g. ⎕NULL could be used to check if set.
 ⍝H     typeN:   one of types below
 ⍝H
 ⍝H     type    designation    source text                sets                       notes
 ⍝H     Flag    'F'            -MyFlag                     ns.MyFlag←1
 ⍝H                            -noMyFlag                   ns.MyFlag←0                prefix lower-case 'no'
 ⍝H     String  'S'            -Name "414 Smith Ln"        ns.Name←'414 Smith Ln'     handles internal quotes (single or dbl)
 ⍝H                            -Name John_Jacob            ns.Name←'John_Jacob'       any non-blank text '[^\s]+'
 ⍝H     Numeric 'N'            -Coord 25 -34 17.2 ¯.5      ns.Coord←25 ¯34 17.2 ¯.5   hyphen converted to high-minus
 ⍝H     Alias   'A'            -Moniker "string"           ns.Name←"string"           options includes: ('Moniker' 'Name' 'A')
 ⍝H     Code    'C'            -Time ⎕TS                   ns.Time←⍎⎕TS               code sequence entered as a string
 ⍝H
 ⍝H  ALIAS: If an alias or its abbrev is found and used, it will update the fully-specified variable it resolves to.
 ⍝H  E.g. if -Moniker "fred" is seen in the source text, ns.Name←'fred', but no ns.Moniker is created.
 ⍝H  Similarly, if -Mo "jack" is seen, ns.Name←'jack' is created.
 ⍝H
 ⍝H CODE: If a code expression is set, its value will be executed in the caller fn's namespace just before ∆OPTS returns.
 ⍝H If not, its default expression will be set, unless null.
 ⍝H 
 ⍝H  Options Sample
 ⍝H           name    default  type                               flag -Debug:   ns.Debug←1           Moniker is an alias only.
 ⍝H           ↓       ↓        ↓                                  ↓    -noDebug: ns.Debug←0           ↓
 ⍝H    opts← ('Nums'  (45 55)  'N')   ('Name'  'john smith' 'S')  ('Debug' 1 'F')   ('Alpha'  ⎕A 'S') ('Moniker' 'Name' 'A')
 ⍝H
 ⍝H SPECIAL VARIABLES (see EXAMPLE below)
 ⍝H       ns.∆NAMES    is the list of names of options. These are in the order entered.
 ⍝H       ns.∆SOURCE   is the original string passed.
 ⍝H       ns.∆ARGS     is the string that remain after all options removed or option -- processed.
 ⍝H       ns.∆DEFAULTS is the list of defaults for the names in order. Defaults may have any type.
 ⍝H       ns.∆VALUES   is the list of final values for each option; if changed, has the type determined by the option flag.
 ⍝H
 ⍝H -------------------------------------------------------------------------------------------------------
 ⍝H EXAMPLE
 ⍝H   opts←('Rainbow' (?2⍴0) 'N') ('Ponies' ⎕NULL 'S')('Optimize' 0 'F')('OPT' 'Optimize' 'A')
 ⍝H   ns ← opts ∆OPTS '-OPT -Rain -1J5 test one two'
 ⍝H   Returns: 
 ⍝H       ns, a namespace with a value for each option and definitions for SPECIAL VARIABLES.
 ⍝H       ns.Rainbow   the current value of option 'Rainbow', with abbrev -Rain matching.
 ⍝H                    ns.Rainbow←¯1J5
 ⍝H       ns.Ponies    the current value of option 'Ponies' (default used).
 ⍝H                    ns.Ponies←⎕NULL   
 ⍝H       ns.Optimize  the current value of option 'Optimize', with alias OPT matching.
 ⍝H                    ns.Optimize←1
 ⍝H       Plus Special Variables:
 ⍝H       ns.∆NAMES    Options in order entered:        'Rainbow'         'Ponies' 'Optimize'   [alias OPT is omitted].
 ⍝H       ns.∆DEFAULTS the defaults in order:            (0.4344 0.7349)   ⎕NULL    0
 ⍝H       ns.∆VALUES   final values for each option:     ¯1J5              ⎕NULL    1
 ⍝H       ns.∆SOURCE   is the original string passed:    '-OPT -Rain -1J5 test one two'
 ⍝H       ns.∆ARGS     the source after processing:      'test one two'
 ⍝H 
 ⍝H         ns.((↑⊂¨'∆NAMES' '∆DEFAULTS' '∆VALUES'),[1] (∆NAMES,[-0.1]∆DEFAULTS),[0]∆VALUES)
 ⍝H       ┌─────────┬────────────────────────┬──────┬────────┐
 ⍝H       │∆NAMES   │Rainbow                 │Ponies│Optimize│
 ⍝H       ├─────────┼────────────────────────┼──────┼────────┤
 ⍝H       │∆DEFAULTS│0.9101705993 0.200383789│[Null]│0       │
 ⍝H       ├─────────┼────────────────────────┼──────┼────────┤
 ⍝H       │∆VALUES  │¯1J5                    │[Null]│1       │
 ⍝H       └─────────┴────────────────────────┴──────┴────────┘
 ⍝H
 ⍝H  NOTES
 ⍝H  ¯¯¯¯¯
 ⍝H   For options of type 'F' (Flag)
 ⍝H      E.g. ('Flag' 1 'F') defines a flag named 'Flag' with a default of 1 (set).
 ⍝H      If -Flag is seen in Source, it sets ns.Flag←1.
 ⍝H      If -noFlag is seen or -unFlag is seen, we set Flag: ns.Flag←0.
 ⍝H   For an option <Option> of type 'S' (String) or 'N' (Numeric)
 ⍝H     E.g. ('Name' '' 'S') defines an option named 'Name' whose default is a null string which can be set to a string.
 ⍝H     E.g. ('Coord' ⎕NULL 'N') defines 'Coord' which can be defined as a numeric vector, but defaulting to ⎕NULL.
 ⍝H          If <Source> contains '-Coord 15 -24 12.3j¯45 -Name "Baton Rouge"'
 ⍝H          ns.Coord←15 ¯24 12.3J¯45 and ns.Name←'Baton Rouge'
 ⍝H     -Option num1 num2...
 ⍝H     -Option "string one"  OR   -Option ''string #2''   OR  -option string3
 ⍝H        sets ns.Option ← value.
 ⍝H        If Numeric, value will be a numeric vector (not a string), with hyphens (minus signs) replaced by high-minuses (¯).
 ⍝H        If String, value will have quotes (single or double) removed and adjusted for any APL-style internal doubling.
 ⍝H        If not quoted, a string value begins with the first non-blank char and ends at the last contiguous non-blank char.
 ⍝H
 ⍝H    --  Option '-' is a special option that terminates option scanning. Everything following  
 ⍝H        -- or the last option is stored in ns.∆ARGS.
 ⍝H
 ⍝H    
 ⍝H     ---------------------------------------------------------------
 ⍝H     EXAMPLE WITH DETAILS on aliases and ⍙ALIAS (requires DEBUG←1)
 ⍝H     ---------------------------------------------------------------
 ⍝H       o←('JACK' 'jack' 'A')('ALPH' 'alph' 'A')('PI' 'pi' 'A')('jack' 'Smith, Jack' 'S')('alph' '⎕A' 'C')('pi' (○1) 'N')
 ⍝H       o  
 ⍝H     ┌─────────────┬─────────────┬─────────┬────────────────────┬─────────────┬──────────────────┐
 ⍝H     │┌────┬────┬─┐│┌────┬────┬─┐│┌──┬──┬─┐│┌────┬───────────┬─┐│┌────┬────┬─┐│┌──┬───────────┬─┐│
 ⍝H     ││JACK│jack│A│││ALPH│alph│A│││PI│pi│A│││jack│Smith, Jack│S│││alph│ ⎕A │C│││pi│3.141592654│N││
 ⍝H     │└────┴────┴─┘│└────┴────┴─┘│└──┴──┴─┘│└────┴───────────┴─┘│└────┴────┴─┘│└──┴───────────┴─┘│
 ⍝H     └─────────────┴─────────────┴─────────┴────────────────────┴─────────────┴──────────────────┘
 ⍝H           ns←o ∆OPTS '-AL "∊⍉2 13⍴⎕A"'   ⍝ Reset ns.alph from ⍎'⎕A' to ⍎'∊⍉2 13⍴⎕A'
 ⍝H           ns.alph
 ⍝H     ANBOCPDQERFSGTHUIVJWKXLYMZ
 ⍝H
 ⍝H  ⍝    ⍙ALIAS maps option aliases and names onto (indices to actual) option names
 ⍝H           ns.⍙ALIAS   ⍝ ⍙ALIAS exists only if DEBUG is 1
 ⍝H  ⍝    ∨---aliases                ∨--- indices to option names in ∆NAMES
 ⍝H     ┌───────────────────────────┬───────────┐
 ⍝H     │┌────┬────┬──┬────┬────┬──┐│0 1 2 0 1 2│
 ⍝H     ││JACK│ALPH│PI│jack│alph│pi││           │
 ⍝H     │└────┴────┴──┴────┴────┴──┘│           │
 ⍝H     └───────────────────────────┴───────────┘  
 ⍝H           ns.∆NAMES  
 ⍝H     ┌────┬────┬──┐
 ⍝H     │jack│alph│pi│
 ⍝H     └────┴────┴──┘

⍝∇⍣§./∆OPTSNew2.dyalog§0§ 2020 9 19 12 57 57 258 §ÅtSZK§0
 }
