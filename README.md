# require
Verifies that required APL objects are available to the calling environment; loads from workspaces or files as necessary.
<br>
* See requireHelp.txt for details.
<br>
* See function source require.dyalog.
<br>
Usage:<br>
       ⍝ Load require.dyalog from the active directory.<br>
         ]load require <br>
         ∇ myFunction<br>
          ...<br>
       ⍝ Load cmpx from dfns workspace and ∆HERE.dyalog from a file (unless already in caller namespace or ⎕PATH) <br>
       ⍝ Reasonably fast if cmpx and ∆HERE are accessible in ⎕PATH.<br>
         require 'dfns:cmpx' '∆HERE' <br>
         ... <br>
           ∇
