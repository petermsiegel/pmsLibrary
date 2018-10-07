 require←{
     ⎕IO ⎕ML←0 1

   ⍝ Help info in:
   ⍝     /Users/<USER>/MyDyalogLibrary/require/require.help
   ⍝ Grab filedir from SALT comment line at end of this function.
     ⍵≡'-HELP':⍬⊣⎕ED'∆'⊣∆←↑⊃⎕NGET 1,⍨⊂'require.help',⍨0⊃⎕NPARTS⊃'§(.*?)§'⎕S'\1'⊣1↑¯2↑⎕NR 0⊃⎕XSI

     DEBUG←0                           ⍝ If CODE<0, DEBUG CODE←(CODE<0)(|CODE)
     defaultLibName←'⍙⍙.require'
     CALLR CALLN←(⊃⎕RSI)(⊃⎕NSI)        ⍝ CALL_ ("caller"): Where was <require> called from?
     (999×~DEBUG)::⎕SIGNAL/⎕DMX.(EM EN)

     TRACE←{                           ⍝ Prints ⍺⍺ ⍵ if DEBUG. Always returns ⍵!
         0::⍵⊣⎕←'TRACE: APL TRAPPED ERROR ',⎕DMX.((⍕EN),': ',⎕EM)
         ⍺←⊢
         DEBUG:⍵⊣⎕←⍺ ⍺⍺ ⍵
         ⍵
     }

  ⍝ Decode ⍺ → [stdLibStr CODE]
     ⍺←⎕NULL
     stdLibStr CODE←2⍴{                ⍝  Sample outer ⍺⊃
         9=⎕NC'_'⊣_←⊃⍵:⍵ 0             ⍝  ⍺:  #  [2]
         0=1↑0⍴⊃⍵:⎕NULL ⍵              ⍝  ⍺:   2
         1=≢⊆⍵:⍵ 0                     ⍝  ⍺:  'test'    OR  ⎕NULL (⍺ omitted)
         ⍵                             ⍝  ⍺:  'test' 5
     }⍺
     DEBUG CODE←(DEBUG∨CODE<0)(|CODE)  ⍝ Do not override DEBUG if set to 1.

  ⍝ DeCODE ⍵ → list of packages (possible of 0-length)
     pkgs←⊆⍵

     stdLibR stdLibN←{
         returning←{2=≢⍵:⍵ ⋄ (⍎⍵ CALLR.⎕NS'')⍵}
         top←'⎕SE' '#'⊃⍨'#'=1↑CALLN          ⍝ what's our top level?
         defdef←top,'.',defaultLibName       ⍝ the default if there's no default library
         ⍵≡⎕NULL:returning defdef

         ∆LIB←'[LIB]'                         ⍝ Possible special prefix to ⍵...
         0::⎕SIGNAL/('require DOMAIN ERROR: Default library name invalid: ',{0::⍕⍵ ⋄ ⍕⍎⍵}⍵)11
         returning{
             val←(⍕⍵)~' '                    ⍝ Set val. If ⍵ is ⎕SE or #, val is '⎕SE' or '#'
             (⊂,val)∊'⎕SE'(,'#'):(⍎val)val   ⍝ Matches:  ⎕SE, '⎕SE', #, '#'
             9.1 9.2∊⍨nc←CALLR.⎕NC⊂,'⍵':(⍵)(⍕⍵)  ⍝ Matches: an actual namespace reference
             2.1≠nc:○○○                      ⍝ If we reached here, ⍵ must be a string.
             0=≢val:(⍎top)top                ⍝ Null (or blank) string? Use <top>
             name←{                          ⍝ See if  [LIB] a prefix of val?
                 fnd←1=⊃∆LIB⍷⍵ ⋄ len←≢∆LIB
                 fnd∧len=≢⍵:defdef           ⍝ [LIB] alone is prefix
                 fnd∧'.'=1↑len↓⍵:defdef,len↓⍵⍝ [LIB]. prefix
                 ⍵
             }val
             nc←CALLR.⎕NC⊂,name              ⍝ nc of name stored in stdLib w.r.t. caller.
             9.1=nc:{⍵(⍕⍵)}(CALLR⍎name)      ⍝ name refers to active namespace. Simplify via ⍎.
             0=nc:CALLN,'.',name             ⍝ Assume name refers to potential namespace...
             ∘∘∘                             ⍝ error!
         }⍵
     }stdLibStr

 ⍝------------------------------------------------------------------------------------
 ⍝  U T I L I T I E S
 ⍝------------------------------------------------------------------------------------
     ⋄ and←{⍺⍺ ⍵:⍵⍵ ⍵ ⋄ 0}
     ⋄ or←{⍺⍺ ⍵:1 ⋄ ⍵⍵ ⍵}
     ⋄ split←{⍺←' ' ⋄ (~⍵∊⍺)⊆⍵}∘,
     ⋄ splitFirst←{⍺←' ' ⋄ (≢⍵)>p←⍵⍳⍺:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
     ⋄ splitLast←{⍺←' ' ⋄ 0≤p←(≢⍵)-1+⍺⍳⍨⌽⍵:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
     ⍝ dunder [prefix]: ∇ s1 s2 → '__s1__s2'. If ⍵ has /, split it on the fly. Remove ##.
     ⋄ dunder←{2=|≡⍵:∊∇¨⍵ ⋄ 0=≢⍵:'' ⋄ 1∊'/.'∊⍵:∊∇¨'/.'split ⍵
         '#'∊⍵:''
         '__',⍵
     }
     ⍝ with [infix]:    s1 ∇ s2    → 's1.s2' ⋄ '' ∇ s2 → s2 ⋄ s1 ∇ '' → ''
     ⋄ with←{0=≢⍵:'' ⋄ 0=≢⍺:⍵ ⋄ ⍺,'.',⍵}

     ⍝ noEmpty, symbols, getEnv
     ⍝ noEmpty: remove empty dirs from colon spec.
     ⍝ symbols: replace [HOME], [FSPATH] etc in colon spec
     ⍝ getenv:  retrieve an env. variable value in OS X
     ⍝ apl2FS:  convert APL style namespace hierarchy to a filesystem hierarchy:
     ⍝          a.b.c → a/b/c     ##.a → ../a    #.a → /a
     ⋄ noEmpty←{{⍵↓⍨-':'=¯1↑⍵}{⍵↓⍨':'=1↑⍵}{⍵/⍨~'::'⍷⍵}⍵}
     ⋄ symbols←{'\[(HOME|FSPATH|WSPATH|PWD)\]'⎕R{getenv ⍵.(Lengths[1]↑Offsets[1]↓Block)}⊣⍵}
     ⋄ getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
     ⋄ apl2FS←{'.'@('#'∘=)⊣'/'@('.'∘=)⊣⍵↓⍨'#.'≡2↑⍵}

 ⍝ resolveNs Ns@str: Return a reference for a namespace string.
 ⍝   Repeated, non-existent, or invalid namespaces are quietly omitted from <resolvePath>.
     resolveNs←CALLR∘{
         nc←⍺.⎕NC⊂⍵
         nc∊9.1 ¯1:⍕⍺⍎⍵      ⍝ nc=¯1: ##.## etc.
         ⎕NULL             ⍝ Return the actual name of the relative ns. If not valid, return ⎕NULL
     }∘,
  ⍝ In ⎕PATH, replace ↑ with the requisite # of levels to the top...
  ⍝ Returns:  if found:  (revised_path 1); else:  (⍵ 0)
     resolvePathUpArrow←{
         ~⍺:⍵
         dist←¯1++/CALLN='.' ⋄ p←⍵⍳'↑' ⋄ w←⍵
         (∊w)⊣w[p]←⊂{⍺←'' ⋄ ⍵>dist:⍺ ⋄ (⍺,' ',∊'##',⍵⍴⊂'.##')∇ ⍵+1}0
     }

  ⍝ resolvePath: Determines actual ordered path to search, based on ∆CALR and ⎕PATH.
  ⍝ resolvePath:  allow non-existent namespaces to stay (since user may have other uses)
     resolvePath←{
         ⎕NULL~⍨∪resolveNs¨split⍣(1≥|≡⍵)⊣⍵
     }


   ⍝ ⍺ inNs ⍵:  Is object ⍺ found in namespace ⍵?
   ⍝    ⍺: name or group.name (etc.).  If 0=≢⍺: inNs fails.
   ⍝    ⍵: an namespace name (interpreted wrt CALLR if not absolute) or reference.
     inNs←{0::0⊣⎕←'inNs error:'⍺'inNs'⍵⊣⎕←⎕DMX.(EM EN)
         0=≢⍺:0
         callr←CALLR ⍝ Workaround: external CALLR, used directly like this (CALLR.⍎) won't be found.
         ns←callr.⍎⍣(⍬⍴2=⎕NC'ns')⊣ns←⍵
         0<ns.⎕NC ⍺          ⍝ test name
     }

     inFile←{~⎕NEXISTS ⍵:0 ⋄ 0≠1 ⎕NINFO ⍵}
     repkg←{e w d n←⍵ ⋄ pkg←e,('::'/⍨0≠≢e),w,(':'/⍨0≠≢w),d,('.'/⍨0≠≢d),n}
     map←{0=≢⍵:'' ⋄ pkg←repkg ⍺ ⋄ pkg ⍵}

   ⍝------------------------------------------------------------------------------------
   ⍝  E N D      U T I L I T I E S
   ⍝------------------------------------------------------------------------------------

   ⍝ From each item in packages of the (regexp with spaces) form:
   ⍝      (\w+::)?    (\w+:)? (\w+(\.\w+)*)\.)? (\w+)
   ⍝   (FSPATH) ext    wsN    group             name
   ⍝ wsN may be a full string ('abc.def:'), null string (':'), or ⎕NULL (omitted).
   ⍝ group may be a full string or null string (if omitted)
   ⍝ name must be present
     lastExt←''      ⍝ If a :: appears with nothing before it, the prior lastExt is used
     lastWs←''       ⍝ If a : appears ..., the prior lastWs is used!
     pkgs←{
         0=≢⍵~' :.':''
         pkg←,⍵

         ext pkg←⍵{                     ⍝ ext: <FSPATH extension> comes before ::
             0=≢⍺:''⍵                   ⍝ '::group name' → <lastExt> '' <group> <name>
             0=⍺:lastExt(⍵↓⍨⍺+2)
             (lastExt∘←⍵↑⍨⍺)(⍵↓⍨⍺+2)    ⍝ ext:: and wsN: are mutually exclusive in fact.
         }⍨⍸'::'⍷pkg

         wsN pkg←{                      ⍝ wsN::[group.]name
             wsDef←(':'=1↑pkg)∧(':'≠1↑1↓pkg)
             wsDef:lastWs(1↓pkg)    ⍝ ':group name'  → '' <lastWs> <group> <name>
             lastWs∘←w⊣w p←':'splitFirst pkg          ⍝ wsN: ws name comes before simple :
             w p
         }pkg

         group name←'.'splitLast pkg
         ext wsN group name
     }¨pkgs

   ⍝ userPathHasCALLR: 1 if CALLR is explicitly in the caller's ⎕PATH
   ⍝ If # is implicit in ↑ in ⎕PATH, value is 0, and ↑ is added when ⎕PATH is updated.
   ⍝ Note that fns/ops in CALLR are always found, since CALLR is always checked before ⎕PATH.
     userPathHasUpArrow←'↑'∊⎕PATH
     ∆PATH←resolvePath stdLibN,' ',userPathHasUpArrow resolvePathUpArrow ⎕PATH

⍝      _←{'CALLN: ',(0⊃⍵),' stdLibN: ',(1⊃⍵)}TRACE CALLN stdLibN
⍝      _←{'userPathHasUpArrow: ',⍵}TRACE userPathHasUpArrow
⍝      _←{'∆PATH: <'⍵'>'}TRACE ∆PATH

   ⍝ ∆FSPATH:
   ⍝   1. If ⎕SE.∆FSPATH exists and is not null, use it.
   ⍝      You can merge new paths with the values of the existing OS X environment variables:
   ⍝        - FSPATH (require-specific for File System Path. See WSPATH for format)
   ⍝        - WSPATH (Dyalog's search path for workspaces; libraries are colon-separated)
   ⍝        - HOME   (the HOME directory)
   ⍝        - PWD    (the current working directory)
   ⍝        - .      (the current working directory)
   ⍝        - ..     (the parent directory)
   ⍝        e.g. if FSPATH is has
   ⍝                   '.:stdLib1:stdLib2'
   ⍝        then       'mydir1:mydir1/mydir1a:[FSPATH]'
   ⍝               →   'mydir1:mydir2/mydir1a:.:stdLib1:stdLib':
   ⍝   2. If GetEnvironment FSPATH is not null, use it.
   ⍝   3. If GetEnvironment WSPATH is not null, use it.
   ⍝      APL maintains this mostly for finding workspaces.
   ⍝   3. Use '.:[HOME]'   (see HOME above).
   ⍝   Each item a string of the form here (if onle group, no colon is used):
   ⍝       'dir1:dir2:...:dirN'

     ∆FSPATH←∪':'split noEmpty{
         2=⎕NC ⍵:symbols ⎕OR ⍵
         0≠≢fs←symbols getenv'FSPATH':fs
         0≠≢env←symbols getenv'WSPATH':env
         symbols'.:[HOME]'             ⍝ current dir ([PWD]) and [HOME]
     }'⎕SE.∆FSPATH'

     _←{'∆FSPATH='⍵}TRACE ∆FSPATH


     0=≢⍵:stdLibR   ⍝ If no main right argument, return the library reference (default or user-specified)
     0∊≢¨pkgs~¨⊂'.: ':⎕SIGNAL/'require DOMAIN ERROR: at least one package string was empty.' 11

   ⍝ statusList:
   ⍝   [0] list of packages successfully found
   ⍝           wsN:group.name status
   ⍝   [1] list of packages not found or whose copy failed (e.g. ⎕FIX failed, etc.)
   ⍝           wsN:group.name status
   ⍝   If wsN not present, wsN and group may be null strings.
   ⍝   If wsN is present,  group and/or name  may each be null.
   ⍝   The status field is always present.

     statusList←⍬ ⍬{
         0=≢⍵:⍺
         status←⍺
         pkg←⊃⍵

         _←{⎕TC[2],'> Package: ',repkg ⍵}TRACE pkg

   ⍝ Is the package in the caller's namespace?
   ⍝ Check for <name>, <group.name>, and <wsN>.
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵

             stat←{
                 ('__',wsN)inNs CALLR:pkg map'ws∊CALLER'      ⍝ wsN found?   success
                 name inNs CALLR:pkg map'name∊CALLER'        ⍝ name found? success
                 group≡'':''
                 ~(group with name)inNs CALLR:''                   ⍝ none found? failure
                 ∆PATH,⍨←⊂resolveNs group                    ⍝ group.name found
                 pkg map'group.name∊CALLER'                    ⍝ ...         success
             }⍵

             0=≢stat:pkg

             _←{'>>> Found in caller ns: ',⍵}TRACE stat

             ''⊣(⊃status),←⊂stat
         }pkg

         0=≢pkg:status ∇ 1↓⍵                        ⍝ Fast path out. Otherwise, we short-circuit one by one

   ⍝ Is the package in the ⎕PATH?
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵


             recurse←{                                   ⍝ find pgk components in <path>.
                 0=≢⍵:''                              ⍝ none found. path exhausted: failure
                 path←⊃⍵

                 _←{'>>> Checking ⎕PATH ns: ',⍵}TRACE path

                 {0≠≢group}and{path inNs⍨dunder group name}1:'[file] group.name∊PATH'
                 {0=≢group}and{path inNs⍨dunder name}1:'[file] name∊PATH'
                 {0=≢name}and{path inNs⍨dunder wsN}0:'ws∊PATH'
                 {wsN inNs path}and{0=≢⍵:1            ⍝ wsN found and group/name empty: success
                     ⍵ inNs path,'.',wsN              ⍝ wsN found and group/name found in path.wsN: success
                 }group with name:'ws∊PATH'
                 name inNs path:'name∊PATH'           ⍝ name found: success
                 group≡'':∇ 1↓⍵                         ⍝ none found: try another path element
                 ~{(group with name)inNs path}and{9=stdLibR.⎕NC group}0:∇ 1↓⍵      ⍝ none found: try another path element
                 ∆PATH,⍨←⊂resolveNs path with group     ⍝ group.name found: ...
                 'group→PATH'                           ⍝ ...         success
             }∪∆PATH

             0=≢recurse:pkg

             _←{'>>> Found in ⎕PATH ns: ',⍵}TRACE recurse

             ''⊣(⊃status),←⊂pkg map recurse
         }pkg

   ⍝ Is the object in the named workspace?
   ⍝ If there is no object named, copy the <entire> workspace into the default library (stdLib).
   ⍝ creating the name <wsN> in the copied namespace, so it won't be copied in each time.
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0=≢wsN:⍵

             _←{'>>> Checking workspace: ',⍵}TRACE wsN

             stat←wsN{
                 0::''
                 0≠≢⍵:'wsN:name→stdLib'⊣⍵ stdLibR.⎕CY ⍺     ⍝ Copy in object from wsN
                 _←stdLibR.⎕CY ⍺
                 _←⍺{
                     stdLibR.⍎(dunder ⍺),'←⍵'               ⍝ Copy in entire wsN <wsN>.
                 }'Workspace ',⍺,' copied on ',⍕⎕TS               ⍝ Deposit in <stdLib> var  __wsN←'Workspace...'
                 'ws→stdLib'
             }group with name

             0=≢stat:pkg
             ''⊣(⊃status),←⊂pkg map stat⊣{'>>> Found in ws: ',repkg ⍵}TRACE ⍵
         }pkg

       ⍝ Is the package in the file system path?
       ⍝ We even check those with a wsN: prefix (which is checked first)
       ⍝ See FSSearchPath
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0∧.=≢¨group name:⍵
             dirFS←apl2FS group                          ⍝ Convert a.b→a/b, ##.a→../a


             recurse←{                                   ⍝ find pgk components in <path>.
                 0=≢⍵:''                                 ⍝ none found. path exhausted: failure
                 path←⊃⍵
                 0=≢path:∇ 1↓⍵                           ⍝ null directory. Skip...
                 searchDir←path,('/'/⍨0≠≢ext),ext,'/',dirFS,('/'⍴⍨0≠≢dirFS),name
                 searchFi←searchDir,'.dyalog'

                 _←{'>>> Searching filesystem: ',⍵}TRACE searchDir

                 ⋄ loaddir←{
                     group name←⍺
                     aplDir←group with name ⋄ fsDir←⍵
                     1≠⊃1 ⎕NINFO fsDir:'NOT A DIRECTORY: ',fsDir
                     names←⊃(⎕NINFO⍠1)fsDir,'/*.dyalog'    ⍝ Will ignore subsidiary directories...
                     0=≢names:aplDir{
                         stamp←'First group ',⍺,'found was empty on ',(⍕⎕TS),': ',⍵
                         'empty group→stdLib: ',⍵⊣(dunder ⍺)stdLibR.{⍎⍺,'←⍵'}stamp
                     }fsDir

                     _←{'>>>>> Found non-empty dir: ',⍵}TRACE fsDir

                     cont←''
                     load←{
                       ⍝ import: group name
                         0::¯1⊣{'Failed to load file for name ',⍵}TRACE ⍵

                         subName←1⊃⎕NPARTS ⍵
                         cont,←' ',,⎕FMT 2 stdLibR.⎕FIX'file://',⍵

                         _←{'>>>>> Loaded file: ',⍵}TRACE ⍵

                         1     ⍝ Success
                     }¨names
                     gwn←group with name
                     stamp←gwn,' copied from disk with contents',cont,' on ',⍕⎕TS
                     _←(dunder group name)stdLibR.{⍎⍺,'←⍵'}stamp
                     res←'[group] ',gwn,'→stdLib '
                     res,←⎕TC[2],'   [Fixed: ',(⍕+/load=1),' Failed: ',(⍕+/load=¯1),']'
                     res
                 }
                 ⎕NEXISTS searchDir:(group name)loaddir searchDir
                 ⋄ loadfi←{
                     group name←⍺

                     id←dunder group name
                     cont∘←,⎕FMT 2 stdLibR.⎕FIX'file://',⍵
                     _←{'>>>>> Loaded file: ',⍵}TRACE ⍵
                     stamp←(group with name),' copied from disk with contents ',cont,' on ',⍕⎕TS
                     _←id stdLibR.{⍎⍺,'←⍵'}stamp
                     'file→stdLib: ',⍵
                 }
                 ⎕NEXISTS searchFi:(group name)loadfi searchFi
                 ∇ 1↓⍵
             }∆FSPATH

             _←{s←'>>> Status: ' ⋄ 0=≢⍵:s,'NOT FOUND' ⋄ s,,⎕FMT ⍵}TRACE recurse

             0=≢recurse:pkg
             ''⊣(⊃status),←⊂pkg map recurse
         }pkg

         pkg←{ ⍝ Any package <pkg> left must not have been found!
             0=≢⍵:''
             ''⊣(⊃⌽status),←⊂pkg map'NOT FOUND'
         }pkg

         status ∇ 1↓⍵    ⍝ Get next package!
     }pkgs

