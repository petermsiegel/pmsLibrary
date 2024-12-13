/* fc: Uses 4-byte (32-bit) unicode chars throughout 
   Name Assoc: (⎕EX '∆FC' if reassociating existing fn)
       '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4    >C4[] =I4' 
                  rc               opts   fString  fLen   outbuf   outlen
   Compile with: 
       cc -dynamiclib -o ∆FC.dylib ∆FC.c   
   Returns:  rc outbuf outlen.  APL code does out← outlen↑out
   rc=¯1:   output buffer not big enough for transformed fString.
            The output buffer is not examined (and may contain junk).
            *outlen=0;
   rc> 0:   an error occurred. Return APL error number (e.g. 11: DOMAIN ERROR).
            The error string is in outbuf, with length *outlen.
   rc= 0:   all is well. 
            The transformed fString is in outbuf with length *outlen.
   Note: We don't end strings with 0 for <fString> or <outbuf>. 
         As a Dyalog APL char vector, <fString> may validly contain 0 or any unicode char.
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define CR    U'\r'
#define DMND  U'⋄'   /* ⋄: ⎕UCS 8900 APL DIAMOND  */
#define DNARO U'↓'
#define DOL   U'$'
#define DQ    U'"' 
#define LBR   U'{'
#define LPAR  U'('
#define OM    U'⍵'
#define OM_US U'⍹'
#define PCT   U'%'
#define RBR   U'}'
#define QT    U'\''
#define RPAR  U')'
#define RTARO U'→'
#define SP    U' '
#define SQ    U'\''
#define ZILDE U'⍬'

/* INPUT BUFFER ROUTINES */
/* CUR... Return current char, w/o checking bounds */
#define CUR_AT(ix)    fString[ix]
#define CUR           CUR_AT(iF)
/* PEEK... Return next char, checking that it's in range (else return -1) */
#define PEEK_AT(ix)   ((ix+1 < fLen)? fString[ix+1]: -1)
#define PEEK          PEEK_AT(iF)
/* NEXT... Skip to next char. */
#define NEXT_AT(ix)   ++ix 
#define NEXT          NEXT_AT(iF)
/* END INPUT BUFFER ROUTINES */

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OUT_LENCHK(len) if (*outlen+len >= maxout){\
                          ERROR_SPACE;\
                       }
/* addStr(x)  x expected to terminate on a null; the null is not added. */
#define addStrN(str, strlen)  {\
                    int lenT=strlen;\
                    int ix;\
                    OUT_LENCHK(lenT);\
                    for(ix=0; ix<lenT; (*outlen)++, ix++)\
                        outbuf[*outlen]= (INT4) str[ix];\
                  }

#define addStr(str)  addStrN(str, str32len(str))

#define addCh(ch)  {\
                  OUT_LENCHK(1);\
                  outbuf[(*outlen)++]=ch;\
                  }

#define ERROR(str, err) {\
                   *outlen=0;\
                   addStr(str);\
                   return(err);\
                   }

#define ERROR_SPACE {\
                    *outlen=0;\
                    return -1;\
                   }

/* Any attempt to add a number bigger than 99999 will result in an error. */
#define ADDNUM5(num) {\
    char nstr[6];  /* allows numbers between 0 and 99999 */ \
    int  i;\
    int  tnum=num;\
    if (tnum>99999){\
         ERROR(U"Omega variables must be between 0 and 99999", 11);\
    }\
    tnum = (tnum>99999)? 99999: tnum;\
    sprintf(nstr, "%d", tnum);\
    for (i=0; nstr[i] && i<sizeof nstr; ++i){\
        addCh( (CHAR4) nstr[i] );\
    }\
}
/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* STATE MANAGEMENT */       
#define NONE      0  /* not in a field */
#define TF       10  /* text field */
#define CF_START 20
#define CF       21  /* code field or space field */
#define STATE(new)  { oldstate=state; state=new;}
/* END STATE MANAGEMENT */

#define MAXLEN  512 
/* str32len: CHAR4's that end with null. */
int str32len( CHAR4* str) {
    int len;
    for (len=0; str[len] && len<MAXLEN; ++len )
        ;
    return len;
}

INT4 afterBlanks(CHAR4 fString[], INT4 fLen, int iF){
    for (; iF<fLen && SP==fString[iF]; ++iF)
           ;
    if (iF>=fLen) 
        return -1;
    return fString[iF];  /* -1 if beyond end */
}

