 {rWhere}←{opts} ∆REQ  objs
 ;⎕IO;⎕ML
 ;count;debugÔ;dir;dirSearchPath;fileName;fileList;fileId;fileIx;found;fnd;forceÔ;hasÔ;CALLENV;CE_PATH
 ;i;libNsDotObj;mainNsDef;memPath;mem;oNC;obj;objList;objIx;opt;Pad;path;rLibNs;rMainNs;rNewLibsRefs
 ;searchPathÔ;setPathÔ;status;stat;sSubNs;subNsDef;verboseÔ;rWhere
 ;ExpandSearchToPath;DebugMsg;Import⍙Directory;Fix2Group;OF;ScanFileSpecs;Update⍙Directory
 ;notFoundOkÔ   ⍝Experimental

  ⍝ Defaults
  ⎕IO ⎕ML←0 1
  mainNsDef subNsDef←⎕SE'⍙⍙.⍙'        ⍝ ...D: Defaults
  
⍝ Get search path from FSPATH if present, else WSPATH, else '.:..'
  dirSearchPath←'.' '..'{
      Get←{2 ⎕NQ'.' 'GetEnvironment' ⍵} 
      0=≢⍵: ⍺
      0≠≢p←Get ⊃⍵: ∪':'(≠⊆⊢)⊣p  ⋄ ⍺ ∇ 1↓⍵
  }'FSPATH' 'WSPATH' 

  :IF 1≥|≡objs ⋄ objs←' '(≠⊆⊢),objs ⋄ :ENDIF

  ⍝ CALLENV: See next line.
  ⍝ opts: If ⎕NC 9, it is the default calling environment (CALLENV); else CALLENV is set from (⊃⎕RSI,mainNsDef).
  ⍝       If     0, it is set from first args of objs (contiguous objs on left with initial hyphens)
  ⍝       Else   2, so all tokens are options, w/ initial hyphens optional.
  CALLENV←⎕RSI{⍵: opts ⋄ ⊃⍺,mainNsDef }9=oNC←⎕NC 'opts'
  :IF oNC∊0 9
      opts objs←''{0=≢⍵:⍺ ⍵ ⋄ '-'≠1↑first←0⊃⍵:⍺ ⍵ ⋄ (⍺,' ',first)∇ 1↓⍵}objs 
  :ENDIF
  
  ⍝ Save CALLENV.⎕PATH into CE_PATH now; allows detection of changes to ⎕PATH when ⎕FIXing objects (See <PathChange> below)
  ⍝ We allow those changes, but warn (since they can mess things up).
  CE_PATH←CALLENV.⎕PATH                

