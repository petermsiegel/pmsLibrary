:namespace TakeDrop

    ⎕IO ⎕ML←0 1 

∇ Benchmark
  ;code ;in ;inShape ;out ;cmpx ;tR ;tC ;dR ;dC ;fullCpyParms ;noCpyParms  
  'cmpx' ⎕CY 'dfns'
  inShape← 3001 4002                           ⍝ input obj
  tR tC dR dC← 1000 999 998 997                ⍝ take rows, cols; drop rows, cols
  in← inShape⍴33333+⍳×/inShape                 ⍝ Ensure it's 32-bit integer with distinct elems
  out← (tR tC⍴33333)                           ⍝ Placeholder of correct size and type!
  fullCpyParms← ¯1 out in, inShape, tR tC dR dC ⍝ parameters for call of C-language routine
  noCpyParms←   ¯2 out in, inShape, tR tC dR dC ⍝ parameters for call of C-language routine
 
 
 ⍝ Share some info with user...                                               
  (26↑'tR tC← ',(⍕tR tC)),  '        ⍝ Take shape '
  (26↑'dR dC← ',(⍕dR dC)),  '        ⍝ Drop shape '
  (26↑'inShape← ',⍕inShape),'        ⍝ Input matrix shape'
  'in←  inShape⍴ 33333+ ⍳×/inShape   ⍝ in:  32-bit integer matrix'
  'out← tR tC⍴33333                  ⍝ out: output matrix prototype'
   '¯'⍴⍨ ⎕PW-2

  '∘ TD_APL2C: APL routine that manages the array shapes and types and calls TD32_C'
  '∘ TD32_C:   Compiled C-language routine solely for 32-bit integer matrices;'
  '  Input array is validated, output array is generated, and args are built by hand.'  
  '  - ⎕NA prototype for TD32_C'
  '    I4 TakeDropLib.so|TakeDrop32  I4   =A  <A I4 I4   I4 I4 I4 I4'
  '                                 magic out in inshape tR tC dR dC'
  '  - Arg lists for TD32_C:'
  '    * fullCpyParms: APL copies in input obj, copies in output prototype, copies out output;'
  '      C routine copies elements with compact code:'
  '      for (r=0; r<tRows; ++r, inPtr+= skip ){'
  '          for (c=0; c<tCols; ++c){'
  '               *outPtr++ = *inPtr++ ;'
  '          }'
  '      }'
  '    * noCpyParms: APL copies as for FullCopy, but does no other work.'
  '∘ Other routines are self-explanatory.'
  '--------'
  '[*] Note: The noCpyParms call will give a different answer, bypassing any C-language copying.'
  ''
  
  ⎕SHADOW 'j' 'TD32_C' 'TD_APL2C' 
⍝ Helpful names for the cmpx output...
  TD32_C← TakeDrop32 ⋄ TD_APL2C← TakeDrop    
  code←  'in[dR+⍳tR;dC+⍳tC]' '(dR+⍳tR)(dC+⍳tC)⌷in' 'tR tC↑dR dC↓in'
  code,← '⊃⌽TD32_C noCpyParms'   '⊃⌽TD32_C fullCpyParms'   'tR tC dR dC TD_APL2C in'  
  cmpx code  
∇

∇ out← spec TakeDrop in  
  ;⎕IO ;⎕ML ;tRows ;tCols ;dRows ;dCols ;rc 

  ⎕IO ⎕ML← 0 1 
  'Invalid left arg to TakeDrop' ⎕SIGNAL 11/⍨ 4≠ ≢spec 

  tRows tCols dRows dCols← spec 

  'Negative offsets for take or drop not implemented' ⎕SIGNAL  11/⍨ tRows tCols∨.< 0
  'Takedrop: Load TakeDrop32/16/8 before calling'     ⎕SIGNAL 910/⍨ 3≠ ⎕NC 'TakeDrop32' 

  :Select 181⌶in    ⍝ Check ⎕DR without implicit compaction
    :Case 323  
        (rc out)← TakeDrop32 ¯1 (tRows tCols⍴ 33333) in, (⍴in),tRows tCols dRows dCols 
    :Case 163  
        (rc out)← TakeDrop16 ¯1 (tRows tCols⍴ 333)   in, (⍴in),tRows tCols dRows dCols 
    :Case 83   
        (rc out)← TakeDrop8  ¯1 (tRows tCols⍴ 3)     in, (⍴in),tRows tCols dRows dCols 
    :Else     
        'TakeDrop is limited to an integer matrix right arg' ⎕SIGNAL 11 
  :EndSelect 

  :Select rc 
      :Case 0 
      :Case 911 
          11 ⎕SIGNAL⍨'DOMAIN ERROR: Negative offsets for TakeDrop not implemented'
      :Case 912 
          11 ⎕SIGNAL⍨'DOMAIN ERROR: Overtaking offsets for TakeDrop not allowed'
      :Else    
         911 ⎕SIGNAL⍨'LOGIC ERROR: TakeDrop lib routine failed with rc=',⍕rc 
  :EndSelect 
