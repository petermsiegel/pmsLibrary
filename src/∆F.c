/* fc: Uses 4-byte (32-bit) unicode chars throughout   
   Name Assoc: (⎕EX '∆F' if reassociating existing fn)
       '∆F' ⎕NA 'I4 ∆F.dylib|fc  <I4[4] <C4[] I4    >C4[] =I4' 
                  rc               opts   fString  fStringLen   outBuf   outPLen
   Compile with: 
       cc -O3 -dynamiclib -o ∆F.dylib ∆F.c
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

// APL_LIB
#define APL_LIB    U"⎕SE.⍙F."
// USE_ALLOCA: Use alloca to dynamically allocate codebuf on thestack
#define USE_ALLOCA 1
// USE_NS: If 1, a ⎕NS is passed as ⍺ for each Code Field
#define USE_NS 0
// FANCY_MARKERS:  For displaying F-String Self Documenting Code {...→} plus {...↓} or {...%},
//                 choose symbols  ▼ and ▶ if 1,  OR  ↓ and →, if 0.
#define FANCY_MARKERS 1

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#if USE_ALLOCA
#  include <stdlib.h>  // for alloca
#endif 

#define CHAR4  uint32_t       
#define  INT4   int32_t 

#define BLANK_STR U" "  // A string, not a char. const.
//        Join pseudo-primitive
#define MERGECD_INT  U"{⎕ML←1 ⋄⍺←⊢⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵},"
#define MERGECD_EXT  BLANK_STR APL_LIB U"M" BLANK_STR
//       Over: field ⍺ is centered over field ⍵
#define ABOVECD_INT  U"{⎕ML←1 ⋄ ⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
#define ABOVECD_EXT  BLANK_STR APL_LIB U"A" BLANK_STR
//       Box (ambivalent): Box item to its right
#define BOXCD_INT    U"{⎕ML←1⋄1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}"
#define BOXCD_EXT    BLANK_STR APL_LIB U"B" BLANK_STR
//       ⎕FMT: Formatting (dyadic)
#define FMTCD_INT    U" ⎕FMT "
// dfn ¨disp¨, used as a prefix for LIST and TABLE modes. 
#define DISPCD_INT   U"0∘⎕SE.Dyalog.Utils.disp" 
#define DISPCD_EXT   U"0∘" APL_LIB U"D" BLANK_STR  

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
#define OUTBUF_GENERIC(str, strLen, grp, expandSq)  {\
        int len=strLen;\
        int ix;\
        if (*grp##PLen+len >= grp##Max) ERROR_SPACE;\
        if (expandSq){   \
        /* Slower path. Possible expansion of single quotes (APL rule) */ \
            for(ix=0; ix<len; (*grp##PLen)++, ix++){\
                grp##Buf[*grp##PLen]= (CHAR4) str[ix];\
                if (grp##Buf[*grp##PLen] == SQ) {\
                    if (*grp##PLen+1 >= grp##Max) ERROR_SPACE;\
                    grp##Buf[++(*grp##PLen)]= (CHAR4) SQ;\
                }\
            }\
        } else{\
         /* Faster path. Copy as is. */ \
            for(ix=0; ix<len; ){\
                  grp##Buf[(*grp##PLen)++]= (CHAR4) str[ix++];\
            }\
        }\
}
#define OUTCH_GENERIC(ch, grp) {\
      if (*grp##PLen+1 >= grp##Max) ERROR_SPACE;\
      grp##Buf[(*grp##PLen)++]= (CHAR4) ch;\
}

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutBuf(str, len)    OUTBUF_GENERIC(str, len, out, 0)
#define OutBufSq(str, len)  OUTBUF_GENERIC(str, len, out, 1)
#define OutStr(str)         OutBuf(str, Str4Len(str))
#define OutCh(ch)           OUTCH_GENERIC(ch, out)

/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Handle special code buffer. 
   To transfer codeBuf to outBuf (and then "clear" it):
     CodeOut
