/* fc: Uses 4-byte (32-bit) unicode chars throughout   
   Name Assoc: (⎕EX '∆F' if reassociating existing fn)
       '∆F' ⎕NA 'I4 ∆F.dylib|fc <I1[4] <I4   <C4[]    I4           >C4[]    =I4' 
                 rc             opts   escCh fString  fStringLen   outBuf   outPLen
   Compile with: 
       cc -O3 -dynamiclib -o ∆F.dylib ∆F.c
   Returns:  rc outBuf outPLen.  APL code does out← outPLen↑out
   rc=¯1:   output buffer not big enough for transformed fString.
            In this case, the output buffer is not examined (and may contain junk).
            *outPLen=0;
   rc> 0:   an error occurred. Return APL error number (e.g. 11: DOMAIN ERROR).
            The error string is in outBuf, with length *outPLen.
   rc= 0:   all is well. 
            The output buffer, outBuf, contains the transformed fString with length *outPLen.
   Note: We don't end strings with 0 for <fString> or <outBuf>. 
         As a Dyalog APL char vector, <fString> may validly contain 0 or any unicode char.
*/

// APL_LIB: Enter the name of the namespace housing the fns 
//          Fns: M (merge ⍺⍵ or ⍵), A (⍺ above ⍵), B (box ⍵), D (display entire object)
#define APL_LIB    u"⎕SE.⍙F."
// USE_ALLOCA: Use alloca to dynamically allocate codebuf on thestack.
//          Otherwise, use a fixed array.
#define USE_ALLOCA 1
// FANCY_MARKERS:  For displaying F-String Self Documenting Code {...→} plus {...↓} or {...%},
//                 choose symbols  ▼ and ▶ if 1,  OR  ↓ and →, if 0.
#define FANCY_MARKERS 1
// 

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#if USE_ALLOCA
#  include <stdlib.h>  // for alloca
#endif 

#define WIDE4  uint32_t  
#define WIDE2  uint16_t
#define  INT4   int32_t 
#define BLANK_STR    u" "  // A string, not a char. const.
//        Join pseudo-primitive
#define MERGECD_INT  u"{⎕ML←1 ⋄⍺←⊢⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵},"
#define MERGECD_EXT  BLANK_STR APL_LIB u"M" BLANK_STR
//       Over: field ⍺ is centered over field ⍵
#define ABOVECD_INT  u"{⎕ML←1 ⋄ ⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
#define ABOVECD_EXT  BLANK_STR APL_LIB u"A" BLANK_STR
//       Box: Box item to its right
#define BOXCD_INT    u"{⎕ML←1⋄1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}"
#define BOXCD_EXT    BLANK_STR APL_LIB u"B" BLANK_STR
//       ⎕FMT: Formatting (dyadic)
#define FMTCD_INT    u" ⎕FMT "
// dfn ¨disp¨, used as a prefix for LIST and TABLE modes. 
#define DISPCD_INT   u"0∘⎕SE.Dyalog.Utils.disp" 
#define DISPCD_EXT   u"0∘" APL_LIB u"D" BLANK_STR  

#define ALPHA  u'⍺'
#define CR     u'\r'
#define CRVIS  u'␍' 
#define DMND   u'⋄'   //APL DIAMOND (⋄) ⎕UCS 8900 
#define DNARO  u'↓'
#define DOL    u'$'
#define DQ     u'"' 
#define LBR    u'{'
#define LPAR   u'('
#define OMG    u'⍵'
#define OMG_US u'⍹'
#define PCT    u'%'
#define RBR    u'}'
#define QT     u'\''
#define RPAR   u')'
#define RTARO  u'→'
#define SP     u' '
#define SQ     u'\''
#define ZILDE  u'⍬'

// Mode enumeration 
#define MODE_STD     1
#define MODE_CODE    0 
#define MODE_LIST   -1
#define MODE_TABLE  -2

/* INPUT BUFFER ROUTINES */
/* CUR... Return current char, w/o checking bounds */
#define CUR_AT(ix)    fString[ix]
#define CUR           CUR_AT(inPos)
#define PEEK_AT(ix)   ((ix< fStringLen)? fString[ix]: -1)
/* PEEK... Return next char, checking that it's in range (else return -1) */
#define PEEK          PEEK_AT(inPos+1)
/* END INPUT BUFFER ROUTINES */

