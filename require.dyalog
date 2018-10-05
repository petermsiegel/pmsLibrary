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

     TRACE←{DEBUG:⍵⊣⎕←⍺⍺ ⍵ ⋄ ⍵}        ⍝ Prints ⍺⍺ ⍵ if DEBUG. Always returns ⍵!

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

         ∆LIB←'⎕LIB'                         ⍝ Possible special prefix to ⍵...
         0::⎕SIGNAL/('require DOMAIN ERROR: Default library name invalid: ',{0::⍕⍵ ⋄ ⍕⍎⍵}⍵)11
         returning{
             val←(⍕⍵)~' '                    ⍝ Set val. If ⍵ is ⎕SE or #, val is '⎕SE' or '#'
             (⊂,val)∊'⎕SE'(,'#'):(⍎val)val   ⍝ Matches:  ⎕SE, '⎕SE', #, '#'
             9.1 9.2∊⍨nc←CALLR.⎕NC⊂,'⍵':(⍵)(⍕⍵)  ⍝ Matches: an actual namespace reference
             2.1≠nc:○○○                      ⍝ If we reached here, ⍵ must be a string.
             0=≢val:(⍎top)top                ⍝ Null (or blank) string? Use <top>
             name←{                          ⍝ See if  ⎕LIB a prefix of val?
                 fnd←1=⊃∆LIB⍷⍵ ⋄ len←≢∆LIB
                 fnd∧len=≢⍵:defdef           ⍝ ⎕LIB alone is prefix
                 fnd∧'.'=1↑len↓⍵:defdef,len↓⍵⍝ ⎕LIB. prefix
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
     ⍝ dunder [prefix]: ∇ s1 s2 → '__s1__s2'
     ⋄ dunder←{2=|≡⍵:∊∇¨⍵ ⋄ 0=≢⍵:'' ⋄ '__',⍵}      ⍝ dunder s1 s2  → '__s1__s2'
     ⍝ with [infix]:    s1 ∇ s2    → 's1.s2' ⋄ '' ∇ s2 → s2 ⋄ s1 ∇ '' → ''
     ⋄ with←{0=≢⍵:'' ⋄ 0=≢⍺:⍵ ⋄ ⍺,'.',⍵}


 ⍝ resolveNs: Return a reference for a namespace string.
 ⍝   Repeated, non-existent, or invalid namespaces are quietly omitted from <resolvePath>.
     resolveNs←CALLR∘{
         6::⎕NULL
         9.1≠⍺.⎕NC⊂,⍵:⎕NULL
         ⍕⍺⍎⍵            ⍝ Return the actual name of the relative ns. If not valid, return ⎕NULL
     }
     resolvePathUpArrow←CALLN∘{
  ⍝ In ⎕PATH, replace ↑ with the requisite # of levels to the top...
  ⍝ Returns:  if found:  (revised_path 1); else:  (⍵ 0)
         ~'↑'∊⍵:⍵ 0
         dist←¯1++/⍺='.' ⋄ p←⍵⍳'↑' ⋄ w←⍵
         (∊w)1⊣w[p]←⊂{⍺←'##' ⋄ ⍵>dist:⍺ ⋄ (⍺,' ',∊'##',⍵⍴⊂'.##')∇ ⍵+1}0
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
     map←{0=≢⍵:'' ⋄ e w d n←⍺ ⋄ pkg←e,('::'/⍨0≠≢e),w,(':'/⍨0≠≢w),d,('.'/⍨0≠≢d),n ⋄ pkg ⍵}

   ⍝------------------------------------------------------------------------------------
   ⍝  E N D      U T I L I T I E S
   ⍝------------------------------------------------------------------------------------

   ⍝ From each item in packages of the (regexp with spaces) form:
   ⍝      (\w+::)?    (\w+:)? (\w+(\.\w+)*)\.)? (\w+)
   ⍝     (path) ext    wsN     group             name
   ⍝ wsN may be a full string ('abc.def:'), null string (':'), or ⎕NULL (omitted).
   ⍝ group may be a full string or null string (if omitted)
   ⍝ name must be present
     pkgs←{
         0=≢⍵~' :.':''
         ext pkg←⍵{                     ⍝ ext: path extension comes before ::
             0=⍺:''⍵ ⋄ (⍵↑⍨⍺)(⍵↓⍨⍺+1)
         }⍨⊃⍸'::'⍷⍵
         wsN pkg←':'splitFirst pkg      ⍝ wsN: ws name comes before simple :
         group name←'.'splitLast pkg
         ⎕←'<',ext,'> <',wsN,'> <',group,'> <',name,'>'
         ext wsN group name
     }¨pkgs

     ∆PATH←resolvePath stdLibN,' ',CALLN,' ',⊃_ userPathHasUpArrow←resolvePathUpArrow ⎕PATH

   ⍝ ∆FSPATH:
   ⍝   1. If ⎕SE.∆FSPATH exists and is not null, use it.
   ⍝      You can merge new paths with the existing environment variable
   ⍝      FSPATH (or, if FSPATH is null, then WSPATH) from the env.  (see 2 below).
   ⍝      If it contains /:,:/ or /^,:/ or /:,$/, then  WSPATH is interpolated in its place!
   ⍝        e.g. if FSPATH/WSPATH has '.:stdLib1:stdLib2'
   ⍝        e.g. 'mydir1:mydir1/mydir1a:,'
   ⍝         →   'mydir1:mydir2/mydir1a:.:stdLib1:stdLib':
   ⍝   2. If GetEnvironment FSPATH is not null, use it.
   ⍝   3. If GetEnvironment WSPATH is not null, use it.
   ⍝      APL maintains this mostly for finding workspaces.
   ⍝   3. Use '.' (current active directory, via ]CD etc.)
   ⍝   Each item a string of the form here (if onle group, no colon is used):
   ⍝       'dir1:dir2:...:dirN'
     ∆FSPATH←∪':'split{
         2=⎕NC ⍵:{
             '^,(?>=:)|(?<=:),(?>=:)|(?<=:),$'⎕R{
                 ×≢fs←2 ⎕NQ'.' 'GetEnvironment' 'FSPATH':fs
                 2 ⎕NQ'.' 'GetEnvironment' 'WSPATH'}⊣⍵
         }⎕OR ⍵
         0≠≢fs←2 ⎕NQ'.' 'GetEnvironment' 'WSPATH':fs
         0≠≢env←2 ⎕NQ'.' 'GetEnvironment' 'WSPATH':env
         '.'
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

             _←{'Caller ns 'CALLN' package 'pkg' status: 'status}TRACE 0

             0=≢stat:pkg
             ''⊣(⊃status),←⊂stat
         }pkg

         0=≢pkg:status ∇ 1↓⍵                        ⍝ Fast path out. Otherwise, we short-circuit one by one

   ⍝ Is the package in the ⎕PATH?
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             _←{'Is package 'pkg' in ⎕PATH?'}TRACE 0

             recurse←{                                   ⍝ find pgk components in <path>.
                 0=≢⍵:''                              ⍝ none found. path exhausted: failure
                 path←⊃⍵

                 _←{'>>> path group: ',path}TRACE 0

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

             _←{'>>> Status 'status}TRACE 0

             0=≢recurse:pkg
             ''⊣(⊃status),←⊂pkg map recurse
         }pkg

   ⍝ Is the object in the named workspace?
   ⍝ If there is no object named, copy the <entire> workspace into the default library (stdLib).
   ⍝ creating the name <wsN> in the copied namespace, so it won't be copied in each time.
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0=≢wsN:⍵
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
             ''⊣(⊃status),←⊂pkg map stat
         }pkg

       ⍝ Is the package in the file system path?
       ⍝ We even check those with a wsN: prefix (which is checked first)
       ⍝ See FSSearchPath
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0∧.=≢¨group name:⍵
             dirFS←'/'@('.'∘=)group  ⍝  dirFS: group with internal dots → slashes

             _←{'1. Searching file sys path for package:',⍵}TRACE pkg

             recurse←{                                   ⍝ find pgk components in <path>.
                 0=≢⍵:''                                 ⍝ none found. path exhausted: failure
                 path←⊃⍵
                 0=≢path:∇ 1↓⍵                            ⍝ null directory. Skip...
                 searchDir←path,('/'/⍨0≠≢ext),ext,'/',dirFS,('/'⍴⍨0≠≢dirFS),name
                 searchfi←searchDir,'.dyalog'

                 _←{'  a. Search path: ',⍵,'[.dyalog]'}TRACE searchDir

                 ⋄ loaddir←{
                     group name←⍺
                     aplDir←group with name ⋄ fsDir←⍵
                     1≠⊃1 ⎕NINFO fsDir:'NOT A DIRECTORY: Ignored: ',fsDir
                     names←⊃(⎕NINFO⍠1)fsDir,'/*.dyalog'    ⍝ Will ignore subsidiary directories...
                     0=≢names:aplDir{
                         stamp←'First group ',⍺,'found was empty on ',(⍕⎕TS),': ',⍵
                         'empty group→stdLib: ',⍵⊣(dunder ⍺)stdLibR.{⍎⍺,'←⍵'}stamp
                     }fsDir
                     cont←⍬
                     fixed←''
                     load←{
                       ⍝ import: group name
                         0::¯1   ⍝ Failure
                         subName←1⊃⎕NPARTS ⍵
                         cont,←' ',,⎕FMT 2 stdLibR.⎕FIX'file://',⍵
                         fixed,←⎕TC[2],'   ',⍵
                         1     ⍝ Success
                     }¨names
                     stamp←(group with name),' copied from disk with contents',cont,' on ',⍕⎕TS
                     _←(dunder group name)stdLibR.{⍎⍺,'←⍵'}stamp
                     res←'[group] ',(group with name),'→stdLib '
                     res,←⎕TC[2],'   [',{⍵=0:'' ⋄ (⍕⍵),' objects ⎕FIXed:',fixed,⎕TC[2]}+/load=1
                     res,←{⍵=0:'' ⋄ '; ',(⍕⍵),' failed to load'}+/load=¯1
                     res,←'   ]',⎕TC[2]
                     res
                 }
                 ⎕NEXISTS searchDir:(group name)loaddir searchDir
                 ⋄ loadfi←{
                     group name←⍺
                     id←dunder group name
                     cont←,⎕FMT 2 stdLibR.⎕FIX'file://',⍵
                     stamp←(group with name),' copied from disk with contents ',cont,' on ',⍕⎕TS
                     _←id stdLibR.{⍎⍺,'←⍵'}stamp
                     'file→stdLib: ',⍵
                 }
                 ⎕NEXISTS searchfi:(group name)loadfi searchfi
                 ∇ 1↓⍵
             }∆FSPATH

             _←{s←'  b. Status: ' ⋄ 0=≢⍵:s,'NOT FOUND' ⋄ s,,⎕FMT ⍵}TRACE recurse

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
     CALLR.⎕PATH←(∊⍕¨resolvePath(⊂stdLibN),∆PATH),' ↑'/⍨userPathHasUpArrow

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
