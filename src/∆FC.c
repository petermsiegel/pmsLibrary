/* fc: Uses 4-byte (32-bit) unicode chars throughout 
   Name Assoc: (⎕EX '∆FC' if reassociating existing fn)
       '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4    >C4[] =I4' 
                  rc               opts   fString  fLen   outBuf   outLen
   Compile with: 
       cc -dynamiclib -o ∆FC.dylib ∆FC.c   
   Returns:  rc outBuf outLen.  APL code does out← outlen↑out
   rc=¯1:   output buffer not big enough for transformed fString.
            The output buffer is not examined (and may contain junk).
            *outLen=0;
   rc> 0:   an error occurred. Return APL error number (e.g. 11: DOMAIN ERROR).
            The error string is in outBuf, with length *outLen.
   rc= 0:   all is well. 
            The transformed fString is in outBuf with length *outLen.
   Note: We don't end strings with 0 for <fString> or <outBuf>. 
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

/* GENERIC BUFFER MANAGEMENT ROUTINES */
#define GENERIC_STR(str, strlen, outBuf, outLen)  {\
                  int lenT=strlen;\
                  int ix;\
                  outLenChk(lenT);\
                  for(ix=0; ix<lenT; (*outLen)++, ix++)\
                      outBuf[*outLen]= (INT4) str[ix];\
        }

#define GENERIC_LENCHK(len, outLen, outMax)\
                if (*outLen+len >= outMax){\
                    ERROR_SPACE;\
        }

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define outLenChk(len) GENERIC_LENCHK(len, outLen, outMax)
#define outStr(str)    GENERIC_STR(str, str32Len(str), outBuf, outLen)
#define outCh(ch)      {outLenChk(1);outBuf[(*outLen)++]=ch;}

/* Any attempt to add a number bigger than 99999 will result in an error. */
#define outNum5(num) {\
    char nstr[6];  /* allows numbers between 0 and 99999 */ \
    int  i;\
    int  tnum=num;\
    if (tnum>99999){\
         ERROR(U"Omega variables must be between 0 and 99999", 11);\
    }\
    tnum = (tnum>99999)? 99999: tnum;\
    sprintf(nstr, "%d", tnum);\
    for (i=0; nstr[i] && i<sizeof nstr; ++i){\
        outCh( (CHAR4) nstr[i] );\
    }\
}
/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Error handling */
#define ERROR(str, err) {\
                   *outLen=0;\
                   outStr(str);\
                   return(err);\
                   }

#define ERROR_SPACE {\
                    *outLen=0;\
                    return -1;\
                   }

/* End Error Handling */

/* Handle special code buffer. To transfer codeBuf to outBuf:
     codeEof;
*/
#define codeInit             codeLen=0
#define codeEof              codeCh(0); outS(codeBuf); codeInit 
#define codeLenChk(len)      GENERIC_LENCHK(len, codeLen, codeMax)
#define codeStr(str)         GENERIC_STR(str, str32Len(str), codeBuf, codeLen)  
#define codeCh(ch)           {codeLenChk(1); codeBuf[(*codeLen)++]=ch;} 
/* End Handle Special code buffer */                  

/* STATE MANAGEMENT */       
#define NONE      0  /* not in a field */
#define TF       10  /* text field */
#define CF_START 20
#define CF       21  /* code field or space field */
#define STATE(new)  { oldState=state; state=new;}
/* END STATE MANAGEMENT */

#define MAXLEN  512 
/* str32Len: CHAR4's that end with null. */
int str32Len( CHAR4* str) {
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
                    outCh(RPAR); outStr(type); outStr(U" ⍵");\
                    outCh(QT);  \
                    for (i=cfStart; i< iF-1; ++i) {\
                      if ( fString[i]==SP)\
                            ++i;\
                      outCh( fString[i] );\
                      if (fString[i]==SQ)\
                          outCh(SQ);\
                    }\
                    outCh(QT); outCh(SP);\
                } 
/* END HERE DOCUMENT HANDLING */