⍝ Update PATH, adding the default Library. Allow no duplicates, but names should be valid.
⍝ userPathHasUpArrow: If 1, we restore '↑'' at the end of ⎕PATH
     CALLR.⎕PATH←(1↓∊' ',¨⍕¨∆PATH),' ↑'/⍨userPathHasUpArrow

     succ←0=≢⊃⌽statusList
     eCode1←'require DOMAIN ERROR: At least one package not found or not ⎕FIXed.' 11

     succ∧CODE∊3:_←{⍵}TRACE(⊂stdLibR),statusList  ⍝ CODE 3:   SUCC: shy     (non-shy if DEBUG)
     ⋄ CODE∊3:(⊂stdLibR),statusList            ⍝           FAIL: non-shy
     succ∧CODE∊2:stdLibR                       ⍝ CODE 2:   SUCC: non_shy
     ⋄ CODE∊2:⎕SIGNAL/eCode1                   ⍝           FAIL: ⎕SIGNAL
     succ∧CODE∊1 0:_←{⍵}TRACE statusList       ⍝ CODE 1|0: SUCC: shy     (non-shy if DEBUG)
     ⋄ CODE∊1 0:statusList                     ⍝           FAIL: non-shy
     ⎕SIGNAL/('require DOMAIN ERROR: Invalid CODE: ',⍕CODE)11   ⍝ ~CODE∊0 1 2 3
⍝    §require/require.dyalog§  Minimum needed for if require.help is in ./require
 }
