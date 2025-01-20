 {ok}←Setup ignore
 ;DIR;LIBS;UCMD;lib;libF;msg;obj;_
 ;Say0;Say1;SayE

 ⎕IO←⎕SE.⎕IO←0 ⋄ ⎕PW←120
 UCMD←⎕SE.UCMD

 ⎕←'To update, do:'
 ⎕←'⍝    ]file.edit /Users/petermsiegel/MyDyalogLibrary/pmsLibrary/userCmds/Setup.dyalog' 
 ⎕←'⍝    ⎕SH ''/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/userCmds/updateMyUcmds'''

 ⍝ Library directory
 DIR←'/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src'
 ⍝ Session libraries
 LIBS←'∆SH' '∆F/∆F' '∆D'
 #.⎕PATH,⍨←' ⎕SE'
 ok←0

 Say0←{1:⎕←⍵}
 Say1←{1:⎕←'>>> ',⍵}
 SayE←{1:⎕←'--- ','ERROR ',⍵}

 Say0'System Variables:'
 Say1'⎕IO: ',⎕IO,';  ','⎕PW: ',⎕PW,';  ','⎕WA: ',⎕WA
 Say1'#.⎕PATH: ',#.⎕PATH


 {}UCMD'cd ',DIR
 Say0'Directory now...'
 Say1 UCMD'cd'

 msg←⍬
 Say0'Loading libraries...'
 :For lib :In LIBS
     libF←(2+⌈/≢¨LIBS){t←'"','"',⍨⍵ ⋄ ⍺<≢t:t ⋄ ⍺↑t}lib
     :Trap 911
             ⍝ UCMD '_←load -target=⎕SE ',lib
         obj←2 ⎕SE.⎕FIX'file://',lib,'.dyalog'
         Say1'   Loaded  ',libF,' into ⎕SE as',obj
     :Else
         SayE'!!!FAILED to load ',libF,' into ⎕SE'
     :EndTrap
 :EndFor

 Say0'Setup Complete'
 ok←1
