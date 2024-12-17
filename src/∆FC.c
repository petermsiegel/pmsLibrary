/* fc: Uses 4-byte (32-bit) unicode chars throughout 
   Name Assoc: (⎕EX '∆FC' if reassociating existing fn)
       '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[] I4    >C4[] =I4' 
                  rc               opts   fString  fStringLen   outBuf   outPLen
   Compile with: 
       cc -dynamiclib -o ∆FC.dylib ∆FC.c   
   Returns:  rc outBuf outPLen.  APL code does out← outPLen↑out
   rc=¯1:   output buffer not big enough for transformed fString.
            The output buffer is not examined (and may contain junk).
            *outPLen=0;
   rc> 0:   an error occurred. Return APL error number (e.g. 11: DOMAIN ERROR).
            The error string is in outBuf, with length *outPLen.
   rc= 0:   all is well. 
            The transformed fString is in outBuf with length *outPLen.
   Note: We don't end strings with 0 for <fString> or <outBuf>. 
         As a Dyalog APL char vector, <fString> may validly contain 0 or any unicode char.
*/

#define DEBUG 
#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define CR     U'\r'
#define DMND   U'⋄'   /* ⋄: ⎕UCS 8900 APL DIAMOND  */
#define DNARO  U'↓'
#define DOL    U'$'
#define DQ     U'"' 
#define LBR    U'{'
#define LPAR   U'('
#define OMG    U'⍵'
#define OMG_US U'⍹'
#define PCT    U'%'
#define RBR    U'}'
#define QT     U'\''
#define RPAR   U')'
#define RTARO  U'→'
#define SP     U' '
#define SQ     U'\''
#define ZILDE  U'⍬'

/* INPUT BUFFER ROUTINES */
/* CUR... Return current char, w/o checking bounds */
#define CUR_AT(ix)    fString[ix]
#define CUR           CUR_AT(cursor)
#define PEEK_AT(ix)   ((ix< fStringLen)? fString[ix]: -1)
/* PEEK... Return next char, checking that it's in range (else return -1) */
#define PEEK          PEEK_AT(cursor+1)
/* END INPUT BUFFER ROUTINES */

/* GENERIC BUFFER MANAGEMENT ROUTINES */
#define GENERIC_STR(str, strLen, _buf, _pLen, _max)  {\
                  int len=strLen;\
                  int ix;\
                  if (*_pLen+len >= _max) ERROR_SPACE;\
                  for(ix=0; ix<len; (*_pLen)++, ix++){\
                      _buf[*_pLen]= (CHAR4) str[ix];\
                  }\
}
#define GENERIC_CHR(ch, _buf, _pLen, _max) {\
          if (*_pLen+1 >= _max) ERROR_SPACE;\
          _buf[(*_pLen)++]= (CHAR4) ch;\
}

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutStr(str)        GENERIC_STR(str, str32Len(str), outBuf, outPLen, outMax)
#define OutNStr(str, len)  GENERIC_STR(str, len, outBuf, outPLen, outMax)
#define OutCh(ch)          GENERIC_CHR(ch, outBuf, outPLen, outMax)

/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Handle special code buffer. 
   To transfer codeBuf to outBuf (and then "clear" it):
     Code2Out
*/
#define CodeInit              *codePLen=0
#define TWOBUFS 
#ifdef TWOBUFS
# define CodeStr(str)         GENERIC_STR(str, str32Len(str), codeBuf, codePLen, codeMax)  
# define CodeCh(ch)           GENERIC_CHR(ch, codeBuf, codePLen, codeMax)
# define CodeOut              OutNStr(codeBuf, *codePLen); CodeInit 
#else 
#  define CodeStr(str)        GENERIC_STR(str, str32Len(str), outBuf, outPLen, outMax)
#  define CodeNStr(str, len)  GENERIC_STR(str, len, outBuf, outPLen, outMax)
#  define CodeCh(ch)          GENERIC_CHR(ch, outBuf, outPLen, outMax)
#  define CodeOut
#endif 

