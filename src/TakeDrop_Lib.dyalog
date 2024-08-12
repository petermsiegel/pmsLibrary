TakeDrop_Lib←{ 
  ⍝ Usage:
  ⍝   TakeDrop_Lib 'G[en]' | 'L[oad]' | 'L[oad ]G[en]' | ''
  ⍝   If '' is specified, 
  ⍝       ∘ generate only if TakeDrop.so does not exist in the active directory'
  ⍝       ∘ load the 3 APL ⎕NA routines TakeDrop32/16/8 
  ⍝         only if the namespace #.TakeDropNs does not exist.
  ⍝   If 'Gen' is specified, generate TakeDrop.so in the current active directory,
  ⍝       generating and compiling the 3 routines TakeDrop32/16/8.c.
  ⍝   If 'Load' is specified, load the 3 APL ⎕NA routines TakeDrop32/16/8
  ⍝       in namespace #.TakeDropNs.
  ⍝   Returns information on what was loaded or ⍬ if no work was required.
  ⍝ 
    ⎕IO ⎕ML←0 1 
    Generate←{ 
        cSrcName cLibName← 'TakeDropLib.c'  'TakeDropLib.so'
      (⍵=0)∧ ⎕NEXISTS cLibName:  0, ⊂⍬
        GenCode←{ 
          fn← 'TakeDrop',⍵  ⋄  ty← 'int',⍵,'_t' ⋄ of← ⍕10× (32÷⍎⍵)
          'TAKE_DROP_FN' 'MY_INT_TYPE'  'MAGIC_OFFSET' ⎕R fn ty of⊢⍺
        }∘⍕¨
        pCode← ⊂'^\h*⍝P(\h?.*)' ⎕S '\1'⊣ ⎕NR ⊃⎕XSI 
        cCode← ⊂'^\h*⍝C(\h?.*)' ⎕S '\1'⊣ ⎕NR ⊃⎕XSI
        cCode← ,/ pCode, cCode GenCode 32 16 8

        0= ≢(cCode) ⎕NPUT cSrcName 1: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
        msg← { 
          src lib← ⍵  ⋄ cr← ⎕UCS 13 
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
          _← ⎕SH 'cc -shared -o ',lib,' ',src
          out1← 'Generated source C code: ',src 
          out2← 'Private shared library:  ',lib
          out3← 'Included lib functions:  ','TakeDrop32/16/8'
          out1,cr,out2,cr,out3 
        } cSrcName cLibName
        1, ⊂⊂msg 
    }
    Load←{ nsNm← '#.TakeDropNs' 
      (⍵=0)∧ 9=⎕NC nsNm: ''
      0:: 911 ⎕SIGNAL⍨ {
        _← ⎕EX ⍵
        'Unable to associate one or more C function names: TakeDrop*'
      } tdNs 
      ns← ⍎nsNm ⎕NS '' ⋄ nms←  ⍬
      nms,← ⊂ns.⎕NA 'I4 TakeDropLib.so|TakeDrop32 I4 =A <A I4 I4 I4 I4 I4 I4'
      nms,← ⊂ns.⎕NA 'I4 TakeDropLib.so|TakeDrop16 I4 =A <A I4 I4 I4 I4 I4 I4'
      nms,← ⊂ns.⎕NA 'I4 TakeDropLib.so|TakeDrop8  I4 =A <A I4 I4 I4 I4 I4 I4'
      ⊂'Namespace ',nsNm,' contains fns:',∊' ',¨nms 
    }
    g l← 'gl'∊ ⎕C ⍵
    g msg← Generate g 
    msg,← Load g∨l
  0 0≢ ≢¨msg: ↑msg  ⋄ ⍬

  
⍝ Source code for library routines...
⍝P  /* TakeDrop.so library */
⍝P  #include <stdint.h>
⍝P  #include <stdio.h>
⍝C
⍝C     int TAKE_DROP_FN(int offset, MY_INT_TYPE *outRaw, MY_INT_TYPE *inRaw,
⍝C                    int inRows, int inCols, int tRows, int tCols, int dRows, int dCols){
⍝C     int     skip, r, c;
⍝C     MY_INT_TYPE *inPtr, *outPtr;  /* int32_t, etc. */ 
⍝C
⍝C /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
⍝C     if (offset == -1) 
⍝C        offset= MAGIC_OFFSET;
⍝C
⍝C   /* We don't allow negative take and drop offsets. Sorry. */
⍝C     if ((tRows<0) || (tCols<0) || (dRows<0) || (dCols<0)) {
⍝C       return 911;
⍝C     }
⍝C
⍝C     inPtr = inRaw + offset;
⍝C     outPtr= outRaw + offset; 
⍝C
⍝C     inPtr+= dCols + dRows * inCols;
⍝C
⍝C     if ((tRows>(inRows-dRows) || (tCols>(inCols-dCols)))){
⍝C       return 11;
⍝C     }
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
}
