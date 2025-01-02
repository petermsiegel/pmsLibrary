/* fc: Uses 4-byte (32-bit) unicode chars throughout  20241223 
   Name Assoc: (⎕EX '∆FC' if reassociating existing fn)
       '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[4] <C4[] I4    >C4[] =I4' 
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

// USE_ALLOCA: Use alloca to dynamically allocate codebuf on thestack
#define USE_ALLOCA
// USE_NS: If defined, a ⎕NS is passed as ⍺ for each Code Field
#define USE_NS
#undef USE_NS 
// FANCY_MARKERS:  For displaying F-String Self Documenting Code {...→} plus {...↓} or {...%},
//                 choose symbols  ▼ and ▶ if 1,  OR  ↓ and →, if 0.
#define FANCY_MARKERS 

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#ifdef USE_ALLOCA
#  include <stdlib.h>  // for alloca
#endif 

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define ALPHA  U'⍺'
#define CR     U'\r'
#define CRVIS  U'␍' 
#define DMND   U'⋄'   //APL DIAMOND (⋄) ⎕UCS 8900 
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

// Mode enumeration 
#define MODE_STD     1
#define MODE_CODE    0 
#define MODE_LIST   -1
#define MODE_TABLE  -2

/* INPUT BUFFER ROUTINES */
/* CUR... Return current char, w/o checking bounds */
#define CUR_AT(ix)    fString[ix]
#define CUR           CUR_AT(cursor)
#define PEEK_AT(ix)   ((ix< fStringLen)? fString[ix]: -1)
/* PEEK... Return next char, checking that it's in range (else return -1) */
#define PEEK          PEEK_AT(cursor+1)
/* END INPUT BUFFER ROUTINES */

/* GENERIC OUTPUT BUFFER MANAGEMENT ROUTINES */ 
#define GENERIC_STR(str, strLen, grp, expandSq)  {\
        int len=strLen;\
        int ix;\
        if (*grp##PLen+len >= grp##Max) ERROR_SPACE;\
        for(ix=0; ix<len; (*grp##PLen)++, ix++){\
            grp##Buf[*grp##PLen]= (CHAR4) str[ix];\
            if (expandSq && (grp##Buf[*grp##PLen] == SQ))\
                grp##Buf[++(*grp##PLen)]= (CHAR4) SQ;\
        }\
}
#define GENERIC_CHR(ch, grp) {\
      if (*grp##PLen+1 >= grp##Max) ERROR_SPACE;\
      grp##Buf[(*grp##PLen)++]= (CHAR4) ch;\
}

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutNStr(str, len)   GENERIC_STR(str, len, out, 0)
#define OutStr(str)         OutNStr(str, Str4Len(str))
#define OutNStrSq(str, len) GENERIC_STR(str, len, out, 1)
#define OutCh(ch)           GENERIC_CHR(ch, out)

/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Handle special code buffer. 
   To transfer codeBuf to outBuf (and then "clear" it):
     CodeOut
*/
# define CodeInit             *codePLen=0
# define CodeStr(str)         GENERIC_STR(str, Str4Len(str), code, 0)  
# define CodeCh(ch)           GENERIC_CHR(ch, code)
# define CodeOut              {OutNStr(codeBuf, *codePLen); CodeInit;} 

/* Any attempt to add a number bigger than 99999 will result in an APL Domain Error. */
#define CODENUM_MAXDIG    5
#define CODENUM_MAX   99999
#define CodeNum(num) {\
    char nstr[CODENUM_MAXDIG+1];\
    int  i;\
    int  tnum=num;\
    if (tnum>CODENUM_MAX){\
        printf("Omega value is: %d. Max is %d\n", tnum, CODENUM_MAX);\
        ERROR(U"Omega variables must be between 0 and 99999", 11);\
        tnum=CODENUM_MAX;\
    }\
    snprintf(nstr, CODENUM_MAXDIG, "%d", tnum);\
    for (i=0;  i<CODENUM_MAXDIG && nstr[i]; ++i){\
        CodeCh((CHAR4)nstr[i]);\
    }\
}
/* End Handle Special code buffer */                  

#define STRLEN_MAX  512  
/* Str4Len: CHAR4's that end with null. */
// int Str4Len( CHAR4* str) {
#define Str4Len(str) ({\
    int len;\
    for (len=0; len<STRLEN_MAX && str[len]; ++len)\
        ;\
    len;\
});

// Error handling  
#define ERROR(str, err) { *outPLen=0; OutStr(str); return(err); }
#define ERROR_SPACE     { *outPLen=0; return -1; }
// End Error Handling  

// STATE MANAGEMENT       
#define NONE      0      // not in a field 
#define TF       10      // text field 
#define CF_START 20      // starting a cf
#define CF       21      // in a code field or space field */
#define STATE(new)  { oldState=state; state=new;}
// END STATE MANAGEMENT 


