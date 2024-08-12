:namespace TakeDropNs 

    ⎕IO ⎕ML←0 1 

∇out← spec TakeDrop in  
  ;⎕IO; ⎕ML
  ;tRows; tCols; dRows; dCols 
  ;myInt; MyTakeDrop; rc 

  ⎕IO ⎕ML← 0 1 
  :If 4≠ ≢spec ⋄ 11 ⎕SIGNAL⍨'Invalid left arg to TakeDrop' ⋄ :EndIf 

  tRows tCols dRows dCols← spec 

  :If 1∊ tRows tCols< 0
      11 ⎕SIGNAL⍨'Negative offsets for take or drop not implemented' 
  :EndIf  
  :If 3≠ ⎕NC '#.TakeDropNs.TakeDrop32' 
      911 ⎕SIGNAL⍨ 'Please load TakeDrop library: ',(⍕⎕THIS),'.Load 1' 
  :EndIf 

  :Select 181⌶in 
    :Case 323 ⋄ MyTakeDrop← #.TakeDropNs.TakeDrop32 ⋄ myInt←33333
    :Case 163 ⋄ MyTakeDrop← #.TakeDropNs.TakeDrop16 ⋄ myInt←  333 
    :Case 83  ⋄ MyTakeDrop← #.TakeDropNs.TakeDrop8  ⋄ myInt←    3
    :Else     ⋄ 11 ⎕SIGNAL⍨'Invalid TakeDrop object'
  :EndSelect 

  out← tRows tCols⍴ myInt                 ⍝ out must be same integer type as in 

  (rc out)← MyTakeDrop ¯1 out in,(⍴in),tRows tCols dRows dCols 

  :Select rc 
      :Case 0 
      :Case 911 
          11 ⎕SIGNAL⍨'DOMAIN ERROR: Negative offsets for take or drop not implemented'
      :Case 912 
          11 ⎕SIGNAL⍨'DOMAIN ERROR: Overtaking offsets for take or drop not allowed'
      :Else    
         911 ⎕SIGNAL⍨'LOGIC ERROR: TakeDrop32/16/8 failed with rc=',⍕rc 
  :EndSelect 
∇
TD← TakeDrop 

  Load←{  
      FORCE_LOAD∨← 0=⎕NC 'TakeDrop32' 
      (0=1↑⍵)∧ ~FORCE_LOAD: ''
      0:: 911 ⎕SIGNAL⍨ 'Unable to associate one or more C function names: TakeDrop*'
      nms← {
        parms← 'I4 =A <A I4 I4 I4 I4 I4 I4'
        ⎕NA 'I4 TakeDropLib.so|TakeDrop',(⍕⍵), ' ', parms
      }¨ 32 16 8 
      'Namespace ',(⍕⎕THIS),' contains fns:',∊' ',¨nms ⊣  FORCE_LOAD⊢← 0
  }

  Generate←{ 
        cLibName cSrcName ← 'TakeDropLib.so' 'TakeDropLib.c' 
      (0=1↑⍵)∧ ⎕NEXISTS cLibName: ''
        FORCE_LOAD∘← 1 
        GenCode←{ 
          fn← 'TakeDrop',⍵  ⋄  ty← 'int',⍵,'_t' ⋄ of← ⍕10× (32÷⍎⍵)
          'TAKE_DROP_FN' 'MY_INT_TYPE'  'MAGIC_OFFSET' ⎕R fn ty of⊢⍺
        }∘⍕¨
        pCode← ⊂'^\h*⍝P(\h?.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
        cCode← ⊂'^\h*⍝C(\h?.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
        cCode← ,/ pCode, cCode GenCode 32 16 8

        0= ≢(cCode) ⎕NPUT cSrcName 1: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
        msg← { 
          src lib← ⍵  ⋄ cr← ⎕UCS 13 
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
          _← ⎕SH ⎕←'cc -O3 -shared -o ',lib,' ',src
          out1← 'Generated source C code: ',src 
          out2← 'Private shared library:  ',lib
          out3← 'Included lib functions:  ','TakeDrop32/16/8'
          out1,cr,out2,cr,out3 
        } cSrcName cLibName
        msg 
    }

    FORCE_LOAD←0 

:Section SOURCE_CODE
⍝ Source code for library routines (P: Preamble, C: Main C Code)...
⍝P  /* TakeDrop.so library */
⍝P  #include <stdint.h>
⍝P  #include <stdio.h>
⍝P  #define I4 int32_t 
⍝C 
⍝C     I4 TAKE_DROP_FN(
⍝C             I4 offset, MY_INT_TYPE *outRaw, MY_INT_TYPE *inRaw,
⍝C             I4 inRows, I4 inCols, I4 tRows, I4 tCols, I4 dRows, I4 dCols
⍝C     ){
⍝C     int     skip, r, c;
⍝C     MY_INT_TYPE *inPtr, *outPtr;  /* int32_t, etc. */ 
⍝C
⍝C /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
⍝C     if (offset == -1) 
⍝C        offset= MAGIC_OFFSET;
⍝C
⍝C   /* We don't allow negative take and drop offsets. Sorry. */
⍝C     if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
⍝C       return 911;
⍝C
⍝C     inPtr = inRaw + offset;
⍝C     outPtr= outRaw + offset; 
⍝C
⍝C     inPtr+= dCols + dRows * inCols;
⍝C
⍝C     if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
⍝C       return 912;
⍝C
⍝C   skip= inCols-tCols;       
⍝C   for (r=0; r<tRows; ++r, inPtr+= skip ){
⍝C       for (c=0; c<tCols; ++c){
⍝C         *outPtr++ = *inPtr++ ;
⍝C       }
⍝C   }
⍝C
⍝C    return 0;
⍝C   }
⍝ End of source code
:EndSection

:EndNamespace


