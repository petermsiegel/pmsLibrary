:Namespace ∆F_C 
  ⍝ Generates functions ∆F4, ∆F2, ∆F1 that provide formatting strings
  ⍝ APL format:
  ⍝ outLen out← ∆Fn in (≢in) (≢outBuffer) (≢outBuffer) 
  ⍝ ∆F2:  n is 4, 2, 1 for ⎕DR 320, 160, 80 ==> ∆F4, ∆F2, ∆F1 respectively.
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
  ⍝ Usage: See ∆F below

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
  ⍝ Associates (⎕NA) APL fns named ∆F4, ∆F2, ∆F1 with corresponding C fns FMT_C4, ...2, ...1
  ⍝ in the library <lib>
    { cType ← ⍕⍵    
      decl← '<C',cType,'[] I4 >0C',cType,'[] I4'
      (⍕⎕THIS),'.',('∆F',cType)⎕NA 'I4 ',lib,'|FMT_C',cType, ' ',decl 
    }¨4 2 1
  } 

  Make ⍬
  ⎕←'To associate APL fns with routines in C library ',lib,', execute:' 
  ⎕←'    ∆F_C.Declare ⍬'

  ∇res← ∆F stuff
    ;fStr ;stuff; lenIn; lenOut; rc; out 

    :If 0= ⎕NC '∆F4' ⋄ {}Declare⍬ ⋄ :EndIf  

    :IF 0< lenIn← ≢fStr← ⊃stuff← ,⊆stuff 
        lenOut← 128⌈ 2× lenIn 
        :Select ⎕DR fStr
            :Case 320 ⋄ rc out← ∆F4 fStr lenIn lenOut lenOut 
            :Case 160 ⋄ rc out← ∆F2 fStr lenIn lenOut lenOut 
            :Case  80 ⋄ rc out← ∆F1 fStr lenIn lenOut lenOut 
            :Else     ⋄ 11 ⎕SIGNAL⍨'DOMAIN ERROR: Format string has improper type'
        :EndSelect 
        :If rc=0 ⋄ 11 ⎕SIGNAL⍨'DOMAIN ERROR: Cannot parse format string' ⋄ :EndIf 
        :Trap 0 
            res← (out⍎⍨ ⊃⎕RSI) stuff 
        :Else 
            ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message' ,⍥⊂¨ ('∆F ',EM) EN Message )
        :EndTrap
    :Else  
        res← 1 0⍴''           ⍝ ⎕FMT ''
    :EndIf 
  ∇ 
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