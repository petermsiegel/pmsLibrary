∇ {where}←{opts} require2 objs
   ;⎕IO;⎕ML   
   ;count;debugO;dir;dirSearchPath;fileIx;fnd;f2;forceO;hasO;here;libNs;mainNs;mainNsD;memPath;m2
   ;newLibsRefs;obj;o2;objIx;OF;oldPath;opt;pad;Debug;searchPathO;setPathO;status;s2;subNs;subNsD
   ;tmp;t2;t3;verboseO;where;w2;_ 

  ⍝ Defaults
    DEBUG←0 
    ⎕IO ⎕ML←0 1
    mainNsD subNsD←⎕SE  '⍙⍙.⍙'        ⍝ ...D: Defaults
    here←⊃⎕RSI, mainNsD
    dirSearchPath←∪⊃,/{':' (≠⊆⊢) 2 ⎕NQ'.' 'GetEnvironment'⍵}¨'FSPATH'   'WSPATH'

    :IF 1≥|≡objs ⋄ objs←' ' (≠⊆⊢),objs ⋄ :ENDIF
    :IF  (900⌶)0 ⋄ opts objs←''{ 0=≢⍵:⍺ ⍵ ⋄  '-'≠1↑first←0⊃⍵ : ⍺ ⍵ ⋄ (⍺,' ',first) ∇ 1↓⍵ } objs ⋄ :ENDIF

  ⍝ Mini-utilities
    pad←{⍺←10 ⋄ ⍺>≢⍵: ⍵↑⍨-⍺ ⋄ ⍵}
    Debug←{debugO: ⎕←'>>> ',⍵ ⋄ 1: _←⍬}  

  ⍝ Process OPTIONS
  ⍝    DEFAULTS    |  ... ALTERNATIVES ...  | IN BRIEF
  ⍝    -Session    |  -Root  |  -Local      | What ns to put lib (NS)
  ⍝    -Prefix     |  -NOPrefix             | Put objs in ns directly or sub-library (NS)
  ⍝    -SEArchpath |  -NOSEArchpath         | Search entire ⎕PATH for objs
  ⍝    -SETpath    |  -NOSETpAth            | Update ⎕PATH on success
  ⍝    -NOVerbose  |  -Verbose              | Provide details on search       
  ⍝    -NOForce    |  -Force                | Update from disk even if objs found on ⎕PATH?
  ⍝ An option's case is ignored; when specified as main fn left arg, each option may omit the initial hyphen.
    debugO verboseO mainNs  searchPathO setPathO forceO subNs  where ←{
⍵}  0      0        mainNsD 1           1        0      subNsD ⍬    ⍝ ...O options and other settings
    :FOR opt :IN ⎕C opts←' '(≠⊆⊢)opts ~'-'
        OF←(≢opt)∘{l←(l<≢⍵)×l←⍵⍳'(' ⋄ (1⌈l⌈⍺)↑⍵~'('}
        :SELECT opt
          :CASE OF 'verbose'        ⋄ verboseO←1
          :CASE OF 'root'           ⋄ mainNs←#
          :CASE OF 'local'          ⋄ mainNs←here
          :CASE OF 'nop(refix'      ⋄ subNs←''
          :CASE OF 'nosea(rchpath'  ⋄ searchPathO←0
          :CASE OF 'noset(path'     ⋄ setPathO←0
          :CASE OF 'force'          ⋄ forceO←1
          :CASE OF 'set(path'       ⋄ setPathO←1
          :CASE OF 'p(refix'        ⋄ subNs←subNsD
          :CASE OF 'ses(sion'       ⋄ mainNs←⎕SE
          :CASE OF 'nov(erbose'     ⋄ verboseO←0
          :CASE OF 'sea(rchpath'    ⋄ searchPathO←1
          :CASE OF 'nof(orce'       ⋄ forceO←0
          :CASE OF 'debug'          ⋄ debugO←1
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
            '   ∘ The standard library is at      ⎕SE.⍙⍙.⍙    - option -session, the default'
            '   ∘ The standard library is at        #.⍙⍙.⍙    - option -root'
            '   ∘ The standard library is at  #.mylib.⍙⍙.⍙    - option -local, with require called from #.mylib'
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
            ~UP∊path:GetRef path
            climb←here{⍵.##≡⍵:⍺ ⋄ (⍺,⍵.##)∇ ⍵.##}here         ⍝ Returns refs to path from here to top lvl (⎕SE or #)
            GetRef ⍬{0=≢⍵:⍺ ⋄ UP≢⊂⊃⍵:(⍺,⊂⊃⍵)∇ 1↓⍵ ⋄ (⍺,climb)∇ 1↓⍵}path
        }here
    :ENDIF

    :IF verboseO
        'Memory path is ',memPath
        'Directory path is ',dirSearchPath
    :EndIf 

    :IF forceO         ⍝ force? Skip check in here, libNs, ⎕PATH; load from disk (if found), even if in memory already...
        status where←(≢objs)⍴¨0 ⎕NULL
    :ELSE 
        status←⍬            ⍝ status, s2: 1= Found, 0:=Not Found, ¯1= Invalid Name. where: ns where found or ⎕NULL, if not.
        :FOR obj :in objs
            s2←0 ⋄ w2←⎕NULL
            :FOR m2 :in memPath
                :IF s2=0
                :ANDIF 1=s2←×m2.⎕NC obj
                    w2←m2
                    Debug '>>> In memory: ',obj
                :ENDIF
                :IF s2≠0 ⋄ :LEAVE ⋄ :ENDIF    ⍝ Don't keep looking if found or invalid name.
            :ENDFOR
            status,←s2  ⋄ where,←w2
        :ENDFOR
    :ENDIF

    :IF  1∊tmp←0>status ⋄ 11 ⎕SIGNAL⍨'Invalid object name(s): ',⍕tmp/objs ⋄ :ENDIF

    newLibsRefs←libNs
    :FOR dir :in dirSearchPath
        :FOR objIx :in ⍳≢ objs
            fnd←0
            :IF status[objIx]≠0  ⋄ :continue ⋄ :ENDIF
            obj←objIx⊃objs
            tmp←dir,'/',('/'@('.'∘=)⊣obj)
            :FOR fileIx :IN ⍳≢t2←↓('' '/*',⍨¨⊂tmp)∘.,'.dyalog' '.apl*' 
                :IF ∨/f2←(⎕NEXISTS⍠1)fileIx⊃t2 
                    fnd←1
                    count←+/≢∘⊃¨t3←0 (⎕NINFO ⍠1)f2/fileIx⊃t2 
                    :IF fileIx=0  ⍝ (fileIx⊃t2) is a single object: not a directory of 0 or more namespace member objects
                        :IF count>1 
                          'DOMAIN ERROR: [',(⍕objIx),'] ','Multiple Objects ',(pad obj),' NOT ALLOWED: ',∊ t3
                        :ELSE 
                          Debug'[',(⍕objIx),'] ','            Object ',(pad obj),' found: ',∊t3
                          :TRAP 22
                              Debug'obj t3: ',t3  
                              o2←2 libNs.⎕FIX 'file://', ∊t3      
                              Debug'Loaded into ',libNs,': ',⍕o2
                              :IF 1∊_←∊9.1=libNs.⎕NC ⊆,o2
                                  Debug 'Obj "',o2,'" is a namespace. Adding to newLibRefs' 
                                  newLibsRefs,←libNs⍎¨_/o2
                              :ENDIF 
                              where[objIx]←libNs ⍝ Simulated...
                          :ELSE ⋄ ⎕SIGNAL/⎕DMX.(EM EN)         
                          :ENDTRAP
                        :ENDIF
                    :ELSE 
                        Debug'[',(⍕objIx),'] ',(3 pad ⍕count),' objects for ns ',(pad obj),' found: ',∊t3
                        :TRAP 0 
                            Debug'dir t3: ',t3
                            Debug'Fixing objects: ','file://'∘,¨∊¨t3
                            _←⍎obj libNs.⎕NS ''
                            o2←2 _.⎕FIX¨'file://'∘,¨∊¨t3
                            newLibsRefs,←_
                            Debug'Loaded into ',(⍕_),': ',o2
                            where[objIx]←libNs   
                        :ELSE ⋄ ⎕SIGNAL/⎕DMX.(EM EN)         
                        :ENDTRAP
                    :ENDIF 
                :ENDIF
            :ENDFOR 
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
