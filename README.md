# require
Verifies that required APL objects are available to the calling environment; loads from workspaces or 
files as necessary.<br>

* See require.help for details.<br>
* See function source require.dyalog.<br><br>

Usage:

````dyalog
       ⍝ Load require.dyalog from the active directory. 
         ]load require  
         ∇ myFunction 
          ... 
       ⍝ Load cmpx from dfns workspace and ∆HERE.dyalog from a file (unless already in caller namespace or ⎕PATH)  
       ⍝ Reasonably fast if cmpx and ∆HERE are accessible in ⎕PATH. 
         require 'dfns:cmpx' '∆HERE'  
         ... 
         ∇
````
