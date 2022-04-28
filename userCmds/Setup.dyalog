 {ok}←Setup ignore
 ;LIBS;bad;good;msg;reqFi;require;say0;say1

 ⎕IO←⎕SE.⎕IO←0 ⋄ ⎕PW←120
 ok←0
 say0←{ ⎕←⍵}
 say1←{⍺←1 ⋄ ⎕←(⍺⊃'!!! ' '    '),⍵}

 say0 'Running ',(⊃⎕SI),' from ',⎕SE.UCMD 'cd'
 say0 'Setting...'
 say1 '⎕IO ',⎕IO
 say1 '⎕PW ',⎕PW

⍝ ∆REQ - require.dyalog bootstraps other objects in path WSPATH
 dir←'/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src'
 reqFi←dir,'/require.dyalog'

⍝ load ¨siegel¨ load session  libraries...
 LIBS←'∆Format' '∆FIX' '∆SH'

 {}⎕SE.UCMD'cd ',dir 
 say0 'Directory now...'
 say1 ⎕SE.UCMD'cd' 

 :Trap 0
     msg←2 ⎕SE.⎕FIX'file://',reqFi
     require←⎕SE.∆REQ
     say1'User command "require" loaded into ⎕SE: ',∊msg
 :Else
     0 say1'Failed to FIX user cmd "require" from ',reqFi
     →0
 :EndTrap

 good←bad←⍬
 :For lib :In LIBS
     :Trap 0
         require lib
         good,←⊂lib
     :Else
         0 say1 'ERROR: ',⎕DMX.EM
         bad,←⊂lib
     :EndTrap
 :EndFor

 say0 'Loading core libraries into ⎕SE'
 :If ×≢good 
        say1'Successful:  ',⍕good 
 :Else 
      0 say1'Successful:   [none]'
 :EndIf

 :If ×≢bad  
      0 say1'Unsuccessful:',⍕bad  
 :Else
        say1'Unsuccessful: [none]'
 :EndIf

 ok←1