/* GENERIC OUTPUT BUFFER MANAGEMENT ROUTINES */ 
#define ADDBUF_GENERIC(str, strLen, grp, expandSq)  {\
        int len=strLen;\
        int ix;\
        if (grp##Len+len >= grp##Max) ERROR_SPACE;\
        if (expandSq){   \
        /* Slower path. Possible expansion of single quotes (APL rule) */ \
            for(ix=0; ix<len; (grp##Len)++, ix++){\
                grp##Buf[grp##Len]= (WIDE4) str[ix];\
                if (grp##Buf[grp##Len] == SQ) {\
                    if (grp##Len+1 >= grp##Max) ERROR_SPACE;\
                    grp##Buf[++(grp##Len)]= (WIDE4) SQ;\
                }\
            }\
        } else{\
         /* Faster path. Copy as is. */ \
            for(ix=0; ix<len; ){\
                  grp##Buf[(grp##Len)++]= (WIDE4) str[ix++];\
            }\
        }\
}
#define ADDCH_GENERIC(ch, grp) {\
      if (grp##Len+1 >= grp##Max) ERROR_SPACE;\
      grp##Buf[(grp##Len)++]= (WIDE4) ch;\
}

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutBuf(str, len)    ADDBUF_GENERIC(str, len, out, 0)
#define OutBufSq(str, len)  ADDBUF_GENERIC(str, len, out, 1)
#define OutStr(str)         OutBuf(str, Wide2Len((WIDE2 *) str))
#define OutCh(ch)           ADDCH_GENERIC(ch, out)

/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Handle special code buffer. 
   To transfer codeBuf to outBuf (and then "clear" it):
     CodeOut
*/
#define CodeInit             codeLen=0
#define CodeStr(str)         ADDBUF_GENERIC(str, Wide2Len((WIDE2 *)str), code, 0)  
#define CodeCh(ch)           ADDCH_GENERIC(ch, code)
#define CodeOut              {OutBuf(codeBuf, codeLen); CodeInit;} 

/* Any attempt to add a number bigger than 99999 will result in an APL Domain Error. */
#define CODENUM_MAXDIG    5
#define CODENUM_MAX   99999
#define CodeNum(num) {\
    char nstr[CODENUM_MAXDIG+1];\
    int  i;\
    int  tnum=num;\
    if (tnum>CODENUM_MAX){\
        ERROR(u"Omega variables must be between 0 and 99999", 11);\
        tnum=CODENUM_MAX;\
    }\
    snprintf(nstr, CODENUM_MAXDIG, "%d", tnum);\
    for (i=0;  i<CODENUM_MAXDIG && nstr[i]; ++i){\
        CodeCh((WIDE2)nstr[i]);\
    }\
}
/* End Handle Special code buffer */                  

#define STRLEN_MAX  512  
// Wide2Len(str)
//   <str> is a null-terminated WIDE2 string.
//   Returns the length of the string, sans the final null.
//   If there is no final null, we will either abnormally terminate or 
//   return a length of STRLEN_MAX.
static inline int Wide2Len(WIDE2 *str) {
    int len;
    for (len=0; len<STRLEN_MAX && str[len]; ++len)
        ;
    return len;
}

// Error handling  

#if USE_ALLOCA
   #define RETURN(n)   *outPLen = outLen;\
                      return(n)
#else
   #define RETURN(n)   *outPLen = outLen;\
                      if (codeBuf) free(codeBuf);\
                      codeBuf = NULL;\
                      return(n)
#endif 
   #define ERROR(str, err) { outLen=0; OutStr(str);\
                            RETURN(err);\
                          } 
   #define ERROR_SPACE     { outLen=0; \
                            RETURN(-1);\
                          }
// End Error Handling  

// STATE MANAGEMENT       
#define NONE      0      // not in a field 
#define TF       10      // text field 
#define CF_START 20      // starting a cf
#define CF       21      // in a code field or space field */
#define STATE(new)  { oldState=state; state=new;}
// End STATE MANAGEMENT 

static inline INT4 afterBlanks(WIDE4 fString[], INT4 fStringLen, int inPos){
    for (; inPos < fStringLen && SP == fString[inPos]; ++inPos)
           ;
    if (inPos>=fStringLen) 
        return -1;
    return fString[inPos];  // -1 if beyond end  
}

