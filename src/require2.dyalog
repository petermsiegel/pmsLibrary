∇ {rWhere}←{opts} require2 objs
   ;⎕IO;⎕ML   
   ;count;debugÔ;dir;dirSearchPath;fileName;fileList;fileId;fileIx;found;fnd;forceÔ;hasÔ;here;rLibNs;libNsDotObj
   ;rMainNs;mainNsD;memPath;mem;rNewLibsRefs;obj;objList;objIx;oldPath;opt;Pad;searchPathÔ;setPathÔ;status
   ;stat;sSubNs;subNsD;verboseÔ;rWhere;wh 
   ;DebugMsg;Import⍙Directory;Fix2Group;OF;ScanFileSpecs;Update⍙Directory
   ;notFoundOkÔ   ⍝Experimental 

  ⍝ Defaults
    ⎕IO ⎕ML←0 1
    mainNsD subNsD←⎕SE  '⍙⍙.⍙'        ⍝ ...D: Defaults
    here←⊃⎕RSI, mainNsD
    dirSearchPath←∪⊃,/{':' (≠⊆⊢) 2 ⎕NQ'.' 'GetEnvironment'⍵}¨'FSPATH'   'WSPATH'

    :IF 1≥|≡objs ⋄ objs←' ' (≠⊆⊢),objs ⋄ :ENDIF
    :IF  (900⌶)0 ⋄ opts objs←''{ 0=≢⍵:⍺ ⍵ ⋄  '-'≠1↑first←0⊃⍵ : ⍺ ⍵ ⋄ (⍺,' ',first) ∇ 1↓⍵ } objs ⋄ :ENDIF

  ⍝ Utilities
    Pad←{⍺←10 ⋄ ⍺>≢⍵: ⍵↑⍨-⍺ ⋄ ⍵}
    DebugMsg←{⍺←0 ⋄ debugÔ∨⍺: ⎕←'>>> ',⍵ ⋄ 1: _←⍬}  
  ⍝ ScanFileSpecs:  fileIds@VS ← fileName@S ∇ fileExtensions@VS
    ScanFileSpecs←{  GetFileNames←0∘(⎕NINFO ⍠1)
      fnd←(⎕NEXISTS⍠1)fiSpecs←⍺∘,¨⍵
      1(~∊)fnd:     ⍬ ⋄ fiIds←⊃,/⊃¨⊆GetFileNames fnd/fiSpecs
      0=+/≢fiIds:   ⍬ ⋄ fiIds
    }
  ⍝ Fix2Group-- Fix named objects.
  ⍝             Each ⍵ may return multiple obj names; ∇ returns a flat list (of depth 2).
    Fix2Group←{
        0/⍨~debugÔ:: ⎕SIGNAL/⎕DMX.(EM EN) 
        _←1 DebugMsg '⎕FIXing: ' ('file://'∘,¨⊆⍵) ⋄ ⊃,/2∘⍺.⎕FIX¨'file://'∘,¨⊆⍵ 
    }   
   ⍝ Directory Services: provide fast search for objects
   ⍝ Call:     (force@B rlibNs@Ns) ∇ objs@SV
   ⍝ Returns:  done @B rWhere@NsV
   ⍝           done:   1 if all objs were found, else 0.
   ⍝           rWh:    namespace (ref) where each object is found, or ⎕NULL.
   ⍝ ⍙Directory: [0] list of objects; [1] their locations (else ⎕NULL-- 1 more item than [0] contains)
    Import⍙Directory←{
        0/⍨~debugÔ:: 11 ⎕SIGNAL⍨'require2: LOGIC ERROR- Invalid ⍙Directory format in ns ',⍕rLibNs
        (force rLibNs) objs←⍺ ⍵ 
        case←rLibNs.⎕NC '⍙Directory' ⋄ no⍙Dir valid⍙Dir←0 2 ⋄ noneFound←0 ((≢objs)⍴⎕NULL)
        ScanForObjs← {⍺≡⎕NULL: 0 ⋄ 0<⍺.⎕NC ⍵ }¨
      ⍝ Look for valid directory. If none, initialize...
        case=no⍙Dir:    noneFound⊣ {⍵.⍙Directory←⍬ (,⎕NULL)}rLibNs 
        case≠valid⍙Dir: 11 ⎕SIGNAL⍨'require2: LOGIC ERROR- Invalid ⍙Directory type in ns ',⍕rLibNs
        force:          noneFound                      ⍝ Even if force, ensure directory exists (used later).
      ⍝ Scan directory (that exists) for objects
        dir←rLibNs.⎕OR '⍙Directory'
        rWh←(1⊃dir)[objs⍳⍨0⊃dir]                        
        done←0(~∊)rWh ScanForObjs objs                  
        done: done rWh ⊣ 1 DebugMsg 'All objects located in fast directory table: ',(⍕rLibNs),'.⍙Directory'
        done rWh 
    }
    Update⍙Directory←{
        oOut wOut←⍺,⍨¨⍵  ⋄ kp←⎕NULL≠¯1↓wOut ⋄ ⍝ Keep only those objects found...
        scan←kp∧≠oOut ⋄ (oOut/⍨scan) (wOut/⍨scan,1)
    }
    

  ⍝ Process OPTIONS
  ⍝    DEFAULTS... |  ALTERNATIVES ...      | IN BRIEF...
  ⍝    -Session    |  -Root  |  -Local      | What ns to put lib (NS)
  ⍝    -Prefix     |  -NOPrefix             | Put objs in ns directly or sub-library (NS)
  ⍝    -SEArchpath |  -NOSEArchpath         | Search entire ⎕PATH for objs
  ⍝    -SETpath    |  -NOSETpAth            | Update ⎕PATH on success
  ⍝    -NOVerbose  |  -Verbose              | Provide details on search  
  ⍝    -NODebug    |  -Debug                | Provide debugging info when searching mem and file sys for objects.     
  ⍝    -NOForce    |  -Force                | Update from disk even if objs found on ⎕PATH?
  ⍝    -NoNF       |  -NFok                 | NOT FOUND? let the fn return ⎕NULL for missing objs, rather than ⎕SIGNALING
  ⍝ An option's case is ignored; when specified as main fileName left arg, each option may omit the initial hyphen.
    debugÔ verboseÔ rMainNs  searchPathÔ setPathÔ forceÔ sSubNs  rWhere notFoundOkÔ ←{
⍵}  0      0        mainNsD  1           1        0      subNsD  ⍬      0  
    :FOR opt :IN ⎕C opts←' '(≠⊆⊢)opts ~'-'
        OF←(≢opt)∘{l←(l<≢⍵)×l←⍵⍳'(' ⋄ (1⌈l⌈⍺)↑⍵~'('}
        :SELECT opt  ⍝ Ordered approx. by likelihood. Left paren shows minimal abbrev.
          :CASE OF 'verbose'        ⋄ verboseÔ←1     ⋄  :CASE OF 'root'           ⋄ rMainNs←#
          :CASE OF 'local'          ⋄ rMainNs←here   ⋄  :CASE OF 'nop(refix'      ⋄ sSubNs←''
          :CASE OF 'nosea(rchpath'  ⋄ searchPathÔ←0  ⋄  :CASE OF 'noset(path'     ⋄ setPathÔ←0
          :CASE OF 'force'          ⋄ forceÔ←1       ⋄  :CASE OF 'debug'          ⋄ debugÔ←1  
          :CASE OF 'set(path'       ⋄ setPathÔ←1     ⋄  :CASE OF 'nov(erbose'     ⋄ verboseÔ←0   
          :CASE OF 'nof(orce'       ⋄ forceÔ←0       ⋄  :CASE OF 'p(refix'        ⋄ sSubNs←subNsD   
          :CASE OF 'ses(sion'       ⋄ rMainNs←⎕SE    ⋄  :CASE OF 'sea(rchpath'    ⋄ searchPathÔ←1   
          :CASE OF 'nf(ok'          ⋄ notFoundOkÔ←01 ⋄  :CASE OF 'nonf'           ⋄ notFoundOkÔ←0  
          :CASE OF 'help'
            'require2: HELP INFORMATION'
            'Description: Checks if required APL objects are in a local "library" or loads them from file or workspace'
            '   Returns the local library. As a side effect, ensures the local library is in the local ⎕PATH.'
            '   (By "local" (namespace), we mean the namespace from which require2 is called).'
            'Syntax:'
            '   {libNS} ← {opts} require2 [ ''<opts> obj1 obj...'' | [''opts''] ''obj1'' ''obj'' ... ]'
            '   opts:'
            '      -[SESsion* | -Root | -Local]'
            '      -[no]Prefix*       -[no]SEArchpath*'
            '      -[no]SETpath*      -[no*]Force'
            '      -nonf | nfok       ⍝ Experimental: return ⎕NULL for missing obj'
            '      -help              -[no*]Verbose      -Debug'
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
            '   ∘   Option 1  Option 2     Std Library     Notes'
            '   ∘   -session  -prefix      ⎕SE.⍙⍙.⍙        Defaults: -session and -prefix'  
            '       -session  -noprefix    ⎕SE             Default:  -session'
            '   ∘   -root     -prefix      #.⍙⍙.⍙          Defaults:              -prefix'
            '       -root     -noprefix    #               '
            '   ∘   -local    -prefix      #.mylib.⍙⍙.⍙    This example: if require called from namespace #.mylib.'
            '       -local    -noprefix    #.mylib         Ditto' 
            '' ⋄ :RETURN
          :ELSE ⋄ 11 ⎕SIGNAL⍨'For help, type "require2 ''-help''".',(⎕UCS 13),'Unknown option: ',opt
        :ENDSELECT
    :ENDFOR

  ⍝ Scan ⍵.⎕PATH, returning a list of references, resolving ↑ and ignoring undefined namespaces.
  ⍝ Return <mempath>, ⎕PATH references prepended by rLibNs (our library)...
    rLibNs←⍎sSubNs rMainNs.⎕NS ⍬     ⍝ If sSubNs is '', returns reference to rMainNs

   ⍝ rWhere:        ns where found or ⎕NULL, if not.
    :IF stat  ⊣ stat rWhere←forceÔ rLibNs Import⍙Directory objs 
         :RETURN 
    :ENDIF 
   
   ⍝ status contains ints: 2= Found in fs, 1=found in APL space, 0= not found, ¯1= Invalid Name. 
    status←(≢objs)⍴0 

    memPath← here rLibNs
    :IF searchPathÔ         
        memPath←memPath{UP←⊂,'↑'
            path←' '(≠⊆⊢)⍵.⎕PATH
            GetRef←⍺∘{∪⍺,(0≠≢¨⍵)/⍵}{6::⍬ ⋄ 9=⎕NC'⍵':⍵ ⋄ ⍎⍵}¨  ⍝ Returns ns ref from string or ref, else ⍬
            Climb←{⍵.##≡⍵:⍺ ⋄ (⍺,⍵.##)∇ ⍵.##}⍨                ⍝ Returns all namespaces between ⍵ and the top level inclusive!
            ~UP∊path:GetRef path
            GetRef ⍬{0=≢⍵:⍺ ⋄ UP≢⊂⊃⍵:(⍺,⊂⊃⍵)∇ 1↓⍵ ⋄ (⍺, Climb here)∇ 1↓⍵}path
        }here
    :ENDIF

    :IF verboseÔ
        'Memory path is    ',memPath
        'Directory path is ',dirSearchPath
    :EndIf 

  ⍝ Scan for objs in APL namespaces <memPath>, unless forceÔ.   If found, skip filesys scan.   
    :IF ~forceÔ
        :FOR i :IN ⍳≢objs   ⍝ Search memPath namespaces for <obj>
            obj←i⊃objs  ⋄ stat←0 ⋄ wh←⎕NULL  
            :FOR mem :IN memPath   
                :IF stat=0
                :ANDIF 1=stat←×mem.⎕NC obj      ⍝ stat∊ 1 (found), 0 (not found), ¯1 (bad name-- leave)
                    wh←mem
                    ⋄ DebugMsg '>>> In memory: ',obj,' at ',⍕wh
                :ENDIF
                :IF stat≠0 ⋄ :LEAVE ⋄ :ENDIF    ⍝ Don't keep looking if found or invalid name.
            :ENDFOR
            status[i]←stat  ⋄ rWhere[i]←wh
        :ENDFOR
    :ENDIF
  ⍝ Error if any obj names are invalid.
    :IF  ¯1∊status ⋄ 11 ⎕SIGNAL⍨'Invalid object name(s): ',⍕objs/⍨¯1=status ⋄ :ENDIF

    rNewLibsRefs←rLibNs
    :FOR dir :IN dirSearchPath
        :FOR objIx :IN ⍳≢ objs
            found←0
            :IF rWhere[objIx]≠⎕NULL ⋄ :continue ⋄ :ENDIF
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
            :IF ×≢fileList←fileName ScanFileSpecs '.dyalog' '.apl?'
                found←1
                :IF 1<≢fileList
                    'WARNING: [',(⍕objIx),'] ','Processing multiple Objects WITH NAME "',(obj),'": ',∊fileList
                :ENDIF 
                :FOR fileId :IN fileList
                    objList←rLibNs Fix2Group fileId  
                    ⋄ DebugMsg'[',(⍕objIx),'] ','            Object ',(Pad obj),' found: ',fileId
                    ⋄ DebugMsg'obj name: ',fileId
                    ⋄ DebugMsg'Loaded into',rLibNs,':',objList
                    :IF 1∊fnd←∊9.1=rLibNs.⎕NC objList
                        rNewLibsRefs,←rLibNs⍎¨fnd/objList
                        ⋄ DebugMsg 'Obj "',(1↓¯1↓⍕objList),'" is a namespace. Adding to newLibRefs' 
                    :ENDIF 
                :ENDFOR
                rWhere[objIx]←rLibNs ⋄ status[objIx]←2
            :ENDIF
            ⍝ +---------------+ 
            ⍝ | Scan Type II. | OBJ is a directory in directory DIR.
            ⍝ +---------------+ If any object SUB found in DIR/OBJ fixes as a namespace, include that namespace in ⎕PATH.
            ⍝                   I.e. if SUB is so fixed, add DIR.OBJ.SUB to ⎕PATH.  
            :IF ~found ⋄ :ANDIF  ×≢fileList←fileName ScanFileSpecs '/*.dyalog' '/*.apl?'
                found←1
                objList←libNsDotObj Fix2Group fileList 
                libNsDotObj←⍎obj rLibNs.⎕NS ''
                ⋄ DebugMsg'[',(⍕objIx),'] ',(3 Pad ⍕+/≢fileList),' objects for ns ',(Pad obj),' found: ',fileList
                DebugMsg'dir name: ',obj ⋄  DebugMsg'Fixing objects: ',fileList
                :IF 1∊fnd←∊9.1=libNsDotObj.⎕NC objList
                    DebugMsg 'Obj "',(1↓¯1↓⍕objList),'" is 1 or more namespaces. Adding to newLibRefs' 
                    rNewLibsRefs,←libNsDotObj⍎¨fnd/objList
                :ENDIF
                ⋄ DebugMsg'Loaded into ',(⍕libNsDotObj),':',objList
            :ENDIF
            :IF ~found ⋄ :LEAVE ⋄ :ENDIF
            rWhere[objIx]←rLibNs ⋄ status[objIx]←2
        :ENDFOR ⍝ :FOR objIx :IN ⍳≢ objs
    :ENDFOR  ⍝ :FOR dir :IN dirSearchPath

    oldPath←here.⎕PATH
    :IF setPathÔ
        here.⎕PATH←{  ⍝ APPEND NEW ITEMS AFTER EXISTING ⎕PATH items: ⍺ ⍵
          ⍺←here.⎕PATH ⋄ old new←{' '(≠⊆⊢)⍣(1≥|≡⍵)⊣⍵}¨⍺ ⍵ ⋄ 1↓∊' ',¨∪old,new
        }⍕¨rNewLibsRefs
    :ENDIF 

    :IF verboseÔ
        ⎕SHADOW 'CShow' ⋄ CShow←{0=≢⍵: ⍺ '[none]' ⋄ ⍺ ⍵}
        'opts     ' opts
        'verbose  ' verboseÔ            ⋄ 'library  ' rLibNs                ⋄  'objs     ' objs
        'mem srch ' memPath             ⋄ 'fi  srch ' dirSearchPath        ⋄  'setPathÔ   ' (setPathÔ⊃'OFF' 'ON')
      ⍞←'⎕PATH IS:' ('''','''',⍨here.⎕PATH)  ⋄ :IF setPathÔ ⋄ :ANDIF oldPath≢here.⎕PATH
      ⍞←'     WAS:' ('''','''',⍨oldPath)     ⋄ :ENDIF
        'Objects Found...'
        '  In mem:     ' CShow (objs/⍨ 1=status)    
        '  On disk:    ' CShow (objs/⍨ 2=status)
        '  Not found:  ' CShow (objs/⍨ 0=status)    ⍝ Only if -NFok option set.
        'objs \ rWhere ' (objs,[-.2]rWhere)
    :ENDIF

  ⍝ Add new items to start of ⍙Directory in rLibNs so most recent items found fastest...
    rLibNs.⍙Directory Update⍙Directory← objs rWhere         
  ⍝ :IF -NFok set, objs may contain names not found! rWhere will contain corresponding ⎕NULLs.
    :IF ~notFoundOkÔ  ⋄ :ANDIF ⎕NULL∊rWhere
        911 ⎕SIGNAL⍨'Required objects not found:',,⎕FMT objs/⍨rWhere∊⎕NULL
    :ENDIF
∇