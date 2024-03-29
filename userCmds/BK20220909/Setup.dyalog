﻿ {ok}←Setup ignore
 ;DIR;LIBS;UCMD;msg;_
 ;Say0;Say1;SayE

 ⎕IO←⎕SE.⎕IO←0 ⋄ ⎕PW←120
 UCMD← ⎕SE.UCMD

 ⎕←'Setup: /Users/petermsiegel/MyDyalogLibrary/pmsLibrary/userCmds/Setup.dyalog'

 ⍝ Library directory
  DIR← '/Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src'
 ⍝ Session libraries
  LIBS← '∆FIX.aplf' '∆SH.dyalog' '∆Format.dyalog'    

 ok←0

 Say0←{ 1: ⎕←⍵ }
 Say1←{ 1: ⎕←'>>> ',⍵ }
 SayE←{ 1: ⎕←'--- ','ERROR ',⍵ }

 Say0 'System Variables:'
 Say1 '⎕IO ',⎕IO,'    ','⎕PW ',⎕PW,'    ','⎕WA ',⎕WA
 

 {}UCMD'cd ',DIR
 Say0 'Directory now...'
 Say1 UCMD'cd' 

 msg←⍬
 :For lib :In LIBS
         :TRAP 911 
             UCMD '_←load -target=⎕SE ',lib
             Say1 'Loaded "',lib,'" into ⎕SE'
         :Else 
             SayE 'loading "',lib,'" into ⎕SE'
         :EndTrap
 :EndFor

 Say0 'Setup Complete'
 ok←1
