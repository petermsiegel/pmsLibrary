#include <stdio.h>
#include <stdint.h>
#include <string.h> 

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define QT  U'\''
#define SP  U' '
#define LBR U'{'
#define RBR U'}'
#define DIAMOND 8900  /* APL DIAMOND */
#define CR  U'\r'

/* INPUT BUFFER ROUTINES */
#define PEEK    ((iF+1 < flen)? fstring[iF+1]: -1)
/* END INPUT BUFFER ROUTINES */

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define LENCHK(len) if (*outlen+len >= maxout){\
                       *outlen=0;\
                       return -1;\
                   }
/* addStr(x)  x expected to terminate on a null; the null is not added. */
#define addStrN(str, strlen)  {\
                    int lenT=strlen;\
                    int ix;\
                    LENCHK(lenT);\
                    for(ix=0; ix<lenT; (*outlen)++, ix++)\
                        outbuf[*outlen]=str[ix];\
                  }

#define addStr(str)  addStrN(str, str32len(str))

#define addCh(ch)  {\
                  LENCHK(1);\
                  outbuf[(*outlen)++]=ch;\
                  }
/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* STATE MANAGEMENT */       
#define NONE 0  /* not in a field */
#define TF   1  /* text field */
#define CF   2  /* code field or space field */
#define STR  3  /* subfield of code field */
#define STATE(new)  { oldstate=state; state=new;}
/* END STATE MANAGEMENT */

int str32len( CHAR4* str) {
    int res;
    for (res=0; str[res]; ++res )
        ;
    return res;
}

/* fc: Uses 4-byte (32-bit) unicode chars throughout 
   Name Assoc: (⎕EX '∆FC' if reassociating existing fn)
       '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4    >C4[] =I4' 
                  rc               opts   fstring  flen   outbuf   outlen
   Compile with: 
       cc -dynamiclib -o ∆FC.dylib ∆FC.c   
   Returns:  rc outbuf outlen.  APL code does out← outlen↑out
   rc=¯1:   output buffer not big enough for transformed fstring.
   rc> 0:   an error occurred. Return APL error number (e.g. 11: DOMAIN ERROR).
            The error string is (outlen↑out).
   rc= 0:   all is well. The transformed fstring is (outlen↑out).
   Note: We don't end strings with 0 for <fstring> or <outbuf>. 
         As a Dyalog APL char vector, <fstring> may validly contain 0 or any unicode char.
*/

int fc(INT4 opts[3], CHAR4 fstring[], INT4 flen, CHAR4 outbuf[], INT4 *outlen){

  INT4 maxout = *outlen;     /* User must pass in *outlen as outbuf[maxout] */
/* outbuf may contain junk. We'll remove on APL side x*/
  *outlen = 0;               /* We will pass back *outlen as actual chars used  */          
  int ix;
  int iF;
  int state=NONE;
  int oldstate=NONE;
  int escape=opts[2];

  if (0) return -1;          /* Testing: attempt to overfill outbuf buffer */
  if (0) {
      addStr(U"∆FC UNDER DEVELOPMENT"); /* Return an error message. */
      return 11;
  }

  /* testing only-- clear output str. */
  for (ix=0; ix< maxout; ++ix)
       outbuf[ix]=SP;

  addCh(LBR); 
  for (iF=0; iF<flen; ++iF) {
      if (state==NONE && fstring[iF]!=LBR){
          STATE(TF); addCh(QT);
      }
      if (state==TF) {
          if (fstring[iF]== escape){
            CHAR4 ch= PEEK; ++iF;
            if (ch==escape){
                addCh(escape);
            }else if (ch==LBR || ch==RBR){
                addCh(ch);
            }else if (ch==DIAMOND){
                addCh(CR);
            }else{ 
                addCh(fstring[--iF]);
            } 
          } else {
            addCh(fstring[iF]);
            if (fstring[iF] == QT)
              addCh(QT); 
          }          
      }
  }
  if (state==TF) 
      addCh(QT);
  addCh(RBR);
  return 0;
}



