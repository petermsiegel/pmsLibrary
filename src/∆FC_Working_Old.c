/* fc: Uses 4-byte (32-bit) unicode chars throughout  202412 
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

// USE_ALLOCA: Use alloca to dynamically allocate codebuf on thestack
#define USE_ALLOCA
// USE_NS: If defined, a ⎕NS is passed as ⍺ for each Code Field

#define USE_NS 
// LIB_INLINE: If defined, put code string for key library routines (see below) inline.
//         If not, assume they are in a library
#define LIB_INLINE 

#define ADVANCED  

#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <ctype.h>
#ifdef USE_ALLOCA
#  include <stdlib.h>  // for alloca
#endif 

#define CHAR4  uint32_t       
#define  INT4   int32_t 

# define CRVIS U'␍' 
# define CR    U'\r'
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
#define GENERIC_STR(str, strLen, grp, expandSq)  {\
                  int len=strLen;\
                  int ix;\
                  if (*grp##PLen+len >= grp##Max) ERROR_SPACE;\
                  for(ix=0; ix<len; (*grp##PLen)++, ix++){\
                      grp##Buf[*grp##PLen]= (CHAR4) str[ix];\
                      if (grp##Buf[*grp##PLen]==SQ && expandSq)\
                          grp##Buf[*grp##PLen]= (CHAR4) str[ix];\
                  }\
}
#define GENERIC_CHR(ch, grp) {\
          if (*grp##PLen+1 >= grp##Max) ERROR_SPACE;\
          grp##Buf[(*grp##PLen)++]= (CHAR4) ch;\
}

/* OUTPUT BUFFER MANAGEMENT ROUTINES */
#define OutNStr(str, len)  GENERIC_STR(str, len, out, 0)
#define OutStr(str)        OutNStr(str, Str4Len(str))
// #define OutStrSq(str)      GENERIC_STR(str, Str4Len(str), out, 1)
#define OutCh(ch)          GENERIC_CHR(ch, out)

/* END OUTPUT BUFFER MANAGEMENT ROUTINES */

/* Handle special code buffer. 
   To transfer codeBuf to outBuf (and then "clear" it):
     Code2Out
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
int Str4Len( CHAR4* str) {
    int len;
    for (len=0; len<STRLEN_MAX && str[len]; ++len )
        ;
    return len;
}

/* Error handling */
#define ERROR(str, err) { *outPLen=0; OutStr(str); return(err); }

#define ERROR_SPACE { *outPLen=0;  return -1; }
/* End Error Handling */

#ifdef ADVANCED
typedef struct {
   CHAR4  *data;
    INT4   size;
    INT4   capacity;
} Vector;

Vector *VFree(Vector *v){
    if (!v) return NULL;
    if (v->data)
        free(v->data);
    free(v);
    return NULL;
}

Vector *VCreate() {
    Vector *v = malloc(sizeof(Vector));
    if (!v)
        return NULL;
    v->data = NULL;
    v->size = 0;
    v->capacity = 0;
    return v;
}

Vector **CreateFields(INT4 count){
    int i;
    Vector **fields = malloc( sizeof(Vector *) * count);
    if (!fields)
        return NULL;
    for (i=0; i< count; ++i)
         fields[i] = VCreate();
    return fields;
}

#define VGROWCHECK(nelem) \
    { INT4 newSize = v->size + nelem;\
      if (newSize >= v->capacity) {\
        do {\
          v->capacity = v->capacity == 0 ? nelem * 2 : v->capacity * 2;\
        } while (newSize >= v-> capacity);\
        v->data = realloc(v->data, v->capacity * sizeof(CHAR4));\
        if (!v->data)\
            return 0;\
      }\
    }
INT4 VAddCh(Vector *v, CHAR4 value) {
    VGROWCHECK(1);
    v->data[v->size++] = value;
    return v->size;
}
INT4 VAddNStr(Vector *v, CHAR4 *value, INT4 nelem) {
    int i;
    VGROWCHECK(nelem);
    for (i=0; i<nelem; ++i)
        v->data[v->size++] = value[i];
    return v->size;
}
INT4 VAddStr(Vector *v, CHAR4 *value) {
    int i;
    VGROWCHECK( Str4Len(value) );
    for (i=0; value[i]; ++i)
        v->data[v->size++] = value[i];
    return v->size;
}
#endif

/* STATE MANAGEMENT */       
#define NONE      0  /* not in a field */
#define TF       10  /* text field */
#define CF_START 20
#define CF       21  /* code field or space field */
#define STATE(new)  { oldState=state; state=new;}
/* END STATE MANAGEMENT */


INT4 afterBlanks(CHAR4 fString[], INT4 fStringLen, int cursor){
    for (; cursor<fStringLen && SP==fString[cursor]; ++cursor)
           ;
    if (cursor>=fStringLen) 
        return -1;            // ¯1: Blanks went all the way to the end of fString
    return fString[cursor];   
}

