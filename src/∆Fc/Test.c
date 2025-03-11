#include <stdio.h>
#include <stdint.h>
#include <string.h>

//  ⍝ ⎕← ⎕NA '∆F/Test.dylib|Test <#C2[] >#C2[] I4'⊣⎕EX 'Test'

typedef struct {
    uint16_t len;
    uint16_t buf[];
} lPString;    /* Length-prefixed string (Dyalog "byte-counted string") */
void Test( lPString *in, lPString *out, int outMax){
  if (in->len > outMax)
      return;
   out->len = in->len;
   for (int i=0; i< out->len; i++){
       out->buf[i] = in->buf[i];
   }
}
void Test2( uint16_t *in, uint16_t *out, int outMax){
  if (in[0] > outMax)
      return;
// We copy out->len + 1 elements; first is in[-1] to out[-1] 
   for (int i= 0; i < in[0]+1; i++){ 
       out[i] = in[i];
   }
}