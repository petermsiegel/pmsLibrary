TakeDrop_Gen←{ 
    ⎕IO ⎕ML←0 1 
    cFnName cSrcName cLibName← 'TakeDrop' '_TakeDrop.c'  'TakeDrop.so'

    cCode← ⊂'^\h*⍝C(\h?.*)' ⎕S '\1'⊣ ⎕NR ⊃⎕XSI
    0= ≢cCode ⎕NPUT cSrcName 1: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
    { 
      fn src lib← ⍵ 
    0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
      _← ⎕SH 'cc -shared -o ',lib,' ',src
      'Created private shared library "',lib,'" with C function "' ,fn,'"'
    } cFnName cSrcName cLibName
  
⍝ Source code for cSrcName above
⍝C /*  Source Code for _TakeDrop.c => TakeDrop.so'  */
⍝C     #include <stdint.h>
⍝C     #include <stdio.h>
⍝C     /*  MAGIC_OFFSET: Don't use this unless you know what you are doing! */
⍝C     #define MAGIC_OFFSET 10            /* I32 (10*4) bytes */
⍝C
⍝C     int32_t TakeDrop(int32_t offset, int32_t *outRaw, int32_t *inRaw,
⍝C                      int inRows, int inCols, int tRows, int tCols, int dRows, int dCols){
⍝C       int     skip, r, c;
⍝C       int32_t *inPtr, *outPtr; 
⍝C
⍝C  
⍝C       if (offset == -1) 
⍝C         offset= MAGIC_OFFSET;
⍝C
⍝C     /* We don't allow negative take and drop offsets. Sorry. */
⍝C       if ((tRows<0) || (tCols<0) || (dRows<0) || (dCols<0)) {
⍝C         return 911;
⍝C       }
⍝C
⍝C       inPtr = inRaw + offset;
⍝C       outPtr= outRaw + offset; 
⍝C
⍝C       inPtr+= dCols + dRows * inCols;
⍝C
⍝C       if ((tRows>(inRows-dRows) || (tCols>(inCols-dCols)))){
⍝C         return 11;
⍝C       }
⍝C
⍝C     skip= inCols-tCols;
⍝C     for (r=0; r<tRows; ++r, inPtr+= skip ){
⍝C         for (c=0; c<tCols; ++c){
⍝C           *outPtr++ = *inPtr++ ;
⍝C         }
⍝C     }
⍝C
⍝C      return 0;
⍝C
⍝C
⍝C     }
⍝ End of source code

}
