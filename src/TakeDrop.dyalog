:namespace TakeDrop

    ⎕IO ⎕ML←0 1 

∇ Benchmark
  ;in; inShape; out; cmpx; tR; tC; dR; dC; c_FullCopy 
  'cmpx' ⎕CY 'dfns'
  {}Reset                                      ⍝ Force compile of C lib and then ⎕NA lib members
  inShape← 3000 4000                           ⍝ input obj
  tR tC dR dC← 1000 1000 1000 1000             ⍝ take rows, cols; drop rows, cols
  in← inShape⍴33333+⍳×/inShape                 ⍝ Ensure it's 32-bit integer with distinct elems
  out← (tR tC⍴33333)                           ⍝ Placeholder of correct size and type!
  c_FullCopy←  ¯1 out in, inShape, tR tC dR dC ⍝ parameters for call of C-language routine
  c_NoCopy←    ¯2 out in, inShape, tR tC dR dC ⍝ parameters for C-lang rtn that returns 
                                               ⍝ w/o doing anything
⍝ Share some info with user...                                               
  'tR tC dR dC← ',⍕tR tC dR dC 
  'inShape← ',⍕inShape 
  'in←  inShape⍴ 33333+ ⍳×/inShape  ⍝ in:   32-bit integer array'
  'out← tR tC⍴33333                 ⍝ out: 32-bit integer array'
   '¯'⍴⍨ ⎕PW-2

  ⎕←'∘ TD: APL routine that creates its own output array (out) and calls'
  ⎕←'      a 32-, 16-, or 8-bit C fn based on the input array''s integer type.'
  ⎕←'∘ c_FullCopy←  ¯1     out           in,          inShape,     tR tC       dR dC'
  ⎕←'∘ c_NoCopy←    ¯2     out           in,          inShape,     tR tC       dR dC'
  ⎕←'               magic  output array  input array  input shape  take shape  drop shape'
  ⎕←'∘ Other routines are self-explanatory.'
  ⎕←'+----------+'
  ⎕←'|  Notes   |'
  ⎕←'+----------+'
  ⎕←'[*] c_NoCopy will give a different answer, since it bypasses any C-language copying.'
  ⎕←'    All other items must give the same answer'
  ⎕←''
  ⎕SHADOW 'j' 
  cmpx 'in[j;j←tR+⍳tC]' '(2⍴⊂tR+⍳tC)⌷in'  'tR tC↑dR dC↓in' '⊃⌽TD32 c_NoCopy' '⊃⌽TD32 c_FullCopy' 'tR tC dR dC TD in'  
∇

