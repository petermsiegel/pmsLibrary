require←{
  ⍝  See help documentation for syntax and overview.
  ⍝   aa,a,a, ab
    ⎕IO ⎕ML←0 1    
  ⍝ Help info hard wired with respect to cur directory...
    HELP_FNAME←'./pmsLibrary/docs/require.help'
    DefaultLibName←'⍙⍙.require'       ⍝ Default will be in # or ⎕SE, based on callerN (default or passed by user)
  ⍝ General Utilities used below
  ⍝ (These should be informational - general)
    getenv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
    help_info←{ ↑⊃⎕NGET 1,⍨⊂HELP_FNAME}
    get_info←{
        _←⊂ 'HELP FILE:    ',HELP_FNAME
        _,←⊂'DEFAULT LIB:  ',DefaultLibName
        _,←⊂'FSPATH:       ',getenv'FSPATH'
        _,←⊂'WSPATH:       ',getenv'WSPATH'
        ↑_
    }
    ⍝⍝⍝⍝ Utilities for copying and fixing objects:
    ⍝⍝⍝⍝ wsGetFix
    ⍝⍝⍝⍝ fileGetFix
    wsGetFix←{
      ⍝ objList@VS ← [objList](destNs wsGetFix) library
      ⍝ → [list]destNs.⎕CY library
      ⍝ Returns list of objects if successful.  ⍬ if it fails. (Reports any error msg as well)
        0::⍬⊣⎕←'Warning: Error ',⎕DMX.(DM,' ',Message),', Library="',library,'"'
        ⍺←⊢ ⋄ listIn←⍺ ⋄ destNs←⍺⍺ ⋄ library←⍵
        ⋄ old←⍬ newObjs destNs
        _←listIn destNs.⎕CY library     ⍝ listIn may be omitted...
        ⋄ listOut←old newObjs destNs    ⍝ Figure out what objects of interest were created.
        listOut
    }
    fileGetFix←{
      ⍝ objList ← destNs fileGetFix fileId
      ⍝ →  objList ← 2 destNs.⎕FIX'file://',fileId
      ⍝ Signals error if not successful.
      ⍝ Returns a list of objects (on success)...
        0::⎕SIGNAL/⎕DMX.(EM EN)
        destNs fileId←⍺ ⍵
        listOut←2 destNs.⎕FIX'file://',fileId
        listOut
    }
    ⍝ Miscellaneous utilities
    ⍝ and:         A and B 0  < dfns 'and', where A, B are code {} or binary
    ⍝ or:          A or  B 0  < dfns 'or',  ...
    ⍝ split:       Split ⍵ on char in set ⍺ (' '), removing ⍺, returning vector of strings.
    ⍝ splitFirst:  Split ⍵ on FIRST single char ⍺ (' ') found, returning 2 vectors (each possibly null string).
    ⍝ splitLast:   Split ⍵ on LAST single char ⍺ (' ') found, returning two vectors (...).
    ⍝ newObjs:     Show what functions and ops have changed in the namespace <where>,
    ⍝              given <old> the list of old fns/ops. Returns only the NEW ones.
    ⍝              Example: old← ⍬ newObjs myNs ⋄ <<fiddle the namespace>> ⍝ new← old newObjs myNs
    ⋄ and←{⍺⍺⊣⍵:⍵⍵⊣⍵ ⋄ 0     }
    ⋄ or← {⍺⍺⊣⍵:1    ⋄ ⍵⍵ ⊣ ⍵}
    ⋄ split←{⍺←' ' ⋄ (~⍵∊⍺)⊆⍵}∘,
    ⋄ splitFirst←{⍺←' ' ⋄ (≢⍵)>p←⍵⍳⍺:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
    ⋄ splitLast←{⍺←' ' ⋄ 0≤p←(≢⍵)-1+⍺⍳⍨⌽⍵:(⍵↑⍨p)(⍵↓⍨p+1) ⋄ ''⍵}∘,
    ⋄ newObjs←{old where←⍺ ⍵ ⋄ new←where.⎕NL-3 4 9.1 ⋄ new~old}
    
  ⍝ For inforation on options. see -HELP information in Require.help
  ⍝ Scan for options
    ⍺←⎕NULL       ⍝ options in right arg before packages?
    options←⍺{
      ⍝ defaults set here... (caller → callerR callerN below)
        forceOpt debugOpt outOpt callerOpt libOpt←0 0 ''⍬ ⍬
        monad opts pkgList←⍺{
            ⍺≢⎕NULL:0(,⊆⍺)(,⊆⍵)
            1<|≡⍵:1(,⍵)(,⊆⍵)
            _←' '(≠⊆⊢)⍵
            1 _ _
        }⍵

        scanOpts←{
          ⍝ Returns 1 only for -help; else 0.
            ⍵≥≢opts:0
            o←⍵⊃opts ⋄ next skip←⍵+1 2
            case←(819⌶o)∘{⍵≡⍺↑⍨≢⍵}          
          ⍝ setFrmNext: Options of form:  -name=val set ⍎⍺ to <val>
          ⍝                  form   -name     set ⍎⍺ to next⊃opts
            setFrmNext←{ 
                e←'='∊⍵    ⋄ ø←{⍵:(1+o⍳'=')↓o ⋄ next⊃opts}e
                _←⍎⍺,'∘←ø' ⋄ e⊃skip next
            }
            3:: 11 ⎕SIGNAL⍨'require: value for option ',o,' missing'
          ⍝ Option is a namespace. Set libOpt option.
            9=⎕NC'o': ∇ next⊣libOpt∘←o
          ⍝ Option begins with -X, X∊'hifd...'
            case'-h':  1⊣⎕ED'⍙'⊣⍙←help_info 0   ⍝ -help
            case'-i':  1⊣⎕ED'⍙'⊣⍙← get_info 0   ⍝ -i[nfo]   (General info on settings)
            case'-f':  ∇ next⊣forceOpt∘←1       ⍝ -f[orce]
            case'-d':  ∇ next⊣debugOpt∘←1       ⍝ -d[ebug]
            case'-s':  ∇ next⊣libOpt∘←⎕SE       ⍝ -s[ession]
            case'-r':  ∇ next⊣libOpt∘←#         ⍝ -ro[ot]
            case'-o':  ∇'outOpt'setFrmNext o    ⍝ -o[utput]=[s|l|sl|b|q]  Output: s[tatus] l[ibrary] [boolean]
            case'-q':  ∇ next⊣outOpt∘←'q'       ⍝ -q (quiet), same as -output=q
            case'-c':  ∇'callerOpt'setFrmNext o ⍝ -c[aller]=nsName | -c[aller] nsRef
            case'-l':  ∇'libOpt'setFrmNext o    ⍝ -l[ib]=nsName    | -l[ib]    nsRef
            ~monad:'require: invalid option(s) found'⎕SIGNAL 11
            case'--':0⊣pkgList∘←next↓opts
            0⊣pkgList∘←⍵↓opts
        }
        scanOpts 0:⍬
        outOpt←{'q'∊⍵: ¯2 ⋄ 'b'∊⍵:¯1 ⋄ 2 1+.×'ls'∊⍵}(819⌶)outOpt
        callerR callerN←{
            9=⎕NC'⍵':⍵(⍕⍵)
            r n←(2⊃⎕RSI)(2⊃⎕NSI)
            ⍵≡⍬:r n
            (r⍎⍵)⍵
        }callerOpt
        options←forceOpt debugOpt outOpt callerR callerN libOpt pkgList

        ~debugOpt:options
        ⎕←'forceOpt  ',⍕forceOpt ⋄ ⎕←'debugOpt  ',⍕debugOpt
        ⎕←'outOpt    ',⍕outOpt   ⋄ ⎕←'callerOpt ',⍕callerOpt 
        ⎕←'libOpt    ',⍕libOpt   ⋄ ⎕←'pkgList   ',,⎕FMT pkgList
        options
    }⍵

  ⍝ If -help or -info, done now...
    0=≢options:''
  ⍝ ... Otherwise, hand out options by name
    forceOpt debugOpt outOpt callerR callerN libOpt pkgList←options
  ⍝ Internal option ADDFIXEDNAMESPACES: See add2PathIfNs
  ⍝   If a .dyalog file is fixed, the created items are returned by ⎕FIX.
  ⍝   If an item is a namespace (now in libR), should it be added to ⎕PATH?
  ⍝   >>> If ADDFIXEDNAMESPACES←1, then it will be added to ⎕PATH.
  ⍝   >>> Otherwise, not.
    ADDFIXEDNAMESPACES←1
  ⍝ Internal option USEHOMEDIR:
  ⍝ If 1, use [HOME] to represent env. var HOME.  See shortDirName
    USEHOMEDIR←1
    debugOpt::⎕SIGNAL/⎕DMX.(EM EN)
  ⍝ Determine library ref and name from option libOpt (via -lib or default)...
    libR libN←DefaultLibName{
        deflib←⍺
        returning←{2=≢⍵:⍵ ⋄ (callerR⍎⍵ callerR.⎕NS'')⍵}   ⍝ Added callerR left of ⍎
      ⍝  Same as ⍕{⍵.##}⍣≡callerR
        top←'⎕SE' '#'⊃⍨'#'=1↑callerN          ⍝ what's our top level?
        topDef←top,'.',deflib                 ⍝ the default if there's no default library
        ⍵≡⍬:returning topDef
       ⍝ Regexp's for special prefixes [LIB] and [CALLER]
        LIB_PFX1p LIB_PFX2p CALR_PFXp←'^\Q[LIB]\E'  '\Q[LIB]\E' '\Q[CALLER]\E'   
        0::⎕SIGNAL/('require DOMAIN ERROR: Default library name invalid: ',{0::⍕⍵ ⋄ ⍕⍎⍵}⍵)11
        returning{
            val←(⍕⍵)~' '                      ⍝ Set val. If ⍵ is ⎕SE or #, val is '⎕SE' or '#'
            (⊂,val)∊'⎕SE'(,'#'):(⍎val)val     ⍝ Matches:  ⎕SE, '⎕SE', #, '#'
            9.1 9.2∊⍨nc←callerR.⎕NC⊂,'⍵':(⍵)(⍕⍵)  ⍝ Matches: an actual namespace reference
            2.1≠nc:○○○                        ⍝ If we reached here, ⍵ must be a string.
            0=≢val:(⍎top)top                  ⍝ Null (or blank) string? Use <top>
          ⍝ Handle (⎕SE or #).[LIB], [LIB].mysub and [CALLER], calling env.
            name←LIB_PFX1p LIB_PFX2p CALR_PFXp ⎕R topDef deflib callerN⊣val
            nc←callerR.⎕NC⊂,name              ⍝ nc of name stored in lib w.r.t. caller.
            9.1=nc:{⍵(⍕⍵)}(callerR⍎name)      ⍝ name refers to active namespace. Simplify via ⍎.
            0=nc:callerN,'.',name             ⍝ Assume name refers to potential namespace...
            error∘∘∘                          ⍝ error!
        }⍵
    }libOpt

⍝------------------------------------------------------------------------------------
⍝  M A J O R    U T I L I T I E S
⍝------------------------------------------------------------------------------------
    TRACE←{                                  ⍝ Prints ⍺⍺ ⍵ if debugOpt. Always returns ⍵!
        0::⍵⊣⎕←'TRACE: APL trapped error ',⎕DMX.((⍕EN),': ',⎕EM)
        ⎕PW←9999
        ⍺←⊢
        debugOpt:⍵⊣⎕←⎕FMT ⍺ ⍺⍺ ⍵
        ⍵
    }

    ⍝ Converting names in form ⍵1 ⍵2 ... to APL or filesystem formats.
    ⍝ dunder:       fs or APL name → unique APL name (using double underscores, dunders).
    ⍝    Syntax:    ∇ ⍵1@str ⍵2@str ... → '__s1__s2'
    ⍝    Usage:     Used to record loading a specific name or directory into a standard library
    ⍝               under certain circumstances.
    ⍝    Ex:        a.b → '__a__b', a → '__a', 'a/b' → '__a__b', '##.fred' → '__fred',
    ⍝               ⎕SE.test → '__⍙SE__test', #.test → 'test'.
    ⍝    If ⍵ has any of '/.', split on it on the fly. Wholly ignore pkgList '##[.]' and '#[.]'.
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
    ⍝ noEmpty:     Remove empty file specs from colon-format string, string-initial, -medial, and -final.
    ⍝ symbols:     Replace [HOME], [FSPATH] etc in colon spec. with their environment variable value (getenv).
    ⍝ getenv:      Retrieve an env. variable value ⍵ in OS X
    ⋄ noEmpty←{{⍵↓⍨-':'=¯1↑⍵}{⍵↓⍨':'=1↑⍵}{⍵/⍨~'::'⍷⍵}⍵}
    ⋄ symbols←{'\[(HOME|FSPATH|WSPATH|PWD)\]'⎕R{getenv ⍵.(Lengths[1]↑Offsets[1]↓Block)}⊣⍵}
    ⍝ getenv: See Above.
    ⍝ resolveNs Ns@str: Return a reference for a namespace string with respect to callerR.
    ⍝                   Deals with '#', '##', '⎕SE' in a kludgey way (they aren't valid names, but #.what is.
    resolveNs←callerR∘{
        ''≡⍵~' ':⎕NULL
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
        dist←¯1++/callerN='.' ⋄ p←⍵⍳'↑' ⋄ w←⍵
      ⍝ Remove any extra up arrows
        '↑'~⍨(∊w)⊣w[p]←⊂{⍺←'' ⋄ ⍵>dist:⍺ ⋄ (⍺,' ',∊'##',⍵⍴⊂'.##')∇ ⍵+1}0
    }

  ⍝ resolvePath: Determines actual ordered path to search, based on callerR and ⎕PATH.
  ⍝ resolvePath:  allow non-existent namespaces to stay (since user may have other uses)
    resolvePath←{
        ⎕NULL~⍨∪resolveNs¨split⍣(1≥|≡⍵)⊣⍵
    }

  ⍝ ⍺ inNs ⍵:  Is object ⍺ found in namespace ⍵?
  ⍝    ⍺: String of form: a, b.a, c.b.a etc.  If 0=≢⍺: inNs fails.
  ⍝    ⍵: an namespace reference or name (interpreted wrt callerR).
    inNs←{
        0::'require/inNs: DOMAIN ERROR: Invalid namespace, library, or package'⎕SIGNAL ⎕DMX.EN
        0=≢⍺:0
        clr←callerR     ⍝ Dyalog bug Workaround: external callerR, used directly like this (callerR.⍎), won't be found.
        ns←clr.⍎⍣(⍬⍴2=⎕NC'ns')⊣ns←⍵
        0<ns.⎕NC ⍺      ⍝ ⍺ defined in ns?
    }

  ⍝ repkg: Convert a split-up package (in <e w d n> format) to a string
    repkg←{e w d n←⍵ ⋄ pkg←e,('::'/⍨0≠≢e),w,(':'/⍨0≠≢w),d,('.'/⍨0≠≢d),n}

  ⍝ map:   For ⍺ a split-up package and ⍵ a string, if ⍵ is non-null, return 2 strings:  (repkg ⍺)⍵
    map←{0=≢⍵:'' ⋄ (repkg ⍺)⍵}

  ⍝ See ADDFIXEDNAMESPACES above for more info.
  ⍝ ⍵ must be a name of an existing object in libR in string form.
  ⍝ If ADDFIXEDNAMESPACES=1, and if ⍵ refers to a namespace (⎕NC 9.1),
  ⍝ ⍵'s reference is added to PathNewR,
  ⍝ and ultimately to callerR.⎕PATH.
    add2PathIfNs←{~ADDFIXEDNAMESPACES:'' ⋄ 9.1≠libR.⎕NC⊂,⍵:'' ⋄ ⍵⊣PathNewR,⍨←libR⍎⍵}

  ⍝------------------------------------------------------------------------------------
  ⍝  E N D      U T I L I T I E S
  ⍝------------------------------------------------------------------------------------

  ⍝ Decode ⍵ → list of packages (possibly 0-length), each package a string (format below)
  ⍝ --------
  ⍝ From each item in packages of the (regexp with spaces) form:
  ⍝      (\w+::)?    (\w+:)? (\w+(\.\w+)*)\.)? (\w+)
  ⍝      ext         wsN     group             name
  ⍝ ext:  a filesystem extension (suffix) to add to path before testing whether group/name is found
  ⍝ wsN:  a full string ('abc.def:') | null string (':') | ⎕NULL (no wsN).
  ⍝ group may be a full string or null string (if omitted)
  ⍝ name must be present
    lastExt←''      ⍝ If a :: appears with nothing before it, the prior lastExt is used
    lastWs←''       ⍝ If a : appears ..., the prior lastWs is used!
    pkgList←{
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
    }¨∪pkgList                          ⍝ Remove duplicates w/o error-- process each pkg just once...

  ⍝ HOMEDIR-- see [HOME]
    HOMEDIR←getenv'HOME'
  ⍝ Process caller APL ⎕PATH → PathOrigR:  handling ↑, resolving namespaces (ignoring those that don't exist).
    PathOrigR←resolvePath('↑'∊callerR.⎕PATH)resolvePathUpArrow callerR.⎕PATH
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
  ⍝        e.g. if FSPATH includes:
  ⍝                   '.:lib1:lib2'
  ⍝        then       'mydir1:mydir1/mydir1a:[FSPATH]'
  ⍝               →   'mydir1:mydir2/mydir1a:.:lib1:lib':
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

    0=≢⍵:libR   ⍝ If no main right argument, return the library reference (default or user-specified)
    0∊≢¨pkgList~¨⊂'.: ':⎕SIGNAL/'require DOMAIN ERROR: at least one package string was empty.' 11
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

      ⍝------------------------------------------------------------------------------------
      ⍝ Is the package in the caller's namespace?
      ⍝ Check for <name>, <group.name>, and <wsN>.
      ⍝------------------------------------------------------------------------------------
        pkg←{
            forceOpt:⍵                                      ⍝ forceOpt? Don't even check caller
            0=≢⍵:⍵
            ext wsN group name←pkg←⍵
            stat←{
                ('__',wsN)inNs callerR:pkg map'ws∊CALLER'   ⍝ wsN found?   success
                name inNs callerR:pkg map'name∊CALLER'      ⍝ name found? success
                group≡'':''
                ~(group with name)inNs callerR:''           ⍝ none found? failure
                PathNewR,⍨←⊂resolveNs group                 ⍝ group.name found
                pkg map'group.name∊CALLER'                  ⍝ ...         success
            }⍵
            0=≢stat:pkg

            ''⊣(⊃status),←⊂stat
        }pkg
        0=≢pkg:status ∇ 1↓⍵                        ⍝ Fast path out. Otherwise, we short-circuit one by one

      ⍝------------------------------------------------------------------------------------
      ⍝ Is the package in the ⎕PATH?
      ⍝------------------------------------------------------------------------------------
        pkg←{
            0=≢⍵:⍵                                     ⍝ Short circuit.
            forceOpt:⍵                                 ⍝ forceOpt? Ignore path.
            ext wsN group name←pkg←⍵
            scanPath←{                                 ⍝ find pgk components in <path> or lib
                ⍺←'PATH'
                0=≢⍵:''                                ⍝ none found. pathEntry exhausted: failure
                pathEntry←⊃⍵
                pathInfo←⍺,' ',⍕pathEntry

              ⍝⍝ --------------------------------------------------------------------------------------
              ⍝⍝ If name is found in PathNewR, do we explicitly add to pathEntry? CHOICE (A)=YES, (B)=NOpt.
              ⍝⍝   PROS: pathEntry may have ↑ and the item may work for this caller ns, but not another
              ⍝⍝         that inherits its ⎕PATH.
              ⍝⍝   CONS: (1) pollutes ⎕PATH and (2) reorders items user explicitly put in pathEntry
              ⍝⍝ Description: For now, we leave out the update, choice (B).
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
                ~{(group with name)inNs pathEntry}and{9=libR.⎕NC group}0:∇ 1↓⍵ ⍝ Not found: try another pathEntry element
                PathNewR,⍨←⊂resolveNs(⍕pathEntry)with group ⍝ group.name found: ...
                'group→',pathInfo                           ⍝ ...         success
            }
          ⍝ Go through pathEntry, next item in PathNewR. If found, return success.
          ⍝ Otherwise, try libR (unless in PathNewR). If found, add libR to PathNewR.
            recurse←{
                ×≢r←scanPath∪PathNewR:r                ⍝ Check pathEntry. Found? Yes: Return status.
                libR∊PathNewR:''                       ⍝ No. If libR in PATHR, return ''.
                0=≢r←'STDLIB'scanPath libR:''          ⍝ Check libR?   Not found: ''
                r⊣PathNewR,⍨←libR                      ⍝ Found: Add libR to pathEntry and return status.
            }⍬
            0=≢recurse:pkg
            ''⊣(⊃status),←⊂pkg map recurse
        }pkg

      ⍝------------------------------------------------------------------------------------
      ⍝ Is the object in the named workspace?
      ⍝ If there is no object named, copy the <entire> workspace into the default library (lib).
      ⍝ creating the name <wsN> in the copied namespace, so it won't be copied in each time.
        pkg←{
            0=≢⍵:⍵                                     ⍝ Short circuit
            ext wsN group name←pkg←⍵
            0=≢wsN:⍵
            stat←wsN{
                0::''
                0≠≢⍵:'wsN:name→libOpt'⊣⍵(libR wsGetFix)⍺     ⍝ Copy in object from wsN
                _←(libR wsGetFix)⍺
                _←⍺{
                    libR.⍎(dunder ⍺),'←⍵'               ⍝ Copy in entire wsN <wsN>.
                }'Workspace ',⍺,' copied on ',⍕⎕TS               ⍝ Deposit in <lib> var  __wsN←'Workspace...'
                'ws→lib'
            }group with name
            0=≢stat:pkg
            PathNewR,⍨←libR                             ⍝ Succeeded: Add libR to path
            _←{'>>> Found in ws: ',repkg ⍵}TRACE ⍵
            ''⊣(⊃status),←⊂pkg map stat
        }pkg

      ⍝------------------------------------------------------------------------------------
      ⍝ Is the package in the file system path?
      ⍝ We even check those with a wsN: prefix (whenever the workspace is not found)
      ⍝ See FSSearchPath
      ⍝------------------------------------------------------------------------------------
        pkg←{
            0=≢⍵:⍵                                      ⍝ Short circuit
            ext wsN group name←pkg←⍵
            0∧.=≢¨group name:⍵
            dirFS←apl2FS group                          ⍝ Convert a.b→a/b, ##.a→../a
            shortDirName←USEHOMEDIR∘{
                ⍺:('\Q',HOMEDIR,'\E')⎕R'[HOME]'⊣⍵
                ⍵
            }
            recurse←{                                   ⍝ find pgk components in <path>.
                0=≢⍵:''                                 ⍝ none found. path exhausted: failure
                path←⊃⍵
                0=≢path:∇ 1↓⍵                           ⍝ NEXT!
                searchDir←path,('/'/⍨0≠≢ext),ext,'/',dirFS,('/'⍴⍨0≠≢dirFS),name
                searchFi←searchDir,'.dyalog'
                loadDir←{
                    group name←⍺
                    aplNs←group with name ⋄ fsDir←⍵
                    1≠⊃1 ⎕NINFO fsDir:'NOT A DIRECTORY: ',fsDir
                    names←⊃(⎕NINFO⍠1)fsDir,'/*.dyalog'    ⍝ Will ignore subsidiary directories...
                    0=≢names:aplNs{
                      ⍝ Put a 'loaded' flag in the libR ns for the empty dir.
                        stamp←'First group ',⍺,'found was empty on ',(⍕⎕TS),': ',⍵
                        _←(dunder ⍺)libR.{⍎⍺,'←⍵'}stamp
                        'empty group→lib: ',⍵
                    }fsDir
                    cont←''
                    ⍝ Returns 1 for each item ⎕FIXed, ¯1 for each item not ⎕FIXed.
                    ⍝ Like loadFi below...
                    load1Fi←{
                        0::¯1
                        fixed←libR fileGetFix ⍵    ⍝ On error, see 0:: above.
                        cont,←' ',,⎕FMT fixed ⋄ _←add2PathIfNs¨fixed
                        1
                    }
                    tried←load1Fi¨names
                    gwn←group with name
                  ⍝ Put a 'loaded' flag in the libR ns for the non-empty dir
                    stamp←gwn,' copied from dir: "',⍵,'" objects: {',cont,'} on ',⍕⎕TS
                    _←(dunder group name)libR.{⍎⍺,'←⍵'}stamp
                    res←'[group] ',gwn,'→lib: "',(shortDirName ⍵),'"'
                    res,←⎕TC[2],'   [Fixed: ',(⍕+/tried=1),' Failed: ',(⍕+/tried=¯1),']'
                  ⍝ Add libR to PathNewR if at least one object was loaded and  ⎕FIXED.
                    1∊tried:res⊣PathNewR,⍨←libR
                    res
                }
              ⍝ See also load1Fi, which has the same basic logic.
                loadFi←{
                    0::'❌file→lib found, but ⎕FIX failed: "',⍵,'"'
                    group name←⍺
                    gwn←group with name
                    id←dunder group name
                    fixed←libR fileGetFix ⍵
                    cont←,⎕FMT fixed ⋄ _←add2PathIfNs¨fixed
                  ⍝ Put a 'loaded' flag in libR for the loaded object.
                    stamp←gwn,' copied from file: "',⍵,'" objects: {',cont,'} on ',⍕⎕TS
                    _←id libR.{⍎⍺,'←⍵'}stamp
                    PathNewR,⍨←libR                ⍝ Succeeded: Note libR (if not already)
                    '[file] ',gwn,'→lib: "',(shortDirName ⍵),'"'
                }
                ⎕NEXISTS searchDir:(group name)loadDir searchDir
                ⎕NEXISTS searchFi:(group name)loadFi searchFi
                ∇ 1↓⍵                                     ⍝ NEXT!
            }FSPATH
            0=≢recurse:pkg
            ''⊣(⊃status),←⊂pkg map recurse
        }pkg
        pkg←{ ⍝ Any package <pkg> left must not have been found!
            0=≢⍵:''                                      ⍝ Short circuit
            ''⊣(⊃⌽status),←⊂pkg map'❌NOT FOUND'
        }pkg
        status ∇ 1↓⍵                                     ⍝ Get next package!
    }pkgList
    _←{
        _←''('>>Caller''s ⎕PATH was ',⍕callerR.⎕PATH)
        _,←('  PathOrigR: ',⍕PathOrigR)('>>PathNewR:  ',⍕∪PathNewR)
        ↑_
    }TRACE 0
  ⍝------------------------------------------------------------------------------------
  ⍝ DONE-- process outOpt options...
  ⍝ Update PATH, adding the default Library. Allow no duplicates, but names should be valid.
  ⍝ Prepend new items and merge with caller's ⎕PATH keeping relative ⎕PATH elements...
  ⍝ Here, we don't make sure callerR.⎕PATH entries are valid. Also ↑ is maintained.
  ⍝-------------------------------------------------------------------------------------
    callerR.⎕PATH←1↓∊' ',¨∪(⍕¨∪PathNewR),(split callerR.⎕PATH)
    succ←0=≢⊃⌽statusList
  ⍝ outOpt=¯2: If successful, return null, 1 or 0; else signal error. 
    succ∧outOpt=¯2:_←⍬
  ⍝ outOpt=¯1 'b[oolean]'  Return 1 on success else 0
    outOpt=¯1:succ
    succ∧outOpt∊3:_←{⍵}TRACE(⊂libR),statusList     ⍝ outOpt 3 (SL):   SUCC: shy     (non-shy if debugOpt)
    ⋄ outOpt∊3:0(⊂libR),statusList                 ⍝                FAIL: non-shy
    succ∧outOpt∊2 0:libR                           ⍝ outOpt 2 (L):    SUCC: non_shy
    ⋄ eCode1←'require DOMAIN ERROR: At least one package not found or not ⎕FIXed.' 11
    ⋄ outOpt∊2:⎕SIGNAL/eCode1                      ⍝                FAIL: ⎕SIGNAL
    succ∧outOpt∊1:_←{⍵}TRACE statusList            ⍝ outOpt 1|0 (S):  SUCC: shy     (non-shy if debugOpt)
    ⋄ outOpt∊¯2 1 0:statusList                     ⍝                FAIL: non-shy
    ⎕SIGNAL/('require DOMAIN ERROR: Invalid outOpt: ',⍕outOpt)11   ⍝ ~outOpt∊0 1 2 3
}
