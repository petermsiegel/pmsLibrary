/* fc: Uses 4-byte (32-bit) unicode chars throughout   
   Name Assoc (in your namespace, ns):  
       '∆F4_C' ns.⎕NA 'I4 ∆F.dylib|fs_format4 <I1[4] <C4   <C4[]   I4         >C4[]  =I4' 
       '∆F4_C' ns.⎕NA 'I4 ∆F.dylib|fs_format2 <I1[4] <C4   <C2[]   I4         >C2[]  =I4'   
                       rc                     opts   escCh fString fStringLen outBuf outLen*
                                                                              * <max output, >actual output
   Compile with: 
       cc -O3 -c -o ∆F4.temp -D WIDTH=4 ∆F.c
       cc -O3 -c -o ∆F2.temp -D WIDTH=2 ∆F.c
       cc -dynamiclib -o ∆F.dylib ∆F4.temp ∆F2.temp
       rm ∆F4.temp ∆F2.temp 
   Returns: 
       rc outBuf outLen.  
   If rc≠¯1, APL code executes 
       out← outLen↑outBuf
   to get execute-ready code or (rc>0) the generated error message.
   rc=¯1:   output buffer not big enough for transformed fString.
            In this case, the output buffer is not examined (and may contain junk).
            outLen↑outBuf is a null string.
   rc> 0:   an error occurred.  
            rc is the APL error number (e.g. 11 for DOMAIN ERROR)
            outLen↑outBuf is the error message.
   rc= 0:   all is well. 
            outLen↑outBuf is the execute-ready code, transformed from the f-string input.
   Note: Strings fString and outBuf are never terminated with 0. 
         They may validly contain 0 or any unicode char in any position.
*/

// APL_LIB: Enter the name of the namespace housing the "library" fns 
//          Code  Name   Description
//          --    M     merge ⍺⍵ or elements of ⍵; 
//          %     A     combine ⍺ above ⍵; 
//          $     ⎕FMT  Call Dyalog ⎕FMT (1- or 2-adic)
//          $$    B     box [display] object ⍵, to its right; 
//          --    D     display entire object generated.
#define APL_LIB    u"⎕SE.⍙F."

// USE_ALLOCA: Use alloca to dynamically allocate codeBuf on thestack.
//             Otherwise, use malloc.
#define USE_ALLOCA 1

// FANCY_MARKERS:  For displaying F-String Self Documenting Code {...→} plus {...↓} or {...%},
//                 choose symbols  ▼ and ▶ if 1,  OR  ↓ and →, if 0.
#define FANCY_MARKERS 1

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#include <stdlib.h>  // for alloca and also for free...

// WIDE4 or WIDE2 -- width of input AND output chars...
// Use -D to change WIDTH to 2:  -D WIDTH=2
#ifndef WIDTH 
   #define WIDTH 4        
#endif 
#define WIDE4  uint32_t  
#define WIDE2  uint16_t 
#if WIDTH==2
   #define WIDE WIDE2
#else 
   #define WIDE WIDE4
#endif      

#define INT4   int32_t 

// Specify code for library calls (internal: code included in result; external: calls a library in APL_LIB)
#define LIB_CALL1(fn)       u" " APL_LIB fn u" "
//       Join: pseudo-primitive, joins fields (possibly differently-shaped char arrays) left-to-right
#define MERGECD_INT  u"{⎕ML←1 ⋄⍺←⊢⋄ ⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}"
#define MERGECD_EXT  LIB_CALL1( u"M" )
//       Over: center field ⍺ over field ⍵
#define ABOVECD_INT  u"{⎕ML←1 ⋄ ⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}"
#define ABOVECD_EXT  LIB_CALL1( u"A" )
//       Box: Box item to its right
#define BOXCD_INT    u"{⎕ML←1⋄1∘⎕SE.Dyalog.Utils.disp ,⍣(⊃0=⍴⍴⍵)⊢⍵}"
#define BOXCD_EXT    LIB_CALL1( u"B" )
//       ⎕FMT: Formatting (dyadic)
#define FMTCD_INT    u" ⎕FMT "
// dfn ¨disp¨, used as a prefix for LIST and TABLE modes. 
#define DISPCD_INT   u"0∘⎕SE.Dyalog.Utils.disp" 
#define DISPCD_EXT   LIB_CALL1( u"D" )

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
#define PEEK_AT(ix)   (((ix) < fStringLen)? fString[ix]: -1)
/* PEEK... Return NEXT char, checking range bounds. If not, return -1 */
#define PEEK          PEEK_AT(inPos+1)
/* END INPUT BUFFER ROUTINES */