/* Any attempt to add a number bigger than 99999 will result in an APL Domain Error. */
#define CODENUM_MAXDIG    5
#define CODENUM_MAX   99999
#define CodeNum(num) {\
    char nstr[CODENUM_MAXDIG+1];\
    int  i;\
    int  tnum=num;\
    if (tnum>CODENUM_MAX){\
         ERROR(U"Omega variables must be between 0 and 99999", 11);\
    }\
    if (tnum>CODENUM_MAX)\
        tnum=CODENUM_MAX;\
    sprintf(nstr, "%d", tnum);\
    for (i=0;  i<CODENUM_MAXDIG && nstr[i]; ++i){\
        CodeCh((CHAR4)nstr[i]);\
    }\
}
/* End Handle Special code buffer */                  

/* Error handling */
#define ERROR(str, err) {\
                   *outPLen=0;\
                   OutStr(str);\
                   return(err);\
                   }

#define ERROR_SPACE {\
                    *outPLen=0;\
                    return -1;\
                   }
/* End Error Handling */

/* STATE MANAGEMENT */       
#define NONE      0  /* not in a field */
#define TF       10  /* text field */
#define CF_START 20
#define CF       21  /* code field or space field */
#define STATE(new)  { oldState=state; state=new;}
/* END STATE MANAGEMENT */

#define STRLEN_MAX  512  
/* str32Len: CHAR4's that end with null. */
int str32Len( CHAR4* str) {
    int len;
    for (len=0; len<STRLEN_MAX && str[len]; ++len )
        ;
#ifdef DEBUG
    int i;
    printf("str32len Str: <");
    for (i=0; i<20 && i<len && str[i]; ++i)
         printf("%lc", (int) str[i]);
    printf(">\nlen=%d\n", len);
#endif 
    return len;
}

INT4 afterBlanks(CHAR4 fString[], INT4 fStringLen, int cursor){
    for (; cursor<fStringLen && SP==fString[cursor]; ++cursor)
           ;
    if (cursor>=fStringLen) 
        return -1;
    return fString[cursor];  /* -1 if beyond end */
}

/* HERE DOCUMENT HANDLING */
#ifdef DOC_TEST
# define IF_IS_DOC(type) \
          if (bracketDepth==1 && RBR==afterBlanks(fString+1, fStringLen, cursor)){\
            int i;\
            OutCh(RPAR); OutStr(type); OutStr(U" ⍵");\
            OutCh(QT);  \
            for (i=cfStart; i< cursor-1; ++i) {\
              if ( fString[i]==SP)\
                    ++i;\
              OutCh( fString[i] );\
              if (fString[i]==SQ)\
                  OutCh(SQ);\
            }\
            OutCh(QT); OutCh(SP);\
          } 
#else
# define IF_IS_DOC(type) if (0) {}
#endif 
/* END HERE DOCUMENT HANDLING */

/* ProcessOmgIx: Scanning input for digits, producing value for int omgIndex */
#define ProcessOmgIx\
       CodeCh(CUR);\
       omgIndex=CUR-'0';\
       for (++cursor; cursor<fStringLen && isdigit(CUR); ++cursor) {\
          omgIndex = omgIndex*10 + CUR-'0';\
          CodeCh(CUR);\
       }\
       --cursor;

