 Setup; libraries;lib;full

libraries ← 'require' '∆FIX' '∆Format'
⎕←'PMS Setup.dyalog routine loading libraries:', ∊⎕FMT libraries

⍝ BEGIN:   PMS 20181011
  :FOR lib :IN libraries
    full←'file:///Users/petermsiegel/MyDyalogLibrary/pmsLibrary/src/',lib,'.dyalog'
    ⍝ ⎕←' *** ',full
    2 ⎕SE.⎕FIX full
  :ENDFOR
  
⍝ END:     PMS 20181011

⎕PATH←'⎕SE ⎕SE.∆Format ↑'
⎕←'PATH: ',⎕PATH

⍝)(!setupP!petermsiegel!2018 3 28 19 24 50 0!0
