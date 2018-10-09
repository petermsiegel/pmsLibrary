﻿ require←{
     ⎕IO ⎕ML←0 1

   ⍝ Help info in:
   ⍝     /Users/<USER>/MyDyalogLibrary/require/require.help
   ⍝ Grab filedir from SALT comment line at end of this function.
     ⍵≡'-HELP':⍬⊣⎕ED'∆'⊣∆←↑⊃⎕NGET 1,⍨⊂'../docs/require.help',⍨0⊃⎕NPARTS⊃'§(.*?)§'⎕S'\1'⊣1↑¯2↑⎕NR 0⊃⎕XSI

     DEBUG←0                           ⍝ If CODE<0, DEBUG CODE←(CODE<0)(|CODE)
     defaultLibName←'⍙⍙.require'       ⍝ Default will be in # or ⎕SE, based on CALLN (next)
     CALLR CALLN←(⊃⎕RSI)(⊃⎕NSI)        ⍝ CALLR/N ("caller"): Where was <require> called from?

     999×DEBUG::⎕SIGNAL/⎕DMX.(EM EN)

  ⍝ Decode ⍺ → [stdLibStr CODE]
     ⍺←⎕NULL
     stdLibStr CODE←2⍴{                ⍝  ⍺:  [[standard_library@string|nsRef] [code@number]], default=⎕NULL
         9=⎕NC'_'⊣_←⊃⍵:⍵ 0             ⍝  ⍺:   #  [2]
         0=1↑0⍴⊃⍵:⎕NULL ⍵              ⍝  ⍺:   2
         1=≢⊆⍵:⍵ 0                     ⍝  ⍺:  'test'    OR  ⎕NULL (⍺ omitted)
         ⍵                             ⍝  ⍺:  'test' 5
     }⍺
     DEBUG CODE←(DEBUG∨CODE<0)(|CODE)  ⍝ Do not override DEBUG if set to 1.

  ⍝ DECODE ⍵ → list of packages (possibly 0-length), each package a string (format below)
     pkgs←⊆⍵

     stdLibR stdLibN←{
         returning←{2=≢⍵:⍵ ⋄ (⍎⍵ CALLR.⎕NS'')⍵}
         top←'⎕SE' '#'⊃⍨'#'=1↑CALLN          ⍝ what's our top level?
         topDef←top,'.',defaultLibName       ⍝ the default if there's no default library
         ⍵≡⎕NULL:returning topDef

         ∆LIB←'[LIB]'                         ⍝ Possible special prefix to ⍵...
         0::⎕SIGNAL/('require DOMAIN ERROR: Default library name invalid: ',{0::⍕⍵ ⋄ ⍕⍎⍵}⍵)11
         returning{
             val←(⍕⍵)~' '                    ⍝ Set val. If ⍵ is ⎕SE or #, val is '⎕SE' or '#'
             (⊂,val)∊'⎕SE'(,'#'):(⍎val)val   ⍝ Matches:  ⎕SE, '⎕SE', #, '#'
             9.1 9.2∊⍨nc←CALLR.⎕NC⊂,'⍵':(⍵)(⍕⍵)  ⍝ Matches: an actual namespace reference
             2.1≠nc:○○○                      ⍝ If we reached here, ⍵ must be a string.
             0=≢val:(⍎top)top                ⍝ Null (or blank) string? Use <top>
             pat2←'^' '',¨⊂'\Q',∆LIB,'\E'    ⍝ Handle... ⎕SE.[LIB], #.[LIB], and [LIB].mysub
             name←pat2 ⎕R topDef defaultLibName⊣val
             nc←CALLR.⎕NC⊂,name              ⍝ nc of name stored in stdLib w.r.t. caller.
             9.1=nc:{⍵(⍕⍵)}(CALLR⍎name)      ⍝ name refers to active namespace. Simplify via ⍎.
             0=nc:CALLN,'.',name             ⍝ Assume name refers to potential namespace...
             ∘∘∘                             ⍝ error!
         }⍵
     }stdLibStr

 ⍝------------------------------------------------------------------------------------
 ⍝  U T I L I T I E S
 ⍝------------------------------------------------------------------------------------
     ⍝ Set 0: Debugging
      TRACE←{                           ⍝ Prints ⍺⍺ ⍵ if DEBUG. Always returns ⍵!
         0::⍵⊣⎕←'TRACE: APL TRAPPED ERROR ',⎕DMX.((⍕EN),': ',⎕EM)
         ⍺←⊢
         DEBUG:⍵⊣⎕←⎕FMT ⍺ ⍺⍺ ⍵
         ⍵
     }
     ⍝ Set I: miscellaneous utilities
     ⍝ and:         A and B 0  < dfns 'and', where A, B are code
     ⍝ or:          A or  B 0  < dfns 'or'...
     ⍝ split:       Split ⍵ on char in set ⍺ (' '), removing ⍺, returning vector of strings.
     ⍝ splitFirst:  Split ⍵ on FIRST single char ⍺ (' ') found, returning 2 vectors (each possibly null string).
     ⍝ splitLast:   Split ⍵ on LAST single char ⍺ (' ') found, returning two vectors (...).
     ⋄ and←{⍺⍺ ⍵:⍵⍵ ⍵ ⋄ 0}
     ⋄ or←{⍺⍺ ⍵:1 ⋄ ⍵⍵ ⍵}
     ⋄ split←{⍺←' ' ⋄ (~⍵∊⍺)⊆⍵}∘,
     ⋄ splitFirst←{⍺←' ' ⋄ (≢⍵)>p←⍵⍳⍺:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
     ⋄ splitLast←{⍺←' ' ⋄ 0≤p←(≢⍵)-1+⍺⍳⍨⌽⍵:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
 
     ⍝ Set II: Converting names in form ⍵1 ⍵2 ... to APL or filesystem formats.
     ⍝ dunder:       fs or APL name → unique APL name (using double underscores, dunders).
     ⍝    Syntax:    ∇ ⍵1@str ⍵2@str ... → '__s1__s2'
     ⍝    Usage:     Used to record loading a specific name or directory into a standard library 
     ⍝               under certain circumstances.
     ⍝    Ex:        a.b → '__a__b', a → '__a', 'a/b' → '__a__b', '##.fred' → '__fred', 
     ⍝               ⎕SE.test → '__⍙SE__test', #.test → 'test'.  
     ⍝    If ⍵ has any of '/.', split on it on the fly. Wholly ignore args '##[.]' and '#[.]'.
     ⍝ apl2FS:      convert APL style namespace hierarchy to a filesystem hierarchy:
     ⍝    Syntax:   s1 ∇ s2    → 's1.s2' ⋄ '' ∇ s2 → s2 ⋄ s1 ∇ '' → ''
     ⍝    Ex:       a.b.c → a/b/c     ##.a → ../a    #.a → /a
     ⍝ with:        Concatenate strings ⍺ with ⍵.  
     ⍝              If ⍺≡'', returns ⍵.   If ⍵≡'', returns ''.  Else returns ⍺,'.',⍵
     ⍝
     ⋄ dunder←{2=|≡⍵:∊∇¨⍵ ⋄ 0=≢⍵~'#':'' ⋄ 1∊'/.'∊⍵:∊∇¨'/.'split ⍵ ⋄ '__','⍙'@('⎕'∘=)⊣⍵}
     ⋄ apl2FS←{'.'@('#'∘=)⊣'/'@('.'∘=)⊣⍵↓⍨'#.'≡2↑⍵}
     ⋄ with←{0=≢⍵:'' ⋄ 0=≢⍺:⍵ ⋄ ⍺,'.',⍵}
 
     ⍝ set III: Manage file specs in colon format like Dyalog's WSPATH: 'file1:file2:file3' etc.
     ⍝ noEmpty:     remove empty file specs from colon-format string, string-initial, -medial, and -final.
     ⍝ symbols:     replace [HOME], [FSPATH] etc in colon spec. with their environment variable value (getenv).
     ⍝ getenv:      Retrieve an env. variable value ⍵ in OS X
     ⋄ noEmpty←{{⍵↓⍨-':'=¯1↑⍵}{⍵↓⍨':'=1↑⍵}{⍵/⍨~'::'⍷⍵}⍵}
     ⋄ symbols←{'\[(HOME|FSPATH|WSPATH|PWD)\]'⎕R{getenv ⍵.(Lengths[1]↑Offsets[1]↓Block)}⊣⍵}
     ⋄ getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
 

   ⍝ resolveNs Ns@str: Return a reference for a namespace string with respect to CALLR.
   ⍝                   Deals with '#', '##', '⎕SE' in a kludgey way (they aren't valid names, but #.what is.
     resolveNs←CALLR∘{
         nc←⍺.⎕NC⊂⍵
         nc∊9.1 ¯1:⍕⍺⍎⍵      ⍝ nc=¯1: ##.## etc.  nc=9.1: namespace
         ⎕NULL               ⍝ Return the actual name of the relative ns. If not valid, return ⎕NULL
     }∘,

   ⍝ resolvePathUpArrow: Where a ↑ is seen in ⎕PATH, replace the ↑ with the actual higher-level namespaces,
   ⍝    so that those namespaces can be searched for packages.
   ⍝    Approach: If we are in #.a.b.c.d and ⎕PATH has ↑, it is replaced by:
   ⍝         ##       ##.##  ##.##.## and ##.##.##.##, which is resolved to the absolute namespaces:
   ⍝         #.a.b.c  #.a.b  #.a      and #
   ⍝ If no ↑, returns ⍵; otherwise returns ⍵ with any '↑' replaced as above.
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
   ⍝    ⍵: an namespace reference or name (interpreted wrt CALLR).
     inNs←{
         0::'require/inNs: DOMAIN ERROR: Invalid namespace, library, or package'⎕SIGNAL ⎕DMX.EN
         0=≢⍺:0
         callr←CALLR     ⍝ Dyalog bug Workaround: external CALLR, used directly like this (CALLR.⍎), won't be found.
         ns←callr.⍎⍣(⍬⍴2=⎕NC'ns')⊣ns←⍵
         0<ns.⎕NC ⍺      ⍝ ⍺ defined in ns?
     }

   ⍝ repkg: Convert a split-up package (in e w d n format) to a string
     repkg←{e w d n←⍵ ⋄ pkg←e,('::'/⍨0≠≢e),w,(':'/⍨0≠≢w),d,('.'/⍨0≠≢d),n}

   ⍝ map:   For ⍺ a split-up package and ⍵ a string, if ⍵ is non-null, return 2 strings:  (repkg ⍺)⍵
     map←{0=≢⍵:'' ⋄ (repkg ⍺)⍵ }

   ⍝------------------------------------------------------------------------------------
   ⍝  E N D      U T I L I T I E S
   ⍝------------------------------------------------------------------------------------

   ⍝ From each item in packages of the (regexp with spaces) form:
   ⍝      (\w+::)?    (\w+:)? (\w+(\.\w+)*)\.)? (\w+)
   ⍝      ext         wsN     group             name
   ⍝ ext:  a filesystem extension (suffix) to add to path before testing whether group/name is found
   ⍝ wsN:  a full string ('abc.def:') | null string (':') | ⎕NULL (no wsN).
   ⍝ group may be a full string or null string (if omitted)
   ⍝ name must be present
     lastExt←''      ⍝ If a :: appears with nothing before it, the prior lastExt is used
     lastWs←''       ⍝ If a : appears ..., the prior lastWs is used!
     pkgs←{
         0=≢⍵~' :.':''                  ⍝ All blanks or null? Bye!
         pkg←,⍵

         ext pkg←⍵{                     ⍝ ext::[group.]name
             0=≢⍺:''⍵                   ⍝ '::group name' → <lastExt> '' <group> <name>
             0=⍺:lastExt(⍵↓⍨⍺+2)
             (lastExt∘←⍵↑⍨⍺)(⍵↓⍨⍺+2)    ⍝ ext:: and wsN: are mutually exclusive in fact.
         }⍨⍸'::'⍷pkg

         wsN pkg←{                      ⍝ wsN:[group.]name
             wsDef←(':'=1↑pkg)∧(':'≠1↑1↓pkg)
             wsDef:lastWs(1↓pkg)    ⍝ ':group name'  → '' <lastWs> <group> <name>
             lastWs∘←w⊣w p←':'splitFirst pkg          ⍝ wsN: ws name comes before simple :
             w p
         }pkg

         group name←'.'splitLast pkg     ⍝ grp1.grp2.grp3.name → 'grp1.grp2.grp3' 'name'
         ext wsN group name              ⍝ Return 4-string internal package format...
     }¨pkgs


   ⍝ Process caller ⎕PATH → ∆PATHin:  handling ↑, resolving namespaces (ignoring those that don't exist).
     ∆PATHin←resolvePath ('↑'∊CALLR.⎕PATH)  resolvePathUpArrow CALLR.⎕PATH  
     ∆PATHadd←⍬

   ⍝ ∆FSPATH: Find File System Path to search
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
                 ∆PATHadd,⍨←⊂resolveNs group                    ⍝ group.name found
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


             scanPath←{                                 ⍝ find pgk components in <path> or stdLib
                 ⍺←'PATH'
                 0=≢⍵:''                                ⍝ none found. path exhausted: failure
                 path←⊃⍵

                 _←{'>>> Checking ⎕PATH ns: ',⍵}TRACE path

             ⍝⍝ --------------------------------------------------------------------------------------
             ⍝⍝ If name is found in path, do we explicitly add to path? CHOICE (A)=YES, (B)=NO.
             ⍝⍝   PROS: path may have ↑ and the item may work for this caller ns, but not another
             ⍝⍝         that inherits its ⎕PATH.
             ⍝⍝   CONS: (1) pollutes ⎕PATH and (2) reorders items user explicitly put in path
             ⍝⍝ Decision: For now, we leave out the update, choice (B).
             ⍝⍝   For (A), replace (B) below with (A):
             ⍝⍝       (A) name inNs path:'name∊',⍺⊣∆PATHadd,⍨←path
             ⍝⍝ --------------------------------------------------------------------------------------

                 {0≠≢group}and{path inNs⍨dunder group name}1:'group.name[.dyalog]∊',⍺
                 {0=≢group}and{path inNs⍨dunder name}1:'name[.dyalog]∊',⍺
                 {0=≢name}and{path inNs⍨dunder wsN}0:'ws∊',⍺
                 {wsN inNs path}and{0=≢⍵:1              ⍝ wsN found and group/name empty: success
                     ⍵ inNs path,'.',wsN                ⍝ wsN found and group/name found in path.wsN: success
                 }group with name:'ws∊',⍺

                 name inNs path:'name∊',⍺               ⍝ Name found: Success.
                 group≡'':∇ 1↓⍵                         ⍝ Not found: try another path element
                 ~{(group with name)inNs path}and{9=stdLibR.⎕NC group}0:∇ 1↓⍵ ⍝ Not found: try another path element
                 ∆PATHadd,⍨←⊂resolveNs path with group  ⍝ group.name found: ...
                 'group→',⍺                             ⍝ ...         success
             }

          ⍝ Go through path. If found, return success.
          ⍝ Otherwise, try stdLibR (unless in path). If found, add stdLibR to path (∆PATHadd).
             recurse←{
                 ×≢r←scanPath∪∆PATHin:r                ⍝ Found in path?
                 stdLibR∊∆PATHin:''                    ⍝ No, so if stdLibR not in path, check there.
                 0=≢r←'STDLIB'scanPath stdLibR:''      ⍝ Found in stdLibR?
                 r⊣∆PATHadd,⍨←stdLibR                  ⍝ Yes, so add stdLibR to path
             }⍬

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
             ∆PATHadd,⍨←stdLibR                             ⍝ Succeeded: Add stdLibR to path
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
                     1∊load:res⊣∆PATHadd,⍨←stdLibR        ⍝ At least one <load> succeeded.
                     res
                 }
                 ⎕NEXISTS searchDir:(group name)loaddir searchDir
                 ⋄ loadfi←{
                     0::'file→stdLib FAILED: "',⍵,'"'
                     group name←⍺

                     id←dunder group name
                     cont←,⎕FMT 2 stdLibR.⎕FIX'file://',⍵
                     _←{'>>>>> Loaded file: ',⍵}TRACE ⍵
                     stamp←(group with name),' copied from disk with contents ',cont,' on ',⍕⎕TS
                     _←id stdLibR.{⍎⍺,'←⍵'}stamp
                     ∆PATHadd,⍨←stdLibR                      ⍝ Succeeded: Note stdLibR (if not already)
                     'file→stdLib: "',⍵,'"'
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

     _←{'Caller''s ⎕PATH was "',CALLR.⎕PATH,'", ∆PATHin=',∆PATHin,', ∆PATHadd=',∆PATHadd}TRACE 0

   ⍝ Update PATH, adding the default Library. Allow no duplicates, but names should be valid.
   ⍝ Prepend new items and merge with caller's ⎕PATH keeping relative ⎕PATH elements...
   ⍝ Here, we don't make sure CALLR.⎕PATH entries are valid. Also ↑ is maintained.
     CALLR.⎕PATH←1↓∊' ',¨∪(⍕¨∆PATHadd),(split CALLR.⎕PATH)    

     _←{'Caller''s ⎕PATH now "',CALLR.⎕PATH,'"'}TRACE 0

     succ←0=≢⊃⌽statusList
     succ∧CODE∊3:_←{⍵}TRACE(⊂stdLibR),statusList  ⍝ CODE 3:   SUCC: shy     (non-shy if DEBUG)

     ⋄ CODE∊3:(⊂stdLibR),statusList               ⍝           FAIL: non-shy
     succ∧CODE∊2:stdLibR                          ⍝ CODE 2:   SUCC: non_shy

     ⋄ eCode1←'require DOMAIN ERROR: At least one package not found or not ⎕FIXed.' 11
     ⋄ CODE∊2:⎕SIGNAL/eCode1                      ⍝           FAIL: ⎕SIGNAL
     succ∧CODE∊1 0:_←{⍵}TRACE statusList          ⍝ CODE 1|0: SUCC: shy     (non-shy if DEBUG)

     ⋄ CODE∊1 0:statusList                        ⍝           FAIL: non-shy
     ⎕SIGNAL/('require DOMAIN ERROR: Invalid CODE: ',⍕CODE)11   ⍝ ~CODE∊0 1 2 3
 }
