 require2←{⍺←⊃⎕RSI
    ⍝ require [flags] [object1 [object2] ... ]]
    ⍝
    ⍝ object:   name OR  dir:name OR wsid::name  OR  dir:(name1 name2 ...)  OR wsid::(name1 name2 ...)
    ⍝
     ⎕IO←0 ⋄ Err←⎕SIGNAL∘11 ⋄ with←⊣ ⋄ ∆SPLIT←{⍺←' ' ⋄ ⍺(≠⊆⊢)⍵}
     SetCaller←{⍺←'In -c arg, arg'
         0::Err'require: ',⍺,' "',(⍕⍵),'" must refer to a valid & active namespace.' 
         9=⎕NC'⍵':⍵ ⋄ 0≤⎕NC ⍵,'._': {9=⎕NC '⍵': ⍵  ⋄  ∘}(⊃⎕RSI)⍎⍵ ⋄  ∘   ⍝ ⎕NC '#' is ¯1, but for '#._' is 0
     }
     dDEBUG←0
     dLIB_SUFFIX←'⍙⍙.require'
     dCALLER←'Calling env ⍺'SetCaller ⍺

     NL←⎕UCS 10 ⋄ with←⊣
     SQ DQ DQ2←'''' '"' '""'
     FILE_EXTENSIONS←∆SPLIT'dws dyapp aplf aplo apln aplc  apli      apla  dyalog'
     FILE_TYPES←∆SPLIT'WS  SALT  FN   OP   NS   CLASS INTERFACE ARRAY GENERIC'
   
⍝ ------ UTILITIES
⍝ ∆F:  Find a pcre field by name or field number
     ∆F←{⎕IO←0
         N O B L←⍺.(Names Offsets Block Lengths)
         def←'' ⋄ isN←0≠⍬⍴0⍴⍵
         p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
         B[O[p]+⍳L[p]]
     }
     GetEnv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
     DLB←{⍵↓⍨+/∧\⍵=' '}                    
    ⍝ Delete leading blanks
     UnDQ←{DQ≠1↑⍵:⍵ ⋄ s/⍨~DQ2⍷s←1↓¯1↓⍵}   ⍝ Convert a DQ string to SQ string, else do nothing.

    ⍝⍝ object of form
    ⍝⍝    parent:name, parent::name, parent:(name1 name2 ...) parent::(name1 name2 ...)
    ⍝⍝    parent: a filename and namespace name of the forms:
    ⍝⍝      a) dir_name: may contain any chars but spaces and colons
    ⍝⍝      b) ""dir_name"" OR ''dir_name'':  parent may have internal spaces or colons
    ⍝⍝    name:   any valid APL object name, possibly a non-simple name like name1.name2 etc.
    ⍝⍝ Returns
    ⍝⍝    [0] name (or null if no : or ::)
    ⍝⍝    [1] 'FILE'  'WS'                   ':' or '' on input ->'FILE' check files, '::' on input → 'WS' check workspaces
    ⍝⍝    [2] name1 [name2 ...]
     GetObj←{⎕IO←0 ⋄ LPAR SQ DQ←'(''"'
         obj←⍵
         parent type obj←{
             ~⍵:'' 'FILE'obj
             na←obj↑⍨p
             ty←'FILE' 'WS'⊃⍨∆←':'=1↑obj↓⍨p+1
             ob←DLB obj↓⍨p+1+∆
             na ty ob
         }(≢obj)>p←obj⍳':'

    ⍝   Process quoted parents (only parents may be quoted).
         parent←{⍺←1↑⍵ ⋄ ⍺=SQ:1↓¯1↓⍵ ⋄ ⍺=DQ:UnDQ ⍵ ⋄ ⍵}parent
    ⍝   Process parens that group many child names. There may be 0 or more children.
         children←obj{
             0=≢⍺:⍬ 
             ~⍵:⊂⍺
             ~')'∊⍺:('GetObj: namelist terminator not found: ',⍺)⎕SIGNAL 11
             kids←∆SPLIT ostr↑⍨')'⍳⍨ostr←1↓⍺
             kids 
         }LPAR=1↑obj
         ok err←{0=≢⍵: 1 0 ⋄ err←¯1=⎕NC↑⍵ ⋄  (1(~∊)err) err  }children
         ok: parent type children
         Err'GetObj: invalid object name(s):',∊' ',¨err/children
     }

  ⍝ ========= MAIN

     GetOptions←{
         oDEBUG oFORCE oCALLER oLIB oPATH←⍺
         obj←⍬{  ⍝ Process options -fff, returning unaffected tokens...
             0=≢⍵:⍺ ⋄ opt←0⊃⍵ ⋄ tokens←1↓⍵ ⋄ done←0
             '-'≠1↑opt:(⍺,⊂opt)∇ tokens
             toksLeft←tokens{toks opt←⍺ ⍵
                 case←(1↑1↓opt)∘∊
                 case'f':toks with oFORCE∘←1                          ⍝ -force_on
                 case'F':toks with oFORCE∘←0                          ⍝ -Force_off           | turns force to 0
                 case'L':toks with oLIB∘←''                           ⍝ -Lib_off             | sets lib prefix to ''
                 case'R':toks with oCALLER oLIB∘←#''                  ⍝ -Root                | sets caller to # and resets lib prefix to ''
                 case'r':toks with oCALLER oLIB∘←# dLIB_SUFFIX        ⍝ -root                | sets caller to # and resets lib prefix to '⍙⍙.require'
                 case'S':toks with oCALLER oLIB∘←⎕SE''                ⍝ -Session_lib_null    | sets caller to ⎕SE & resets lib prefix to ""
                 case's':toks with oCALLER oLIB∘←⎕SE dLIB_SUFFIX      ⍝ -session_lib_std     | sets caller to ⎕SE & resets lib prefix to '⍙⍙.require'
                 case'd':toks with oDEBUG∘←1                          ⍝ -debug
                 case'Dq':toks with oDEBUG∘←0                         ⍝ -Debug_off, -quiet
                 case'-':toks with done∘←1                            ⍝ --                   | done with options
                 ⋄ skip←1↓toks ⋄ first←⊃toks
                 case'c':skip with oCALLER∘←SetCaller first           ⍝ -caller namespace
              ⍝ -l "" sets library prefix to null string. -l name or -l "name" sets it to "name".
                 case'l':skip ⊣oLIB∘←UnDQ first                  ⍝ -lib    prefix       | sets library prefix to "prefix" or, if "", null string
                 case'p':skip with oPATH,⍨←first                      ⍝ -path   addition     | augment search path
                 case'P':skip with oPATH∘←first                       ⍝ -Path   replacement  | replace search path

                 Err'Invalid option: ',opt
             }opt
             done:⍺,toksLeft
             ⍺ ∇ toksLeft
         }∘,⍵
         obj(oDEBUG oFORCE oCALLER oLIB oPATH)
     }

     Tokenize←{
         pList←'-[^ ]+' '(?x) (?: ([^ :]+|(?:"[^"]*")+|(?:''[^'']*'')+) (::?) )?  ( \( [^\)]* \) | [^ ]+)?' ' +'
         aList←'\0' '\0' '\n'
         pList ⎕R aList⊣⊆DLB ⍵
     }
     ReportObj←{ ⍝ Returns right arg
         ~oDEBUG:⍵
         show←{⍺←', ' ⋄ ⍺,⍵,': "',(,⎕FMT⍎⍵),'"'}
         ⎕←1↓∊show¨'oDEBUG' 'oFORCE' 'oCALLER' 'oLIB'
         ⎕←'oPATH:'oPATH
         ⍵
     }

    EnQ←{⍺←SQ ⋄ 1↓∊⍺{' ',⍺,⍺,⍨⍕⍵}¨⊆⍵}

  ⍝ ∆CY: Just in time creation of the require library from oCALLER and oLIB 
  ⍝      ⍺ ∆CY ⍵
  ⍝        - copy objects 'a1' 'a2' ... from apl ws <⍵>, a qualified APL file name (.dws)
  ⍝        - return 1 (success) or 0 (failure). ∆CY is atomic: on failure, no objects are copied at all.
  ⍝        - If the ∆CY fails, oCALLER.⍎oLIB is not created, if not already in existence.
  ⍝      This approach is fast:
  ⍝             1) ⎕CY into a tmp ns, then 2) "copy" (⎕NS) into the target ns <oLIB>, 2a) creating <oLIB> if required.   
    ∆CY←{ ⍺←⍬ 
          ⍙CY←{⍺←⊢  ⋄ 0:: 0 ⋄ tmp←⎕NS ''  ⋄  1⊣oLIB oCALLER.⎕NS  tmp ⊣⍺ tmp.⎕CY ⍵  }
          0=≢⍺:⍙CY  ⍵ ⋄ ⍺ ⍙CY  ⍵
    }
   
    Scan←{        
        STARTL←⍬ 1
        dirs objects←⍵    
        sFULLNS←(⍕oCALLER),('.'/⍨0≠≢oLIB),oLIB
        ScanL1←{ 
            ⍺←STARTL                  ⍝ Scan Dirs
            res done←⍺
            done∨0=≢⍵: ⍺ ⋄ dir←⊃⍵  
            ⎕←'dir="',dir,'"'
            objLists←{  
                ⍺←STARTL         ⍝ Scan Objects
                res done←⍺
                done∨0=≢⍵: ⍺ 
                parent type children←⊃⍵ 
                type≡'WS': ⍺ ∇ (1↓⍵) with {
                    ws←dir,'/',parent,'.dws' 
                    found←children ∆CY ws   
                    ⊢⎕←('Not '/⍨~found),'Found ',(EnQ children),' ',sFULLNS,'.⎕CY',(EnQ ws)
                }⍬ 
                fileLists←{
                      ⍺←STARTL        ⍝ Scan Children Objects. If none, use '*'
                      res done←⍺
                      done∨0=≢⍵: ⍺ 
                      child←⊃⍵ 
                      c←'/'@('.'∘=)⊣child ⋄ fi←parent,'/',c 
                      ⎕←'  2 ',sFULLNS,'.⎕FIX ',EnQ '//FILE:',fi,'.*'     
                      res done ∇ 1↓⍵
                }{0=≢⍵: ⊂'*'  ⋄ ⍵}children  
                (res, fileLists) done ∇ 1↓⍵
            }objects
            res done ∇ 1↓⍵
        }
        ScanL1 dirs
    }

     dPATH←∊':',¨GetEnv¨'WSPATH' 'FSPATH'         ⍝ directories separated by ':
     opts←dDEBUG 0 dCALLER dLIB_SUFFIX dPATH
     ⋄ objects opts←opts GetOptions Tokenize ⍵
     oDEBUG oFORCE oCALLER oLIB oPATH←opts
     objects←GetObj¨objects

     oPATH←∪':'∆SPLIT oPATH
     _←ReportObj objects
     found←Scan oPATH objects
     0=≢found: 'Not found'
     'Scan: 'found
 }
