 require2←{⍺←⊃⎕RSI
     ⍝ require [flags] [object1 [object2] ... ]]
     ⍝
     ⍝ object:   name OR  dir:name OR wsid::name  OR  dir:(name1 name2 ...)  OR wsid::(name1 name2 ...)
     ⍝ 

    DEBUG←0   ⋄   ⎕IO←0 ⋄ Err←⎕SIGNAL∘11
    LIB_SFX←'⍙⍙.require'
    CALLER←{0:: Err 'Left arg (CALLER) must be a valid namespace name or reference: ',⍕⍵
       9=⎕NC '⍵': ⍵ ⋄  2=⎕NC '⍵': (⊃⎕RSI)⍎⍵
    }⍺

    NL←⎕UCS 10
    with←⊣

⍝ ------ UTILITIES
⍝ ∆F:  Find a pcre field by name or field number
     ∆F←{⎕IO←0
         N O B L←⍺.(Names Offsets Block Lengths)
         def←'' ⋄ isN←0≠⍬⍴0⍴⍵
         p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
         B[O[p]+⍳L[p]]
     }
     GetEnv←{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}
     DLB←{⍵↓⍨+/∧\⍵=' '}                                   ⍝ Delete leading blanks
     UnDQ←{s/⍨~DQ2⍷s←1↓¯1↓⍵} ⋄ DQ2←2⍴'"'               ⍝ Convert DQ strings to SQ strings

    ⍝⍝ object of form
    ⍝⍝    parent:name, parent::name, parent:(name1 name2 ...) parent::(name1 name2 ...)
    ⍝⍝    parent: a filename and namespace name of the forms:
    ⍝⍝      a) dir_name: may contain any chars but spaces and colons
    ⍝⍝      b) ""dir_name"" OR ''dir_name'':  parent may have internal spaces or colons
    ⍝⍝    name:   any valid APL object name, possibly a non-simple name like name1.name2 etc. 
    ⍝⍝ Returns
    ⍝⍝    [0] name (or null if no : or ::)
    ⍝⍝    [1] ':' or '::' or ''
    ⍝⍝    [2] name1 [name2 ...] 
    GetObj←{⎕IO←0 ⋄ LPAR SQ DQ←'(''"'
        obj←⍵
        parent punct obj←{
            ~⍵:''   '' obj
            na←obj↑⍨p
            pu←':'⍴⍨∆←1+':'=1↑obj↓⍨p+1
            ob←DLB obj↓⍨p+∆
            na pu ob
        }(≢obj)>p←obj⍳':'

    ⍝   Process quoted parents (only).
        parent←{ ⍺←1↑⍵ ⋄ ⍺=SQ:1↓¯1↓⍵ ⋄   ⍺=DQ:UnDQ ⍵ ⋄   ⍵ }parent
        names←{
            ~⍵:⊂obj
            ~')'∊obj:('GetObj: namelist terminator not found: ',obj)⎕SIGNAL 11
            p←')'⍳⍨obj←1↓obj
            ' '(≠⊆⊢)p↑obj
        }LPAR=1↑obj
        1∊e←¯1=⎕NC↑names:11 ⎕SIGNAL⍨'GetObj: invalid object name(s):',∊' ',¨e/names
        parent punct names
 }

  ⍝ ========= MAIN

     GetOptions←{  ⍝ Process options -fff, returning unaffected tokens...
         ⍺←⍬ 
         0=≢⍵:⍺ ⋄ opt←0⊃⍵ ⋄ tokens←1↓⍵ ⋄ done←0
         '-'≠1↑opt:(⍺,⊂opt)∇ tokens
         toksLeft←tokens{toks opt←⍺ ⍵
             case←(1↑1↓opt)∘≡∘, 
             case'f':toks with oForce∘←1
             case'R':toks with oCaller oLib∘←#''                  ⍝ -Root           also sets -lib ""
             case'r':toks with oCaller oLib∘←# LIB_SFX            ⍝ -root           also sets -lib '⍙⍙.require'
             case'S':toks with oCaller oLib∘←⎕SE''                ⍝ -Session        also sets -lib ""
             case's':toks with oCaller oLib∘←⎕SE LIB_SFX          ⍝ -session        also sets -lib '⍙⍙.require'
             case'd':toks with DEBUG∘←1                           ⍝ -debug
             case'-':toks with done∘←1                            ⍝ --                  (done with options)
             skip←1↓toks ⋄ first←⊃toks
             case'c':skip with oCaller∘←first                     ⍝ -Caller namespace
             case'l':skip with oLib∘←first                        ⍝ -lib    prefix
             case'p':skip with oPath,⍨←first                      ⍝ -path   addition     (augment search path: colon sep.)
             case'P':skip with oPath∘←first                       ⍝ -Path   replacement  (replace search path: colon sep.)
         
             Err'Invalid option: ',opt
         }opt
         done:⍺,toksLeft
         ⍺ ∇ toksLeft
     }∘,

     Tokenize←{ 
         pList←'-[^ ]+'  '(?x) (?: ([^ :]+|(?:"[^"]*")+|(?:''[^'']*'')+) (::?) )?  ( \( [^\)]* \) | [^ ]+)' ' +'
         aList←'\0'     '\0'  '\n'
         pList ⎕R aList⊣⊆DLB ⍵
     }
     ReportAndReturnObjects←{
        ~DEBUG: ⍵
          ⎕←'  DEBUG'DEBUG'oForce'oForce'  oCaller'oCaller'  oLib'oLib
          ⎕←('  oPath [',(⍕≢oPath),' entries]') oPath
          ⍵
     }

     oForce oCaller oLib←0 CALLER LIB_SFX
     oPath← ∊':',¨ ':',¨GetEnv¨ 'WSPATH' 'FSPATH'         ⍝ directories separated by ':

     objects←GetObj¨GetOptions Tokenize ⍵
     oPath←∪':' (≠⊆⊢) oPath
     ReportAndReturnObjects objects
 }
