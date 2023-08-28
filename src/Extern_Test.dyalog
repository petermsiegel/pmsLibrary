 (cmddir list)←{tell}TRADFN1 names;ignore_me;me_too;⎕FR
⍝ "TEST/DEMO" function for Extern utility (PMS)
⍝ ∘ This is: Dyalog ⎕SE.SaltUtils.GetUCMDList
⍝   with locals (internals) not declared and with externals declared.
⍝ ∘ Retrieve the list of all Spice commands
⍝ ORIGINAL LOCALS: ;folder;nc;ns;show1;t;b;gn;cn;files
 :Extern ClassFolder splitOn PATHDEL BootPath DEBUG CR lCase findMinLen FS PATHDEL
 :Extern ⎕IO
 :If show1←326∊⎕DR names
     folder←1↑(cmddir names)←names
 :Else
     folder←ClassFolder∘''¨(cmddir←⎕SE.SALT.Settings'cmddir')splitOn PATHDEL
 :EndIf
 ignore←{junk Plus ⎕SE.junk}names
 t←↑⍪/⎕SE.SALT.List¨'"',¨folder,¨⊂FS,names,'" -rec -raw -full=2'
 files←∪(0=,⊃⍴¨t[;1])/t[;2]
 :If ~show1
     files∪←(BootPath'spice',FS)∘,¨'Spice' 'SaltInSpice' 'NewCmd'  ⍝ always there
 :EndIf
 list←⍬
 :If 0=⎕NC'tell'
     tell←0
 :EndIf
 :With test1
     one
     two
     :With one
         test
     :EndWith
 :End

⍝ Spice keeps track of the commands in the Spice folder
 :For t :In files
     :Trap DEBUG↓0
         ns←⎕SE.SALT.Load'"',t,'.dyalog" -noname -nolink'
         :If 9=⎕NC'ns'
         :AndIf 3=⌊|ns.⎕NC⊂'List'
         :AndIf ~0∊⍴nc←ns.List
             nc←{⍵⊣⍵.(Name Group)←'' 'NONE'VerifyNEstring¨2↑⍵.(Name Group Desc Parse)←,¨⍵.(Name Group Desc Parse)}¨,nc
             nc.ObjName←⊂{⍵↑⍨-⊥⍨'.'≠⍵}⍕ns
             nc.FullName←⊂t
             nc.Name←~∘'() '¨cn←nc.Name
             nc.MinLen←{(b⍳1)×1∊b←'('=⍵}¨cn
             list,←nc
         :EndIf
     :Else
         ⍞←CR,CR,⍨'* Error loading a User Command from ',t,': ',⎕IO⊃⎕DM
     :EndTrap
 :EndFor
 →(⍴list)↓0
⍝ Remove duplicates, if any. Groups are important.
 list←(b←(⍳⍴t)=t⍳t←{⍺,'.',⍵}/gn←lCase⊃list.(Group Name))/list ⋄ t←b/t ⋄ gn←b⌿gn
⍝ At this point all we have is unique group/names. We now try to find the unique names
 list←gn,⊃list.(Name Desc Parse ObjName FullName MinLen) ⍝ get rid of namespaces
 list[;8]←list[;8]findMinLen gn