*/
#define CodeInit             *codePLen=0
#define CodeStr(str)         OUTBUF_GENERIC(str, Str4Len(str), code, 0)  
#define CodeCh(ch)           OUTCH_GENERIC(ch, code)
#define CodeOut              {OutBuf(codeBuf, *codePLen); CodeInit;} 

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
//      IfCodeDoc(merge)  // where merge has defined mergeCd and mergeMarker
//      else {...}
# define IfCodeDoc(marker, code) \
    if (bracketDepth == 1 && RBR == afterBlanks(fString+1, fStringLen, cursor)){\
      int i, m;\
      OutCh(QT);\
      for (i=cfStart; i< cursor; ++i) {\
        OutCh( fString[i] );\
        if (fString[i] == SQ)\
            OutCh(SQ);\
      }\
      OutStr(marker);\
      m = Str4Len(marker);\
      for (i=cursor+1; fString[i] == SP; ++i){\
          if (--m <= 0) OutCh(SP);\
      }\
      OutCh(QT); OutCh(SP);\
      OutStr(code);\
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

int fs_format(INT4 opts[4], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen){
  INT4 outMax = *outPLen;           // User must pass in *outPLen as outBuf[outMax]  
  *outPLen = 0;                     // We will pass back *outPLen as actual chars used           
// Code buffer
#if USE_ALLOCA
    INT4 codeMax = outMax;
    CHAR4 *codeBuf = alloca( codeMax * sizeof(CHAR4));
#else 
    #define CODEBUF_MAX 512         // Test. Should be dynamically same as outMax
    CHAR4 codeBuf[CODEBUF_MAX];    // Use codeBuf=alloca(outMax*sizeof CHAR4)
    INT4  codeMax = CODEBUF_MAX;
#endif 
  INT4 codePLen[1]={0};

  int cursor;                      // fString (input) "cursor" position
  int state=NONE;
  int oldState=NONE;
  int mode=  opts[0];              // See modes (MODE_...) above
  int debug= opts[1];              // debug (boolean)
  int escCh= opts[2];              // User tells us escCh character as unicode #  
  int extLib=opts[3];              // If 0, pseudo-primitives are defined internally.
  CHAR4 crOut= debug? CRVIS: CR;
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;

// Code sequences...
CHAR4 *mergeCd = extLib? MERGECD_EXT: MERGECD_INT;
CHAR4 *aboveCd = extLib? ABOVECD_EXT: ABOVECD_INT;
CHAR4 *boxCd  =  extLib? BOXCD_EXT:   BOXCD_INT;
CHAR4 *fmtCd  =  FMTCD_INT;
CHAR4 *dispCd =  extLib? DISPCD_EXT:  DISPCD_INT;

CHAR4 *mergeMarker  = FANCY_MARKERS? U"▶": U"→"; 
CHAR4 *aboveMarker  = FANCY_MARKERS? U"▼": U"↓";

  // Preamble code string...
  
  OutCh(LBR); 
  #if USE_NS
     OutStr(U"⍺←⎕NS⍬⋄")
  #endif

  switch(mode){
    case MODE_STD:
      OutStr(mergeCd);
      break;
    case MODE_LIST:
      OutStr(dispCd); OutStr(U"¯1↓"); 
      break;
    case MODE_TABLE:
      OutStr(dispCd); OutStr(U"⍪¯1↓");  
      break;
    case MODE_CODE:
      OutStr(mergeCd);
      #if USE_NS
         OutCh(ALPHA);
      #endif
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
                #if USE_NS 
                   OutStr(U"(⍺{");
                #else 
                   OutStr(U"({"); 
                #endif
                CodeInit;
            }
      }  
      if (state == TF) {
          if (CUR == escCh){
            CHAR4 ch= PEEK; 
            ++cursor;
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
          } else if (CUR == LBR){
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
                IfCodeDoc(mergeMarker, mergeCd)
                else {
                  CodeCh(CUR);
                }
                break;
            case DNARO:
                IfCodeDoc(aboveMarker, aboveCd)
                else {
                  CodeCh(CUR);
                }
                break;
            case PCT: // Pseudo-builtin % (Over) 
                IfCodeDoc(aboveMarker, aboveCd)
                else {
                  CodeStr(aboveCd);  
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
  }else if (state != NONE){
      ERROR(L"Code or Space Field was not terminated properly", 11);
  }

  // Postamble Code String
  OutStr(L"⍬}");
  //   Mode 0: extra code because we need to input the format string (fString) 
  //           into the resulting function (see ∆F.dyalog).
  if (mode == MODE_CODE){
      OutStr(L"⍵,⍨⍥⊆"); 
      OutCh(SQ);
      OutBufSq(fString, fStringLen);
      OutCh(SQ);    
      OutCh(RBR);
  }else {
      OutStr(L"ⓇⒼⓉ");
  }

  return 0;  /* 0= all ok */
}



