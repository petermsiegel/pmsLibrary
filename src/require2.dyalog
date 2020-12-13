∇ {where}←{opts} require2 objs
   ;⎕IO;⎕ML
   ;i;j;dir;dirSearchPath;subNsD;memPath;fnd;forceO;hasO;libNs;mainNs;mainNsD
   ;newLibsRefs;o;o2;obj;oldPath;OF;pad;pathO;s;say;status;subNs;t;t2;t3;t3a;updateO;verboseO;w;_

    ⎕IO ⎕ML←0 1
  ⍝ Defaults
    mainNsD subNsD verboseD←⎕SE  '⍙⍙.⍙' 0       ⍝ ...D: Defaults
    here←⊃⎕RSI, mainNsD
    dirSearchPath←∪⊃,/{':' (≠⊆⊢) 2 ⎕NQ'.' 'GetEnvironment'⍵}¨'FSPATH'   'WSPATH'

    :IF 1≥|≡objs ⋄ objs←' ' (≠⊆⊢),objs ⋄ :ENDIF
    :IF  (900⌶)0 ⋄ opts objs←''{ 0=≢⍵:⍺ ⍵ ⋄  '-'≠1↑first←0⊃⍵ : ⍺ ⍵ ⋄ (⍺,' ',first) ∇ 1↓⍵ } objs ⋄ :ENDIF

  ⍝ Mini-utilities
    say←{verboseO: ⎕←⍵ ⋄ 1: ⍬}
    pad←{⍺←10 ⋄ ⍺>≢⍵: ⍵↑⍨-⍺ ⋄ ⍵}

  ⍝ Process OPTIONS
  ⍝    DEFAULTS    |  ... ALTERNATIVES ...  | Gist
  ⍝    -Session    |  -Root  |  -Local      | What ns to put lib (NS)
  ⍝    -Prefix     |  -NOPrefix             | Put objs in ns directly or sub-library (NS)
  ⍝    -SEArchpath |  -NOSEArcppath         | Search entire ⎕PATH for objs
  ⍝    -SETpath    |  -NOSETpAth            | Update ⎕PATH on success
  ⍝    -NOVerbose  |  -Verbose              | Provide details on search       
  ⍝    -NOForce    |  -Force                | Update from disk even if objs found on ⎕PATH?
  ⍝ An option's case is ignored; when specified as left arg, each option may omit the initial hyphen.
    verboseO mainNs  pathO updateO forceO subNs  where ←{
⍵}  verboseD mainNsD 1     1       0      subNsD ⍬    ⍝ ...O options and other settings
    :FOR o :IN ⎕C opts←' '(≠⊆⊢)opts ~'-'
        OF←(≢o)∘{l←(l<≢⍵)×l←⍵⍳'(' ⋄ (1⌈l⌈⍺)↑⍵~'('}
        :SELECT o
          :CASE OF 'verbose'        ⋄ verboseO←1
          :CASE OF 'root'           ⋄ mainNs←#
          :CASE OF 'local'          ⋄ mainNs←here
          :CASE OF 'nop(refix'      ⋄ subNs←''
          :CASE OF 'nosea(rchpath'  ⋄ pathO←0
          :CASE OF 'noset(path'     ⋄ updateO←0
          :CASE OF 'force'          ⋄ forceO←1
          :CASE OF 'set(path'       ⋄ pathO←1
          :CASE OF 'p(refix'        ⋄ subNs←subNsD
          :CASE OF 'ses(sion'       ⋄ mainNs←⎕SE
          :CASE OF 'nov(erbose'     ⋄ verboseO←0
          :CASE OF 'sea(rchpath'    ⋄ updateO←1
          :CASE OF 'nof(orce'       ⋄ forceO←0
          :CASE OF 'help'
            'require2: HELP INFORMATION'
            'Description: Checks if required APL objects are in a local "library" or loads them from file or workspace'
            '   Returns the local library. As a side effect, ensures the local library is in the local ⎕PATH.'
            '   (By "local" (namespace), we mean the namespace from which require2 is called).'
            'Syntax:'
            '   {libNS} ← {opts} require2 [ ''<opts> obj1 obj2...'' | [''opts''] ''obj1'' ''obj2'' ... ]'
            '   opts:'
            '      -[no*]Verbose  -[SESsion* | Root | Local] -[no]Prefix*    -[no]SEArchpath*  -[no]SETpath*  -[no*]Force   -help'
            '                     <   library location     > <Lib name=∆.⍙>  <search ⎕PATH?>   <update ⎕PATH> force updte?  <This help>'
            'Notes:'
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
          :ELSE ⋄ 11 ⎕SIGNAL⍨'Unknown option: ',o
        :ENDSELECT
    :ENDFOR

    ⍝ Scan ⍵.⎕PATH, returning a list of references, resolving ↑ and ignoring undefd namespaces.
    ⍝ Return list, prepending libNs (our library)...
    libNs←⍎subNs mainNs.⎕NS ⍬
    memPath← here libNs
    :IF pathO
        memPath←memPath{UP←⊂,'↑'
            path←' '(≠⊆⊢)⍵.⎕PATH
            GetRef←⍺∘{∪⍺,(0≠≢¨⍵)/⍵}{6::⍬ ⋄ 9=⎕NC'⍵':⍵ ⋄ ⍎⍵}¨  ⍝ Returns ns ref from string or ref, else ⍬
            ~path∊⍨isUp←UP:GetRef path
            climb←here{⍵.##≡⍵:⍺ ⋄ (⍺,⍵.##)∇ ⍵.##}here
            GetRef ⍬{0=≢⍵:⍺ ⋄ isUp≢⊂⊃⍵:(⍺,⊂⊃⍵)∇ 1↓⍵ ⋄ (⍺,climb)∇ 1↓⍵}path
        }here
    :ENDIF

    :IF verboseO
        'Memory path is ',memPath
        'Directory path is ',dirSearchPath
    :EndIf 

    :IF forceO         ⍝ force? Skip check in here, libNs, ⎕PATH; load from disk (if found), even if in memory already...
        status where←(≢objs)⍴¨0 ⎕NULL
    :ELSE 
        status←⍬            ⍝ status, s: 1= Found, 0:=Not Found, ¯1= Invalid Name. where: ns where found or ⎕NULL, if not.
        :FOR o :in objs
            s←0 ⋄ w←⎕NULL
            :FOR p :in memPath
                :IF s=0
                :ANDIF 1=s←×p.⎕NC o
                    w←p
                :ENDIF
                :IF s≠0 ⋄ :LEAVE ⋄ :ENDIF    ⍝ Don't keep looking if found or invalid name.
            :ENDFOR
            status,←s  ⋄ where,←w
        :ENDFOR
    :ENDIF

    :IF  1∊t←0>status ⋄ 11 ⎕SIGNAL⍨'Invalid object name(s): ',⍕t/objs ⋄ :ENDIF

    newLibsRefs←libNs
    :FOR d :in dirSearchPath
        :FOR i :in ⍳≢ objs
            fnd←0
            :IF status[i]≠0  ⋄ :continue ⋄ :ENDIF
          ⍝ Use  0 ⎕NINFO ⍠1⊣t,'.dy*' to return 0 or more values.   Same as  "0 ⎕NINFO ⍠ ('Wildcard' 1)".
          ⍝ Also 1 ⎕NINFO t           to see if t is a directory (absorb all contents)... 
            o←i⊃objs
            t←d,'/',('/'@('.'∘=)⊣o)
            :FOR j :IN ⍳≢t2←↓('' '/*',⍨¨⊂t)∘.,'.dyalog' '.apl*' 
                :IF ∨/f←(⎕NEXISTS⍠1)j⊃t2 
                    fnd←1
                    n←+/≢∘⊃¨t3←0 (⎕NINFO ⍠1)f/j⊃t2 
                    :IF j=0  ⍝ (j⊃t2) is a single object: not a directory of 0 or more namespace member objects
                        :IF n>1 
                          'DOMAIN ERROR: [',(⍕i),'] ','Multiple Objects ',(pad o),' NOT ALLOWED: ',∊ t3
                        :ELSE 
                          say'[',(⍕i),'] ','            Object ',(pad o),' found: ',∊t3
                          :TRAP 22
                              say'obj t3: ',t3  
                              o2←2 libNs.⎕FIX 'file://', ∊t3      
                              say'Loaded into ',libNs,': ',⍕o2
                              :IF 1∊_←∊9.1=libNs.⎕NC ⊆,o2
                                  say 'Obj "',o2,'" is a namespace. Adding to newLibRefs' 
                                  newLibsRefs,←libNs⍎¨_/o2
                              :ENDIF 
                              where[i]←libNs ⍝ Simulated...
                          :ELSE ⋄ ⎕SIGNAL/⎕DMX.(EM EN)         
                          :ENDTRAP
                        :ENDIF
                    :ELSE 
                        say'[',(⍕i),'] ',(3 pad ⍕n),' objects for ns ',(pad o),' found: ',∊t3
                        :TRAP 0 
                            say'dir t3: ',t3
                            say'Fixing objects: ','file://'∘,¨∊¨t3
                            _←⍎o libNs.⎕NS ''
                            o2←2 _.⎕FIX¨'file://'∘,¨∊¨t3
                            newLibsRefs,←_
                            say'Loaded into ',(⍕_),': ',o2
                            where[i]←libNs   
                        :ELSE ⋄ ⎕SIGNAL/⎕DMX.(EM EN)         
                        :ENDTRAP
                    :ENDIF 
                :ENDIF
            :ENDFOR 
        :ENDFOR
    :ENDFOR

    :IF verboseO  ⋄ :ANDIF ⎕NULL∊where
        '*** OBJECTS NOT FOUND!'
        (where∊⎕NULL){  (⍺/⍳≢⍵) {say'    [',(⍕⍺),'] ',⍵}¨ ⍺/⍵  }objs
    :ENDIF

    oldPath←here.⎕PATH
    :IF updateO
        here.⎕PATH←{
          ⍺←here.⎕PATH ⋄ old new←{' '(≠⊆⊢)⍣(1≥|≡⍵)⊣⍵}¨⍺ ⍵ ⋄ 1↓∊' ',¨∪old,new
        }⍕¨newLibsRefs
    :ENDIF 

    :IF verboseO
        'opts     ' opts
        'verbose  ' verboseO             ⋄ 'library  ' libNs                ⋄  'objs     ' objs
        'mem srch ' memPath             ⋄ 'fi  srch ' dirSearchPath        ⋄  'updateO   ' (updateO⊃'OFF' 'ON')
      ⍞←'⎕PATH IS:' ('''','''',⍨here.⎕PATH)             ⋄ :IF updateO ⋄ :ANDIF oldPath≢here.⎕PATH
      ⍞←'     WAS:' ('''','''',⍨oldPath)                ⋄ :ENDIF
        'mem:     ' (objs/⍨1=status)     ⋄  'disk?    ' (objs/⍨0=status)
        'status   ' status               ⋄  'where    ' where
    :ENDIF

∇
