#include <stdio.h>
#include <stdint.h>
#include <string.h> 

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define QT    U'\''
#define SP    U' '
#define LBR   U'{'
#define RBR   U'}'
#define LPAR  U'('
#define RPAR  U')'
#define DMND  U'⋄'   /* ⋄: ⎕UCS 8900 APL DIAMOND  */
#define CR    U'\r'
#define ZILDE U'⍬'
#define OMEGA U'⍵'
#define SQ    U'\''
#define DQ    U'"' 

/* INPUT BUFFER ROUTINES */
#define CUR_AT(ix)    fstring[ix]
#define CUR           CUR_AT(iF)
#define PEEK_AT(ix)   ((ix+1 < flen)? fstring[ix+1]: -1)
#define PEEK          PEEK_AT(iF)
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
#define NONE      0  /* not in a field */
#define TF       10  /* text field */
#define CF_START 20
#define CF       21  /* code field or space field */
#define STR      22    /* subfield of code field */
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
  int bracketDepth=0;

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
      if (state==NONE && CUR!= LBR) {
            STATE(TF); 
            addCh(QT);
      } else if (state==CF_START){
            int i;
            int nspaces=0;
            if (oldstate==TF){
                addCh(QT); 
                addCh(SP);
            }
            for (i=iF; i<flen && CUR_AT(i)==SP; ++i){
              /* ++iF: Skip leading blanks in Code or Space Fields */
                ++nspaces, ++iF; 
            }
            if (i<flen&&CUR_AT(i)==RBR){
                /* Handled above at ++iF 
                  iF= i;
                */
                STATE(NONE);
                if (nspaces){
                      char str[5];
                      int  i;
                      addStr(U"(''⍴⍨");
                      sprintf(str, "%d", nspaces);
                      for (i=0; str[i] && i<sizeof str; ++i){
                          addCh( (CHAR4) str[i] );
                      }
                      addCh(RPAR);
                }
            }else {
                STATE(CF);
                bracketDepth=1;
                addStr(U"({"); 
            }
      }  
      if (state==TF) {
          if (CUR== escape){
            CHAR4 ch= PEEK; ++iF;
            if (ch==escape){
                addCh(escape);
            }else if (ch==LBR || ch==RBR){
                addCh(ch);
            }else if (ch==DMND){
                addCh(CR);
            }else{ 
                --iF; 
                addCh(CUR);
            } 
          }else if (CUR==LBR){
            STATE(CF_START);
          } else {
            addCh(CUR);
            if (CUR == QT)
              addCh(QT); 
          }          
      }else if (state==CF){
        /* We are in a code field */
        if (CUR==RBR) {
            --bracketDepth;
            if (bracketDepth > 0) {
               addCh(CUR);
            }else {
              addStr(U"}⍵)");
              bracketDepth=0;
              STATE(NONE);
            }
        }else if (CUR==LBR) {
          ++bracketDepth;
          addCh(CUR);
        }else if (CUR==SQ || CUR==DQ){
          int i;
          int tcur=CUR;
          addCh(SQ);
          for (iF=iF+1; iF<flen; ++iF){ 
              if (CUR==tcur){ 
                  if (PEEK==tcur) {
                      addCh(tcur);
                      if (tcur==SQ)
                          addCh(tcur);
                      ++iF;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  addCh(tcur);
                  if (tcur==SQ)
                      addCh(tcur);
              }
          }
          addCh(SQ);
        }else {
          addCh(CUR); /* Catchall */
        }
      }
  } /* for (iF...)*/
  if (state==TF) { 
      addCh(QT);
      STATE(NONE);
  }
  addCh(RBR); 
  return 0;
}