int fc(INT4 opts[3], CHAR4 fString[], INT4 fLen, CHAR4 outBuf[], INT4 *outLen){
  INT4 outMax = *outLen;     /* User must pass in *outLen as outBuf[outMax] */
  *outLen = 0;               /* We will pass back *outLen as actual chars used  */          
  int ix;
  int iF;
  CHAR4 codeBuf[512];
  INT4 *codeLen=0;
  INT4  codeMax = sizeof(codeBuf);
  int state=NONE;
  int oldState=NONE;
  int escape=opts[2];        /* User tells us escape character as unicode # */
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;

  /* testing only-- clear output str. */
  for (ix=0; ix< outMax; ++ix)
       outBuf[ix]=SP;

  outCh(LBR); 
  for (iF=0; iF<fLen; NEXT) {
      if (state==NONE && CUR!= LBR) {
            STATE(TF); 
            outCh(QT);
      } else if (state==CF_START){
            int i;
            int nspaces=0;
            if (oldState==TF){
                outCh(QT); 
                outCh(SP);
            }
          /* Skip leading blanks in Code or Space Fields */
            for (i=iF; PEEK_AT(i)==SP; ++i){ 
                ++nspaces, NEXT;
            }
            if (i<fLen&&CUR_AT(i)==RBR){
                STATE(NONE);
                if (nspaces){
                      outStr(U"(''⍴⍨");
                      outNum5(nspaces);
                      outCh(RPAR);
                }
            }else {
                STATE(CF);
                bracketDepth=1;
                cfStart= iF;
                outStr(U"({"); 
            }
      }  
      if (state==TF) {
          if (CUR== escape){
            CHAR4 ch= PEEK; NEXT;
            if (ch==escape){
                outCh(escape);
            }else if (ch==LBR || ch==RBR){
                outCh(ch);
            }else if (ch==DMND){
                outCh(CR);
            }else{ 
                --iF; 
                outCh(CUR);
            } 
          }else if (CUR==LBR){
            STATE(CF_START);
          } else {
            outCh(CUR);
            if (CUR == QT)
              outCh(QT); 
          }          
      }else if (state==CF){
        /* We are in a code field */
        if (CUR==RBR) {
            --bracketDepth;
            if (bracketDepth > 0) {
               outCh(CUR);
            }else {
              outStr(U"}⍵)");
              bracketDepth=0;
              STATE(NONE);
            }
        }else if (CUR==LBR) {
          ++bracketDepth;
          outCh(CUR);
        }else if (CUR==SQ || CUR==DQ){
          int i;
          int tcur=CUR;
          outCh(SQ);
          for (iF=iF+1; iF<fLen; NEXT){ 
              if (CUR==tcur){ 
                  if (PEEK==tcur) {
                      outCh(tcur);
                      if (tcur==SQ)
                          outCh(tcur);
                      NEXT;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur==escape){
                      if (PEEK==DMND) {
                          outCh(CR);
                          NEXT;
                      }else {
                          outCh(escape);
                      }
                  }else { 
                      outCh(tcur);
                      if (tcur==SQ)
                          outCh(tcur);
                  }
              }
          }
          outCh(SQ);
        }else if (CUR==OM_US||(CUR==escape&&PEEK==OM)){ 
          if (CUR==escape) NEXT;  /* esc+⍵ => skip the esc */
          if (isdigit(PEEK)){
             int curnum;
             NEXT; 
             outStr(U"⍵⊃⍨⎕IO+");
             outCh(CUR);
             curnum=CUR-'0';
             for ( NEXT; iF<fLen && isdigit(CUR); NEXT) {
                 curnum = curnum*10 + CUR-'0';
                 outCh(CUR);
             }
             --iF;
             outCh(RPAR);
             omegaNext = curnum;
          }else {
            ++omegaNext;
            outStr(U"(⍵⊃⍨⎕IO+");
            outNum5(omegaNext);
            outCh(RPAR); 
          }
        }else {
          switch(CUR) {
            case DOL: 
               if (PEEK!=DOL){
                 outStr(U" ⎕FMT ");
               }else {
                 outStr(U" ⎕SE.Dyalog.Utils.display ");
                 NEXT;
               }
               for (; PEEK_AT(iF+1)==DOL; NEXT)
                  ;
               break;
           case RTARO:
                IF_IS_DOC(U"⍙AFTER⍙")
                else {
                  outCh(CUR);
                }
                break;
            case DNARO:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  outCh(CUR);
                }
                break;
            case PCT:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  outStr(U" ⍙OVER⍙ ");
                  for (; PEEK_AT(iF+1)==PCT; NEXT)
                    ;
                }
                break;
            default:
                outCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (iF...)*/
  if (state==TF) { 
      outCh(QT);
      STATE(NONE);
  }
  outCh(RBR); 
  return 0;  /* 0= all ok */
}