// GENERIC OUTPUT BUFFER MANAGEMENT ROUTINES 
typedef struct {
    WIDE *buf;
    int   len;
    int   max;
} buffer ;

#define ADDBUF(str, strLen, grp, expandSq)  {\
        int len=strLen;\
        int ix;\
        if (grp.len+len >= grp.max) ERROR_SPACE;\
        if (expandSq){   \
        /* SQ doubling: Slower path. */ \
            for(ix=0; ix<len; (grp.len)++, ix++){\
                grp.buf[grp.len]= (WIDE) str[ix];\
                if (grp.buf[grp.len] == SQ) {\
                    if (grp.len+1 >= grp.max) ERROR_SPACE;\
                    grp.buf[++(grp.len)]= (WIDE) SQ;\
                }\
            }\
        } else{\
         /* No SQ doubling: Faster path. */ \
            for(ix=0; ix<len; ){\
                  grp.buf[(grp.len)++]= (WIDE) str[ix++];\
            }\
        }\
}
#define ADDCH(ch, grp) {\
      if (grp.len+1 >= grp.max) ERROR_SPACE;\
      grp.buf[(grp.len)++]= (WIDE) ch;\
} 

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutBuf(str, len)    ADDBUF(str, len, out, 0)
#define OutBufSq(str, len)  ADDBUF(str, len, out, 1)
#define OutStr(str)         OutBuf(str, Wide2Len((WIDE2 *) str))
#define OutCh(ch)           ADDCH(ch, out)
/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

// CODE BUFFER MANAGEMENT ROUTINES  
// Handle special code buffer. 
// To transfer codeBuf to outBuf (and then "clear" it):
//    CodeOut
#define CodeInit             code.len=0
#define CodeStr(str)         ADDBUF(str, Wide2Len((WIDE2 *)str), code, 0)  
#define CodeCh(ch)           ADDCH(ch, code)
#define CodeOut              {OutBuf(code.buf, code.len); CodeInit;} 
// END CODE BUFFER MANAGEMENT ROUTINES  

// Any attempt to add a number bigger than 99999 will result in an APL Domain Error.  
// Used in routines to decode omegas: `⍵nnn, and so on.
#define IX_ERR u"Omega index or space field width too large (>99999)"
#define IX_MAXDIG    5
#define IX_MAX   99999
#define Ix2CodeBuf(num) {\
    char nstr[IX_MAXDIG+1];\
    int  i;\
    int  tnum=num;\
    if (tnum>IX_MAX){\
        ERROR(IX_ERR, 11);\
        tnum=IX_MAX;\
    }\
    snprintf(nstr, IX_MAXDIG+1, "%d", tnum);\
    for (i=0;  i<IX_MAXDIG && nstr[i]; ++i){\
        CodeCh((WIDE2)nstr[i]);\
    }\
}

// Wide2Len(str)
//   <str> is a null-terminated WIDE2 string.
//   Returns the length of the string, sans the final null.
//   If there is no final null, we will either abnormally terminate or 
//   return a length of STRLEN_MAX. 
static inline int Wide2Len(WIDE2 *str) {
    int len;
    #define STRLEN_MAX  512
    for (len=0; len<STRLEN_MAX && str[len]; ++len)
        ;
    return len;
}

// Termination Code
#if USE_ALLOCA
   #define RETURN(rc)   *outPLen = out.len;\
                      return(rc)
#else /* using malloc/free */
   #define RETURN(rc)   *outPLen = out.len;\
                      if (code.buf) free(code.buf);\
                      code.buf = NULL;\
                      return(rc)
#endif 

// Error handling-- must be called within scope of main function below!
#define ERROR(str, errno) { out.len=0;  OutStr(str); RETURN(errno); } 
/* ERROR_SPACE: Ran out of space. Error msg generated in ∆F.dyalog */ 
#define ERROR_SPACE     { out.len=0; RETURN(-1); }
// End Error Handling  

// STATE MANAGEMENT       
#define NONE      0      // not in a field 
#define TF        1      // in a text field 
#define CF_START  2      // starting a cf
#define CF        3      // in a code field or space field */
#define STATE(new)  { oldState=state; state=new;}
// End STATE MANAGEMENT 

