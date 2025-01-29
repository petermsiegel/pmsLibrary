#include <stdio.h>
#include <stdint.h>
#include <string.h>

//  ⍝ ⎕← ⎕NA '∆F/Test.dylib|Test <#C2[] >#C2[]'⊣⎕EX 'Test'

typedef struct {
    uint16_t len;
    uint16_t buf[];
} LPString;    /* Length-prefixed string (Dyalog "byte-counted string") */
void Test( LPString *in, LPString *out){
   int len= in->len;
   out->len = in->len;
   for (int i=0,j=0; i< len; i++, j++){
       out->buf[i] = in->buf[i];
   }
}