// Self-documenting Code Handler  
// Be sure <type> has any internal quotes doubled, as needed.
//Usage:
//      IfCodeDoc(merge)  // where merge has defined mergeCd and mergeMarker
//      else {...}
# define IfCodeDoc(marker, code) \
    if (bracketDepth == 1 && RBR == afterBlanks(fString+1, fStringLen, inPos)){\
      int i, m;\
      OutCh(QT);\
      for (i=cfStart; i< inPos; ++i) {\
        OutCh( fString[i] );\
        if (fString[i] == SQ)\
            OutCh(SQ);\
      }\
      OutStr(marker);\
      m = Wide2Len(marker);\
      for (i=inPos+1; fString[i] == SP; ++i){\
          if (--m <= 0)\ 
             OutCh(SP);\
      }\
      OutCh(QT); OutCh(SP);\
      OutStr(code);\
      OutCh(SP);\
      CodeOut;\
    } 
// END Self-documenting Code Handler  


// Scan4OmegaIx(oIx): 
//    Scanning input for digits, producing value for the name passed as oIx. 
//    At the same time, writes the digits to the code buffer.
#define Scan4OmegaIx(oIx)\
       CodeCh(CUR);\
       if (!isdigit(CUR))\
          ERROR(u"Logic Error: Omega not followed by digit", 911);\
       oIx=CUR-'0';\
       for (++inPos; inPos<fStringLen && isdigit(CUR); ++inPos) {\
          oIx = oIx * 10 + CUR-'0';\
          CodeCh(CUR);\
       }\
       --inPos;


