∇ {where}←{opts} require2 objs
   ;⎕IO;⎕ML   
   ;count;Debug;debugO;dir;dirSearchPath;fname;fname2;fileIx;fnd;fnd2;fnd3;forceO;hasO;here;ScanFileSys;libNs;lib_sub2
   ;mainNs;mainNsD;memPath;m2;newLibsRefs;obj;obj2;objIx;OF;oldPath;opt;Pad;searchPathO;setPathO;status
   ;stat2;subNs;subNsD;verboseO;where;wh2;_ 

  ⍝ Defaults
    ⎕IO ⎕ML←0 1
    mainNsD subNsD←⎕SE  '⍙⍙.⍙'        ⍝ ...D: Defaults
    here←⊃⎕RSI, mainNsD
    dirSearchPath←∪⊃,/{':' (≠⊆⊢) 2 ⎕NQ'.' 'GetEnvironment'⍵}¨'FSPATH'   'WSPATH'

    :IF 1≥|≡objs ⋄ objs←' ' (≠⊆⊢),objs ⋄ :ENDIF
    :IF  (900⌶)0 ⋄ opts objs←''{ 0=≢⍵:⍺ ⍵ ⋄  '-'≠1↑first←0⊃⍵ : ⍺ ⍵ ⋄ (⍺,' ',first) ∇ 1↓⍵ } objs ⋄ :ENDIF

  ⍝ Mini-utilities
    Pad←{⍺←10 ⋄ ⍺>≢⍵: ⍵↑⍨-⍺ ⋄ ⍵}
    Debug←{debugO: ⎕←'>>> ',⍵ ⋄ 1: _←⍬}  

  ⍝ Process OPTIONS
  ⍝    DEFAULTS... |  ALTERNATIVES ...      | IN BRIEF...
  ⍝    -Session    |  -Root  |  -Local      | What ns to put lib (NS)
  ⍝    -Prefix     |  -NOPrefix             | Put objs in ns directly or sub-library (NS)
  ⍝    -SEArchpath |  -NOSEArchpath         | Search entire ⎕PATH for objs
  ⍝    -SETpath    |  -NOSETpAth            | Update ⎕PATH on success
  ⍝    -NOVerbose  |  -Verbose              | Provide details on search  
  ⍝    -NODebug    |  -Debug                | Provide debugging info when searching mem and file sys for objects.     
  ⍝    -NOForce    |  -Force                | Update from disk even if objs found on ⎕PATH?
  ⍝ An option's case is ignored; when specified as main fname left arg, each option may omit the initial hyphen.
    debugO verboseO mainNs  searchPathO setPathO forceO subNs  where ←{
⍵}  0      0        mainNsD 1           1        0      subNsD ⍬    ⍝ ...O options and other settings
    :FOR opt :IN ⎕C opts←' '(≠⊆⊢)opts ~'-'
        OF←(≢opt)∘{l←(l<≢⍵)×l←⍵⍳'(' ⋄ (1⌈l⌈⍺)↑⍵~'('}
        :SELECT opt  ⍝ Ordered approx. by likelihood. Left paren shows minimal abbrev.
          :CASE OF 'verbose'        ⋄ verboseO←1     ⋄  :CASE OF 'root'           ⋄ mainNs←#
          :CASE OF 'local'          ⋄ mainNs←here    ⋄  :CASE OF 'nop(refix'      ⋄ subNs←''
          :CASE OF 'nosea(rchpath'  ⋄ searchPathO←0  ⋄  :CASE OF 'noset(path'     ⋄ setPathO←0
          :CASE OF 'force'          ⋄ forceO←1       ⋄  :CASE OF 'debug'          ⋄ debugO←1  
          :CASE OF 'set(path'       ⋄ setPathO←1     ⋄  :CASE OF 'nov(erbose'     ⋄ verboseO←0   
          :CASE OF 'nof(orce'       ⋄ forceO←0       ⋄  :CASE OF 'p(refix'        ⋄subNs←subNsD   
          :CASE OF 'ses(sion'       ⋄ mainNs←⎕SE     ⋄  :CASE OF 'sea(rchpath'    ⋄ searchPathO←1     
          :CASE OF 'help'
            'require2: HELP INFORMATION'
            'Description: Checks if required APL objects are in a local "library" or loads them from file or workspace'
            '   Returns the local library. As a side effect, ensures the local library is in the local ⎕PATH.'
            '   (By "local" (namespace), we mean the namespace from which require2 is called).'
            'Syntax:'
            '   {libNS} ← {opts} require2 [ ''<opts> obj1 obj2...'' | [''opts''] ''obj1'' ''obj2'' ... ]'
            '   opts:'
            '      -[SESsion* | -Root | -Local]'
            '      -[no]Prefix*       -[no]SEArchpath*'
            '      -[no]SETpath*      -[no*]Force'
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
            '   ∘ If -path is specified, the entire "local"namespace, local search ⎕PATH, and the library are searched for objects.'
            '     If -nopath, only the "local" namespace and the library are searched.'
            'The Standard Library:'
            '   ∘ The standard library is at      ⎕SE.⍙⍙.⍙    - option -session, the default.'
            '   ∘ The standard library is at        #.⍙⍙.⍙    - option -root.'
            '   ∘ The standard library is at  #.mylib.⍙⍙.⍙    - option -local, with require called from #.mylib.'
            '' ⋄ :RETURN
          :ELSE ⋄ 11 ⎕SIGNAL⍨'For help, type "require2 ''-help''".',(⎕UCS 13),'Unknown option: ',opt
        :ENDSELECT
    :ENDFOR

    ⍝ Scan ⍵.⎕PATH, returning a list of references, resolving ↑ and ignoring undefined namespaces.
    ⍝ Return <mempath>, ⎕PATH references prepended by libNs (our library)...
    libNs←⍎subNs mainNs.⎕NS ⍬
    memPath← here libNs
    :IF searchPathO
        memPath←memPath{UP←⊂,'↑'
            path←' '(≠⊆⊢)⍵.⎕PATH
            GetRef←⍺∘{∪⍺,(0≠≢¨⍵)/⍵}{6::⍬ ⋄ 9=⎕NC'⍵':⍵ ⋄ ⍎⍵}¨  ⍝ Returns ns ref from string or ref, else ⍬
            Climb←{⍵.##≡⍵:⍺ ⋄ (⍺,⍵.##)∇ ⍵.##}⍨                ⍝ Returns all namespaces between ⍵ and the top level inclusive!
            ~UP∊path:GetRef path
            GetRef ⍬{0=≢⍵:⍺ ⋄ UP≢⊂⊃⍵:(⍺,⊂⊃⍵)∇ 1↓⍵ ⋄ (⍺, Climb here)∇ 1↓⍵}path
        }here
    :ENDIF

    :IF verboseO
        'Memory path is ',memPath
        'Directory path is ',dirSearchPath
    :EndIf 

    :IF forceO         ⍝ force? Skip check in here, libNs, ⎕PATH; load from disk (if found), even if in memory already...
        status where←(≢objs)⍴¨0 ⎕NULL
    :ELSE 
        status←⍬            ⍝ status, stat2: 1= Found, 0:=Not Found, ¯1= Invalid Name. where: ns where found or ⎕NULL, if not.
        :FOR obj :in objs   ⍝ Search memPath namespaces for <obj>
            stat2←0 ⋄ wh2←⎕NULL
            :FOR m2 :in memPath   
                :IF stat2=0
                :ANDIF 1=stat2←×m2.⎕NC obj
                    wh2←m2
                    Debug '>>> In memory: ',obj
                :ENDIF
                :IF stat2≠0 ⋄ :LEAVE ⋄ :ENDIF    ⍝ Don't keep looking if found or invalid name.
            :ENDFOR
            status,←stat2  ⋄ where,←wh2
        :ENDFOR
    :ENDIF

    :IF  ¯1∊status ⋄ 11 ⎕SIGNAL⍨'Invalid object name(s): ',⍕objs/⍨¯1=status ⋄ :ENDIF

    newLibsRefs←libNs
    :FOR dir :in dirSearchPath
        :FOR objIx :in ⍳≢ objs
            fnd←0
            :IF status[objIx]≠0  ⋄ :continue ⋄ :ENDIF
            obj←objIx⊃objs
          ⍝ Obj name of form OBJL.OBJR. See [OBJ FORMS] below.
            fname←dir,'/',('/'@('.'∘=)⊣obj)
          ⍝ OBJ FORMS: (A) OBJ is simple name, e.g. "this"; (B) OBJ has embedded dots, e.g. "this.that".
          ⍝ (A) Search for files DIR/this.dyalog, DIR/this.apl*      & dirs DIR/this/*.dyalog, DIR/this/*.apl*
          ⍝ (B) Search for files DIR/this/that.dyalog, DIR/this.apl* & dirs DIR/this/that/*.dyalog, DIR/this/that/*.apl
            ScanFileSys←{ nms←⍺∘,¨⍵
              ~∨/fnd←(⎕NEXISTS⍠1)nms: ⍬ 
              0=count←+/≢fnameOut←⊃,/0 (⎕NINFO ⍠1)fnd/nms: ⍬
              fnameOut
            }
            :IF ×≢fname2←fname ScanFileSys '.dyalog' '.apl*'
                :IF 1<≢fname2
                    '⎕SIGNAL... DOMAIN ERROR: [',(⍕objIx),'] ','Multiple Objects ',(Pad obj),' NOT ALLOWED: ',∊fname2
                :ELSE 
                    Debug'[',(⍕objIx),'] ','            Object ',(Pad obj),' found: ',∊fname2
                    :TRAP 0/⍨~debugO
                        Debug'obj name: ',fname2  
                        obj2←2 libNs.⎕FIX 'file://',∊fname2      
                        Debug'Loaded into',libNs,':',obj2
                        :IF 1∊_←∊9.1=libNs.⎕NC ⊆,obj2
                            Debug 'Obj "',(1↓¯1↓⍕obj2),'" is a namespace. Adding to newLibRefs' 
                            newLibsRefs,←libNs⍎¨_/obj2
                        :ENDIF 
                        where[objIx]←libNs  
                    :ELSE 
                        ⎕SIGNAL/⎕DMX.(EM EN)         
                    :ENDTRAP
                :ENDIF
            :ENDIF
            :IF ×≢fname2←fname ScanFileSys '/*.dyalog' '/*.apl*'
                    Debug'[',(⍕objIx),'] ',(3 Pad ⍕+/≢fname2),' objects for ns ',(Pad obj),' found: ',fname2
                    :TRAP 0/⍨~debugO
                        Debug'dir name: ',obj
                        Debug'Fixing objects: ',(⊂'file://')∘,¨∊¨fname2
                        lib_sub2←⍎obj libNs.⎕NS ''
                        obj2←{⎕←'fixing "',⍵,'" [items=',(⍕≢⍵),']'⋄ 2 lib_sub2.⎕FIX¨'file://',⍵}¨fname2
                        :IF 1∊fnd3←∊9.1=lib_sub2.⎕NC ⊆,obj2
                            Debug 'Obj "',(1↓¯1↓⍕obj2),'" is a namespace(s). Adding to newLibRefs' 
                            newLibsRefs,←lib_sub2⍎¨fnd3/obj2
                        :ENDIF
                        Debug'Loaded into ',(⍕lib_sub2),':',obj2
                        where[objIx]←libNs   
                    :ELSE 
                        ⎕SIGNAL/⎕DMX.(EM EN)         
                    :ENDTRAP
            :ENDIF
        :ENDFOR
    :ENDFOR

    oldPath←here.⎕PATH
    :IF setPathO
        here.⎕PATH←{
          ⍺←here.⎕PATH ⋄ old new←{' '(≠⊆⊢)⍣(1≥|≡⍵)⊣⍵}¨⍺ ⍵ ⋄ 1↓∊' ',¨∪old,new
        }⍕¨newLibsRefs
    :ENDIF 

    :IF verboseO
        'opts     ' opts
        'verbose  ' verboseO            ⋄ 'library  ' libNs                ⋄  'objs     ' objs
        'mem srch ' memPath             ⋄ 'fi  srch ' dirSearchPath        ⋄  'setPathO   ' (setPathO⊃'OFF' 'ON')
      ⍞←'⎕PATH IS:' ('''','''',⍨here.⎕PATH)  ⋄ :IF setPathO ⋄ :ANDIF oldPath≢here.⎕PATH
      ⍞←'     WAS:' ('''','''',⍨oldPath)     ⋄ :ENDIF
        'Objects Found...'
        '  In mem:     ' (objs/⍨1=status)    
        '  On disk:    ' (objs/⍨0=status)
        'objs\where' (objs,[-.2]where)
    :ENDIF

    :IF ⎕NULL∊where
        _←911 ⎕SIGNAL⍨'Required objects not found:',,⎕FMT ((where∊⎕NULL)/objs) 
    :ENDIF
∇