∇ out← spec TakeDrop in  
  ;⎕IO; ⎕ML
  ;tRows; tCols; dRows; dCols 
  ;myInt; MyTakeDrop; rc 

  ⎕IO ⎕ML← 0 1 
  :If 4≠ ≢spec ⋄ 11 ⎕SIGNAL⍨'Invalid left arg to TakeDrop' ⋄ :EndIf 

  tRows tCols dRows dCols← spec 

  :If 1∊ tRows tCols< 0
      11 ⎕SIGNAL⍨'Negative offsets for take or drop not implemented' 
  :EndIf  
  :If 3≠ ⎕NC 'TakeDrop32' 
      911 ⎕SIGNAL⍨ 'Please load TakeDrop library: ',(⍕⎕THIS),'.Load 1' 
  :EndIf 

  :Select 181⌶in 
    :Case 323 ⋄ MyTakeDrop← TakeDrop32 ⋄ myInt←33333
    :Case 163 ⋄ MyTakeDrop← TakeDrop16 ⋄ myInt←  333 
    :Case 83  ⋄ MyTakeDrop← TakeDrop8  ⋄ myInt←    3
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
TD← TakeDrop       ⍝ Simple alias...

  ∇ msg←Reset 
      msg← (Generate 1),(⎕UCS 13), Load 1
  ∇

  Load←{  
      FORCE_LOAD∨← 0=⎕NC 'TakeDrop32' 
      (0=1↑⍵)∧ ~FORCE_LOAD: ''
      0:: 911 ⎕SIGNAL⍨ 'Unable to associate one or more C function names: TakeDrop*'
      nms← {
        parms← 'I4 =A <A I4 I4 I4 I4 I4 I4'
           ⎕NA 'I4 TakeDropLib.so|TakeDrop',⍵, ' ', parms
      }∘⍕¨ 32 16 8 
    ⍝ Simple aliases
      TD32∘← TakeDrop32 ⋄ TD16∘← TakeDrop16 ⋄ TD8∘← TakeDrop8
      'Namespace ',(⍕⎕THIS),' contains fns:',∊' ',¨nms ⊣  FORCE_LOAD⊢← 0
  }

  Generate←{  
        cLibName cSrcName ← 'TakeDropLib.so' 'TakeDropLib.c' 
      (0=1↑⍵)∧ ⎕NEXISTS cLibName: ''
        FORCE_LOAD∘← 1 
        MAGIC_BYTES← AOff 2                ⍝ 40
        msg← 'Magic offset in bytes: ',⍕MAGIC_BYTES 
        GenCode← MAGIC_BYTES { 
          iCh← ⍕⍵ 
          fn← 'TakeDrop',iCh  ⋄  ty← 'int',iCh,'_t' ⋄ of← ⍕⍺⍺× 8÷⍵
          'TAKE_DROP_FN' 'MY_INT_TYPE'  'MAGIC_OFFSET' ⎕R fn ty of⊢⍺
        }¨
        pCode← ⊂'^\h*⍝P(\h?.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
        cCode← ⊂'^\h*⍝C(\h?.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
        cCode← ,/ pCode, cCode GenCode 32 16 8
        count← cCode ⎕NPUT cSrcName 1
        0= ≢count: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
        msg { cr← ⎕UCS 13 
          src lib← ⍵   
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
          out← ⊂'Generated source C code: ',src 
          _← ⎕SH cc← 'cc -O3 -shared -o ',lib,' ',src 
          out,← ⊂'>>> ', cc
          out,← ⊂'Private shared library:  ',lib
          out,← ⊂'Included lib functions:  ','TakeDrop32/16/8'
          out,← ⊂'Alias lib functions:     TD32, TD16, TD8'
          ⍺, ∊cr, ↑out
        } cSrcName cLibName 
    }

    FORCE_LOAD←0 

  AOff←{
    ⍝ offset_bytes← [library] AOff rank 
    ⍝ Find the offset in BYTES to the payload of any APL I4 (32-bit integer) array.
    ⍝ (Same as finding the length of the header in bytes).
    ⍝ ⍵:  A single integer:  
    ⍝     1: return offset in bytes for vector, 2: for matrix, 3: for 3-dim array
    ⍝ ⍺:  the dynamic library containing MEMCPY. You shouldn't need to set this.
    ⍝     What is the name of the dynamic library for utility MEMCPY?
    ⍝     We are assuming it's in dyalog64 with a possible extension:
    ⍝         Windows: (none); Mac: .dylib; Linux, AIX, Pi: .so
    ⍝     If this isn't correct, set ⍺ on your own!
    ⍝ Note: This can be extended by the reader to handle other ints, floats, char types, etc. 
    ⍝       We expect the header offsets will be identical given the same ranks.
    ⍝ Method:
    ⍝ ∘ Copy out a small number of integers (but bigger than the expected header size)
    ⍝   as a "raw" APL array (type 'A'), starting it with a unique "signature" integer value.
    ⍝ ∘ Read it back as an integer array. 
    ⍝ This will return the original header as part of the APL payload (integer array).
    ⍝ ∘ Search for the first instance of the signature, 
    ⍝   which will be the offset to the APL payload (just past the header).
    ⍝ Returns: the offset IN BYTES for the rank specified.
    ⍝ Note: Currently on the Mac, the offset is:
    ⍝       24+ 8× rank

    ⎕IO ⎕ML←0 1
    rank signature nelem← ⍵ ¯314159265 32  
    ⍺← 'dyalog64', '' '.dylib' '.so'⊃⍨ 'Win' 'Mac'⍳ ⊂3↑⊃'.'⎕WG'APLversion'
    library← ⍺ 
    ⋄ err1← 'AOff DOMAIN ERROR: rank ∉ 1 2 3  -OR- 1 ≠ ≢rank' 11  
    ⋄ err2← 'AOff UNKNOWN ERROR' 911
    ⋄ err2← 'AOff OBJECT FORMAT ERROR: unable to locate signature at start of payload' 912
  1≠ ≢rank: ⎕SIGNAL/err1 ⋄ (>∘3∨<∘1) rank: ⎕SIGNAL/err1 ⋄ 0:: ⎕SIGNAL/err2
  ⍝ Load utility memcpy as local fn MC2I4 (copy header and payload of 32-bit int array)
  ⍝ void* memcpy( void* dest, const void* src, std::size_t count );
    MC2I4← ⊢  ⋄ _←'MC2I4' ⎕NA library,'|MEMCPY >I4[] <A I4' 
  ⍝ * Object contains the signature, an integer unlikely to occur in the header,
  ⍝   padded with zeroes to length <nelem> and shaped as shown here to the rank <rank>.
    obj←  (nelem↑ signature)⍴⍨ nelem,⍨ 1⍴⍨ ¯1+ rank
    iOff← signature⍳⍨ MC2I4 nelem obj (4× nelem)
  iOff<nelem: 4× iOff ⋄ ⎕SIGNAL/err3 
}


:Section SOURCE_CODE
⍝ Source code for library routines (P: Preamble, C: Main C Code)...
⍝P  /* TakeDrop.so library */
⍝P  #include <stdint.h>
⍝P  #include <stdio.h>
⍝C 
⍝C     int TAKE_DROP_FN(
⍝C             int offset, MY_INT_TYPE *outRaw, MY_INT_TYPE *inRaw,
⍝C             int inRows, int inCols, int tRows, int tCols, int dRows, int dCols
⍝C     ){
⍝C     int     skip, r, c;
⍝C     MY_INT_TYPE *inPtr, *outPtr;  /* int32_t, etc. */ 
⍝C
⍝C /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
⍝C     if (offset < 0) {
⍝C       if (offset == -1) 
⍝C           offset= MAGIC_OFFSET;
⍝C       else if (offset == -2)   /* This is for testing w/o doing any copying */
⍝C           return 0;   
⍝C       else 
⍝C           return 999;          /* invalid offset */
⍝C     }
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