static inline INT4 afterBlanks(WIDE fString[], INT4 fStringLen, int inPos){
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


// Scan4Ix(destVar): 
//    Scanning input for digits, producing value for the name passed as destVar. 
//    At the same time, writes the digits to the code buffer.
#define Scan4Ix(destVar)\
       CodeCh(CUR);\
       if (!isdigit(CUR))\
          ERROR(u"Logic Error: Expected digit after esc-omega (`⍵) not found", 911);\
       destVar=CUR-'0';\
       for (++inPos; inPos<fStringLen && isdigit(CUR); ++inPos) {\
          destVar = destVar * 10 + CUR-'0';\
          CodeCh(CUR);\
       }\
       if (destVar > IX_MAX)\
           ERROR(IX_ERR, 11);\
       --inPos;


#if WIDTH==4 
      int fs_format4( 
#else
      int fs_format2(
#endif 
              const char opts[4], const WIDE4 escCh, 
              WIDE fString[],     INT4 fStringLen, 
              WIDE outBuf[],      INT4 *outPLen
){ 
   buffer out;
     out.buf = outBuf;
     out.max = *outPLen;
     out.len = 0;                   // output buffer length/position; passed back to APL as *outPLen = out.len;
   int mode=  opts[0];              // See modes (MODE_...) above
   int debug= opts[1];              // debug (boolean) 
   int useNs= opts[2];              // If 1, pass an anon ns to each Code Fn.           
   int extLib=opts[3];              // If 0, pseudo-primitives are defined internally.
   WIDE crOut= debug? CRVIS: CR;
                       
  int inPos;                             // fString's (input's) "current" position
  int state=NONE;                        // what kind of field are we in: NONE, TF, CF_START, CF 
  int oldState=NONE;                     // last state
  int bracketDepth=0;                    // finding } closing a field.
  int omegaNext=0;                       // `⍵/⍹ processing.
  int cfStart=0;                         // Note start of code field in input-- for "doc" processing.

// Code buffer-- allows us to set aside generated code field (CF) code to the end, in case its a 
//    self-doc CF. If so, we output the doc literal text and append the processed CF code:
//          'code_text_verbatim_quoted' ("▶" | "▼") code_text_processed
  buffer code;
    code.len = 0;
    code.max = out.max;
#if USE_ALLOCA
    code.buf = alloca(code.max * sizeof(WIDE));  // Automatically freed...
#else 
    code.buf = malloc(code.max  * sizeof(WIDE));  // Manually freed...
#endif


// Code sequences...
WIDE2 *mergeCd = extLib? MERGECD_EXT: MERGECD_INT;
WIDE2 *aboveCd = extLib? ABOVECD_EXT: ABOVECD_INT;
WIDE2 *boxCd  =  extLib? BOXCD_EXT:   BOXCD_INT;
WIDE2 *fmtCd  =  FMTCD_INT;
WIDE2 *dispCd =  extLib? DISPCD_EXT:  DISPCD_INT;
// Markers for self-doc code. Drawback: the fancy markers are wider than std Dyalog characters. 
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
                      Ix2CodeBuf(nspaces);
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
            WIDE ch= PEEK; 
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
                      int ch=PEEK; 
                      if (ch == DMND) {
                          CodeCh(crOut);
                          ++inPos;
                      }else if (ch == escCh){
                          CodeCh(escCh);
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
            ++inPos;                  // Yes: `⍵NNN or ⍹NNN. 
            CodeStr(u"(⍵⊃⍨⎕IO+");
            int ix;
            Scan4Ix( ix );            // Read in the index NNN... 
            omegaNext = ix;           // ... and set omegaNext.
            CodeCh(RPAR);
          }else {                     // No: a bare `⍵ or ⍹ 
            ++omegaNext;              // Increment omegaNext
            CodeStr(u"(⍵⊃⍨⎕IO+");     // Write: "(⍵⊃⍨⎕IO+<omegaNext>""
            Ix2CodeBuf(omegaNext);    // ...
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

// get2lib: Returns a (null-terminated) character string containing the ⍙F library routines
//          M, A, B, D (merge, above, box, display).
#if WIDTH==2
  void get2lib( WIDE2 libStr[] ){
    #define EOS     u"⋄"
    #define LIB1    u"M←" MERGECD_INT EOS
    #define LIB2    u"A←" ABOVECD_INT EOS
    #define LIB3    u"B←" BOXCD_INT   EOS 
    #define LIB4    u"D←" DISPCD_INT  
    WIDE2 code[] = LIB1 LIB2 LIB3 LIB4;
    int len = Wide2Len(code)+1;
    int i;
    for (i=0; i< len; ++i)
          libStr[i] = code[i];
}
#endif 

