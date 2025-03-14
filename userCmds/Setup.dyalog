 {ok}←Setup ignore
 ;DIR;utils;UCMD;util;fn;msg;obj;_
 ;Say0;Say1;SayE

 ⎕IO←⎕SE.⎕IO←0 ⋄ ⎕PW←120
 UCMD←⎕SE.UCMD

 ⎕←'To update, do:'
 ⎕←'⍝    ]file.edit /Users/petermsiegel/MyDyalogLibrary/pmsLibrary/userCmds/Setup.dyalog' 
 ⎕←'⍝    ⎕SH ''/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/userCmds/updateMyUcmds'''

 ⍝ Library directory
 DIR←'/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src'
 ⍝ Session libraries
 utils←'∆SH' '∆Fre' '∆D'
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
 Say0'Loading utilities...'
 :For util :In utils
     fn←(2+⌈/≢¨utils){t←'"','"',⍨⍵ ⋄ ⍺<≢t:t ⋄ ⍺↑t}util
     :Trap 911
          ⎕SE.UCMD 'obj←Load -target=⎕SE ',util
          obj← ⍕obj 
          Say1 30↑'Loaded "', obj,'"'
     :Else
         SayE'!!!FAILED to load ',util,' into ⎕SE'
     :EndTrap
 :EndFor

 Say0'Setup Complete'
 ok←1