INT4 afterBlanks(CHAR4 fString[], INT4 fStringLen, int cursor){
    for (; cursor < fStringLen && SP == fString[cursor]; ++cursor)
           ;
    if (cursor>=fStringLen) 
        return -1;
    return fString[cursor];  // -1 if beyond end  
}

// F String DOCUMENT HANDLING  
// Be sure <type> has any internal quotes doubled, as needed.
//Usage:
//      IfCodeDoc(cat)  // where cat has defined catCd and catMarker
//      else {...}
# define IfCodeDoc(type) \
    if (bracketDepth == 1 && RBR == afterBlanks(fString+1, fStringLen, cursor)){\
      int i, m;\
      OutCh(QT);\
      for (i=cfStart; i< cursor; ++i) {\
        OutCh( fString[i] );\
        if (fString[i] == SQ)\
            OutCh(SQ);\
      }\
      OutStr(type##Marker);\
      m = Str4Len(type##Marker);\
      for (i=cursor+1; fString[i] == SP; ++i){\
          if (--m <= 0) OutCh(SP);\
      }\
      OutCh(QT); OutCh(SP);\
      OutStr(type##Cd);\
      OutCh(SP);\
      CodeOut;\
    } 
// END HERE DOCUMENT HANDLING  

// OmegaIndices: Scanning input for digits, producing value for int omgIndex  
#define OmegaIndices\
       CodeCh(CUR);\
       if (!isdigit(CUR))\
          ERROR(U"Logic Error: Omega not followed by digit", 911);\
       omgIndex=CUR-'0';\
       for (++cursor; cursor<fStringLen && isdigit(CUR); ++cursor) {\
          omgIndex = omgIndex*10 + CUR-'0';\
          CodeCh(CUR);\
       }\
       --cursor;

int fc(INT4 opts[3], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen){
  INT4 outMax = *outPLen;           // User must pass in *outPLen as outBuf[outMax]  
  *outPLen = 0;                     // We will pass back *outPLen as actual chars used           
// Code buffer
#ifdef USE_ALLOCA
    INT4 codeMax = outMax;
    CHAR4 *codeBuf = alloca( codeMax * sizeof(CHAR4));
#else 
#   define CODEBUF_MAX 512          // Test. Should be dynamically same as outMax
    CHAR4 codeBuf[CODEBUF_MAX];    // Use codeBuf=alloca(outMax*sizeof CHAR4)
    INT4  codeMax = CODEBUF_MAX;
#endif 
  INT4 codePLen[1]={0};

  int cursor;                      // fString (input) "cursor" position
  int state=NONE;
  int oldState=NONE;
  int mode= opts[0];               // See modes (MODE_...) above
  int debug=opts[1];               // debug (boolean)
  int escCh=opts[2];               // User tells us escCh character as unicode #  
  int extLib=opts[3];              // If 0, pseudo-primitives are defined internally.
  CHAR4 crOut= debug? CRVIS: CR;
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;
  //        Join pseudo-primitive
    #define JOINCD0  U"{⎕ML←1 ⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍵},"
    #define JOINCD1  U" ⎕SE.∆FLib.Join "
  //       Over: field ⍺ is centered over field ⍵
    #define OVERCD0  U"{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
    #define OVERCD1  U" ⎕SE.∆FLib.Ovr "
  //       Cat (dyadic):  field ⍺ is catenated to field ⍵ left to right
    #define CATCD0  U"{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}"
    #define CATCD1  U" ⎕SE.∆FLib.Cat "
  //       Box (ambivalent): Box item to its right
    #define BOXCD0  U"{1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}"
    #define BOXCD1  U" ⎕SE.∆FLib.Box "
  //       ⎕FMT: Formatting (dyadic)
    #define FMTCD01 U" ⎕FMT "
     CHAR4 *joinCd = extLib? JOINCD1: JOINCD0;
     CHAR4 *overCd = extLib? OVERCD1: OVERCD0;
     CHAR4 *catCd  = extLib? CATCD1:  CATCD0;
     CHAR4 *boxCd  = extLib? BOXCD1:  BOXCD0;
     CHAR4 *fmtCd  = FMTCD01;
  #ifdef FANCY_MARKERS
      CHAR4 overMarker[] = U"▼";   // string  
      CHAR4 catMarker[]  = U"▶"; 
  #else 
      CHAR4 overMarker[] = U"↓";   // string
      CHAR4 catMarker[]  = U"→"; 
  #endif 
  

  // Preamble code string...
  
  OutCh(LBR); 
  #ifdef USE_NS
     OutStr(U"⍺←⎕NS⍬⋄")
  #endif

  switch(mode){
    case MODE_STD:
      OutStr(joinCd);
      break;
    case MODE_LIST:
    case MODE_TABLE:
      break;
    case MODE_CODE:
      OutStr(joinCd);
#    ifdef USE_NS
      OutCh(ALPHA);
#    endif
      OutCh(LBR);
      break;
    default:
      ERROR(U"Unknown mode option in left arg", 11);
  }



  for (cursor = 0; cursor < fStringLen; ++cursor) {
    // Logic for changing state (NONE, CF_START)
      if (state == NONE){
          if  (CUR!= LBR) {
            STATE(TF); 
            OutCh(QT);
          }else {
            STATE(CF_START);
            ++cursor;
          }
      }
      if (state == CF_START){
            int i;
            int nspaces=0;
            if (oldState == TF){
                OutCh(QT); 
                OutCh(SP);
            }
          // cfStart marks start of code field (effectively ignored if a space field).
            cfStart= cursor;  // cfStart is used in document strings....
          /* Skip leading blanks in Code/Space Field code, 
             though NOT in any associated document strings */
            for (i=cursor; PEEK_AT(i) == SP; ++i){ 
                ++nspaces, ++cursor;
            }
          // See if we really had a space field (SF). I.e. 0 or more blanks between braces.
            if (i < fStringLen && PEEK_AT(i) == RBR){
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
              // WAS HERE:::  
#ifdef USE_NS 
                OutStr(U"(⍺{");
#else 
                OutStr(U"({"); 
#endif
                CodeInit;
            }
      }  
      if (state == TF) {
          if (CUR == escCh){
            CHAR4 ch= PEEK; ++cursor;
            if (ch == escCh){
                OutCh(escCh);
            }else if (ch == LBR || ch == RBR){
                OutCh(ch);
            }else if (ch == DMND){
                OutCh(crOut);
            }else{ 
                --cursor; 
                OutCh(CUR);
            } 
          }else if (CUR == LBR){
            STATE(CF_START);
          } else {
            OutCh(CUR);
            if (CUR == QT)
              OutCh(QT); 
          }          
      }
      if (state == CF){
        /* We are in a code field */
        if (CUR == RBR) {
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
        }else if (CUR == LBR) {
          ++bracketDepth;
          CodeCh(CUR);
        }else if (CUR == SQ || CUR == DQ){
          int i;
          int tcur=CUR;
          CodeCh(SQ);
          for (cursor++; cursor<fStringLen; ++cursor){ 
              if (CUR == tcur){ 
                  if (PEEK == tcur) {
                      CodeCh(tcur);
                      if (tcur == SQ)
                          CodeCh(tcur);
                      ++cursor;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur == escCh){
                      if (PEEK == DMND) {
                          CodeCh(crOut);
                          ++cursor;
                      }else {
                          CodeCh(escCh);
                      }
                  }else { 
                      CodeCh(tcur);
                      if (tcur == SQ)
                          CodeCh(tcur);
                  }
              }
          }
          CodeCh(SQ);
        }else if (CUR == OMG_US||(CUR == escCh && PEEK == OMG)){ 
          if (CUR == escCh) ++cursor;  /* esc+⍵ => skip the esc */
          if (isdigit(PEEK)){
            ++cursor; 
            CodeStr(U"(⍵⊃⍨⎕IO+");
            int omgIndex;
            OmegaIndices;
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
            case DOL:  // Pseudo-builtins $ (⎕FMT) and $$ (Box, i.e. dfns display)
               if (PEEK!=DOL){
                 CodeStr(fmtCd);
               }else {
                 CodeStr(boxCd);
                 ++cursor;
               }
               for (; PEEK_AT(cursor+1) == DOL; ++cursor)
                  ;
               break;
           case RTARO:
                IfCodeDoc(cat)
                else {
                  CodeCh(CUR);
                }
                break;
            case DNARO:
                IfCodeDoc(over)
                else {
                  CodeCh(CUR);
                }
                break;
            case PCT: // Pseudo-builtin % (Over) 
                IfCodeDoc(over)
                else {
                  CodeStr(overCd);  
                  for (; PEEK_AT(cursor+1) == PCT; ++cursor)
                    ;
                }
                break;
            default:
                CodeCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (cursor...)*/
  if (state == TF) { 
      OutCh(QT);
      STATE(NONE);
  }

  // Postamble Code String
  OutStr(L"⍬}");
  //   Mode 0: extra code because we need to input the format string (fString) 
  //           into the resulting function (see ∆FC.dyalog).
  if (mode == MODE_CODE){
      OutStr(L"⍵,⍨⍥⊆"); 
      OutCh(SQ);
      OutNStrSq(fString, fStringLen);
      OutCh(SQ);    
      OutCh(RBR);
  }else {
      OutStr(L"⍵⍵");
  }

  return 0;  /* 0= all ok */
}



