 waitAct←Sleep sec
 ;waitEach;waitLeft
⍝H actual← Sleep sec
⍝H Sleeps (⎕DL) a specified number of (float) seconds, while allowing interruption.
⍝H Returns actual amount slept.
⍝H
 waitEach←1⌊0.001⌈100÷⍨waitLeft←sec
 :Trap 0 1000
     :While waitLeft>0
         waitLeft-←⎕DL waitEach
     :EndWhile
 :EndTrap
 waitAct←sec-waitLeft
