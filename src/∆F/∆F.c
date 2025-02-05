/* fc: Uses 4-byte (32-bit) unicode chars throughout   
   Name Assoc (in your namespace, ns):  
       '∆F4_C' ns.⎕NA 'I4 ∆F.dylib|fs_format4 <I1[4] <C4   <#C4[]  >#C4[]  I4' 
       '∆F4_C' ns.⎕NA 'I4 ∆F.dylib|fs_format2 <I1[4] <C4   <#C2[]  >#C2[]  I4'   
                       rc                     opts   escCh fStrIn cStrOut outLen
                                                                              * <max output, >actual output
   Compile with: 
       cc -O3 -c -o ∆F4.temp -D WIDTH=4 ∆F.c
       cc -O3 -c -o ∆F2.temp -D WIDTH=2 ∆F.c
       cc -dynamiclib -o ∆F.dylib ∆F4.temp ∆F2.temp
       rm ∆F4.temp ∆F2.temp 
   Returns: 
       rc cStrOut, where cStrOut contains its length ( >#C2 or >#C4 ⎕NA format)
   If rc≠¯1, cStrOut is a string (rc=0: code, or rc>0: error message).
   to get execute-ready code or (rc>0) the generated error message.
   rc=¯1:   output buffer not big enough for transformed fStrIn.
            In this case, the output buffer is not examined.
            cStrOut is a null string (length 0).
   rc> 0:   an error occurred.  
            rc is the APL error number (e.g. 11 for DOMAIN ERROR)
            cStrOut is the error message.
   rc= 0:   all is well. 
            cStrOut is the execute-ready code in string form, transformed from the f-string input.
   Note: Strings fStrIn and cStrOut are never terminated with 0. 
         They may validly contain 0 or any unicode char in any position.
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#include <stdlib.h>  // for alloca and also for free...

// APL_LIB: Enter the name of the namespace housing the "library" fns 
//          Code  Name   Description
//          --    M     merge ⍺⍵ or elements of ⍵; 
//          %     A     combine ⍺ above ⍵; 
//          $     ⎕FMT  Call Dyalog ⎕FMT (1- or 2-adic)
//          $$    B     box [display] object ⍵, to its right; 
//          --    D     display entire object generated.
#define APL_LIB    u"⎕SE.⍙F."

// USE_VLA: Use variable length arrays ((VLAs: dynamic arrays) where possible 
//          for arrays dependent on size passed from Dyalog.
#define USE_VLA (!__STDC_NO_VLA__)

// FANCY_MARKERS:  For displaying F-String Self Documenting Code {...→} plus {...↓} or {...%},
//                 choose symbols  ▼ and ▶ if 1,  OR  ↓ and →, if 0.
#define FANCY_MARKERS 1

// WIDE4 or WIDE2 -- width of input AND output chars...
// Use -D to change WIDTH to 2:  -D WIDTH=2
#ifndef WIDTH 
   #define WIDTH 4        
#endif 
#define INT4   int32_t 
#define WIDE4  uint32_t  
#define WIDE2  uint16_t 
#if WIDTH==2
   #define WIDE WIDE2
#else 
   #define WIDE WIDE4
#endif      

#include "∆F_MACROS.h"

#if WIDTH==4 
      int fs_format4( 
#else
      int fs_format2(
#endif 
              const char opts[5], const WIDE4 escCh, 
              lpString *fStrIn, lpString *cStrOut, uint32_t outMax
){ 
   enum mode 
       mode=   opts[0];        // See modeEnum
   int debug=  opts[1];             // debug (boolean) 
   int boxAll= opts[2];             // if 1, use B instead of M overall. 
   int useNs=  opts[3];             // If 1, pass an anon ns to each Code Fn.           
   int extLib= opts[4];             // If 0, pseudo-primitives are defined internally.
   WIDE crOut= debug? CRVIS: CR;
                       
  enum state 
     state=None,                    // what kind of field are we in: None, TF, CF_START, CF 
     oldState=None;                 // last state
  int bracketDepth=0;               // finding } closing a field.
  int omegaNext=0;                  // `⍵/⍹ processing.
  int cfStart=0;                    // Note start of code field in input-- for "doc" processing.

  buffer in;
    in.buf = fStrIn->buf;
    in.max = fStrIn->len;
    in.cur = 0;
  buffer out;
    out.buf = cStrOut->buf;
    out.max = outMax;
    out.cur = 0;                   // output buffer length/position; passed back to APL as cStrOut->len = out.cur;
// Code buffer-- allows us to set aside generated code field (CF) code to the end, in case its a 
//    self-doc CF. If so, we output the doc literal text and append the processed CF code:
//          'code_text_verbatim_quoted' ("▶" | "▼") code_text_processed
  buffer code;
#if USE_VLA 
    WIDE codeBuf[out.max];
    code.buf = codeBuf;
#else 
    code.buf = malloc(out.max * sizeof(WIDE));  // Manually freed...
#endif
    code.max = out.max;
    code.cur = 0;

// Code sequences...
WIDE2 *mergeCd = extLib? MERGECD_EXT: MERGECD_INT;
WIDE2 *aboveCd = extLib? ABOVECD_EXT: ABOVECD_INT;
WIDE2 *boxCd  =  extLib? BOXCD_EXT:   BOXCD_INT;
WIDE2 *dispCd=   extLib? DISPCD_EXT:  DISPCD_INT;
WIDE2 *fmtCd  =  FMTCD_INT;

// Markers for self-doc code. Drawback: the fancy markers are wider than std Dyalog characters. 
WIDE2 *mergeMarker  = FANCY_MARKERS? u"▶": u"→"; 
WIDE2 *aboveMarker  = FANCY_MARKERS? u"▼": u"↓";

// Preamble code string...
  OutCh(LBR); 
  if (useNs) 
     OutSC(u"⍺←⎕NS⍬⋄");

  switch(mode){
    case modeStd:
      OutS( boxAll? dispCd: mergeCd );
      break;
    case modeList:
      OutS(dispCd);
      break;
    case modeTable:
      OutS(dispCd);
      OutCh(u'⍪');
      break;
    case modeCode:
      OutS( boxAll? dispCd: mergeCd );
      if (useNs)
         OutCh(ALPHA);
      OutCh(LBR);
      break;
    default:
      ERROR(u"Unknown mode option in left arg", 11);
  }

  for (in.cur = 0; in.cur < in.max; SKIP) {
    // Logic for changing state (None, CF_START)
      if (state == None){
          if  (CUR!= LBR) {
            STATE(TF); 
            OutCh(QT);
          }else {
            STATE(CF_START);
            SKIP;   // Move past the left brace
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
            cfStart= in.cur;             // If a space field, this is ignored.
          // Skip leading blanks in CF/SF code, though NOT in any associated document strings 
            for (i=in.cur; PEEK_AT(i) == SP; ++i){ 
                ++nspaces, SKIP;
            }
          // See if we really have a SF: 0 or more (solely) blanks between matching braces.
            if (i < in.max && PEEK_AT(i) == RBR){  // Is a SF!
                if (nspaces){   
                      CodeSC(u"(''⍴⍨");
                      Ix2CodeBuf(nspaces);
                      CodeCh(RPAR);
                      CodeOut;
                }
                STATE(None);    // Set state to None: SF is complete !
            }else {             // It's a CF.
                STATE(CF);
                bracketDepth=1;
                if (useNs)
                   OutSC(u"(⍺{")
                else 
                   OutSC(u"({"); 
                CodeInit;      // Ready to write code buffer (doesn't change output buffer).
            }
      }  
      if (state == TF) {       // Text field 
          if (CUR == escCh){   // Check for escape chars
            WIDE ch= PEEK; 
            SKIP;
            if (ch == escCh){
                OutCh(escCh);
            }else if (ch == LBR || ch == RBR){
                OutCh(ch);
            }else if (ch == DMND){
                OutCh(crOut);
            }else{ 
                --in.cur; 
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
              OutSC(u"}⍵)");
              bracketDepth=0;
              STATE(None);
            }
        }else if (CUR == LBR) {
          ++bracketDepth;
          CodeCh(CUR);
        }else if (CUR == SQ || CUR == DQ){
          int i;
          int tcur=CUR;
          CodeCh(SQ);
          for (SKIP; in.cur<in.max; SKIP){ 
              if (CUR == tcur){ 
                  if (PEEK == tcur) {
                      CodeCh(tcur);
                      if (tcur == SQ)
                          CodeCh(tcur);
                      SKIP;
                  }else {
                      break;
                  }
              }else{
                  int tcur=CUR;
                  if (tcur == escCh){
                      int ch=PEEK; 
                      if (ch == DMND) {
                          CodeCh(crOut);
                          SKIP;
                      }else if (ch == escCh){
                          CodeCh(escCh);
                          SKIP;
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
              SKIP;                // Skip whatever was just matched (`⍵ or ⍹)
          if (isdigit(PEEK)){         // Is ⍹ or `⍵ followed by digits?
            SKIP;                  // Yes: `⍵NNN or ⍹NNN. 
            CodeSC(u"(⍵⊃⍨⎕IO+");
            int ix;
            Scan4Ix( ix );            // Read in the index NNN... 
            omegaNext = ix;           // ... and set omegaNext.
            CodeCh(RPAR);
          }else {                     // No: a bare `⍵ or ⍹ 
            ++omegaNext;              // Increment omegaNext
            CodeSC(u"(⍵⊃⍨⎕IO+");     // Write: "(⍵⊃⍨⎕IO+<omegaNext>""
            Ix2CodeBuf(omegaNext);    // ...
            CodeCh(RPAR); 
          }
        }else {
          switch(CUR) {
            #define SKIP_SP while (PEEK==SP) SKIP 
            case DOL:  // Pseudo-builtins $ (⎕FMT) and $$ (Box, i.e. dfns display)
                if (PEEK==DOL) {       // useful: $$; otherwise extra $$, $ are redundant. Ignore
                    SKIP; SKIP_SP;
                    if (PEEK==DOL)
                      CodeS(fmtCd)    // box ⎕FMT is equiv. to ⎕FMT, since monadic format generates simple mx.
                    else
                      CodeS(boxCd);
                    while (PEEK==DOL || PEEK==SP) 
                      SKIP;                   
                }else {
                    CodeS(fmtCd);      // useful: $. Any following $$, $$ are redundant. Ignore
                    SKIP_SP;
                    while (PEEK==DOL||PEEK==SP) SKIP;
                }
                while (PEEK==DOL||PEEK==SP)  // Ignore extra $...
                    SKIP;
                break;
            case PCT:      // Pseudo-builtin % (Over)   
                if (IsCodeDoc()) {
                   ProcCodeDoc(aboveMarker, aboveCd);
                } else {  // Optimize multiple |% *| sequences into at most two calls to aboveCd.
                  CodeS(aboveCd);         // This first call to aboveCd may have a left arg (⍺).
                  int extraPct = 0;
                  SKIP_SP;
                  while (PEEK==PCT) {
                      SKIP, ++extraPct;
                      SKIP_SP;
                  }
                  if (extraPct) { /* We see more than one % (w/ opt'l spaces) in a row. 
                                     Emit one one additional abovceCd call. */
                      CodeS(u"(⍪''⍴⍨") ; Ix2CodeBuf(extraPct); CodeS(u")"); 
                      CodeS(aboveCd);
                  }
                }
                break;
           case RTARO:   
                if (IsCodeDoc()) {
                  ProcCodeDoc(mergeMarker, mergeCd);
                }else {
                  CodeCh(CUR);
                }
                break;
            case DNARO:
                if (IsCodeDoc()) {
                  ProcCodeDoc(aboveMarker, aboveCd);
                } else {
                  CodeCh(CUR);
                }
                break;
            case SP:   /* Conflate multiple blanks => " " (one blank) */
                SKIP_SP;
            default:
                CodeCh(CUR); /* Catchall */
          }
        }
      }
  } /* for (in.cur...)*/
  if (state == TF) { 
      OutCh(QT);
      STATE(None);
  }else if (state != None){
      ERROR(u"Code or Space Field was not terminated properly", 11);
  }

  // Postamble Code String
  OutSC(u"⍬}");
  //   Mode 0: extra code because we need to input the format string (fStrIn) 
  //           into the resulting function (see ∆F.dyalog).
  if (mode == modeCode){
      OutSC(u"⍵,⍨⍥⊆"); 
      OutCh(SQ);
      OutBufSq(in.buf, in.cur);
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
  void get2lib( WIDE2 strOut[] ){
    #define ABOVEDEF   u"A←" ABOVECD_INT 
    #define BOXDEF     u"B←" BOXCD_INT    
    #define DISPDEF    u"D←" DISPCD_INT  
    #define MERGEDEF   u"M←" MERGECD_INT 
    #define EOS        u"⋄" 
    const WIDE2 code[] = ABOVEDEF EOS BOXDEF EOS DISPDEF EOS MERGEDEF;
    int len = sizeof(code) / sizeof(*code);    // includes the null get2Lib expects.
    for (int i=0; i< len; ++i)
          strOut[i] = code[i];
}
#endif 

static inline WIDE CharAfterBlanks( buffer *pIn, int cur ){
    for ( ; cur < pIn->max && SP == pIn->buf[cur]; ++cur)
        ;
    if (cur >= pIn->max) 
        return -1;
    return pIn->buf[cur];  // -1 if beyond end  
}

// S2Len(str)
//   <str> is a null-terminated WIDE2 string.
//   Returns the length of the string, sans the final null.
//   If there is no final null, we will either abnormally terminate or 
//   return a length of STRLEN_MAX. 
static inline int S2Len(WIDE2 *str) {
    int len;
    #define STRLEN_MAX  512
    for (len=0; len<STRLEN_MAX && str[len]; ++len)
        ;
    return len;
}