/* HERE DOCUMENT HANDLING */
// Be sure <type> has any internal quotes doubled, as needed.
# define IF_IS_DOC(type) \
    if (bracketDepth==1 && RBR==afterBlanks(fString+1, fStringLen, cursor)){\
      int i;\
      OutCh(QT);\
      for (i=cfStart; i< cursor; ++i) {\
        OutCh( fString[i] );\
        if (fString[i]==SQ)\
            OutCh(SQ);\
      }\
      for (i=cursor+1; fString[i]==SP; ++i)\
          OutCh(SP);\
      OutCh(QT); OutCh(SP);\
      OutStr(type);\
      OutCh(SP);\
      CodeOut;\
    } 
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

int fc(INT4 opts[4], CHAR4 fString[], INT4 fStringLen, CHAR4 outBuf[], INT4 *outPLen){
  INT4 outMax = *outPLen;        // User must pass in *outPLen as outBuf[outMax]  
  *outPLen = 0;                  // We will pass back *outPLen as actual chars used           
// Code buffer
#ifdef USE_ALLOCA
  INT4 codeMax = outMax;
  CHAR4 *codeBuf = alloca( codeMax * sizeof(CHAR4));
#else 
# define CODEBUF_MAX 512          // Test. Should be dynamically same as outMax
  CHAR4 codeBuf[CODEBUF_MAX];    // Use codeBuf=alloca(outMax*sizeof CHAR4)
  INT4  codeMax = CODEBUF_MAX;
#endif 
  INT4 codePLen[1]={0};

  int cursor;                    // fString (input) "cursor" position
  int state=NONE;
  int oldState=NONE;
  int debug=opts[2];
  int escCh=opts[3];             // User tells us escCh character as unicode #  
  CHAR4 crOut= debug? CRVIS: CR;
  int bracketDepth=0;
  int omegaNext=0;
  int cfStart=0;
  // Library for use within code for pseudo-primitives $, %, %%.
  #ifdef LIB_INLINE 
    //    Over: field ⍺ is centered over field ⍵
    CHAR4 overCd[]= U"{⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}";
    //    Cat (dyadic):  field ⍺ is catenated to field ⍵ left to right
    CHAR4 catCd[]= U"{⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}";
    //    Box (ambivalent): Box item to its right
    CHAR4 boxCd[]= U"{⎕SE.Dyalog.Utils.display ,⍣(0=⍴⍴⍵)⊢⍵}";
    //    ⎕FMT: Formatting (dyadic)
    CHAR4 fmtCd[]= U" ⎕FMT ";
  #else
    // See above. Library is assumed to be established.
    // Note spacing required.
    CHAR4 overCd[]= U" ⎕SE.∆FLib.Ovr ";
    //    See above
    CHAR4 catCd[]= U" ⎕SE.∆FLib.Cat ";
    //    See above
    CHAR4 boxCd[]= U" ⎕SE.∆FLib.Box ";
    //    See above
    CHAR4 fmtCd[]= U" ⎕FMT ";
  #endif 

  /* testing only-- clear output str. */
  {int ix;
   for (ix=0; ix< outMax; ++ix)
       outBuf[ix]=SP;
  }
  
  OutCh(LBR); 
  #ifdef USE_NS
  OutStr(U"⍺←⎕NS⍬⋄")
  #endif

  for (cursor=0; cursor<fStringLen; ++cursor) {
    // Logic for changing state (NONE, CF_START)
      if (state==NONE){
          if  (CUR!= LBR) {
            STATE(TF); 
            OutCh(QT);
          }else {
            STATE(CF_START);
            ++cursor;
          }
      }
      if (state==CF_START){
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
#ifdef USE_NS 
                OutStr(U"(⍺{");
#else 
                OutStr(U"({"); 
#endif
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
                OutCh(crOut);
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
      }
      if (state==CF){
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
                          CodeCh(crOut);
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
            CodeStr(U"(⍵⊃⍨⎕IO+");
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
            case DOL:  // Pseudo-builtins $ (⎕FMT) and $$ (Box, i.e. dfns display)
               if (PEEK!=DOL){
                 CodeStr(fmtCd);
               }else {
                 CodeStr(boxCd);
                 ++cursor;
               }
               for (; PEEK_AT(cursor+1)==DOL; ++cursor)
                  ;
               break;
           case RTARO:
                IF_IS_DOC(catCd)
                else {
                  CodeCh(CUR);
                }
                break;
            case DNARO:
                IF_IS_DOC(overCd)
                else {
                  CodeCh(CUR);
                }
                break;
            case PCT: // Pseudo-builtin % (Over) 
                IF_IS_DOC(overCd)
                else {
                  CodeStr(overCd);  
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

// FINISHING UP!
  if (state==TF) { 
      OutCh(QT);
      STATE(NONE);
  }
  OutCh(RBR); 
  return 0;  /* 0= all ok */
}