/* HERE DOCUMENT HANDLING */
#define IF_IS_DOC(type) \
                 if (bracketDepth==1 && RBR==afterBlanks(fString+1, fLen, iF)){\
                    int i;\
                    addStr(type); addStr(U" ⍵");\
                    addCh(QT);  \
                    for (i=cfStart+1; i< iF-1; ++i) {\
                      if ( fString[i]==SP)\
                            ++i;\
                      addCh( fString[i] );\
                      if (fString[i]==SQ)\
                          addCh(SQ);\
                    }\
                    addCh(QT); addCh(SP);\
                } 
/* END HERE DOCUMENT HANDLING */

int fc(INT4 opts[3], CHAR4 fString[], INT4 fLen, CHAR4 outbuf[], INT4 *outlen){

  INT4 maxout = *outlen;     /* User must pass in *outlen as outbuf[maxout] */
/* outbuf may contain junk. 
   We'll remove on APL side using *outlen actual length. 
*/
  *outlen = 0;               /* We will pass back *outlen as actual chars used  */          
  int ix;
  int iF;
  int state=NONE;
  int oldstate=NONE;
  int escape=opts[2];        /* User tells us escape character as unicode # */
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;

  /* testing only-- clear output str. */
  for (ix=0; ix< maxout; ++ix)
       outbuf[ix]=SP;

  addCh(LBR); 
  for (iF=0; iF<fLen; NEXT) {
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
          /* Skip leading blanks in Code or Space Fields */
            for (i=iF; PEEK_AT(i)==SP; ++i){ 
                ++nspaces, NEXT;
            }
            if (i<fLen&&CUR_AT(i)==RBR){
                /* Handled above at NEXT above
                  iF= i;
                */
                STATE(NONE);
                if (nspaces){
                      addStr(U"(''⍴⍨");
                      ADDNUM5(nspaces);
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
            CHAR4 ch= PEEK; NEXT;
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
            cfStart= iF;
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
          for (iF=iF+1; iF<fLen; NEXT){ 
              if (CUR==tcur){ 
                  if (PEEK==tcur) {
                      addCh(tcur);
                      if (tcur==SQ)
                          addCh(tcur);
                      NEXT;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur==escape){
                      if (PEEK==DMND) {
                          addCh(CR);
                          NEXT;
                      }else {
                          addCh(escape);
                      }
                  }else { 
                      addCh(tcur);
                      if (tcur==SQ)
                          addCh(tcur);
                  }
              }
          }
          addCh(SQ);
        }else if (CUR==OM_US||(CUR==escape&&PEEK==OM)){ 
          if (CUR==escape) NEXT;  /* esc+⍵ => skip the esc */
          if (isdigit(PEEK)){
             int curnum;
             NEXT; 
             addStr(U"⍵⊃⍨⎕IO+");
             addCh(CUR);
             curnum=CUR-'0';
             for ( NEXT; iF<fLen && isdigit(CUR); NEXT) {
                 curnum = curnum*10 + CUR-'0';
                 addCh(CUR);
             }
             --iF;
             addCh(RPAR);
             omegaNext = curnum;
          }else {
            ++omegaNext;
            addStr(U"(⍵⊃⍨⎕IO+");
            ADDNUM5(omegaNext);
            addCh(RPAR); 
          }
        }else {
          switch(CUR) {
            case DOL: 
               if (PEEK!=DOL){
                 addStr(U" ⎕FMT ");
               }else {
                 addStr(U" ⎕SE.Dyalog.Utils.display ");
                 NEXT;
               }
               for (; PEEK_AT(iF+1)==DOL; NEXT)
                  ;
               break;
           case RTARO:
                IF_IS_DOC(U"⍙AFTER⍙")
                else {
                  addCh(CUR);
                }
                break;
            case DNARO:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  addCh(CUR);
                }
                break;
            case PCT:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  addStr(U" ⍙OVER⍙ ");
                  for (; PEEK_AT(iF+1)==PCT; NEXT)
                    ;
                }
                break;
            default:
                addCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (iF...)*/
  if (state==TF) { 
      addCh(QT);
      STATE(NONE);
  }
  addCh(RBR); 
  return 0;  /* 0= all ok */
}