∇

  ∇ msg← Make; l  
    msg←  MakeCLib 0
    msg,← (0≠≢l)/(⎕UCS 13),l← MakeQuadNA 0
  ∇

  MakeQuadNA←{    
      FORCE_LOAD∨← 0=⎕NC 'TakeDrop32' 
      (0=1↑⍵)∧ ~FORCE_LOAD: ''
      0:: 911 ⎕SIGNAL⍨ 'Unable to associate one or more C function names: TakeDrop*'
      nms← 'I4 =A <A I4 I4 I4 I4 I4 I4'∘{
          ⎕NA 'I4 TakeDropLib.so|TakeDrop',⍵, ' ',⍺
      }¨ '32' '16' '8' 
      'Namespace ',(⍕⎕THIS),' contains fns:',∊' ',¨nms ⊣  FORCE_LOAD⊢← 0
  }

  FORCE_LOAD←0 
  MakeCLib←{  
        dName cLibName cSrcName ← 'TakeDrop.dyalog' 'TakeDropLib.so' 'TakeDropLib.c'
        ForceUpdate← { ⍵: 1 ⋄ d c←⍺ ⋄  0= ⎕NEXISTS c: 1 ⋄ >/1 ⎕DT¨3 ⎕NINFO¨d c: 1 ⋄ 0 }  
      ~dName cLibName ForceUpdate 1↑⍵: 'TakeDrop.dyalog: C library and Dyalog namespace are up to date!'
        FORCE_LOAD∘← 1 
        MAGIC_BYTES← AOff 2                        ⍝ For matrices (⍵=2), ==> 40
        msg← 'Magic offset in bytes: ',⍕MAGIC_BYTES 
        GenCode← MAGIC_BYTES { 
          iCh← ⍕⍺ 
          fn← 'TakeDrop',iCh  ⋄  ty← 'int',iCh,'_t' ⋄ of← ⍕⍺⍺× 8÷⍺
          'TAKE_DROP_FN' 'MY_INT_TYPE'  'MAGIC_OFFSET' ⎕R fn ty of⊢⍵
        }¨
        pre bdy← 'PB'{⊂('^\h*⍝',⍺,'\h?(.*)') ⎕S '\1'⊣⍵}¨ ⊂⎕SRC ⎕THIS  
        libCode← ,/ pre, 32 16 8 GenCode bdy
        count← libCode ⎕NPUT cSrcName 1
        0= ≢count: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
        msg { cr← ⎕UCS 13 
          src lib← ⍵   
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
          out← ⊂'Generated source C code: ',src 
          _← ⎕SH cc← 'cc -O3 -shared -o ',lib,' ',src 
          out,← ⊂'>>> ', cc
          out,← ⊂'Private shared library:  ',lib
          out,← ⊂'Included lib functions:  ','TakeDrop32/16/8'
         ⍺, ∊cr, ↑out
        } cSrcName cLibName 
    }


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

⎕← Make 

:Section SOURCE_CODE
⍝ Source code for library routines (P: Preamble, C: Main C Code)...
⍝P  /* TakeDrop.so library */
⍝P  #include <stdint.h>
⍝P  #include <stdio.h>
⍝B 
⍝B     int TAKE_DROP_FN(
⍝B             int offset, MY_INT_TYPE *outRaw, MY_INT_TYPE *inRaw,
⍝B             int inRows, int inCols, int tRows, int tCols, int dRows, int dCols
⍝B     ){
⍝B     int     skip, r, c;
⍝B     MY_INT_TYPE *inPtr, *outPtr;  /* int32_t, etc. */ 
⍝B
⍝B /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
⍝B     if (offset < 0) {
⍝B       if (offset == -1) 
⍝B           offset= MAGIC_OFFSET;
⍝B       else if (offset == -2)   /* This is for testing w/o doing any copying */
⍝B           return 0;   
⍝B       else 
⍝B           return 999;          /* invalid offset */
⍝B     }
⍝B
⍝B   /* We don't allow negative take and drop offsets. Sorry. */
⍝B     if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
⍝B       return 911;
⍝B
⍝B     inPtr = inRaw + offset;
⍝B     outPtr= outRaw + offset; 
⍝B
⍝B     inPtr+= dCols + dRows * inCols;
⍝B
⍝B   /* Overtaking is NOT allowed here. Sorry. */
⍝B     if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
⍝B       return 912;
⍝B
⍝B   skip= inCols-tCols;      
⍝B /* This is where all the work is done! */ 
⍝B   for (r=0; r<tRows; ++r, inPtr+= skip ){
⍝B       for (c=0; c<tCols; ++c)
⍝B         *outPtr++ = *inPtr++ ;
⍝B   }
⍝B
⍝B    return 0;
⍝B   }
⍝ End of source code
:EndSection

:EndNamespace


