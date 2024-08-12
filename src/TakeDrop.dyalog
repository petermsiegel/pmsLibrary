out←TD (in tRows tCols dRows dCols) 
  ;⎕IO;⎕ML
  ;rc 

⎕IO ⎕ML← 0 1      

:IF ~⎕NEXISTS 'TakeDrop.so' 
     911 ⎕SIGNAL⍨ 'Library "TakeDrop.so" does not exist! Have you run TakeDrop_Gen⍬ first?' 
:EndIf 

:IF 323≠ 181⌶in ⋄ :AndIf 1 
     ⎕← 'Ensuring input array has 4-byte integers (⎕DR 323). For best performance do in advance.'
     ⎕← 'For var ¨in¨,'
     ⎕← '   save← in[⎕io;⎕io] ⋄ in[⎕io;⎕io]← 33333 ⋄ in[⎕io;⎕io]← save'
     ⎕SHADOW 'save' ⋄ save← in[0;0]  ⍝ Ensure ¨in¨ is ⎕DR 323
    in[0;0]← 33333 ⋄ in[0;0]← save
:EndIf 
:IF 323≠ 181⌶in ⋄ :OrIf 2≠⍴⍴in 
    11 ⎕SIGNAL⍨'Argument (in) must be a matrix of  ⎕DR type "323" (32-bit integer array)'  
:EndIf 
:IF ¯1∊ tRows tCols dRows dCols 
    11 ⎕SIGNAL⍨ 'Take and drop args (tRows tCols dRows dCols) must all be positive'
:EndIF 

out← tRows tCols⍴33333                    ⍝ required placeholder!
        
⍝C     int32_t TakeDrop(int32_t offset, int32_t *outRaw, int32_t *inRaw,
⍝C                      int inRows, int inCols, int tRows, int tCols, int dRows, int dCols){ 
_← ⎕NA 'I4 TakeDrop.so|TakeDrop I4 =A <A I4 I4 I4 I4 I4 I4'
(rc out)← TakeDrop ¯1 out in,(⍴in),tRows tCols dRows dCols 
:IF rc≠0  
     11 ⎕SIGNAL 'TakeDrop failed with rc=',⍕rc
:EndIf 

save (out[⎕io;⎕io])← out[⎕io;⎕io] 33333 ⋄ out[⎕io;⎕io]← save