int fc(INT4 opts[3], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen){
  INT4 outMax = *outPLen;        // User must pass in *outPLen as outBuf[outMax]  
  *outPLen = 0;                  // We will pass back *outPLen as actual chars used           
// Code buffer
# define CODEBUF_MAX 512 // Test. Should be dynamically same as outMax
  CHAR4 codeBuf[CODEBUF_MAX];    // Use codeBuf=alloca(outMax*sizeof CHAR4)
  INT4 codePLen[1]={0};
  INT4  codeMax = CODEBUF_MAX;
  int cursor;                    // fString (input) "cursor" position
  int state=NONE;
  int oldState=NONE;
  int escCh=opts[2];             // User tells us escCh character as unicode #  
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;

  /* testing only-- clear output str. */
  {int ix;
   for (ix=0; ix< outMax; ++ix)
       outBuf[ix]=SP;
  }

  OutCh(LBR); 
  for (cursor=0; cursor<fStringLen; ++cursor) {
      if (state==NONE && CUR!= LBR) {
            STATE(TF); 
            OutCh(QT);
      } else if (state==CF_START){
            int i;
            int nspaces=0;
            if (oldState==TF){
                OutCh(QT); 
                OutCh(SP);
            }
          /* Skip/Count leading blanks in Code/Space Fields */
          // Should this be i+1 or i?
            for (i=cursor; PEEK_AT(i)==SP; ++i){ 
                ++nspaces, ++cursor;
            }
            if (i<fStringLen&&PEEK_AT(i)==RBR){
                STATE(NONE);    // State=> None. Space field is complete !
                if (nspaces){
                      CodeStr(U"(''⍴⍨");
                      CodeNum(nspaces);
                      printf("nspaces %d", nspaces);
                      CodeCh(RPAR);
                      CodeOut;
                }
            }else {
                STATE(CF);
                bracketDepth=1;
                cfStart= cursor;
                OutStr(U"({"); 
                CodeInit;
            }
      }  
      if (state==TF) {
          if (CUR== escCh){
            CHAR4 ch= PEEK; ++cursor;
            if (ch==escCh){
                OutCh(escCh);
            }else if (ch==LBR || ch==RBR){
                OutCh(ch);
            }else if (ch==DMND){
                OutCh(CR);
            }else{ 
                --cursor; 
                OutCh(CUR);
            } 
          }else if (CUR==LBR){
            STATE(CF_START);
          } else {
            OutCh(CUR);
            if (CUR == QT)
              OutCh(QT); 
          }          
      }else if (state==CF){
        /* We are in a code field */
        if (CUR==RBR) {
            --bracketDepth;
            if (bracketDepth > 0) {
               CodeCh(CUR);
        // Terminating right brace: Ending Code Field!
            }else {
              CodeOut;
              OutStr(U"}⍵)");
              bracketDepth=0;
              STATE(NONE);
            }
        }else if (CUR==LBR) {
          ++bracketDepth;
          CodeCh(CUR);
        }else if (CUR==SQ || CUR==DQ){
          int i;
          int tcur=CUR;
          CodeCh(SQ);
          for (cursor++; cursor<fStringLen; ++cursor){ 
              if (CUR==tcur){ 
                  if (PEEK==tcur) {
                      CodeCh(tcur);
                      if (tcur==SQ)
                          CodeCh(tcur);
                      ++cursor;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur==escCh){
                      if (PEEK==DMND) {
                          CodeCh(CR);
                          ++cursor;
                      }else {
                          CodeCh(escCh);
                      }
                  }else { 
                      CodeCh(tcur);
                      if (tcur==SQ)
                          CodeCh(tcur);
                  }
              }
          }
          CodeCh(SQ);
        }else if (CUR==OMG_US||(CUR==escCh && PEEK==OMG)){ 
          if (CUR==escCh) ++cursor;  /* esc+⍵ => skip the esc */
          if (isdigit(PEEK)){
            ++cursor; 
            CodeStr(U"⍵⊃⍨⎕IO+");
            int omgIndex;
            ProcessOmgIx;
            omegaNext = omgIndex; 
            CodeCh(RPAR);
          }else {
            ++omegaNext;
            CodeStr(U"(⍵⊃⍨⎕IO+");
            CodeNum(omegaNext);
            CodeCh(RPAR); 
          }
        }else {
          switch(CUR) {
            case DOL: 
               if (PEEK!=DOL){
                 CodeStr(U" ⎕FMT ");
               }else {
                 CodeStr(U" ⎕SE.Dyalog.Utils.display ");
                 ++cursor;
               }
               for (; PEEK_AT(cursor+1)==DOL; ++cursor)
                  ;
               break;
           case RTARO:
                IF_IS_DOC(U"⍙AFTER⍙")
                else {
                  CodeCh(CUR);
                }
                break;
            case DNARO:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  CodeCh(CUR);
                }
                break;
            case PCT:
                IF_IS_DOC(U"⍙OVER⍙")
                else {
                  CodeStr(U" ⍙OVER⍙ ");
                  for (; PEEK_AT(cursor+1)==PCT; ++cursor)
                    ;
                }
                break;
            default:
                CodeCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (cursor...)*/
  if (state==TF) { 
      OutCh(QT);
      STATE(NONE);
  }
  OutCh(RBR); 
  return 0;  /* 0= all ok */
}



