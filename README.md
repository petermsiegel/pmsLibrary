### require
Verifies that required APL objects are available to the calling environment; loads from workspaces or 
files as necessary.
* See require.help for details.
* See function source require.dyalog.

Usage:
````dyalog
       ⍝ Load require.dyalog from the active directory. 
         ]load require  
         ∇ myFunction 
          ... 
       ⍝ First time through, loads cmpx from dfns workspace and ∆HERE.dyalog from a file. 
       ⍝ Updates ⎕PATH to reflect locations of loaded packages (cmpx, ∆HERE).
       ⍝ Reasonably fast since it does the minimal checks required: 
       ⍝     current namespace, ⎕PATH, then workspaces and disk locations. 
         require 'dfns:cmpx' '∆HERE'  
         ... 
         ∇
````