⍝ Utilities
  Pad←{⍺←10 ⋄ ⍺>≢⍵:⍵↑⍨-⍺ ⋄ ⍵}
  DebugMsg←{⍺←0 ⋄ debugÔ∨⍺: ⎕←'∆REQ: ',⍵ ⋄ 1:_←⍬}
  ExpandSearchToPath←{UP←⊂,'↑' ⋄ env path0←⍺ ⍵
      path←' '(≠⊆⊢)env.⎕PATH
      GetRef←path0∘{∪⍺,(0≠≢¨⍵)/⍵}{6::⍬ ⋄ 9=⎕NC'⍵':⍵ ⋄ ⍎⍵}¨  ⍝ Returns ns ref from string or ref, else ⍬
      Climb←{⍵.##≡⍵:⍺ ⋄ (⍺,⍵.##)∇ ⍵.##}⍨                ⍝ Returns all namespaces between ⍵ and the top level inclusive!
      ~UP∊path:GetRef path
      GetRef ⍬{0=≢⍵:⍺ ⋄ UP≢⊂⊃⍵:(⍺,⊂⊃⍵)∇ 1↓⍵ ⋄ (⍺,Climb env)∇ 1↓⍵}path
  }
⍝ ScanFileSpecs:  fileIds@VS ← fileName@S ∇ fileExtensions@VS
  ScanFileSpecs←{GetFileNames←0∘(⎕NINFO⍠1)
      fnd←(⎕NEXISTS⍠1)fiSpecs←⍺∘,¨⍵
      1(~∊)fnd:⍬ ⋄ fiIds←⊃,/⊃¨⊆GetFileNames fnd/fiSpecs
      0=+/≢fiIds:⍬ ⋄ fiIds
  }
⍝ Fix2Group-- Fix named objects.
⍝             Each ⍵ may return multiple obj names; ∇ returns a flat list (of depth 2).
  Fix2Group←{
        PathChange←{
            CE_PATH≡CALLENV.⎕PATH: ⍵ 
            ⍵⊣⎕←'∆REQ WARNING: ',(⍕CALLENV),'.⎕PATH changed while ⎕FIXing file(s) in: ',⍕⍵
        }
        0/⍨~debugÔ::⎕SIGNAL/⎕DMX.(EM EN) ⋄ _←DebugMsg'⎕FIXing: '('file://'∘,¨⊆⍵)
        PathChange ⊃,/2∘⍺.⎕FIX¨'file://'∘,¨⊆⍵
  }
⍝ Directory Services: provide fast search for objects
⍝ Call:     (force@B rlibNs@Ns) ∇ objs@SV
⍝ Returns:  done @B rWhere@NsV
⍝           done:   1 if all objs were found, else 0.
⍝           rWh:    namespace (ref) where each object is found, or ⎕NULL.
⍝ ⍙Directory: [0] list of objects; [1] their locations (else ⎕NULL-- 1 more item than [0] contains)
  Import⍙Directory←{
      0/⍨~debugÔ::11 ⎕SIGNAL⍨'require: LOGIC ERROR- Invalid ⍙Directory format in ns ',⍕rLibNs
      (force rLibNs)objs←⍺ ⍵
      case←rLibNs.⎕NC'⍙Directory' ⋄ no⍙Dir valid⍙Dir←0 2 ⋄ noneFound←0((≢objs)⍴⎕NULL)
      ScanForObjs←{⍺≡⎕NULL:0 ⋄ 0<⍺.⎕NC ⍵}¨
        ⍝ Look for valid directory. If none, initialize...
      case=no⍙Dir:noneFound⊣{⍵.⍙Directory←⍬(,⎕NULL)}rLibNs
      case≠valid⍙Dir:11 ⎕SIGNAL⍨'require: LOGIC ERROR- Invalid ⍙Directory type in ns ',⍕rLibNs
      force:noneFound                      ⍝ Even if force, ensure directory exists (used later).
        ⍝ Scan directory (that exists) for objects
      dir←rLibNs.⎕OR'⍙Directory'
      rWh←(1⊃dir)[objs⍳⍨0⊃dir]
      done←0(~∊)rWh ScanForObjs objs
      done:1 rWh⊣DebugMsg'All objects located in fast directory table: ',(⍕rLibNs),'.⍙Directory'
      0 rWh
  }
  Update⍙Directory←{
      oOut wOut←⍺,⍨¨⍵ ⋄ kp←⎕NULL≠¯1↓wOut ⋄ ⍝ Keep only those objects found...
      scan←kp∧≠oOut ⋄ (oOut/⍨scan)(wOut/⍨scan,1)
  }

⍝ Process OPTIONS-- see Options in Brief (below).
 debugÔ verboseÔ rMainNs searchPathÔ setPathÔ forceÔ sSubNs rWhere notFoundOkÔ←{
     ⍵}0 0 mainNsDef 1 1 0 subNsDef ⍬ 0
 :For opt :In ⎕C opts←' '(≠⊆⊢)opts~'-'                ⍝ Ignore case and hyphens here...
     OF←(≢opt)∘{l←(l<≢⍵)×l←⍵⍳'(' ⋄ (1⌈l⌈⍺)↑⍵~'('}∘⎕C
     :Select opt  ⍝ Ordered approx. by likelihood. Left paren shows minimal abbrev.
        ⍝  Non-defaults
     :Case OF'root' ⋄ rMainNs←# ⋄ :Case OF'local' ⋄ rMainNs←CALLENV
     :Case OF'NOp(refix' ⋄ sSubNs←''
     :Case OF'NOsea(rchpath' ⋄ searchPathÔ←0 ⋄ :Case OF'NOset(path' ⋄ setPathÔ←0
     :Case OF'verbose' ⋄ verboseÔ←1 ⋄ :Case OF'debug' ⋄ debugÔ←1
     :Case OF'force' ⋄ forceÔ←1 ⋄ :Case OF'nf(OK' ⋄ notFoundOkÔ←1
        ⍝ Defaults
     :Case OF'ses(sion' ⋄ rMainNs←⎕SE ⋄ :Case OF'p(refix' ⋄ sSubNs←subNsDef
     :Case OF'sea(rchpath' ⋄ searchPathÔ←1 ⋄ :Case OF'set(path' ⋄ setPathÔ←1
     :Case OF'NOv(erbose' ⋄ verboseÔ←0 ⋄ :Case OF'NOf(orce' ⋄ forceÔ←0
     :Case OF'NOnf' ⋄ notFoundOkÔ←0
     :Case OF'help'
         ']require and ⎕SE.∆REQ: HELP INFORMATION'
         'Description: Checks if required APL objects are in a local library* or loads them from file or workspace'
         '   Returns the local library. As a side effect (see -NOSETpath), ensures the library is in the search ⎕PATH '
         '   in the calling environment.'
         '--------------------------'
         '   [*] By "local library", we mean the namespace from which require is called, ⎕SE or #.'
         'Syntax:'
         '   {libNS} ←[optsL | altCallEnv] require [-optsR] argsR'
         '           optsL:If optsL is present, but not a namespace, '
         '                       it must be a single string with space-separated options, with optional hyphen (-) prefixes. '
         '                 If omitted , <opts> are contained in argsR. See below'
         '           altCallEnv: If optL is a namespace, it will be used for the local path. See -local'
         '           argsR: If a string, it is split on spaces into a vector of strings'
         '                  If opts not defined in optsL, opts are the initial strings of argsR:'
         '           optsR: If opts not set in optsL, opts are optionally set from the leading strings'
         '                       of argsR, left to right, ending before the first without a hyphen (-) prefix.'
         '           objs:  one or more strings of argsR after the last option in optsR'
         'Syntax Summary:'
         '    {libNs} ← ''[-]opt1 [[-]opt2 ...]'' require ''obj1 [obj2] ...'''
         '    {libNs} ← [altCallEnv@Ns]         require '' [-opt1 [-opt2] ...] obj1 [obj2] ... '''
         '                                      require '' [-opt1 [-opt2] ...] obj1 [obj2] ... '''
         '                                      require ''-help''    ⍝ To view this help information.'
         '   opts:'
         '      -[SESsion* | -Root | -Local]'
         '      -[no]Prefix*       -[no]SEArchpath*'
         '      -[no]SETpath*      -[no*]Force'
         '      -nonf | nfok       ⍝ Experimental: return ⎕NULL for missing obj'
         '      -help              -[no*]Verbose      -Debug'
         ''
         '+------------------+'
         '+ Options in Brief +'
         '+------------------+'
         '   DEFAULTS... |  ALTERNATIVES ...      | IN BRIEF...'
         '   -Session    |  -Root  |  -Local      | What ns to put library in (NS): ⎕SE # or calling environment.'
         '   -Prefix     |  -NOPrefix             | Put objs in sub-library ⍙⍙.⍙ vs above ns directly'
         '   -SEArchpath |  -NOSEArchpath         | Search entire ⎕PATH for objs'
         '   -SETpath    |  -NOSETpAth            | Update ⎕PATH on success'
         '   -NOVerbose  |  -Verbose              | Provide details on search'
        '    -NODebug    |  -Debug                | Provide debugging info when searching mem and file sys for objects.'
         '   -NOForce    |  -Force                | Update from disk even if objs found on ⎕PATH?'
         '   -NoNF       |  -NFok                 | NOT FOUND? let the fn return ⎕NULL for missing objs, rather than ⎕SIGNALING.'
         ''
         'Notes:'
         '   ∘ Default library location: ⎕SE (alternatives: # if -Root, calling namespace if -Local).'
         '   ∘ Default library name: ⍙⍙.⍙    (none, if -noPrefix).'
         '   ∘ Defaults are indicated by an asterisk (*) above.'
         '   ∘ For options, case is ignored. Options may appear as left arg or as first/leading right args.'
         '   ∘ Objects may be passed in one string ,separated by blanks, or as a vector of 1 or more strings (one per object).'
         '   ∘ Objects must be valid APL user names, simple or hierarchical (like.this); never system names (like ⎕THIS).'
         '   ∘ If the first item in a vector of strings starts with a hyphen, that entire item will be treated as options,'
         '     but only if there is no explicit left argument (options).'
         '   ∘ If -SEArchpath is specified, the entire "local"namespace, local search ⎕PATH, and the library are searched for objects.'
         '     If -noSEArpath, only the "local" namespace and the library are searched.'
         '   ∘ If an obj is found, but cannot be fixed via 2∘⎕FIX, an error is ⎕SIGNALled no matter what.'
         '   ∘ Experimental:'
         '     If -nfok is specified, returns ⎕NULL elements for missing objs, rather than ⎕SIGNALling failure.'
         'Options for the Standard Library Namespace'
         '[Option -local assumes that require happened to be called from namespace #.mylib]'
         '   ∘   Option 1  Option 2     Std Library     Notes'
         '   ∘   -session  -prefix      ⎕SE.⍙⍙.⍙        Defaults: -session and -prefix'
         '       -session  -noprefix    ⎕SE             Default:  -session'
         '   ∘   -root     -prefix      #.⍙⍙.⍙          Defaults:              -prefix'
         '       -root     -noprefix    # '
         '   ∘   -local    -prefix      #.mylib.⍙⍙.⍙  '
         '       -local    -noprefix    #.mylib       '
         '' ⋄ :Return
     :Else ⋄ 11 ⎕SIGNAL⍨'require: For help, type "require ''-help''".',(⎕UCS 13),'Unknown option: ',opt
     :EndSelect
 :EndFor
 :IF 0=≢objs ⋄ ⎕SIGNAL/'require: no objects to require?' 11 ⋄ :Endif 

  ⍝ Scan ⍵.⎕PATH, returning a list of references, resolving ↑ and ignoring undefined namespaces.
  ⍝ Return <mempath>, ⎕PATH references prepended by rLibNs (our library)...
 rLibNs←⍎sSubNs rMainNs.⎕NS ⍬     ⍝ If sSubNs is '', returns reference to rMainNs

   ⍝ rWhere:        ns where found or ⎕NULL, if not.
 found rWhere←forceÔ rLibNs Import⍙Directory objs   ⍝ initializes rWhere
 :If found ⋄ :Return ⋄ :EndIf
   ⍝ status contains ints: 2= Found in filesys, 1= found in APL space, 0= not found, ¯1= Invalid Name.
 status←(≢objs)⍴0
 memPath←CALLENV ExpandSearchToPath⍣searchPathÔ⊣CALLENV rLibNs
 :If verboseÔ ⋄ 'Memory path is    ',memPath ⋄ 'Directory path is ',dirSearchPath ⋄ :EndIf

   ⍝ Scan for objs in APL namespaces <memPath>, unless forceÔ.   If found, skip filesys scan.
 :If ~forceÔ
     :For i :In ⍳≢objs   ⍝ Search memPath namespaces for <obj>
         obj←i⊃objs
         :For mem :In memPath
             found←×mem.⎕NC obj         ⍝ found ∊ 1 (found), 0 (not found), ¯1 (malformed name)
             :If 0≠found                ⍝ 1 or ¯1
                 status[i]←found
                 :If found=1
                     rWhere[i]←mem
                      ⋄ DebugMsg'>>> In memory: ',obj,' at ',⍕mem
                 :EndIf
                 :Leave ⍝ :FOR mem :IN memPath
             :EndIf
         :EndFor
     :EndFor
 :EndIf
  ⍝ Error if any obj names are invalid.
 :If ¯1∊status ⋄ 11 ⎕SIGNAL⍨'require: Invalid object name(s): ',⍕objs/⍨¯1=status ⋄ :EndIf

 rNewLibsRefs←rLibNs
 :For dir :In dirSearchPath
     :For objIx :In ⍳≢objs
         found←0
         :If rWhere[objIx]≠⎕NULL ⋄ :Continue ⋄ :EndIf
         obj←objIx⊃objs
          ⍝ Obj name of form OBJL.OBJR. See [OBJ FORMS] below.
         fileName←dir,'/',('/'@('.'∘=)⊣obj)
          ⍝ OBJ FORMS: (A) OBJ is simple name, e.g. "this"; (B) OBJ has embedded dots, e.g. "this.that".
          ⍝ (A) Search for files DIR/this.dyalog, DIR/this.apl?      & dirs DIR/this/*.dyalog, DIR/this/*.apl?
          ⍝ (B) Search for files DIR/this/that.dyalog, DIR/this.apl? & dirs DIR/this/that/*.dyalog, DIR/this/that/*.apl?
          ⍝ The following file types are associated with various source code management tools.
          ⍝    .dyalog (generic),
          ⍝    .aplf (functions), .aplo (operators), .apln (namespaces), .aplc (classes), .apli (interfaces),
          ⍝    .apla (serialised arrays for Link).
          ⍝ We accept all as direct input to 2∘⎕FIX.
          ⍝ +---------------+
          ⍝ | Scan Type I.  | OBJ is a file in directory DIR.
          ⍝ +---------------+ If any object SUB found in file OBJ fixes as a namespace, include that namespace in ⎕PATH.
          ⍝                   I.e. if SUB is so fixed, add DIR.SUB to ⎕PATH.
         :If ×≢fileList←fileName ScanFileSpecs'.dyalog' '.apl?'
             found←1
             :If 1<≢fileList
                 '∆REQ WARNING: [',(⍕objIx),'] ','Processing multiple Objects WITH NAME "',(obj),'": ',∊fileList
             :EndIf
             :For fileId :In fileList
                 objList←rLibNs Fix2Group fileId
                  ⋄ DebugMsg'[',(⍕objIx),'] ','            Object ',(Pad obj),' found: ',fileId
                  ⋄ DebugMsg'obj name: ',fileId
                  ⋄ DebugMsg'Loaded into',rLibNs,':',objList
                 :If 1∊fnd←∊9.1=rLibNs.⎕NC objList
                     rNewLibsRefs,←rLibNs⍎¨fnd/objList
                      ⋄ DebugMsg'Obj "',(1↓¯1↓⍕objList),'" is a namespace. Adding to newLibRefs'
                 :EndIf
             :EndFor
             rWhere[objIx]←rLibNs ⋄ status[objIx]←2
         :EndIf
            ⍝ +---------------+
            ⍝ | Scan Type II. | OBJ is a directory in directory DIR.
            ⍝ +---------------+ If any object SUB found in DIR/OBJ fixes as a namespace, include that namespace in ⎕PATH.
            ⍝                   I.e. if SUB is so fixed, add DIR.OBJ.SUB to ⎕PATH.
         :If ~found ⋄ :AndIf ×≢fileList←fileName ScanFileSpecs'/*.dyalog' '/*.apl?'
             found←1
             objList←libNsDotObj Fix2Group fileList
             libNsDotObj←⍎obj rLibNs.⎕NS''
              ⋄ DebugMsg'[',(⍕objIx),'] ',(3 Pad⍕+/≢fileList),' objects for ns ',(Pad obj),' found: ',fileList
             DebugMsg'dir name: ',obj ⋄ DebugMsg'Fixing objects: ',fileList
             :If 1∊fnd←∊9.1=libNsDotObj.⎕NC objList
                 DebugMsg'Obj "',(1↓¯1↓⍕objList),'" is 1 or more namespaces. Adding to newLibRefs'
                 rNewLibsRefs,←libNsDotObj⍎¨fnd/objList
             :EndIf
              ⋄ DebugMsg'Loaded into ',(⍕libNsDotObj),':',objList
         :EndIf
         :If ~found ⋄ :Leave ⋄ :EndIf
         rWhere[objIx]←rLibNs ⋄ status[objIx]←2
     :EndFor ⍝ :FOR objIx :IN ⍳≢ objs
 :EndFor  ⍝ :FOR dir :IN dirSearchPath

 :If setPathÔ  
  ⍝ APPEND NEW ITEMS ⍵ AFTER EXISTING ⎕PATH items: ⍺ 
  ⍝ Note:  Doesn't protect against ⎕FIXed functions changing ⎕PATH, though a warning is issued above.
  ⍝        To prevent this, set protect←1 in the next line (default: protect←0).
     CALLENV.⎕PATH←{ protect←0  
         old new←{' '(≠⊆⊢)⍣(1≥|≡⍵)⊣⍵}¨(protect⊃CALLENV.⎕PATH CE_PATH) ⍵ ⋄ 1↓∊' ',¨∪old,new
     }⍕¨rNewLibsRefs
 :EndIf

 :If verboseÔ
     ⎕SHADOW'CShow' ⋄ CShow←{0=≢⍵:⍺'[none]' ⋄ ⍺ ⍵}
     'opts     'opts
     'verbose  'verboseÔ ⋄ 'library  'rLibNs ⋄ 'objs     'objs
     'mem srch 'memPath ⋄ 'fi  srch 'dirSearchPath ⋄ 'setPathÔ   '(setPathÔ⊃'OFF' 'ON')
     ⍞←'⎕PATH IS:'('''','''',⍨CALLENV.⎕PATH) ⋄ :If setPathÔ ⋄ :AndIf CE_PATH≢CALLENV.⎕PATH
         ⍞←'     WAS:'('''','''',⍨CE_PATH) ⋄ :EndIf
     'Objects Found...'
     '  In mem:     'CShow(objs/⍨1=status)
     '  On disk:    'CShow(objs/⍨2=status)
     '  Not found:  'CShow(objs/⍨0=status)    ⍝ Only if -NFok option set.
     'objs \ rWhere '(objs,[-0.2]rWhere)
 :EndIf

  ⍝ Add new items to start of ⍙Directory in rLibNs so most recent items found fastest...
 rLibNs.⍙Directory Update⍙Directory←objs rWhere
  ⍝ :IF -NFok set, objs may contain names not found! rWhere will contain corresponding ⎕NULLs.
 :If ~notFoundOkÔ ⋄ :AndIf ⎕NULL∊rWhere
     911 ⎕SIGNAL⍨'require: Required objects not found:',,⎕FMT objs/⍨rWhere∊⎕NULL
 :EndIf
