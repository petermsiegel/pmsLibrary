:Namespace ∆F_C 
 src lib← '∆F_C.c'  '∆F_C.so' 
 Make←{ 
      pre bdy← 'PB'{⊂('^\h*⍝',⍺,'\h?(.*)') ⎕S '\1'⊣⍵}¨ ⊂⎕SRC ⎕THIS  
      GenCode←{
        'char_nn' 'FMT_Cnn' ⎕R ('char',(⍕⍺),'_t') ('FMT_C',⍕⍺÷8)⊣ ⍵
      }
      libCode← ,/ pre, 32 16 8 GenCode¨ bdy
      count← libCode ⎕NPUT src 1
    0= ≢count: 11 ⎕SIGNAL⍨ 'Error writing source file "',cSrcName,'"' 
      {  
          cr← ⎕UCS 13 
        0:: 11 ⎕SIGNAL⍨ 'Error compiling "',src,'" to "',lib,'"' 
          l1← 'Generating source C code:            ',src 
          _← ⎕SH cc←'cc -O3 -shared -o ',lib,' ',src 
          l2← '*** ',cc
          l3← 'Compiled to private shared library: ',lib
        1: ⎕← ↑l1 l2 l3 
      } ⍬ 
 }
 Declare←{ 
  ⍝ Generates functions ∆F8, ∆F16, ∆F32
  ⍝ APL format:
  ⍝ outLen out← ∆F16 in (≢in) (≢outBuffer) (≢outBuffer) 
  ⍝ ∆F16:  for ⎕DR 80, 160, 320, call ∆F8, ∆F16, ∆F32 respectively...   
  ⍝   in:  the input string (⎕DR 80, 160, 320).
  ⍝   ≢in: the true APL length of the input string.
  ⍝   outBuffer: a buffer set aside by APL during the call. You only provide its length.
  ⍝              The length is provided twice; the 2nd time so the C routine has access to its
  ⍝              length. This MUST be the buffer size, including a terminal null. 
  ⍝ Returns: outLen out:
  ⍝ ∘ If ∆Fnn succeeds, outLen is the ACTUAL output string's length, not the buffer size.
  ⍝    out will be the output string in APL format, without any trailing bytes of the outBuffer.
  ⍝ ∘ If ∆Fnn fails, outLen←0 and out←''.
  ⍝ Example:
  ⍝      in← 'input_string'
  ⍝ outLen out← ∆F16 in (≢in) 512 512
    ⎕←{ cType ← ⍕⍵    
      decl← '<C',cType,'[] I4 >0C',cType,'[] I4'
      (⍕⎕THIS),'.',('∆F',cType)⎕NA 'I4 ',lib,'|FMT_C',cType, ' ',decl 
    }¨4 2 1
  } 

  Make ⍬
  ⎕←'To associate APL fns with routines in C library ',lib,', execute:' 
  ⎕←'    ∆F_C.Declare ⍬'

 :Section Source
⍝P #include <stdio.h>
⍝P /* Not found on macos 
⍝P    #include <uchar.h> 
⍝P */
⍝P #define char8_t  unsigned char 
⍝P #define char16_t __CHAR16_TYPE__
⍝P #define char32_t __CHAR32_TYPE__
⍝P /* char_nn replaced by char8_t, char16_t, char32_t */
⍝B int FMT_Cnn( char_nn *in, int inLen, char_nn *out, int outLen){
⍝B     int i;
⍝B     if (inLen >= outLen || outLen<1)   /* we need 1 space for the null */
⍝B         goto bad;
⍝B     for (i=0; i< inLen && i<outLen; ++i)
⍝B          out[i]=in[i];
⍝B     if ( i>= outLen )
⍝B         goto bad;
⍝B     out[i]=0; 
⍝B     return i;
⍝B  bad:
⍝B    out[0]=0;
⍝B    return 0;
⍝B } 
 :EndSection 
:EndNamespace 