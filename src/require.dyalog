 require←{
⍝  TRACING (see TRACE) lines are prefixed with ⍝:DBG when inactive...

     ⎕IO ⎕ML←0 1

   ⍝ Help info in:
   ⍝     /Users/<USER>/MyDyalogLibrary/require/require.help
   ⍝ Grab filedir from SALT comment line at end of this function.
     ((819⌶)∊⍵)≡'-help':⍬⊣⎕ED'∆'⊣∆←↑⊃⎕NGET 1,⍨⊂'../docs/require.help',⍨0⊃⎕NPARTS⊃'§(.*?)§'⎕S'\1'⊣1↑¯2↑⎕NR 0⊃⎕XSI

     DEBUG←0                           ⍝ If CODE<0, DEBUG CODE←(CODE<0)(|CODE)
     DefaultLibName←'⍙⍙.require'       ⍝ Default will be in # or ⎕SE, based on CallerN (next)


   ⍝ ADDFIXEDNAMESPACES: See add2PathIfNs
   ⍝   If a .dyalog file is fixed, the created items are returned by ⎕FIX.
   ⍝   If an item is a namespace (now in stdLibR), should it be added to ⎕PATH?
   ⍝   If ADDFIXEDNAMESPACES←1, then it will be added to ⎕PATH.
   ⍝   Otherwise, not.
     ADDFIXEDNAMESPACES←1

     999×DEBUG::⎕SIGNAL/⎕DMX.(EM EN)

  ⍝ Decode ⍺ → [StdLibStr CODE]
     ⍺←⎕NULL
  ⍝ CallerR/N ("caller"): Where was <require> called from?
  ⍝   If the first option in ⍺ is 'CALLER', then we get the Caller (NS) as 2nd item.
  ⍝   Otherwise from the stack.
     options CallerR CallerN←{
         0=≢⍵:⍵(1⊃⎕RSI)(1⊃⎕NSI)
         'CALLER'≢⊃⍵:⍵(1⊃⎕RSI)(1⊃⎕NSI)
         (2↓⍵)(C)(⍕C←1⊃⍵)
     }⍺
     StdLibStr CODE←2⍴{                ⍝  ⍺:  [[standard_library@string|nsRef] [code@number]], default=⎕NULL
         0=≢⍵:⎕NULL 0
         9=⎕NC'_'⊣_←⊃⍵:⍵ 0             ⍝  ⍺:   #  [2]
         0=1↑0⍴⊃⍵:⎕NULL ⍵              ⍝  ⍺:   2
         1=≢⊆⍵:⍵ 0                     ⍝  ⍺:  'test'    OR  ⎕NULL (⍺ omitted)
         ⍵                             ⍝  ⍺:  'test' 5
     }options
     DEBUG CODE←(DEBUG∨CODE<0)(|CODE)  ⍝ Do not override DEBUG if set to 1.

  ⍝ DECODE ⍵ → list of packages (possibly 0-length), each package a string (format below)
     pkgs←⊆⍵

     stdLibR stdLibN←{
         returning←{2=≢⍵:⍵ ⋄ (⍎⍵ CallerR.⎕NS'')⍵}
         top←'⎕SE' '#'⊃⍨'#'=1↑CallerN          ⍝ what's our top level?
         topDef←top,'.',DefaultLibName       ⍝ the default if there's no default library
         ⍵≡⎕NULL:returning topDef

         ∆LIB←'[LIB]'                         ⍝ Possible special prefix to ⍵...
         0::⎕SIGNAL/('require DOMAIN ERROR: Default library name invalid: ',{0::⍕⍵ ⋄ ⍕⍎⍵}⍵)11
         returning{
             val←(⍕⍵)~' '                    ⍝ Set val. If ⍵ is ⎕SE or #, val is '⎕SE' or '#'
             (⊂,val)∊'⎕SE'(,'#'):(⍎val)val   ⍝ Matches:  ⎕SE, '⎕SE', #, '#'
             9.1 9.2∊⍨nc←CallerR.⎕NC⊂,'⍵':(⍵)(⍕⍵)  ⍝ Matches: an actual namespace reference
             2.1≠nc:○○○                      ⍝ If we reached here, ⍵ must be a string.
             0=≢val:(⍎top)top                ⍝ Null (or blank) string? Use <top>

           ⍝ Handle (⎕SE or #).[LIB], [LIB].mysub and [CALLER], calling env.
             pat2←('^' '',¨⊂'\Q',∆LIB,'\E'),⊂'\Q[CALLER]\E'   
        
             name←pat2 ⎕R topDef DefaultLibName CallerN⊣val
             nc←CallerR.⎕NC⊂,name              ⍝ nc of name stored in stdLib w.r.t. caller.
             9.1=nc:{⍵(⍕⍵)}(CallerR⍎name)      ⍝ name refers to active namespace. Simplify via ⍎.
             0=nc:CallerN,'.',name             ⍝ Assume name refers to potential namespace...
             ∘∘∘                             ⍝ error!
         }⍵
     }StdLibStr

 ⍝------------------------------------------------------------------------------------
 ⍝  U T I L I T I E S
 ⍝------------------------------------------------------------------------------------
     ⍝ Set 0: Debugging
     TRACE←{                           ⍝ Prints ⍺⍺ ⍵ if DEBUG. Always returns ⍵!
         0::⍵⊣⎕←'TRACE: APL trapped error ',⎕DMX.((⍕EN),': ',⎕EM)
         ⎕PW←9999
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
     ⋄ with←{0=≢⍵:'' ⋄ 0=≢⍺:⍵ ⋄ ∊⍺,'.',⍵}

     ⍝ set III: Manage file specs in colon format like Dyalog's WSPATH: 'file1:file2:file3' etc.
     ⍝ noEmpty:     remove empty file specs from colon-format string, string-initial, -medial, and -final.
     ⍝ symbols:     replace [HOME], [FSPATH] etc in colon spec. with their environment variable value (getenv).
     ⍝ getenv:      Retrieve an env. variable value ⍵ in OS X
     ⋄ noEmpty←{{⍵↓⍨-':'=¯1↑⍵}{⍵↓⍨':'=1↑⍵}{⍵/⍨~'::'⍷⍵}⍵}
     ⋄ symbols←{'\[(HOME|FSPATH|WSPATH|PWD)\]'⎕R{getenv ⍵.(Lengths[1]↑Offsets[1]↓Block)}⊣⍵}
     ⋄ getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}


   ⍝ resolveNs Ns@str: Return a reference for a namespace string with respect to CallerR.
   ⍝                   Deals with '#', '##', '⎕SE' in a kludgey way (they aren't valid names, but #.what is.
     resolveNs←CallerR∘{
         nc←⍺.⎕NC⊂⍵
         nc∊9.1 ¯1:⍺⍎⍵      ⍝ nc=¯1: ##.## etc.  nc=9.1: namespace
         ⎕NULL              ⍝ If not valid, return ⎕NULL
     }∘,

   ⍝ resolvePathUpArrow: Where a ↑ is seen in ⎕PATH, replace the ↑ with the actual higher-level namespaces,
   ⍝    so that those namespaces can be searched for packages.
   ⍝    Approach: If we are in #.a.b.c.d and ⎕PATH has ↑, it is replaced by:
   ⍝         ##       ##.##  ##.##.## and ##.##.##.##, which is resolved to the absolute namespaces:
   ⍝         #.a.b.c  #.a.b  #.a      and #
   ⍝ If no ↑, returns ⍵; otherwise returns ⍵ with any '↑' replaced as above.
     resolvePathUpArrow←{
         ~⍺:⍵
         dist←¯1++/CallerN='.' ⋄ p←⍵⍳'↑' ⋄ w←⍵
         (∊w)⊣w[p]←⊂{⍺←'' ⋄ ⍵>dist:⍺ ⋄ (⍺,' ',∊'##',⍵⍴⊂'.##')∇ ⍵+1}0
     }

  ⍝ resolvePath: Determines actual ordered path to search, based on ∆CALR and ⎕PATH.
  ⍝ resolvePath:  allow non-existent namespaces to stay (since user may have other uses)
     resolvePath←{
         ⎕NULL~⍨∪resolveNs¨split⍣(1≥|≡⍵)⊣⍵
     }


   ⍝ ⍺ inNs ⍵:  Is object ⍺ found in namespace ⍵?
   ⍝    ⍺: String of form: a, b.a, c.b.a etc.  If 0=≢⍺: inNs fails.
   ⍝    ⍵: an namespace reference or name (interpreted wrt CallerR).
     inNs←{
         0::'require/inNs: DOMAIN ERROR: Invalid namespace, library, or package'⎕SIGNAL ⎕DMX.EN
         0=≢⍺:0
         clr←CallerR     ⍝ Dyalog bug Workaround: external CallerR, used directly like this (CallerR.⍎), won't be found.
         ns←clr.⍎⍣(⍬⍴2=⎕NC'ns')⊣ns←⍵
         0<ns.⎕NC ⍺      ⍝ ⍺ defined in ns?
     }

   ⍝ repkg: Convert a split-up package (in <e w d n> format) to a string
     repkg←{e w d n←⍵ ⋄ pkg←e,('::'/⍨0≠≢e),w,(':'/⍨0≠≢w),d,('.'/⍨0≠≢d),n}

   ⍝ map:   For ⍺ a split-up package and ⍵ a string, if ⍵ is non-null, return 2 strings:  (repkg ⍺)⍵
     map←{0=≢⍵:'' ⋄ (repkg ⍺)⍵}

   ⍝ See ADDFIXEDNAMESPACES above for more info.
   ⍝ ⍵ must be a name of an existing object in stdLibR in string form.
   ⍝ If ADDFIXEDNAMESPACES=1, and if ⍵ refers to a namespace (⎕NC 9.1),
   ⍝ ⍵'s reference is added to PathNewR,
   ⍝ and ultimately to CallerR.⎕PATH.
     add2PathIfNs←{~ADDFIXEDNAMESPACES:'' ⋄ 9.1≠stdLibR.⎕NC⊂,⍵:'' ⋄ ⍵⊣PathNewR,⍨←stdLibR⍎⍵}

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


   ⍝ Process caller APL ⎕PATH → PathOrigR:  handling ↑, resolving namespaces (ignoring those that don't exist).
     PathOrigR←resolvePath('↑'∊CallerR.⎕PATH)resolvePathUpArrow CallerR.⎕PATH
     PathNewR←PathOrigR

   ⍝ FSPATH: Find File System Path to search
   ⍝   1. If ⎕SE.FSPATH exists and is not null, use it.
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

     FSPATH←∪':'split noEmpty{
         2=⎕NC ⍵:symbols ⎕OR ⍵
         0≠≢fs←symbols getenv'FSPATH':fs
         0≠≢env←symbols getenv'WSPATH':env
         symbols'.:[HOME]'             ⍝ current dir ([PWD]) and [HOME]
     }'⎕SE.FSPATH'

⍝:DBG   _←{'FSPATH='⍵}TRACE FSPATH

     0=≢⍵:stdLibR   ⍝ If no main right argument, return the library reference (default or user-specified)
     0∊≢¨pkgs~¨⊂'.: ':⎕SIGNAL/'require DOMAIN ERROR: at least one package string was empty.' 11

   ⍝------------------------------------------------------------------------------------
   ⍝ statusList:
   ⍝   [0] list of packages successfully found
   ⍝           wsN:group.name status
   ⍝   [1] list of packages not found or whose copy failed (e.g. ⎕FIX failed, etc.)
   ⍝           wsN:group.name status
   ⍝   If wsN not present, wsN and group may be null strings.
   ⍝   If wsN is present,  group and/or name  may each be null.
   ⍝   The status field is always present.
   ⍝------------------------------------------------------------------------------------
     statusList←⍬ ⍬{
         0=≢⍵:⍺
         status←⍺
         pkg←⊃⍵

⍝:DBG    _←{⎕TC[2],'> Package: ',repkg ⍵}TRACE pkg

       ⍝------------------------------------------------------------------------------------
       ⍝ Is the package in the caller's namespace?
       ⍝ Check for <name>, <group.name>, and <wsN>.
       ⍝------------------------------------------------------------------------------------
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵

             stat←{
                 ('__',wsN)inNs CallerR:pkg map'ws∊CALLER'      ⍝ wsN found?   success
                 name inNs CallerR:pkg map'name∊CALLER'        ⍝ name found? success
                 group≡'':''
                 ~(group with name)inNs CallerR:''                   ⍝ none found? failure
                 PathNewR,⍨←⊂resolveNs group                    ⍝ group.name found
                 pkg map'group.name∊CALLER'                    ⍝ ...         success
             }⍵

             0=≢stat:pkg

⍝:DBG        _←{'>>> Found in caller ns: ',⍵}TRACE stat

             ''⊣(⊃status),←⊂stat
         }pkg

         0=≢pkg:status ∇ 1↓⍵                        ⍝ Fast path out. Otherwise, we short-circuit one by one

       ⍝------------------------------------------------------------------------------------
       ⍝ Is the package in the ⎕PATH?
       ⍝------------------------------------------------------------------------------------
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵


             scanPath←{                                 ⍝ find pgk components in <path> or stdLib
                 ⍺←'PATH'
                 0=≢⍵:''                                ⍝ none found. pathEntry exhausted: failure
                 pathEntry←⊃⍵
                 pathInfo←⍺,' ',⍕pathEntry

⍝:DBG           _←{'>>> Checking ⎕PATH ns: <',(⍕⍵),'>'}TRACE pathEntry

               ⍝⍝ --------------------------------------------------------------------------------------
               ⍝⍝ If name is found in PathNewR, do we explicitly add to pathEntry? CHOICE (A)=YES, (B)=NO.
               ⍝⍝   PROS: pathEntry may have ↑ and the item may work for this caller ns, but not another
               ⍝⍝         that inherits its ⎕PATH.
               ⍝⍝   CONS: (1) pollutes ⎕PATH and (2) reorders items user explicitly put in pathEntry
               ⍝⍝ Decision: For now, we leave out the update, choice (B).
               ⍝⍝   For (A), replace (B) below with (A):
               ⍝⍝       (A) name inNs pathEntry:'name∊',⍺⊣PathNewR,⍨←pathEntry
               ⍝⍝ --------------------------------------------------------------------------------------

                 {0≠≢group}and{pathEntry inNs⍨dunder group name}1:'group.name[.dyalog]∊',pathInfo
                 {0=≢group}and{pathEntry inNs⍨dunder name}1:'name[.dyalog]∊',pathInfo
                 {0=≢name}and{pathEntry inNs⍨dunder wsN}0:'ws∊',pathInfo
                 {wsN inNs pathEntry}and{0=≢⍵:1              ⍝ wsN found and group/name empty: success
                     ⍵ inNs pathEntry,'.',wsN                ⍝ wsN found and group/name found in pathEntry.wsN: success
                 }group with name:'ws∊',pathInfo

                 name inNs pathEntry:'name∊',pathInfo        ⍝ Name found: Success.
                 group≡'':∇ 1↓⍵                              ⍝ Not found: try another pathEntry element
                 ~{(group with name)inNs pathEntry}and{9=stdLibR.⎕NC group}0:∇ 1↓⍵ ⍝ Not found: try another pathEntry element
                 PathNewR,⍨←⊂resolveNs(⍕pathEntry)with group ⍝ group.name found: ...
                 'group→',pathInfo                           ⍝ ...         success
             }

          ⍝ Go through pathEntry, next item in PathNewR. If found, return success.
          ⍝ Otherwise, try stdLibR (unless in PathNewR). If found, add stdLibR to PathNewR.
             recurse←{
                 ×≢r←scanPath∪PathNewR:r                ⍝ Check pathEntry. Found? Yes: Return status.
                 stdLibR∊PathNewR:''                    ⍝ No. If stdLibR in PATHR, return ''.
                 0=≢r←'STDLIB'scanPath stdLibR:''    ⍝ Check stdLibR?   Not found: ''
                 r⊣PathNewR,⍨←stdLibR                  ⍝ Found: Add stdLibR to pathEntry and return status.
             }⍬
             0=≢recurse:pkg

⍝:DBG        _←{'>>> Found in ⎕PATH ns: ',⍵}TRACE recurse

             ''⊣(⊃status),←⊂pkg map recurse
         }pkg

       ⍝------------------------------------------------------------------------------------
       ⍝ Is the object in the named workspace?
       ⍝ If there is no object named, copy the <entire> workspace into the default library (stdLib).
       ⍝ creating the name <wsN> in the copied namespace, so it won't be copied in each time.
       ⍝------------------------------------------------------------------------------------
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0=≢wsN:⍵

⍝:DBG       _←{'>>> Checking workspace: ',⍵}TRACE wsN

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
             PathNewR,⍨←stdLibR                             ⍝ Succeeded: Add stdLibR to path
             _←{'>>> Found in ws: ',repkg ⍵}TRACE ⍵
             ''⊣(⊃status),←⊂pkg map stat
         }pkg

       ⍝------------------------------------------------------------------------------------
       ⍝ Is the package in the file system path?
       ⍝ We even check those with a wsN: prefix (whenever the workstation is not found)
       ⍝ See FSSearchPath
       ⍝------------------------------------------------------------------------------------
         pkg←{
             0=≢⍵:⍵
             ext wsN group name←pkg←⍵
             0∧.=≢¨group name:⍵
             dirFS←apl2FS group                          ⍝ Convert a.b→a/b, ##.a→../a

             recurse←{                                   ⍝ find pgk components in <path>.
                 0=≢⍵:''                                 ⍝ none found. path exhausted: failure
                 path←⊃⍵
                 0=≢path:∇ 1↓⍵                           ⍝ NEXT!
                 searchDir←path,('/'/⍨0≠≢ext),ext,'/',dirFS,('/'⍴⍨0≠≢dirFS),name
                 searchFi←searchDir,'.dyalog'

⍝:DBG            _←{'>>> Searching filesystem: ',⍵}TRACE searchDir

                 loadDir←{
                     group name←⍺
                     aplNs←group with name ⋄ fsDir←⍵
                     1≠⊃1 ⎕NINFO fsDir:'NOT A DIRECTORY: ',fsDir
                     names←⊃(⎕NINFO⍠1)fsDir,'/*.dyalog'    ⍝ Will ignore subsidiary directories...
                     0=≢names:aplNs{
                       ⍝ Put a 'loaded' flag in the stdLibR ns for the empty dir.
                         stamp←'First group ',⍺,'found was empty on ',(⍕⎕TS),': ',⍵
                         _←(dunder ⍺)stdLibR.{⍎⍺,'←⍵'}stamp
                         'empty group→stdLib: ',⍵
                     }fsDir

⍝:DBG                _←{'>>>>> Found non-empty dir: ',⍵}TRACE fsDir

                     cont←''
                     ⍝ Returns 1 for each item ⎕FIXed, ¯1 for each item not ⎕FIXed.
                     ⍝ Like loadFi below...
                     load1Fi←{
                         0:¯1
⍝:DBG                   0::¯1⊣{'❌dir.file→stdLIB found but ⎕FIX failed: "',⍵,'"'}TRACE ⍵

                         fixed←2 stdLibR.⎕FIX'file://',⍵    ⍝ On error, see 0:: above.
                         cont,←' ',,⎕FMT fixed ⋄ _←add2PathIfNs¨fixed

⍝:DBG                _←{↑('>>>>> Loaded file: ',⍵)('>>>>>> Names fixed: ',fixed)}TRACE ⍵
                         1

                     }
                     tried←load1Fi¨names
                     gwn←group with name

                   ⍝ Put a 'loaded' flag in the stdLibR ns for the non-empty dir
                     stamp←gwn,' copied from dir: "',⍵,'" objects: {',cont,'} on ',⍕⎕TS
                     _←(dunder group name)stdLibR.{⍎⍺,'←⍵'}stamp

                     res←'[group] ',gwn,'→stdLib: "',⍵,'"'
                     res,←⎕TC[2],'   [Fixed: ',(⍕+/tried=1),' Failed: ',(⍕+/tried=¯1),']'

                   ⍝ Add stdLibR to PathNewR if at least one object was loaded and  ⎕FIXED.
                     1∊tried:res⊣PathNewR,⍨←stdLibR
                     res
                 }
               ⍝ See also load1Fi, which has the same basic logic.
                 loadFi←{
                     0::'❌file→stdLib found, but ⎕FIX failed: "',⍵,'"'
                     group name←⍺
                     gwn←group with name
                     id←dunder group name

                     fixed←2 stdLibR.⎕FIX'file://',⍵
                     cont←,⎕FMT fixed ⋄ _←add2PathIfNs¨fixed

⍝:DBG                _←{'>>>>> Loaded file: ',⍵}TRACE ⍵
                   ⍝ Put a 'loaded' flag in stdLibR for the loaded object.
                     stamp←gwn,' copied from file: "',⍵,'" objects: {',cont,'} on ',⍕⎕TS
                     _←id stdLibR.{⍎⍺,'←⍵'}stamp
                     PathNewR,⍨←stdLibR                ⍝ Succeeded: Note stdLibR (if not already)
                     '[file] ',gwn,'→stdLib: "',⍵,'"'
                 }

                 ⎕NEXISTS searchDir:(group name)loadDir searchDir
                 ⎕NEXISTS searchFi:(group name)loadFi searchFi
                 ∇ 1↓⍵                                     ⍝ NEXT!
             }FSPATH

⍝:DBG        _←{s←'>>> Status: ' ⋄ 0=≢⍵:s,'❌NOT FOUND' ⋄ s,,⎕FMT ⍵}TRACE recurse

             0=≢recurse:pkg
             ''⊣(⊃status),←⊂pkg map recurse
         }pkg

         pkg←{ ⍝ Any package <pkg> left must not have been found!
             0=≢⍵:''
             ''⊣(⊃⌽status),←⊂pkg map'❌NOT FOUND'
         }pkg

         status ∇ 1↓⍵    ⍝ Get next package!
     }pkgs

     _←{
         _←''('>>Caller''s ⎕PATH was ',⍕CallerR.⎕PATH)
         _,←('  PathOrigR: ',⍕PathOrigR)('>>PathNewR: ',⍕∪PathNewR)
         ↑_
     }TRACE 0

   ⍝------------------------------------------------------------------------------------
   ⍝ DONE-- process CODE options...
   ⍝ Update PATH, adding the default Library. Allow no duplicates, but names should be valid.
   ⍝ Prepend new items and merge with caller's ⎕PATH keeping relative ⎕PATH elements...
   ⍝ Here, we don't make sure CallerR.⎕PATH entries are valid. Also ↑ is maintained.
   ⍝-------------------------------------------------------------------------------------
     CallerR.⎕PATH←1↓∊' ',¨∪(⍕¨∪PathNewR),(split CallerR.⎕PATH)

⍝:DBG _←{'>>Caller''s ⎕PATH now ',⍕CallerR.⎕PATH}TRACE 0

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