int fs_format(const char opts[4], const WIDE4 escCh, 
              WIDE4 fString[],    INT4 fStringLen, 
              WIDE4 outBuf[],     INT4 *outPLen){ 
   INT4 outMax = *outPLen;          // User must pass in *outPLen as outBuf[outMax]  
   int mode=  opts[0];              // See modes (MODE_...) above
   int debug= opts[1];              // debug (boolean) 
   int useNs= opts[2];              // If 1, pass an anon ns to each Code Fn.           
   int extLib=opts[3];              // If 0, pseudo-primitives are defined internally.
   WIDE4 crOut= debug? CRVIS: CR;

  int outLen = 0;                        // output buffer length/position; passed back to APL.
  INT4 codeLen= 0;                       // length/position in code buffer. Like outLen.
  int inPos;                             // fString's (input's) "current" position
  int state=NONE;                        // what kind of field are we in: NONE, TF, CF_START, CF 
  int oldState=NONE;                     // last state
  int bracketDepth=0;                    // finding } closing a field.
  int omegaNext=0;                       // `⍵/⍹ processing.
  int cfStart=0;                         // Note start of code field in input-- for "doc" processing.

// Code buffer-- allows us to set aside generated code field (CF) code to the end, in case its a 
//    self-doc CF. If so, we output the doc literal text and append the processed CF code.
  const INT4 codeMax = outMax;
#if USE_ALLOCA
  WIDE4 *codeBuf = alloca( codeMax * sizeof(WIDE4));  // Automatically freed...
#else 
  WIDE4 *codeBuf = malloc( codeMax * sizeof(WIDE4));  // Manually freed...
#endif

// Code sequences...
WIDE2 *mergeCd = extLib? MERGECD_EXT: MERGECD_INT;
WIDE2 *aboveCd = extLib? ABOVECD_EXT: ABOVECD_INT;
WIDE2 *boxCd  =  extLib? BOXCD_EXT:   BOXCD_INT;
WIDE2 *fmtCd  =  FMTCD_INT;
WIDE2 *dispCd =  extLib? DISPCD_EXT:  DISPCD_INT;
// Markers for self-doc code 
WIDE2 *mergeMarker  = FANCY_MARKERS? u"▶": u"→"; 
WIDE2 *aboveMarker  = FANCY_MARKERS? u"▼": u"↓";

// Preamble code string...
  OutCh(LBR); 
  if (useNs) 
     OutStr(u"⍺←⎕NS⍬⋄");

  switch(mode){
    case MODE_STD:
      OutStr(mergeCd);
      break;
    case MODE_LIST:
      OutStr(dispCd); OutStr(u"¯1↓"); 
      break;
    case MODE_TABLE:
      OutStr(dispCd); OutStr(u"⍪¯1↓");  
      break;
    case MODE_CODE:
      OutStr(mergeCd);
      if (useNs)
         OutCh(ALPHA);
      OutCh(LBR);
      break;
    default:
      ERROR(u"Unknown mode option in left arg", 11);
  }

  for (inPos = 0; inPos < fStringLen; ++inPos) {
    // Logic for changing state (NONE, CF_START)
      if (state == NONE){
          if  (CUR!= LBR) {
            STATE(TF); 
            OutCh(QT);
          }else {
            STATE(CF_START);
            ++inPos;   // Move past the left brace
          }
      }
      if (state == CF_START){
            int i;
            int nspaces=0;
            if (oldState == TF){  // Terminate existing TF
                OutCh(QT); 
                OutCh(SP);
            }
          // cfStart marks start of code field (in case a self-documenting CF)
            cfStart= inPos;             // If a space field, this is ignored.
          // Skip leading blanks in CF/SF code, though NOT in any associated document strings 
            for (i=inPos; PEEK_AT(i) == SP; ++i){ 
                ++nspaces, ++inPos;
            }
          // See if we really have a SF: 0 or more (solely) blanks between matching braces.
            if (i < fStringLen && PEEK_AT(i) == RBR){  // Is a SF!
                if (nspaces){   
                      CodeStr(u"(''⍴⍨");
                      CodeNum(nspaces);
                      CodeCh(RPAR);
                      CodeOut;
                }
                STATE(NONE);    // Set state to NONE: SF is complete !
            }else {             // It's a CF.
                STATE(CF);
                bracketDepth=1;
                if (useNs)
                   OutStr(u"(⍺{")
                else 
                   OutStr(u"({"); 
                CodeInit;      // Ready to write code buffer (doesn't change output buffer).
            }
      }  
      if (state == TF) {       // Text field 
          if (CUR == escCh){   // Check for escape chars
            WIDE4 ch= PEEK; 
            ++inPos;
            if (ch == escCh){
                OutCh(escCh);
            }else if (ch == LBR || ch == RBR){
                OutCh(ch);
            }else if (ch == DMND){
                OutCh(crOut);
            }else{ 
                --inPos; 
                OutCh(CUR);
            } 
          } else if (CUR == LBR){
            STATE(CF_START);     // TF will end at (state == CF_START) above.
          } else {
            OutCh(CUR);
            if (CUR == QT)       // Double internal quotes per APL
              OutCh(QT); 
          }          
      }
      if (state == CF){          // Code field 
        if (CUR == RBR) {
            --bracketDepth;
            if (bracketDepth > 0) {
               CodeCh(CUR);
            }else {            // Terminating right brace: Ending Code Field!
              CodeOut;
              OutStr(u"}⍵)");
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
          for (inPos++; inPos<fStringLen; ++inPos){ 
              if (CUR == tcur){ 
                  if (PEEK == tcur) {
                      CodeCh(tcur);
                      if (tcur == SQ)
                          CodeCh(tcur);
                      ++inPos;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur == escCh){
                      if (PEEK == DMND) {
                          CodeCh(crOut);
                          ++inPos;
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
        // we see ⍹ or `⍵ (where ` is the current escape char)
          if (CUR == escCh) 
              ++inPos;                // Skip whatever was just matched (`⍵ or ⍹)
          if (isdigit(PEEK)){         // Is ⍹ or `⍵ followed by digits?
            ++inPos; 
            CodeStr(u"(⍵⊃⍨⎕IO+");
            int omegaIx;
            Scan4OmegaIx( omegaIx );
            omegaNext = omegaIx; 
            CodeCh(RPAR);
          }else {
            ++omegaNext;
            CodeStr(u"(⍵⊃⍨⎕IO+");
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
                 ++inPos;
               }
               for (; PEEK_AT(inPos+1) == DOL; ++inPos)
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
                  for (; PEEK_AT(inPos+1) == PCT; ++inPos)
                    ;
                }
                break;
            default:
                CodeCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (inPos...)*/
  if (state == TF) { 
      OutCh(QT);
      STATE(NONE);
  }else if (state != NONE){
      ERROR(u"Code or Space Field was not terminated properly", 11);
  }

  // Postamble Code String
  OutStr(u"⍬}");
  //   Mode 0: extra code because we need to input the format string (fString) 
  //           into the resulting function (see ∆F.dyalog).
  if (mode == MODE_CODE){
      OutStr(u"⍵,⍨⍥⊆"); 
      OutCh(SQ);
      OutBufSq(fString, fStringLen);
      OutCh(SQ);    
      OutCh(RBR);
  }else {
      OutCh(OMG);
  }

  RETURN(0);  /* 0= all ok */
}



