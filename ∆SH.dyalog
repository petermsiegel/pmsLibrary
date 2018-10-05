 ∆SH←{
  ⍝ ∆SH string- calls ⎕SH, but converts input returned back to UTF-8 Unicode.
     0::'Error executing ∆SH'⎕SIGNAL ⎕EN
     ↑{'UTF-8'⎕UCS ⎕UCS ⍵}¨⎕SH ⍵
 }
